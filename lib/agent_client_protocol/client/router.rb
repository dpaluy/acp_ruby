# frozen_string_literal: true

module AgentClientProtocol
  module Client
    S = Schema

    module_function

    def build_router(handler)
      router = AgentClientProtocol::Router.new

      router.on_notification("session/update", request_class: S::SessionNotification) do |params|
        handler.session_update(session_id: params.session_id, update: params.update)
      end

      router.on_request("session/request_permission", request_class: S::RequestPermissionRequest) do |params|
        handler.request_permission(
          session_id: params.session_id,
          tool_call: params.tool_call,
          options: params.options
        )
      end

      router.on_request("fs/read_text_file", request_class: S::ReadTextFileRequest, optional: true) do |params|
        handler.read_text_file(
          session_id: params.session_id,
          path: params.path,
          line: params.line,
          limit: params.limit
        )
      end

      router.on_request("fs/write_text_file", request_class: S::WriteTextFileRequest, optional: true) do |params|
        handler.write_text_file(
          session_id: params.session_id,
          path: params.path,
          content: params.content
        )
      end

      router.on_request("terminal/create", request_class: S::CreateTerminalRequest, optional: true) do |params|
        handler.create_terminal(
          session_id: params.session_id,
          command: params.command,
          args: params.args,
          cwd: params.cwd,
          env: params.env
        )
      end

      router.on_request("terminal/output", request_class: S::TerminalOutputRequest, optional: true) do |params|
        handler.terminal_output(
          session_id: params.session_id,
          terminal_id: params.terminal_id
        )
      end

      router.on_request("terminal/release", request_class: S::ReleaseTerminalRequest, optional: true) do |params|
        handler.release_terminal(
          session_id: params.session_id,
          terminal_id: params.terminal_id
        )
      end

      router.on_request("terminal/wait_for_exit", request_class: S::WaitForTerminalExitRequest, optional: true) do |params|
        handler.wait_for_terminal_exit(
          session_id: params.session_id,
          terminal_id: params.terminal_id
        )
      end

      router.on_request("terminal/kill", request_class: S::KillTerminalCommandRequest, optional: true) do |params|
        handler.kill_terminal(
          session_id: params.session_id,
          terminal_id: params.terminal_id
        )
      end

      router.on_ext_method { |method, params| handler.ext_method(method, params) }
      router.on_ext_notification { |method, params| handler.ext_notification(method, params) }

      router
    end
  end
end
