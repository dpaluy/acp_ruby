# frozen_string_literal: true

require "json"
require "async"

module AgentClientProtocol
  class Connection
    JSONRPC_VERSION = "2.0"

    attr_reader :reader, :writer

    def initialize(reader:, writer:, handler:)
      @reader = reader
      @writer = writer
      @handler = handler
      @next_id = 0
      @pending = {} # id -> Async::Promise
      @mutex = Mutex.new
      @closed = false
    end

    def send_request(method, params = nil)
      id = next_id
      variable = Async::Promise.new

      @mutex.synchronize { @pending[id] = variable }

      msg = {"jsonrpc" => JSONRPC_VERSION, "id" => id, "method" => method}
      msg["params"] = params if params
      @writer.write(msg)

      result = variable.wait
      if result.is_a?(Hash) && result.key?("__error__")
        raise RequestError.from_hash(result["__error__"])
      end
      result
    end

    def send_notification(method, params = nil)
      msg = {"jsonrpc" => JSONRPC_VERSION, "method" => method}
      msg["params"] = params if params
      @writer.write(msg)
    end

    def listen
      @reader.each do |message|
        process_message(message)
      end
    rescue IOError, Errno::EPIPE
      # Connection closed
    ensure
      close
    end

    def close
      return if @closed

      @closed = true

      # Reject all pending requests
      @mutex.synchronize do
        @pending.each_value do |var|
          var.resolve({"__error__" => {"code" => -32603, "message" => "Connection closed"}}) unless var.resolved?
        end
        @pending.clear
      end

      @reader.close
      @writer.close
    end

    def closed?
      @closed
    end

    private

    def next_id
      @mutex.synchronize { @next_id += 1 }
    end

    def process_message(message)
      has_method = message.key?("method")
      has_id = message.key?("id")

      if has_method && has_id
        handle_request(message)
      elsif has_method
        handle_notification(message)
      elsif has_id
        handle_response(message)
      end
    end

    def handle_request(message)
      id = message["id"]
      method = message["method"]
      params = message["params"]

      begin
        result = @handler.call(method, params, false)
        send_response(id, result: result)
      rescue RequestError => e
        send_response(id, error: e.to_h)
      rescue => e
        send_response(id, error: RequestError.internal_error(e.message).to_h)
      end
    end

    def handle_notification(message)
      method = message["method"]
      params = message["params"]

      @handler.call(method, params, true)
    rescue RequestError
      # Notifications don't send error responses
    rescue => e
      # Log but don't propagate — notifications are fire-and-forget
      $stderr.puts("ACP notification handler error: #{e.message}") if $DEBUG
    end

    def handle_response(message)
      id = message["id"]
      variable = @mutex.synchronize { @pending.delete(id) }
      return unless variable

      if message.key?("error")
        variable.resolve({"__error__" => message["error"]})
      else
        variable.resolve(message["result"])
      end
    end

    def send_response(id, result: nil, error: nil)
      msg = {"jsonrpc" => JSONRPC_VERSION, "id" => id}
      if error
        msg["error"] = error
      else
        msg["result"] = result
      end
      @writer.write(msg)
    end
  end
end
