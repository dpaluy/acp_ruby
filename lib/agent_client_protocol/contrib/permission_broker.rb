# frozen_string_literal: true

module AgentClientProtocol
  module Contrib
    class PermissionBroker
      def initialize(requester:, tracker: nil)
        @requester = requester
        @tracker = tracker
      end

      def request_for(external_id, session_id:, description: nil, options: nil, content: nil, tool_call: nil)
        tc = tool_call
        if tc.nil? && @tracker
          tc = @tracker.tool_call_model(external_id)
        end
        tc ||= Schema::ToolCallUpdate.new(
          tool_call_id: external_id,
          title: description || external_id
        )

        opts = options || default_permission_options

        @requester.call(
          session_id: session_id,
          tool_call: tc,
          options: opts
        )
      end

      def self.default_permission_options
        [
          Schema::PermissionOption.new(
            option_id: "approve",
            name: "Approve",
            kind: Schema::PermissionOptionKind::ALLOW_ONCE
          ),
          Schema::PermissionOption.new(
            option_id: "approve_session",
            name: "Approve for session",
            kind: Schema::PermissionOptionKind::ALLOW_ALWAYS
          ),
          Schema::PermissionOption.new(
            option_id: "reject",
            name: "Reject",
            kind: Schema::PermissionOptionKind::REJECT_ONCE
          )
        ]
      end

      private

      def default_permission_options
        self.class.default_permission_options
      end
    end
  end
end
