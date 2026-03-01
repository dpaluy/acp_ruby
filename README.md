# AgentClientProtocol

[![Gem Version](https://badge.fury.io/rb/agent_client_protocol.svg)](https://badge.fury.io/rb/agent_client_protocol)

Ruby SDK for the [Agent Client Protocol (ACP)](https://agentclientprotocol.com/) — a JSON-RPC 2.0 based open protocol standardizing communication between code editors and AI coding agents.

## Installation

```sh
bundle add agent_client_protocol
```

Or add to your Gemfile:

```ruby
gem "agent_client_protocol"
```

## Usage

### Building an Agent

```ruby
require "agent_client_protocol"

class MyAgent
  include AgentClientProtocol::AgentInterface
  include AgentClientProtocol::Helpers

  def on_connect(conn)
    @conn = conn
  end

  def initialize_agent(protocol_version:, **)
    AgentClientProtocol::Schema::InitializeResponse.new(
      protocol_version: 1,
      agent_info: { name: "my-agent", version: "1.0.0" },
      capabilities: {}
    )
  end

  def new_session(cwd:, **)
    AgentClientProtocol::Schema::NewSessionResponse.new(session_id: SecureRandom.uuid)
  end

  def prompt(prompt:, session_id:, **)
    @conn.session_update(
      session_id: session_id,
      update: update_agent_message_text("You said: #{prompt}")
    )
    AgentClientProtocol::Schema::PromptResponse.new(
      stop_reason: "end_turn"
    )
  end
end

AgentClientProtocol.run_agent(MyAgent.new)
```

### Building a Client

```ruby
require "agent_client_protocol"

class MyClient
  include AgentClientProtocol::ClientInterface

  def on_connect(conn)
    @conn = conn
  end

  def session_update(session_id:, update:, **)
    puts "Update: #{update}"
  end

  def request_permission(session_id:, tool_call:, options:, **)
    AgentClientProtocol::Schema::RequestPermissionResponse.new(
      allowed: true
    )
  end
end

client = MyClient.new
AgentClientProtocol.spawn_agent_process(client, "claude-code", "--acp") do |conn, pid|
  resp = conn.initialize_agent(protocol_version: 1, client_info: { name: "my-client", version: "1.0.0" })
  session = conn.new_session(cwd: Dir.pwd)
  result = conn.prompt(session_id: session.session_id, prompt: "Hello!")
  puts "Done: #{result.stop_reason}"
end
```

### Spawning Both Sides in One Process

```ruby
require "agent_client_protocol"

# See examples/duet.rb for a full working example
```

## Error Handling

```ruby
begin
  conn.prompt(session_id: sid, prompt: "hello")
rescue AgentClientProtocol::RequestError => e
  puts "Error #{e.code}: #{e.message}"
  puts "Data: #{e.data}" if e.data
end
```

## Development

```sh
bundle install
bundle exec rake test
bundle exec ruby script/generate_schema.rb  # regenerate schema types
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/davidcopeland/agent_client_protocol).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
