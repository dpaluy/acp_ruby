# frozen_string_literal: true

module AgentClientProtocol
  module ClientInterface
    def on_connect(conn)
      raise NotImplementedError, "#{self.class}#on_connect"
    end

    def session_update(session_id:, update:, **)
      nil
    end

    def request_permission(session_id:, tool_call:, options:, **)
      raise NotImplementedError, "#{self.class}#request_permission"
    end

    def read_text_file(session_id:, path:, line: nil, limit: nil, **)
      raise RequestError.method_not_found("fs/read_text_file")
    end

    def write_text_file(session_id:, path:, content:, **)
      raise RequestError.method_not_found("fs/write_text_file")
    end

    def create_terminal(session_id:, command:, args: nil, cwd: nil, env: nil, **)
      raise RequestError.method_not_found("terminal/create")
    end

    def terminal_output(session_id:, terminal_id:, **)
      raise RequestError.method_not_found("terminal/output")
    end

    def release_terminal(session_id:, terminal_id:, **)
      raise RequestError.method_not_found("terminal/release")
    end

    def wait_for_terminal_exit(session_id:, terminal_id:, **)
      raise RequestError.method_not_found("terminal/wait_for_exit")
    end

    def kill_terminal(session_id:, terminal_id:, **)
      raise RequestError.method_not_found("terminal/kill")
    end

    def ext_method(method, params)
      raise RequestError.method_not_found(method)
    end

    def ext_notification(method, params)
      nil
    end
  end
end
