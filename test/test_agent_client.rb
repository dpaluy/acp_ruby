# frozen_string_literal: true

require "test_helper"
require "async"
require "securerandom"

class EchoAgent
  include AgentClientProtocol::AgentInterface
  include AgentClientProtocol::Helpers

  attr_reader :conn

  def on_connect(conn)
    @conn = conn
  end

  def initialize_agent(protocol_version:, **)
    AgentClientProtocol::Schema::InitializeResponse.new(
      protocol_version: protocol_version,
      agent_info: AgentClientProtocol::Schema::Implementation.new(
        name: "echo-agent", version: "0.1.0"
      )
    )
  end

  def new_session(cwd:, **)
    AgentClientProtocol::Schema::NewSessionResponse.new(
      session_id: "test-session-#{SecureRandom.hex(4)}"
    )
  end

  def prompt(prompt:, session_id:, **)
    text = prompt.first.is_a?(Hash) ? prompt.first["text"] : prompt.first.text
    @conn.session_update(
      session_id: session_id,
      update: update_agent_message_text("Echo: #{text}")
    )

    AgentClientProtocol::Schema::PromptResponse.new(
      stop_reason: AgentClientProtocol::Schema::StopReason::END_TURN
    )
  end

  def cancel(session_id:, **)
    nil
  end
end

class TestClient
  include AgentClientProtocol::ClientInterface

  attr_reader :updates, :conn

  def initialize
    @updates = []
  end

  def on_connect(conn)
    @conn = conn
  end

  def session_update(session_id:, update:, **)
    @updates << {session_id: session_id, update: update}
  end

  def request_permission(session_id:, tool_call:, options:, **)
    AgentClientProtocol::Schema::RequestPermissionResponse.new(
      outcome: {"outcome" => "selected", "optionId" => options.first.option_id}
    )
  end
end

class TestAgentClientIntegration < Minitest::Test
  def setup
    @r1, @w1 = IO.pipe # client writes, agent reads
    @r2, @w2 = IO.pipe # agent writes, client reads
  end

  def teardown
    [@r1, @w1, @r2, @w2].each { |io| io.close unless io.closed? }
  end

  def make_connections
    agent_handler = EchoAgent.new
    client_handler = TestClient.new

    agent_reader = AgentClientProtocol::Transport::NdjsonReader.new(@r1)
    agent_writer = AgentClientProtocol::Transport::NdjsonWriter.new(@w2)
    agent_conn = AgentClientProtocol::Agent::Connection.new(agent_handler, agent_reader, agent_writer)

    client_reader = AgentClientProtocol::Transport::NdjsonReader.new(@r2)
    client_writer = AgentClientProtocol::Transport::NdjsonWriter.new(@w1)
    client_conn = AgentClientProtocol::Client::Connection.new(client_handler, client_reader, client_writer)

    [agent_conn, client_conn, agent_handler, client_handler]
  end

  def test_full_roundtrip
    Async do
      agent_conn, client_conn, _agent, client = make_connections

      agent_task = Async { agent_conn.listen }
      client_task = Async { client_conn.listen }

      # Initialize
      init_resp = client_conn.initialize_agent(protocol_version: 1)
      assert_equal 1, init_resp.protocol_version
      assert_equal "echo-agent", init_resp.agent_info.name

      # New session
      session_resp = client_conn.new_session(cwd: "/tmp")
      assert session_resp.session_id.start_with?("test-session-")

      # Prompt
      prompt_resp = client_conn.prompt(
        session_id: session_resp.session_id,
        prompt: "hello world"
      )
      assert_equal "end_turn", prompt_resp.stop_reason

      # Check that we received the session update
      sleep(0.05)
      assert_equal 1, client.updates.size
      assert_equal session_resp.session_id, client.updates[0][:session_id]

      agent_conn.close
      client_conn.close
      agent_task.stop
      client_task.stop
    end
  end

  def test_initialize_only
    Async do
      agent_conn, client_conn, _agent, _client = make_connections

      agent_task = Async { agent_conn.listen }
      client_task = Async { client_conn.listen }

      resp = client_conn.initialize_agent(
        protocol_version: 1,
        client_info: AgentClientProtocol::Schema::Implementation.new(
          name: "test-client", version: "0.1.0"
        )
      )
      assert_equal 1, resp.protocol_version

      agent_conn.close
      client_conn.close
      agent_task.stop
      client_task.stop
    end
  end

  def test_cancel_notification
    Async do
      agent_conn, client_conn, _agent, _client = make_connections

      agent_task = Async { agent_conn.listen }
      client_task = Async { client_conn.listen }

      session_resp = client_conn.new_session(cwd: "/tmp")

      # Cancel should not block (it's a notification)
      client_conn.cancel(session_id: session_resp.session_id)

      # Small sleep to let notification propagate
      sleep(0.05)

      agent_conn.close
      client_conn.close
      agent_task.stop
      client_task.stop
    end
  end
end
