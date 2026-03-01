# frozen_string_literal: true

module AgentClientProtocol
  module AgentInterface
    def on_connect(conn)
      raise NotImplementedError, "#{self.class}#on_connect"
    end

    def initialize_agent(protocol_version:, client_capabilities: nil, client_info: nil, **)
      raise NotImplementedError, "#{self.class}#initialize_agent"
    end

    def new_session(cwd:, mcp_servers: nil, **)
      raise NotImplementedError, "#{self.class}#new_session"
    end

    def prompt(prompt:, session_id:, **)
      raise NotImplementedError, "#{self.class}#prompt"
    end

    def cancel(session_id:, **)
      nil
    end

    def authenticate(method_id:, **)
      raise NotImplementedError, "#{self.class}#authenticate"
    end

    def load_session(cwd:, session_id:, mcp_servers: nil, **)
      nil
    end

    def set_session_mode(mode_id:, session_id:, **)
      nil
    end

    def set_config_option(config_id:, session_id:, value:, **)
      nil
    end

    def ext_method(method, params)
      raise RequestError.method_not_found(method)
    end

    def ext_notification(method, params)
      nil
    end
  end
end
