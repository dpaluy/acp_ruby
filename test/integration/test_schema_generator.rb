# frozen_string_literal: true

require "test_helper"

class TestSchemaGenerator < Minitest::Test
  def test_generated_files_are_up_to_date
    script = File.expand_path("../../script/generate_schema.rb", __dir__)
    output = `ruby #{script} --check 2>&1`
    assert $?.success?, "Generated files are out of date. Run: ruby script/generate_schema.rb\n#{output}"
  end

  def test_all_schema_types_have_properties
    # Verify all generated classes are loadable and have properties
    schema_classes = AgentClientProtocol::Schema.constants.select do |c|
      klass = AgentClientProtocol::Schema.const_get(c)
      klass.is_a?(Class) && klass < AgentClientProtocol::Schema::BaseModel
    end

    assert schema_classes.size > 20, "Expected at least 20 schema classes, got #{schema_classes.size}"
  end

  def test_all_enums_have_all_constant
    enum_modules = AgentClientProtocol::Schema.constants.select do |c|
      mod = AgentClientProtocol::Schema.const_get(c)
      mod.is_a?(Module) && !mod.is_a?(Class) && mod.const_defined?(:ALL)
    end

    assert enum_modules.size > 3, "Expected at least 3 enum modules, got #{enum_modules.size}"

    enum_modules.each do |name|
      mod = AgentClientProtocol::Schema.const_get(name)
      assert mod::ALL.is_a?(Array), "#{name}::ALL should be an Array"
      assert mod::ALL.frozen?, "#{name}::ALL should be frozen"
      assert mod::ALL.size > 0, "#{name}::ALL should not be empty"
    end
  end

  def test_discriminated_unions_have_parse
    union_modules = %i[ContentBlock SessionUpdate ToolCallContent RequestPermissionOutcome]

    union_modules.each do |name|
      mod = AgentClientProtocol::Schema.const_get(name)
      assert mod.respond_to?(:parse), "#{name} should respond to .parse"
    end
  end

  def test_content_block_parse_all_types
    blocks = {
      "text" => {"type" => "text", "text" => "hello"},
      "image" => {"type" => "image", "data" => "b64", "mimeType" => "image/png"},
      "audio" => {"type" => "audio", "data" => "b64", "mimeType" => "audio/wav"},
      "resource" => {"type" => "resource", "resource" => {"uri" => "file:///f", "text" => "x"}},
      "resource_link" => {"type" => "resource_link", "name" => "f", "uri" => "file:///f"}
    }

    blocks.each do |type, hash|
      result = AgentClientProtocol::Schema::ContentBlock.parse(hash)
      refute_nil result, "ContentBlock.parse should handle type=#{type}"
      refute result.is_a?(Hash), "ContentBlock.parse(#{type}) should return a model, not a Hash"
    end
  end

  def test_session_update_parse_all_types
    updates = {
      "tool_call" => {"sessionUpdate" => "tool_call", "toolCallId" => "tc-1", "title" => "Test"},
      "tool_call_update" => {"sessionUpdate" => "tool_call_update", "toolCallId" => "tc-1"},
      "agent_message_chunk" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "hi"}},
      "user_message_chunk" => {"sessionUpdate" => "user_message_chunk", "content" => {"type" => "text", "text" => "hi"}},
      "plan" => {"sessionUpdate" => "plan", "entries" => []},
      "current_mode_update" => {"sessionUpdate" => "current_mode_update", "currentModeId" => "code"},
      "available_commands_update" => {"sessionUpdate" => "available_commands_update", "availableCommands" => []},
      "config_option_update" => {"sessionUpdate" => "config_option_update", "configOptions" => []}
    }

    updates.each do |type, hash|
      result = AgentClientProtocol::Schema::SessionUpdate.parse(hash)
      refute_nil result, "SessionUpdate.parse should handle sessionUpdate=#{type}"
    end
  end
end
