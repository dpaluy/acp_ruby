# frozen_string_literal: true

require "test_helper"

class TestToolCallTracker < Minitest::Test
  S = AgentClientProtocol::Schema

  def setup
    counter = 0
    @tracker = AgentClientProtocol::Contrib::ToolCallTracker.new(
      id_factory: -> { "id-#{counter += 1}" }
    )
  end

  def test_start_returns_tool_call
    result = @tracker.start("ext-1", title: "Read file", kind: S::ToolKind::READ)
    assert_instance_of S::ToolCall, result
    assert_equal "id-1", result.tool_call_id
    assert_equal "Read file", result.title
    assert_equal "read", result.kind
    assert_equal "pending", result.status
  end

  def test_progress_returns_update
    @tracker.start("ext-1", title: "Read")
    result = @tracker.progress("ext-1", status: S::ToolCallStatus::COMPLETED)
    assert_instance_of S::ToolCallUpdate, result
    assert_equal "id-1", result.tool_call_id
    assert_equal "completed", result.status
  end

  def test_append_stream_text
    @tracker.start("ext-1", title: "Execute")
    r1 = @tracker.append_stream_text("ext-1", "hello ")
    r2 = @tracker.append_stream_text("ext-1", "world")
    assert_equal "hello ", r1.raw_output
    assert_equal "hello world", r2.raw_output
  end

  def test_view_returns_copy
    @tracker.start("ext-1", title: "Read")
    @tracker.progress("ext-1", status: S::ToolCallStatus::IN_PROGRESS)
    view = @tracker.view("ext-1")
    assert_equal "ext-1", view.external_id
    assert_equal "in_progress", view.status
  end

  def test_tool_call_model
    @tracker.start("ext-1", title: "Read", kind: S::ToolKind::READ)
    model = @tracker.tool_call_model("ext-1")
    assert_instance_of S::ToolCallUpdate, model
    assert_equal "id-1", model.tool_call_id
  end

  def test_forget
    @tracker.start("ext-1", title: "Read")
    @tracker.forget("ext-1")
    assert_raises(ArgumentError) { @tracker.view("ext-1") }
  end

  def test_unknown_raises
    assert_raises(ArgumentError) { @tracker.progress("nonexistent") }
    assert_raises(ArgumentError) { @tracker.view("nonexistent") }
  end
end
