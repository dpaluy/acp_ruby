# frozen_string_literal: true

require "test_helper"
require "json"

class TestWireFormat < Minitest::Test
  include AgentClientProtocol::Helpers
  S = AgentClientProtocol::Schema

  # Verify that serialized messages match the expected ACP wire format

  def test_initialize_request_wire_format
    req = S::InitializeRequest.new(
      protocol_version: 1,
      client_info: S::Implementation.new(name: "test", version: "1.0")
    )
    h = req.to_h
    assert_equal 1, h["protocolVersion"]
    assert_equal "test", h["clientInfo"]["name"]
    assert_equal "1.0", h["clientInfo"]["version"]
  end

  def test_session_update_wire_format
    update = update_agent_message_text("thinking...")
    h = update.to_h

    assert_equal "agent_message_chunk", h["sessionUpdate"]
    assert_equal "text", h["content"]["type"]
    assert_equal "thinking...", h["content"]["text"]
  end

  def test_tool_call_wire_format
    tc = start_tool_call(
      "tc-1", "Read file",
      kind: S::ToolKind::READ,
      status: S::ToolCallStatus::IN_PROGRESS
    )
    h = tc.to_h

    assert_equal "tool_call", h["sessionUpdate"]
    assert_equal "tc-1", h["toolCallId"]
    assert_equal "Read file", h["title"]
    assert_equal "read", h["kind"]
    assert_equal "in_progress", h["status"]
  end

  def test_content_block_roundtrip
    original = S::TextContent.new(text: "hello")
    h = original.to_h
    json = JSON.generate(h)
    parsed = JSON.parse(json)
    restored = S::ContentBlock.parse(parsed)

    assert_instance_of S::TextContent, restored
    assert_equal "hello", restored.text
    assert_equal original, restored
  end

  def test_session_notification_wire_format
    notif = session_notification("sess-1", update_agent_message_text("hi"))
    h = notif.to_h

    assert_equal "sess-1", h["sessionId"]
    assert_equal "agent_message_chunk", h["update"]["sessionUpdate"]
    assert_equal "text", h["update"]["content"]["type"]
    assert_equal "hi", h["update"]["content"]["text"]
  end

  def test_prompt_request_with_content_blocks
    blocks = [
      S::TextContent.new(text: "first").to_h,
      S::TextContent.new(text: "second").to_h
    ]
    req = S::PromptRequest.new(session_id: "s1", prompt: blocks)
    h = req.to_h

    assert_equal 2, h["prompt"].size
    assert_equal "text", h["prompt"][0]["type"]
    assert_equal "first", h["prompt"][0]["text"]
    assert_equal "second", h["prompt"][1]["text"]
  end

  def test_permission_request_wire_format
    req = S::RequestPermissionRequest.new(
      session_id: "s1",
      tool_call: S::ToolCallUpdate.new(tool_call_id: "tc-1", title: "Run bash"),
      options: [
        S::PermissionOption.new(
          option_id: "approve",
          name: "Approve",
          kind: S::PermissionOptionKind::ALLOW_ONCE
        )
      ]
    )
    h = req.to_h

    assert_equal "s1", h["sessionId"]
    assert_equal "tc-1", h["toolCall"]["toolCallId"]
    assert_equal 1, h["options"].size
    assert_equal "approve", h["options"][0]["optionId"]
    assert_equal "allow_once", h["options"][0]["kind"]
  end

  def test_json_roundtrip_preserves_all_fields
    # Build a complex object and verify JSON roundtrip
    original = S::NewSessionRequest.new(
      cwd: "/home/user",
      mcp_servers: [
        S::McpServerStdio.new(
          name: "test-server",
          command: "node",
          args: ["server.js"],
          env: {"PORT" => "3000"}
        )
      ]
    )

    json = original.to_json
    parsed = JSON.parse(json)
    restored = S::NewSessionRequest.from_hash(parsed)

    assert_equal "/home/user", restored.cwd
    assert_equal 1, restored.mcp_servers.size
  end

  def test_discriminator_preserved_in_serialization
    # TextContent should include "type": "text"
    tc = S::TextContent.new(text: "hello")
    assert_equal "text", tc.to_h["type"]

    # ImageContent should include "type": "image"
    ic = S::ImageContent.new(data: "b64", mime_type: "image/png")
    assert_equal "image", ic.to_h["type"]

    # AudioContent should include "type": "audio"
    ac = S::AudioContent.new(data: "b64", mime_type: "audio/wav")
    assert_equal "audio", ac.to_h["type"]

    # ToolCall should include "sessionUpdate": "tool_call"
    tool = S::ToolCall.new(tool_call_id: "tc-1", title: "Test")
    assert_equal "tool_call", tool.to_h["sessionUpdate"]

    # ToolCallUpdate should include "sessionUpdate": "tool_call_update"
    upd = S::ToolCallUpdate.new(tool_call_id: "tc-1")
    assert_equal "tool_call_update", upd.to_h["sessionUpdate"]

    # Plan should include "sessionUpdate": "plan"
    plan = S::Plan.new(entries: [])
    assert_equal "plan", plan.to_h["sessionUpdate"]
  end
end
