#!/usr/bin/env ruby
# frozen_string_literal: true

# Interactive ACP client — spawns an agent subprocess and sends prompts.
# Usage: ruby examples/client.rb -- <agent-command> [args...]
# Example: ruby examples/client.rb -- ruby examples/echo_agent.rb

require_relative "../lib/agent_client_protocol"

class InteractiveClient
  include AgentClientProtocol::ClientInterface

  def on_connect(conn)
    @conn = conn
    $stderr.puts "Connected to agent."
  end

  def session_update(session_id:, update:, **)
    case update
    when AgentClientProtocol::Schema::ContentChunk
      content = update.content
      if content.is_a?(AgentClientProtocol::Schema::TextContent)
        $stderr.puts "Agent: #{content.text}"
      else
        $stderr.puts "Agent: [#{content.class.name}]"
      end
    when AgentClientProtocol::Schema::ToolCall
      $stderr.puts "Tool call: #{update.title} (#{update.tool_call_id})"
    when AgentClientProtocol::Schema::ToolCallUpdate
      $stderr.puts "Tool update: #{update.tool_call_id} -> #{update.status}"
    when Hash
      type = update["sessionUpdate"]
      $stderr.puts "Update (#{type}): #{update.inspect}"
    else
      $stderr.puts "Update: #{update.inspect}"
    end
  end

  def request_permission(session_id:, tool_call:, options:, **)
    $stderr.puts "\nPermission requested for: #{tool_call.respond_to?(:title) ? tool_call.title : tool_call}"
    options.each_with_index do |opt, i|
      name = opt.respond_to?(:name) ? opt.name : opt["name"]
      $stderr.puts "  #{i + 1}. #{name}"
    end
    $stderr.print "Choose (1-#{options.size}): "
    choice = $stdin.gets&.strip&.to_i || 1
    choice = 1 if choice < 1 || choice > options.size

    selected = options[choice - 1]
    option_id = selected.respond_to?(:option_id) ? selected.option_id : selected["optionId"]

    AgentClientProtocol::Schema::RequestPermissionResponse.new(
      outcome: AgentClientProtocol::Schema::SelectedPermissionOutcome.new(option_id: option_id)
    )
  end
end

# Parse command
separator = ARGV.index("--")
unless separator
  $stderr.puts "Usage: ruby examples/client.rb -- <agent-command> [args...]"
  exit 1
end

agent_command = ARGV[separator + 1]
agent_args = ARGV[separator + 2..] || []

client = InteractiveClient.new

AgentClientProtocol.spawn_agent_process(client, agent_command, *agent_args) do |conn, pid|
  # Initialize
  resp = conn.initialize_agent(
    protocol_version: AgentClientProtocol::PROTOCOL_VERSION,
    client_info: AgentClientProtocol::Schema::Implementation.new(
      name: "interactive-client",
      version: AgentClientProtocol::VERSION
    )
  )
  $stderr.puts "Agent: #{resp.agent_info&.name} v#{resp.agent_info&.version}"

  # Create session
  session = conn.new_session(cwd: Dir.pwd, mcp_servers: [])
  $stderr.puts "Session: #{session.session_id}"

  # Interactive prompt loop
  loop do
    $stderr.print "\nYou: "
    input = $stdin.gets
    break if input.nil?

    input = input.strip
    break if input.empty? || input == "quit" || input == "exit"

    result = conn.prompt(session_id: session.session_id, prompt: input)
    $stderr.puts "[Stop: #{result.stop_reason}]"
  end

  $stderr.puts "Goodbye."
end
