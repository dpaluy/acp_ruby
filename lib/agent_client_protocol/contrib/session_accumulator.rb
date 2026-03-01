# frozen_string_literal: true

module AgentClientProtocol
  module Contrib
    class SessionAccumulator
      SessionSnapshot = Struct.new(
        :session_id, :tool_calls, :plan_entries, :current_mode_id,
        :available_commands, :user_messages, :agent_messages, :agent_thoughts,
        :config_options,
        keyword_init: true
      ) do
        def freeze
          tool_calls&.freeze
          plan_entries&.freeze
          available_commands&.freeze
          user_messages&.freeze
          agent_messages&.freeze
          agent_thoughts&.freeze
          config_options&.freeze
          super
        end
      end

      def initialize
        reset
        @subscribers = []
      end

      def reset
        @session_id = nil
        @tool_calls = {}
        @plan_entries = []
        @current_mode_id = nil
        @available_commands = []
        @user_messages = []
        @agent_messages = []
        @agent_thoughts = []
        @config_options = []
      end

      def apply(notification)
        notif = normalize(notification)
        session_id = notif[:session_id]
        update = notif[:update]

        # Reset on session change
        if @session_id && @session_id != session_id
          reset
        end
        @session_id = session_id

        apply_update(update)

        snap = snapshot
        @subscribers.each { |cb| cb.call(snap, notification) }
        snap
      end

      def snapshot
        SessionSnapshot.new(
          session_id: @session_id,
          tool_calls: @tool_calls.dup,
          plan_entries: @plan_entries.dup,
          current_mode_id: @current_mode_id,
          available_commands: @available_commands.dup,
          user_messages: @user_messages.dup,
          agent_messages: @agent_messages.dup,
          agent_thoughts: @agent_thoughts.dup,
          config_options: @config_options.dup
        ).freeze
      end

      def subscribe(&block)
        @subscribers << block
      end

      private

      def normalize(notification)
        case notification
        when Schema::SessionNotification
          {session_id: notification.session_id, update: notification.update}
        when Hash
          sid = notification["sessionId"] || notification[:session_id]
          upd = notification["update"] || notification[:update]
          {session_id: sid, update: upd}
        else
          {session_id: notification.session_id, update: notification.update}
        end
      end

      def apply_update(update)
        return unless update

        session_update_type = case update
                              when TaggedUpdate
                                update.tag
                              when Hash
                                update["sessionUpdate"] || update[:session_update]
                              when Schema::BaseModel
                                update.to_h["sessionUpdate"]
                              end

        case session_update_type
        when "user_message_chunk"
          content = extract_content(update)
          @user_messages << content if content
        when "agent_message_chunk"
          content = extract_content(update)
          @agent_messages << content if content
        when "agent_thought_chunk"
          content = extract_content(update)
          @agent_thoughts << content if content
        when "tool_call"
          tc_id = extract_field(update, "toolCallId", :tool_call_id)
          @tool_calls[tc_id] = update if tc_id
        when "tool_call_update"
          tc_id = extract_field(update, "toolCallId", :tool_call_id)
          @tool_calls[tc_id] = merge_tool_call(@tool_calls[tc_id], update) if tc_id
        when "plan"
          entries = extract_field(update, "entries", :entries)
          @plan_entries = entries || []
        when "available_commands_update"
          commands = extract_field(update, "availableCommands", :available_commands)
          @available_commands = commands || []
        when "current_mode_update"
          @current_mode_id = extract_field(update, "currentModeId", :current_mode_id)
        when "config_option_update"
          options = extract_field(update, "configOptions", :config_options)
          @config_options = options || []
        end
      end

      def extract_content(update)
        case update
        when Hash
          update["content"] || update[:content]
        when Schema::ContentChunk
          update.content
        else
          update.respond_to?(:content) ? update.content : nil
        end
      end

      def extract_field(update, json_key, ruby_key)
        case update
        when Hash
          update[json_key] || update[ruby_key]
        else
          update.respond_to?(ruby_key) ? update.send(ruby_key) : nil
        end
      end

      def merge_tool_call(existing, update)
        # Just replace with the update — the update contains the latest state
        update
      end
    end
  end
end
