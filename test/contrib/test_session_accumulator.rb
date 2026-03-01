# frozen_string_literal: true

require "test_helper"

class TestSessionAccumulator < Minitest::Test
  include AgentClientProtocol::Helpers
  S = AgentClientProtocol::Schema

  def setup
    @acc = AgentClientProtocol::Contrib::SessionAccumulator.new
  end

  def test_apply_agent_message
    notif = {
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "hello"}}
    }
    snap = @acc.apply(notif)
    assert_equal "s1", snap.session_id
    assert_equal 1, snap.agent_messages.size
  end

  def test_apply_user_message
    notif = {
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "user_message_chunk", "content" => {"type" => "text", "text" => "hi"}}
    }
    snap = @acc.apply(notif)
    assert_equal 1, snap.user_messages.size
  end

  def test_apply_tool_call
    notif = {
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "tool_call", "toolCallId" => "tc-1", "title" => "Read file"}
    }
    snap = @acc.apply(notif)
    assert_equal 1, snap.tool_calls.size
    assert snap.tool_calls.key?("tc-1")
  end

  def test_apply_tool_call_update
    @acc.apply({
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "tool_call", "toolCallId" => "tc-1", "title" => "Read"}
    })
    snap = @acc.apply({
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "tool_call_update", "toolCallId" => "tc-1", "status" => "completed"}
    })
    assert_equal 1, snap.tool_calls.size
  end

  def test_apply_plan
    notif = {
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "plan", "entries" => [{"content" => "Step 1", "priority" => "high", "status" => "pending"}]}
    }
    snap = @acc.apply(notif)
    assert_equal 1, snap.plan_entries.size
  end

  def test_apply_current_mode_update
    notif = {
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "current_mode_update", "currentModeId" => "code"}
    }
    snap = @acc.apply(notif)
    assert_equal "code", snap.current_mode_id
  end

  def test_session_change_resets_state
    @acc.apply({
      "sessionId" => "s1",
      "update" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "hi"}}
    })
    snap = @acc.apply({
      "sessionId" => "s2",
      "update" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "new"}}
    })
    assert_equal "s2", snap.session_id
    assert_equal 1, snap.agent_messages.size
  end

  def test_subscribe
    received = []
    @acc.subscribe { |snap, notif| received << snap.session_id }
    @acc.apply({"sessionId" => "s1", "update" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "hi"}}})
    assert_equal ["s1"], received
  end

  def test_snapshot_is_frozen
    @acc.apply({"sessionId" => "s1", "update" => {"sessionUpdate" => "agent_message_chunk", "content" => {"type" => "text", "text" => "hi"}}})
    snap = @acc.snapshot
    assert snap.frozen?
  end

  def test_with_schema_model
    notif = S::SessionNotification.new(
      session_id: "s1",
      update: update_agent_message_text("thinking...")
    )
    snap = @acc.apply(notif)
    assert_equal "s1", snap.session_id
  end
end
