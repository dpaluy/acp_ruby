# frozen_string_literal: true

require "test_helper"

class TestRouter < Minitest::Test
  def setup
    @router = AgentClientProtocol::Router.new
  end

  def test_request_dispatch
    @router.on_request("echo") { |params| params }
    result = @router.call("echo", {"msg" => "hi"}, false)
    assert_equal({"msg" => "hi"}, result)
  end

  def test_request_with_model_deserialization
    @router.on_request("test", request_class: AgentClientProtocol::Schema::TextContent) do |params|
      AgentClientProtocol::Schema::PromptResponse.new(stop_reason: params.text)
    end

    result = @router.call("test", {"text" => "done"}, false)
    assert_equal({"stopReason" => "done"}, result)
  end

  def test_notification_dispatch
    received = nil
    @router.on_notification("notify") { |params| received = params }
    result = @router.call("notify", {"x" => 1}, true)
    assert_nil result
    assert_equal({"x" => 1}, received)
  end

  def test_method_not_found
    err = assert_raises(AgentClientProtocol::RequestError) do
      @router.call("nonexistent", nil, false)
    end
    assert_equal(-32601, err.code)
  end

  def test_optional_route_returns_nil_on_not_implemented
    @router.on_request("optional", optional: true) { raise NotImplementedError }
    result = @router.call("optional", nil, false)
    assert_nil result
  end

  def test_extension_method
    @router.on_ext_method { |method, params| {"ext" => method} }
    result = @router.call("_custom/method", nil, false)
    assert_equal({"ext" => "_custom/method"}, result)
  end

  def test_extension_notification
    received = nil
    @router.on_ext_notification { |method, params| received = method }
    @router.call("_custom/notify", nil, true)
    assert_equal "_custom/notify", received
  end

  def test_ext_method_not_found_without_handler
    err = assert_raises(AgentClientProtocol::RequestError) do
      @router.call("_custom", nil, false)
    end
    assert_equal(-32601, err.code)
  end
end
