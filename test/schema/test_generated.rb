# frozen_string_literal: true

require "test_helper"

class TestGeneratedSchema < Minitest::Test
  S = AgentClientProtocol::Schema

  def test_text_content_roundtrip
    tc = S::TextContent.new(text: "hello world")
    assert_equal "hello world", tc.text
    h = tc.to_h
    assert_equal({"type" => "text", "text" => "hello world"}, h)
    restored = S::TextContent.from_hash(h)
    assert_equal tc, restored
  end

  def test_initialize_request
    req = S::InitializeRequest.new(protocol_version: 1)
    assert_equal 1, req.protocol_version
    h = req.to_h
    assert_equal 1, h["protocolVersion"]
  end

  def test_initialize_response_defaults
    resp = S::InitializeResponse.new(protocol_version: 1)
    assert_equal 1, resp.protocol_version
    h = resp.to_h
    assert h.key?("protocolVersion")
  end

  def test_prompt_response
    resp = S::PromptResponse.new(stop_reason: S::StopReason::END_TURN)
    assert_equal "end_turn", resp.stop_reason
    assert_equal({"stopReason" => "end_turn"}, resp.to_h)
  end

  def test_content_block_parse_text
    hash = {"type" => "text", "text" => "hello"}
    block = S::ContentBlock.parse(hash)
    assert_instance_of S::TextContent, block
    assert_equal "hello", block.text
  end

  def test_content_block_parse_image
    hash = {"type" => "image", "data" => "base64data", "mimeType" => "image/png"}
    block = S::ContentBlock.parse(hash)
    assert_instance_of S::ImageContent, block
    assert_equal "base64data", block.data
  end

  def test_session_update_parse_tool_call
    hash = {
      "sessionUpdate" => "tool_call",
      "toolCallId" => "tc-1",
      "title" => "Read file"
    }
    update = S::SessionUpdate.parse(hash)
    assert_instance_of S::ToolCall, update
    assert_equal "tc-1", update.tool_call_id
  end

  def test_session_update_parse_agent_message
    hash = {
      "sessionUpdate" => "agent_message_chunk",
      "content" => {"type" => "text", "text" => "thinking..."}
    }
    update = S::SessionUpdate.parse(hash)
    assert_instance_of S::ContentChunk, update
    assert_instance_of S::TextContent, update.content
  end

  def test_session_notification
    notif = S::SessionNotification.new(
      session_id: "sess-1",
      update: S::ToolCall.new(tool_call_id: "tc-1", title: "Read")
    )
    h = notif.to_h
    assert_equal "sess-1", h["sessionId"]
    assert_equal "tc-1", h["update"]["toolCallId"]
    assert_equal "tool_call", h["update"]["sessionUpdate"]
  end

  def test_tool_call_content_parse
    hash = {"type" => "diff", "path" => "/tmp/f.rb", "newText" => "puts 'hi'"}
    content = S::ToolCallContent.parse(hash)
    assert_instance_of S::Diff, content
    assert_equal "/tmp/f.rb", content.path
  end

  def test_enum_constants
    assert_equal "end_turn", S::StopReason::END_TURN
    assert_equal "pending", S::ToolCallStatus::PENDING
    assert_equal "read", S::ToolKind::READ
    assert_equal "high", S::PlanEntryPriority::HIGH
    assert_equal "allow_once", S::PermissionOptionKind::ALLOW_ONCE
  end

  def test_enum_all
    assert_includes S::StopReason::ALL, "end_turn"
    assert_includes S::StopReason::ALL, "cancelled"
    assert_equal 5, S::StopReason::ALL.size
  end

  def test_nested_model_serialization
    cap = S::AgentCapabilities.new(load_session: true)
    assert_equal true, cap.load_session
  end

  def test_create_terminal_request
    req = S::CreateTerminalRequest.new(
      command: "bash",
      session_id: "s1",
      args: ["-c", "echo hi"],
      cwd: "/tmp"
    )
    h = req.to_h
    assert_equal "bash", h["command"]
    assert_equal "s1", h["sessionId"]
    assert_equal ["-c", "echo hi"], h["args"]
  end

  def test_new_session_request
    req = S::NewSessionRequest.new(cwd: "/home/user", mcp_servers: [])
    h = req.to_h
    assert_equal "/home/user", h["cwd"]
    assert_equal [], h["mcpServers"]
  end

  def test_plan_entry
    entry = S::PlanEntry.new(
      content: "Fix the bug",
      priority: S::PlanEntryPriority::HIGH,
      status: S::PlanEntryStatus::PENDING
    )
    h = entry.to_h
    assert_equal "Fix the bug", h["content"]
    assert_equal "high", h["priority"]
  end
end
