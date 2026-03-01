#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal ACP echo agent — echoes back every prompt as an agent message.
# Run: ruby examples/echo_agent.rb
# This agent communicates over stdio (stdin/stdout) using NDJSON.

require_relative "../lib/agent_client_protocol"

class EchoAgent
  include AgentClientProtocol::AgentInterface
  include AgentClientProtocol::Helpers

  def on_connect(conn)
    @conn = conn
  end

  def initialize_agent(protocol_version:, **)
    AgentClientProtocol::Schema::InitializeResponse.new(
      protocol_version: AgentClientProtocol::PROTOCOL_VERSION,
      agent_info: AgentClientProtocol::Schema::Implementation.new(
        name: "echo-agent",
        version: AgentClientProtocol::VERSION
      ),
      capabilities: AgentClientProtocol::Schema::AgentCapabilities.new
    )
  end

  def new_session(cwd:, **)
    @session_count ||= 0
    @session_count += 1
    AgentClientProtocol::Schema::NewSessionResponse.new(
      session_id: "echo-#{@session_count}"
    )
  end

  def prompt(prompt:, session_id:, **)
    # Echo each content block back
    prompt.each do |block|
      text = case block
             when AgentClientProtocol::Schema::TextContent then block.text
             when Hash then block["text"] || block.inspect
             else block.inspect
             end

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

AgentClientProtocol.run_agent(EchoAgent.new)
