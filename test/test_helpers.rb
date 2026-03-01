# frozen_string_literal: true

require "test_helper"

class TestHelpers < Minitest::Test
  include AgentClientProtocol::Helpers
  S = AgentClientProtocol::Schema

  def test_text_block
    block = text_block("hello")
    assert_instance_of S::TextContent, block
    assert_equal "hello", block.text
  end

  def test_image_block
    block = image_block("data123", "image/png", uri: "file:///img.png")
    assert_instance_of S::ImageContent, block
    assert_equal "data123", block.data
    assert_equal "image/png", block.mime_type
  end

  def test_audio_block
    block = audio_block("audiodata", "audio/wav")
    assert_instance_of S::AudioContent, block
  end

  def test_resource_link_block
    block = resource_link_block(name: "file.rb", uri: "file:///file.rb", mime_type: "text/plain")
    assert_instance_of S::ResourceLink, block
    assert_equal "file.rb", block.name
  end

  def test_tool_content
    content = tool_content(text_block("output"))
    assert_instance_of S::Content, content
  end

  def test_tool_diff_content
    diff = tool_diff_content("/path/file.rb", "new code", old_text: "old code")
    assert_instance_of S::Diff, diff
    assert_equal "new code", diff.new_text
    assert_equal "old code", diff.old_text
  end

  def test_tool_terminal_ref
    ref = tool_terminal_ref("term-1")
    assert_instance_of S::Terminal, ref
    assert_equal "term-1", ref.terminal_id
  end

  def test_update_agent_message_text
    update = update_agent_message_text("thinking...")
    assert_instance_of AgentClientProtocol::TaggedUpdate, update
    assert_equal "agent_message_chunk", update.tag
    assert_instance_of S::TextContent, update.content
    assert_equal "thinking...", update.content.text

    # Wire format includes sessionUpdate discriminator
    h = update.to_h
    assert_equal "agent_message_chunk", h["sessionUpdate"]
    assert_equal "text", h["content"]["type"]
  end

  def test_plan_entry
    entry = plan_entry("Fix bug", priority: S::PlanEntryPriority::HIGH, status: S::PlanEntryStatus::IN_PROGRESS)
    assert_instance_of S::PlanEntry, entry
    assert_equal "Fix bug", entry.content
    assert_equal "high", entry.priority
    assert_equal "in_progress", entry.status
  end

  def test_update_plan
    entries = [plan_entry("Step 1"), plan_entry("Step 2")]
    plan = update_plan(entries)
    assert_instance_of AgentClientProtocol::TaggedUpdate, plan
    assert_equal "plan", plan.tag
    assert_equal 2, plan.entries.size
  end

  def test_start_tool_call
    tc = start_tool_call("tc-1", "Read file", kind: S::ToolKind::READ, status: S::ToolCallStatus::IN_PROGRESS)
    assert_instance_of AgentClientProtocol::TaggedUpdate, tc
    assert_equal "tool_call", tc.tag
    assert_equal "tc-1", tc.tool_call_id
    assert_equal "Read file", tc.title
    assert_equal "read", tc.kind
  end

  def test_update_tool_call
    tc = update_tool_call("tc-1", status: S::ToolCallStatus::COMPLETED)
    assert_instance_of AgentClientProtocol::TaggedUpdate, tc
    assert_equal "tool_call_update", tc.tag
    assert_equal "tc-1", tc.tool_call_id
    assert_equal "completed", tc.status
  end

  def test_session_notification
    notif = session_notification("sess-1", update_agent_message_text("hi"))
    assert_instance_of S::SessionNotification, notif
    assert_equal "sess-1", notif.session_id

    # Verify wire format includes sessionUpdate discriminator
    h = notif.to_h
    assert_equal "agent_message_chunk", h["update"]["sessionUpdate"]
  end
end
