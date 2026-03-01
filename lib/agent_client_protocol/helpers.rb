# frozen_string_literal: true

module AgentClientProtocol
  module Helpers
    # --- Content blocks ---

    def text_block(text)
      Schema::TextContent.new(text: text)
    end

    def image_block(data, mime_type, uri: nil)
      Schema::ImageContent.new(data: data, mime_type: mime_type, uri: uri)
    end

    def audio_block(data, mime_type)
      Schema::AudioContent.new(data: data, mime_type: mime_type)
    end

    def resource_link_block(name:, uri:, mime_type: nil, size: nil, description: nil, title: nil)
      Schema::ResourceLink.new(
        name: name, uri: uri, mime_type: mime_type,
        size: size, description: description, title: title
      )
    end

    def embedded_text_resource(uri:, text:, mime_type: nil)
      Schema::TextResourceContents.new(uri: uri, text: text, mime_type: mime_type)
    end

    def embedded_blob_resource(uri:, blob:, mime_type: nil)
      Schema::BlobResourceContents.new(uri: uri, blob: blob, mime_type: mime_type)
    end

    def resource_block(resource)
      Schema::EmbeddedResource.new(resource: resource)
    end

    # --- Tool call content ---

    def tool_content(block)
      Schema::Content.new(content: block)
    end

    def tool_diff_content(path, new_text, old_text: nil)
      Schema::Diff.new(path: path, new_text: new_text, old_text: old_text)
    end

    def tool_terminal_ref(terminal_id)
      Schema::Terminal.new(terminal_id: terminal_id)
    end

    # --- Session updates ---
    # These return TaggedUpdate objects that include the sessionUpdate discriminator
    # when serialized, matching the wire format.

    def update_agent_message(content)
      TaggedUpdate.new("agent_message_chunk", Schema::ContentChunk.new(content: content))
    end

    def update_agent_message_text(text)
      update_agent_message(text_block(text))
    end

    def update_user_message(content)
      TaggedUpdate.new("user_message_chunk", Schema::ContentChunk.new(content: content))
    end

    def update_user_message_text(text)
      update_user_message(text_block(text))
    end

    def update_agent_thought(content)
      TaggedUpdate.new("agent_thought_chunk", Schema::ContentChunk.new(content: content))
    end

    def update_agent_thought_text(text)
      update_agent_thought(text_block(text))
    end

    def update_available_commands(commands)
      TaggedUpdate.new("available_commands_update",
        Schema::AvailableCommandsUpdate.new(available_commands: commands))
    end

    def update_current_mode(current_mode_id)
      TaggedUpdate.new("current_mode_update",
        Schema::CurrentModeUpdate.new(current_mode_id: current_mode_id))
    end

    def update_config_options(config_options)
      TaggedUpdate.new("config_option_update",
        Schema::ConfigOptionUpdate.new(config_options: config_options))
    end

    # --- Plans ---

    def plan_entry(content, priority: Schema::PlanEntryPriority::MEDIUM, status: Schema::PlanEntryStatus::PENDING)
      Schema::PlanEntry.new(content: content, priority: priority, status: status)
    end

    def update_plan(entries)
      TaggedUpdate.new("plan", Schema::Plan.new(entries: entries))
    end

    # --- Tool calls ---

    def start_tool_call(tool_call_id, title, kind: nil, status: nil, content: nil, locations: nil, raw_input: nil, raw_output: nil)
      TaggedUpdate.new("tool_call", Schema::ToolCall.new(
        tool_call_id: tool_call_id,
        title: title,
        kind: kind,
        status: status,
        content: content,
        locations: locations,
        raw_input: raw_input,
        raw_output: raw_output
      ))
    end

    def update_tool_call(tool_call_id, title: nil, kind: nil, status: nil, content: nil, locations: nil, raw_input: nil, raw_output: nil)
      TaggedUpdate.new("tool_call_update", Schema::ToolCallUpdate.new(
        tool_call_id: tool_call_id,
        title: title,
        kind: kind,
        status: status,
        content: content,
        locations: locations,
        raw_input: raw_input,
        raw_output: raw_output
      ))
    end

    # --- Notification wrapper ---

    def session_notification(session_id, update)
      Schema::SessionNotification.new(session_id: session_id, update: update)
    end
  end

  # A session update tagged with its discriminator value.
  # Serializes to include the "sessionUpdate" key in the wire format.
  class TaggedUpdate
    attr_reader :tag, :model

    def initialize(tag, model)
      @tag = tag
      @model = model
    end

    def to_h
      h = @model.is_a?(Schema::BaseModel) ? @model.to_h : @model
      {"sessionUpdate" => @tag}.merge(h)
    end

    def to_json(*)
      JSON.generate(to_h, *)
    end

    # Delegate attribute access to the underlying model
    def respond_to_missing?(method, include_private = false)
      @model.respond_to?(method, include_private) || super
    end

    def method_missing(method, ...)
      if @model.respond_to?(method)
        @model.send(method, ...)
      else
        super
      end
    end

    def inspect
      "#<TaggedUpdate tag=#{@tag.inspect} #{@model.inspect}>"
    end
  end
end
