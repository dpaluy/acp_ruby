# frozen_string_literal: true

module AgentClientProtocol
  module Agent
    S = Schema

    module_function

    def build_router(handler)
      router = AgentClientProtocol::Router.new

      router.on_request("initialize", request_class: S::InitializeRequest) do |params|
        handler.initialize_agent(
          protocol_version: params.protocol_version,
          client_capabilities: params.client_capabilities,
          client_info: params.client_info
        )
      end

      router.on_request("authenticate", request_class: S::AuthenticateRequest, optional: true) do |params|
        handler.authenticate(method_id: params.method_id)
      end

      router.on_request("session/new", request_class: S::NewSessionRequest) do |params|
        handler.new_session(cwd: params.cwd, mcp_servers: params.mcp_servers)
      end

      router.on_request("session/load", request_class: S::LoadSessionRequest, optional: true) do |params|
        handler.load_session(
          cwd: params.cwd,
          session_id: params.session_id,
          mcp_servers: params.mcp_servers
        )
      end

      router.on_request("session/prompt", request_class: S::PromptRequest) do |params|
        handler.prompt(prompt: params.prompt, session_id: params.session_id)
      end

      router.on_notification("session/cancel", request_class: S::CancelNotification) do |params|
        handler.cancel(session_id: params.session_id)
      end

      router.on_request("session/set_mode", request_class: S::SetSessionModeRequest, optional: true) do |params|
        handler.set_session_mode(mode_id: params.mode_id, session_id: params.session_id)
      end

      router.on_request("session/set_config_option", request_class: S::SetSessionConfigOptionRequest, optional: true) do |params|
        handler.set_config_option(
          config_id: params.config_id,
          session_id: params.session_id,
          value: params.value
        )
      end

      router.on_ext_method { |method, params| handler.ext_method(method, params) }
      router.on_ext_notification { |method, params| handler.ext_notification(method, params) }

      router
    end
  end
end
