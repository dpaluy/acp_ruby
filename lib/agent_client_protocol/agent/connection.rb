# frozen_string_literal: true

require_relative "router"

module AgentClientProtocol
  module Agent
    class Connection
      attr_reader :conn

      def initialize(handler, reader, writer)
        @handler = handler
        router = Agent.build_router(handler)
        @conn = AgentClientProtocol::Connection.new(
          reader: reader,
          writer: writer,
          handler: router.method(:call)
        )
        handler.on_connect(self)
      end

      # --- Client-calling methods (agent sends to client) ---

      def session_update(session_id:, update:)
        params = Schema::SessionNotification.new(
          session_id: session_id,
          update: update
        )
        @conn.send_notification("session/update", params.to_h)
      end

      def request_permission(session_id:, tool_call:, options:)
        params = Schema::RequestPermissionRequest.new(
          session_id: session_id,
          tool_call: tool_call.is_a?(Schema::BaseModel) ? tool_call : Schema::ToolCallUpdate.from_hash(tool_call),
          options: options
        )
        result = @conn.send_request("session/request_permission", params.to_h)
        Schema::RequestPermissionResponse.from_hash(result)
      end

      def read_text_file(session_id:, path:, line: nil, limit: nil)
        params = Schema::ReadTextFileRequest.new(
          session_id: session_id,
          path: path,
          line: line,
          limit: limit
        )
        result = @conn.send_request("fs/read_text_file", params.to_h)
        Schema::ReadTextFileResponse.from_hash(result)
      end

      def write_text_file(session_id:, path:, content:)
        params = Schema::WriteTextFileRequest.new(
          session_id: session_id,
          path: path,
          content: content
        )
        result = @conn.send_request("fs/write_text_file", params.to_h)
        Schema::WriteTextFileResponse.from_hash(result)
      end

      def create_terminal(session_id:, command:, args: nil, cwd: nil, env: nil)
        params = Schema::CreateTerminalRequest.new(
          session_id: session_id,
          command: command,
          args: args,
          cwd: cwd,
          env: env
        )
        result = @conn.send_request("terminal/create", params.to_h)
        Schema::CreateTerminalResponse.from_hash(result)
      end

      def terminal_output(session_id:, terminal_id:)
        params = Schema::TerminalOutputRequest.new(
          session_id: session_id,
          terminal_id: terminal_id
        )
        result = @conn.send_request("terminal/output", params.to_h)
        Schema::TerminalOutputResponse.from_hash(result)
      end

      def release_terminal(session_id:, terminal_id:)
        params = Schema::ReleaseTerminalRequest.new(
          session_id: session_id,
          terminal_id: terminal_id
        )
        result = @conn.send_request("terminal/release", params.to_h)
        Schema::ReleaseTerminalResponse.from_hash(result)
      end

      def wait_for_terminal_exit(session_id:, terminal_id:)
        params = Schema::WaitForTerminalExitRequest.new(
          session_id: session_id,
          terminal_id: terminal_id
        )
        result = @conn.send_request("terminal/wait_for_exit", params.to_h)
        Schema::WaitForTerminalExitResponse.from_hash(result)
      end

      def kill_terminal(session_id:, terminal_id:)
        params = Schema::KillTerminalCommandRequest.new(
          session_id: session_id,
          terminal_id: terminal_id
        )
        result = @conn.send_request("terminal/kill", params.to_h)
        Schema::KillTerminalCommandResponse.from_hash(result)
      end

      # --- Lifecycle ---

      def listen
        @conn.listen
      end

      def close
        @conn.close
      end

      def closed?
        @conn.closed?
      end
    end
  end
end
