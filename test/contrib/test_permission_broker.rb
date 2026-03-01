# frozen_string_literal: true

require "test_helper"

class TestPermissionBroker < Minitest::Test
  S = AgentClientProtocol::Schema

  def test_request_for_with_defaults
    response = S::RequestPermissionResponse.new(
      outcome: {"outcome" => "selected", "optionId" => "approve"}
    )
    requester = proc { |**kwargs| response }

    broker = AgentClientProtocol::Contrib::PermissionBroker.new(requester: requester)
    result = broker.request_for("ext-1", session_id: "s1", description: "Run command")
    assert_equal response, result
  end

  def test_request_for_with_tracker
    counter = 0
    tracker = AgentClientProtocol::Contrib::ToolCallTracker.new(
      id_factory: -> { "tid-#{counter += 1}" }
    )
    tracker.start("ext-1", title: "Read file", kind: S::ToolKind::READ)

    received_kwargs = nil
    requester = proc do |**kwargs|
      received_kwargs = kwargs
      S::RequestPermissionResponse.new(outcome: {"outcome" => "selected", "optionId" => "approve"})
    end

    broker = AgentClientProtocol::Contrib::PermissionBroker.new(requester: requester, tracker: tracker)
    broker.request_for("ext-1", session_id: "s1")

    assert_equal "s1", received_kwargs[:session_id]
    assert_instance_of S::ToolCallUpdate, received_kwargs[:tool_call]
    assert_equal "tid-1", received_kwargs[:tool_call].tool_call_id
  end

  def test_default_permission_options
    opts = AgentClientProtocol::Contrib::PermissionBroker.default_permission_options
    assert_equal 3, opts.size
    assert_equal "approve", opts[0].option_id
    assert_equal "approve_session", opts[1].option_id
    assert_equal "reject", opts[2].option_id
  end

  def test_custom_options
    custom_opts = [
      S::PermissionOption.new(option_id: "yes", name: "Yes", kind: S::PermissionOptionKind::ALLOW_ONCE)
    ]

    received_opts = nil
    requester = proc do |**kwargs|
      received_opts = kwargs[:options]
      S::RequestPermissionResponse.new(outcome: {"outcome" => "selected", "optionId" => "yes"})
    end

    broker = AgentClientProtocol::Contrib::PermissionBroker.new(requester: requester)
    broker.request_for("ext-1", session_id: "s1", options: custom_opts)

    assert_equal 1, received_opts.size
    assert_equal "yes", received_opts[0].option_id
  end
end
