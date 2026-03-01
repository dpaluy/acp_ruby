# frozen_string_literal: true

require_relative "router"

module AgentClientProtocol
  module Client
    class Connection
      attr_reader :conn

      def initialize(handler, reader, writer)
        @handler = handler
        router = Client.build_router(handler)
        @conn = AgentClientProtocol::Connection.new(
          reader: reader,
          writer: writer,
          handler: router.method(:call)
        )
        handler.on_connect(self)
      end

      # --- Agent-calling methods (client sends to agent) ---

      def initialize_agent(protocol_version:, client_capabilities: nil, client_info: nil)
        params = Schema::InitializeRequest.new(
          protocol_version: protocol_version,
          client_capabilities: client_capabilities,
          client_info: client_info
        )
        result = @conn.send_request("initialize", params.to_h)
        Schema::InitializeResponse.from_hash(result)
      end

      def new_session(cwd:, mcp_servers: [])
        params = Schema::NewSessionRequest.new(cwd: cwd, mcp_servers: mcp_servers)
        result = @conn.send_request("session/new", params.to_h)
        Schema::NewSessionResponse.from_hash(result)
      end

      def load_session(cwd:, session_id:, mcp_servers: [])
        params = Schema::LoadSessionRequest.new(
          cwd: cwd,
          session_id: session_id,
          mcp_servers: mcp_servers
        )
        result = @conn.send_request("session/load", params.to_h)
        Schema::LoadSessionResponse.from_hash(result)
      end

      def prompt(session_id:, prompt:)
        prompt_blocks = case prompt
                        when String
                          [Schema::TextContent.new(text: prompt).to_h]
                        when Array
                          prompt.map { |b| b.is_a?(Schema::BaseModel) ? b.to_h : b }
                        else
                          [prompt.is_a?(Schema::BaseModel) ? prompt.to_h : prompt]
                        end

        params = Schema::PromptRequest.new(
          session_id: session_id,
          prompt: prompt_blocks
        )
        result = @conn.send_request("session/prompt", params.to_h)
        Schema::PromptResponse.from_hash(result)
      end

      def cancel(session_id:)
        params = Schema::CancelNotification.new(session_id: session_id)
        @conn.send_notification("session/cancel", params.to_h)
      end

      def authenticate(method_id:)
        params = Schema::AuthenticateRequest.new(method_id: method_id)
        result = @conn.send_request("authenticate", params.to_h)
        Schema::AuthenticateResponse.from_hash(result)
      end

      def set_session_mode(session_id:, mode_id:)
        params = Schema::SetSessionModeRequest.new(
          session_id: session_id,
          mode_id: mode_id
        )
        result = @conn.send_request("session/set_mode", params.to_h)
        Schema::SetSessionModeResponse.from_hash(result)
      end

      def set_config_option(session_id:, config_id:, value:)
        params = Schema::SetSessionConfigOptionRequest.new(
          session_id: session_id,
          config_id: config_id,
          value: value
        )
        result = @conn.send_request("session/set_config_option", params.to_h)
        Schema::SetSessionConfigOptionResponse.from_hash(result)
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
