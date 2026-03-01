# frozen_string_literal: true

require "securerandom"

module AgentClientProtocol
  module Contrib
    class ToolCallTracker
      TrackedToolCallView = Struct.new(
        :external_id, :tool_call_id, :title, :kind, :status,
        :content, :locations, :raw_input, :raw_output, :stream_text,
        keyword_init: true
      )

      def initialize(id_factory: -> { SecureRandom.hex(16) })
        @id_factory = id_factory
        @tracked = {} # external_id -> TrackedToolCallView
      end

      def start(external_id, title:, kind: nil, status: nil, content: nil, locations: nil, raw_input: nil, raw_output: nil)
        tool_call_id = @id_factory.call
        view = TrackedToolCallView.new(
          external_id: external_id,
          tool_call_id: tool_call_id,
          title: title,
          kind: kind,
          status: status || Schema::ToolCallStatus::PENDING,
          content: content || [],
          locations: locations || [],
          raw_input: raw_input,
          raw_output: raw_output,
          stream_text: ""
        )
        @tracked[external_id] = view

        Schema::ToolCall.new(
          tool_call_id: tool_call_id,
          title: title,
          kind: kind,
          status: status || Schema::ToolCallStatus::PENDING,
          content: content,
          locations: locations,
          raw_input: raw_input,
          raw_output: raw_output
        )
      end

      def progress(external_id, title: nil, kind: nil, status: nil, content: nil, locations: nil, raw_input: nil, raw_output: nil)
        view = @tracked[external_id]
        raise ArgumentError, "Unknown tool call: #{external_id}" unless view

        view.title = title if title
        view.kind = kind if kind
        view.status = status if status
        view.content = content if content
        view.locations = locations if locations
        view.raw_input = raw_input if raw_input
        view.raw_output = raw_output if raw_output

        Schema::ToolCallUpdate.new(
          tool_call_id: view.tool_call_id,
          title: title,
          kind: kind,
          status: status,
          content: content,
          locations: locations,
          raw_input: raw_input,
          raw_output: raw_output
        )
      end

      def append_stream_text(external_id, text, title: nil, status: nil)
        view = @tracked[external_id]
        raise ArgumentError, "Unknown tool call: #{external_id}" unless view

        view.stream_text = (view.stream_text || "") + text
        view.title = title if title
        view.status = status if status

        Schema::ToolCallUpdate.new(
          tool_call_id: view.tool_call_id,
          title: title,
          status: status,
          raw_output: view.stream_text
        )
      end

      def view(external_id)
        view = @tracked[external_id]
        raise ArgumentError, "Unknown tool call: #{external_id}" unless view

        TrackedToolCallView.new(**view.to_h)
      end

      def tool_call_model(external_id)
        v = @tracked[external_id]
        raise ArgumentError, "Unknown tool call: #{external_id}" unless v

        Schema::ToolCallUpdate.new(
          tool_call_id: v.tool_call_id,
          title: v.title,
          kind: v.kind,
          status: v.status,
          content: v.content,
          locations: v.locations,
          raw_input: v.raw_input,
          raw_output: v.raw_output
        )
      end

      def forget(external_id)
        @tracked.delete(external_id)
      end
    end
  end
end
