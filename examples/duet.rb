#!/usr/bin/env ruby
# frozen_string_literal: true

# Duet — spawns both an echo agent and a client in one process, connected via pipes.
# Demonstrates the full ACP roundtrip without any external processes.
# Run: ruby examples/duet.rb

require_relative "../lib/agent_client_protocol"
require "async"

# --- Agent side ---
class DuetAgent
  include AgentClientProtocol::AgentInterface
  include AgentClientProtocol::Helpers

  def on_connect(conn)
    @conn = conn
  end

  def initialize_agent(protocol_version:, **)
    AgentClientProtocol::Schema::InitializeResponse.new(
      protocol_version: AgentClientProtocol::PROTOCOL_VERSION,
      agent_info: AgentClientProtocol::Schema::Implementation.new(
        name: "duet-echo", version: "1.0.0"
      )
    )
  end

  def new_session(cwd:, **)
    AgentClientProtocol::Schema::NewSessionResponse.new(session_id: "duet-1")
  end

  def prompt(prompt:, session_id:, **)
    prompt.each do |block|
      text = block.is_a?(Hash) ? block["text"] : block.text
      @conn.session_update(
        session_id: session_id,
        update: update_agent_message_text("Echo: #{text}")
      )
    end
    AgentClientProtocol::Schema::PromptResponse.new(
      stop_reason: AgentClientProtocol::Schema::StopReason::END_TURN
    )
  end
end

# --- Client side ---
class DuetClient
  include AgentClientProtocol::ClientInterface

  attr_reader :messages

  def initialize
    @messages = []
  end

  def on_connect(conn)
    @conn = conn
  end

  def session_update(session_id:, update:, **)
    if update.is_a?(AgentClientProtocol::Schema::ContentChunk) &&
       update.content.is_a?(AgentClientProtocol::Schema::TextContent)
      @messages << update.content.text
    end
  end

  def request_permission(session_id:, tool_call:, options:, **)
    AgentClientProtocol::Schema::RequestPermissionResponse.new(
      outcome: AgentClientProtocol::Schema::SelectedPermissionOutcome.new(
        option_id: options.first.option_id
      )
    )
  end
end

# --- Run the duet ---
Async do
  # Create two pipe pairs: agent reads from pipe1, writes to pipe2
  r1, w1 = IO.pipe # client -> agent
  r2, w2 = IO.pipe # agent -> client

  agent = DuetAgent.new
  client = DuetClient.new

  agent_reader = AgentClientProtocol::Transport::NdjsonReader.new(r1)
  agent_writer = AgentClientProtocol::Transport::NdjsonWriter.new(w2)
  agent_conn = AgentClientProtocol::Agent::Connection.new(agent, agent_reader, agent_writer)

  client_reader = AgentClientProtocol::Transport::NdjsonReader.new(r2)
  client_writer = AgentClientProtocol::Transport::NdjsonWriter.new(w1)
  client_conn = AgentClientProtocol::Client::Connection.new(client, client_reader, client_writer)

  agent_task = Async { agent_conn.listen }
  client_task = Async { client_conn.listen }

  # Initialize
  init = client_conn.initialize_agent(protocol_version: 1)
  puts "Connected to: #{init.agent_info.name}"

  # New session
  session = client_conn.new_session(cwd: Dir.pwd, mcp_servers: [])
  puts "Session: #{session.session_id}"

  # Send a prompt
  result = client_conn.prompt(session_id: session.session_id, prompt: "Hello, ACP!")
  sleep(0.05) # Let notification propagate

  puts "Stop reason: #{result.stop_reason}"
  puts "Messages received: #{client.messages.inspect}"

  # Cleanup
  agent_conn.close
  client_conn.close
  agent_task.stop
  client_task.stop

  [r1, w1, r2, w2].each { |io| io.close unless io.closed? }
end

puts "Done."
