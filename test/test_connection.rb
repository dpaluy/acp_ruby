# frozen_string_literal: true

require "test_helper"
require "async"

class TestConnection < Minitest::Test
  def setup
    @r1, @w1 = IO.pipe
    @r2, @w2 = IO.pipe
  end

  def teardown
    [@r1, @w1, @r2, @w2].each { |io| io.close unless io.closed? }
  end

  def make_connection(reader_io, writer_io, &handler)
    reader = AgentClientProtocol::Transport::NdjsonReader.new(reader_io)
    writer = AgentClientProtocol::Transport::NdjsonWriter.new(writer_io)
    AgentClientProtocol::Connection.new(
      reader: reader,
      writer: writer,
      handler: handler || method(:default_handler)
    )
  end

  def default_handler(method, params, is_notification)
    case method
    when "echo"
      params
    when "add"
      {"sum" => params["a"] + params["b"]}
    when "fail"
      raise AgentClientProtocol::RequestError.invalid_params("bad")
    else
      raise AgentClientProtocol::RequestError.method_not_found(method)
    end
  end

  def test_request_response_roundtrip
    Async do
      # Server side reads from r1, writes to w2
      server = make_connection(@r1, @w2)
      server_task = Async { server.listen }

      # Client side reads from r2, writes to w1
      client = make_connection(@r2, @w1)
      client_task = Async { client.listen }

      result = client.send_request("echo", {"msg" => "hello"})
      assert_equal({"msg" => "hello"}, result)

      result = client.send_request("add", {"a" => 3, "b" => 4})
      assert_equal({"sum" => 7}, result)

      client.close
      server.close
      server_task.stop
      client_task.stop
    end
  end

  def test_request_error_propagation
    Async do
      server = make_connection(@r1, @w2)
      server_task = Async { server.listen }

      client = make_connection(@r2, @w1)
      client_task = Async { client.listen }

      err = assert_raises(AgentClientProtocol::RequestError) do
        client.send_request("fail")
      end
      assert_equal(-32602, err.code)
      assert_equal "Invalid params", err.message

      client.close
      server.close
      server_task.stop
      client_task.stop
    end
  end

  def test_method_not_found
    Async do
      server = make_connection(@r1, @w2)
      server_task = Async { server.listen }

      client = make_connection(@r2, @w1)
      client_task = Async { client.listen }

      err = assert_raises(AgentClientProtocol::RequestError) do
        client.send_request("nonexistent")
      end
      assert_equal(-32601, err.code)

      client.close
      server.close
      server_task.stop
      client_task.stop
    end
  end

  def test_notification_does_not_block
    received = []
    handler = proc do |method, params, is_notification|
      received << {method: method, params: params} if is_notification
    end

    Async do
      server = make_connection(@r1, @w2, &handler)
      server_task = Async { server.listen }

      writer = AgentClientProtocol::Transport::NdjsonWriter.new(@w1)
      writer.write({"jsonrpc" => "2.0", "method" => "notify", "params" => {"x" => 1}})

      # Give the server a moment to process
      sleep(0.05)

      assert_equal 1, received.size
      assert_equal "notify", received[0][:method]

      server.close
      server_task.stop
    end
  end

  def test_bidirectional_requests
    Async do
      # Both sides can send requests to each other
      side_a = make_connection(@r1, @w2) do |method, params, _|
        {"from" => "a", "echo" => params}
      end

      side_b = make_connection(@r2, @w1) do |method, params, _|
        {"from" => "b", "echo" => params}
      end

      a_task = Async { side_a.listen }
      b_task = Async { side_b.listen }

      result_from_b = side_a.send_request("ping", {"val" => 1})
      assert_equal "b", result_from_b["from"]

      result_from_a = side_b.send_request("pong", {"val" => 2})
      assert_equal "a", result_from_a["from"]

      side_a.close
      side_b.close
      a_task.stop
      b_task.stop
    end
  end

  def test_close_rejects_pending
    Async do
      server = make_connection(@r1, @w2) do |method, params, _|
        # Intentionally slow — will be interrupted by close
        sleep(10)
      end
      server_task = Async { server.listen }

      client = make_connection(@r2, @w1)
      client_task = Async { client.listen }

      request_task = Async { client.send_request("slow") }

      # Close before server responds
      sleep(0.05)
      client.close

      err = assert_raises(AgentClientProtocol::RequestError) { request_task.wait }
      assert_equal(-32603, err.code)

      server.close
      server_task.stop
      client_task.stop
    end
  end
end
