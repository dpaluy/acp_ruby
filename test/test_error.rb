# frozen_string_literal: true

require "test_helper"

class TestRequestError < Minitest::Test
  def test_parse_error
    err = AgentClientProtocol::RequestError.parse_error
    assert_equal(-32700, err.code)
    assert_equal "Parse error", err.message
    assert_nil err.data
  end

  def test_method_not_found_with_data
    err = AgentClientProtocol::RequestError.method_not_found("session/foo")
    assert_equal(-32601, err.code)
    assert_equal "Method not found", err.message
    assert_equal({"method" => "session/foo"}, err.data)
  end

  def test_resource_not_found_with_uri
    err = AgentClientProtocol::RequestError.resource_not_found("/tmp/file.txt")
    assert_equal({"uri" => "/tmp/file.txt"}, err.data)
  end

  def test_resource_not_found_without_uri
    err = AgentClientProtocol::RequestError.resource_not_found
    assert_nil err.data
  end

  def test_to_h
    err = AgentClientProtocol::RequestError.invalid_params("bad input")
    expected = {"code" => -32602, "message" => "Invalid params", "data" => "bad input"}
    assert_equal expected, err.to_h
  end

  def test_to_h_omits_nil_data
    err = AgentClientProtocol::RequestError.internal_error
    refute err.to_h.key?("data")
  end

  def test_from_hash
    err = AgentClientProtocol::RequestError.from_hash(
      "code" => -32600, "message" => "Invalid request", "data" => {"detail" => "missing id"}
    )
    assert_equal(-32600, err.code)
    assert_equal "Invalid request", err.message
    assert_equal({"detail" => "missing id"}, err.data)
  end

  def test_is_standard_error
    err = AgentClientProtocol::RequestError.parse_error
    assert_kind_of StandardError, err
  end
end
