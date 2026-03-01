# frozen_string_literal: true

require "test_helper"
require "async"
require "open3"

class TestEchoRoundtrip < Minitest::Test
  S = AgentClientProtocol::Schema

  # Full round-trip test: spawn the echo agent as a subprocess,
  # communicate over stdio, verify responses.

  def test_spawn_echo_agent_roundtrip
    echo_agent_path = File.expand_path("../../examples/echo_agent.rb", __dir__)

    client = CollectingClient.new

    AgentClientProtocol.spawn_agent_process(client, "ruby", echo_agent_path) do |conn, pid|
      # Initialize
      init = conn.initialize_agent(
        protocol_version: AgentClientProtocol::PROTOCOL_VERSION,
        client_info: S::Implementation.new(name: "test-client", version: "0.0.1")
      )
      assert_equal AgentClientProtocol::PROTOCOL_VERSION, init.protocol_version
      assert_equal "echo-agent", init.agent_info.name

      # New session
      session = conn.new_session(cwd: Dir.pwd, mcp_servers: [])
      refute_nil session.session_id
      assert session.session_id.start_with?("echo-")

      # Prompt
      result = conn.prompt(session_id: session.session_id, prompt: "Hello from integration test!")
      assert_equal S::StopReason::END_TURN, result.stop_reason

      # Wait for notification to propagate
      sleep(0.1)

      # Verify session update was received
      assert_equal 1, client.updates.size

      update = client.updates.first
      assert_equal session.session_id, update[:session_id]

      # The update should contain our echoed text
      content = update[:update]
      assert content.respond_to?(:content), "Expected update to have content, got: #{content.inspect}"
      assert_instance_of S::TextContent, content.content
      assert_equal "Echo: Hello from integration test!", content.content.text
    end
  end

  def test_multiple_prompts_in_session
    echo_agent_path = File.expand_path("../../examples/echo_agent.rb", __dir__)
    client = CollectingClient.new

    AgentClientProtocol.spawn_agent_process(client, "ruby", echo_agent_path) do |conn, _pid|
      conn.initialize_agent(protocol_version: AgentClientProtocol::PROTOCOL_VERSION)
      session = conn.new_session(cwd: Dir.pwd, mcp_servers: [])

      3.times do |i|
        conn.prompt(session_id: session.session_id, prompt: "Message #{i}")
      end

      sleep(0.1)
      assert_equal 3, client.updates.size
    end
  end

  def test_multiple_sessions
    echo_agent_path = File.expand_path("../../examples/echo_agent.rb", __dir__)
    client = CollectingClient.new

    AgentClientProtocol.spawn_agent_process(client, "ruby", echo_agent_path) do |conn, _pid|
      conn.initialize_agent(protocol_version: AgentClientProtocol::PROTOCOL_VERSION)

      s1 = conn.new_session(cwd: Dir.pwd, mcp_servers: [])
      s2 = conn.new_session(cwd: Dir.pwd, mcp_servers: [])

      refute_equal s1.session_id, s2.session_id

      conn.prompt(session_id: s1.session_id, prompt: "In session 1")
      conn.prompt(session_id: s2.session_id, prompt: "In session 2")

      sleep(0.1)
      assert_equal 2, client.updates.size
      assert_equal s1.session_id, client.updates[0][:session_id]
      assert_equal s2.session_id, client.updates[1][:session_id]
    end
  end

  private

  class CollectingClient
    include AgentClientProtocol::ClientInterface

    attr_reader :updates

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
      S::RequestPermissionResponse.new(
        outcome: S::SelectedPermissionOutcome.new(option_id: options.first.option_id)
      )
    end
  end
end
