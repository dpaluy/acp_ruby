# Agent Client Protocol — Ruby SDK

Ruby SDK implementing the Agent Client Protocol (ACP), a JSON-RPC 2.0 based open protocol for communication between code editors and AI coding agents. Think LSP but for AI agents.

## Architecture

The protocol is fully bidirectional — both sides send AND receive requests over the same stdio connection using newline-delimited JSON-RPC.

```
lib/agent_client_protocol/
  schema/          # Code-generated types from schema.json (DO NOT EDIT)
  agent/           # Agent-side connection and routing
  client/          # Client-side connection and routing
  contrib/         # Optional helpers (accumulator, tracker, broker)
  connection.rb    # Core bidirectional JSON-RPC 2.0 engine
  transport.rb     # NDJSON read/write over IO streams
  router.rb        # Method name -> handler dispatch
  error.rb         # RequestError with JSON-RPC error codes
  stdio.rb         # Process spawn and management
  helpers.rb       # Builder functions (text_block, etc.)
  meta.rb          # Generated: method constants, PROTOCOL_VERSION
```

## Key Conventions

- **Concurrency**: `async` gem (fiber-based). No Thread-based concurrency.
- **Schema types**: Code-generated from `schema/schema.json`. Never edit generated files.
- **Wire format**: camelCase JSON keys. Ruby uses snake_case internally, serialization handles conversion.
- **Testing**: Minitest (not RSpec). TDD approach.
- **Ruby version**: >= 3.2 (fiber scheduler support required)

## Build & Test

```sh
bundle install
bundle exec rake test                    # Run all tests
bundle exec ruby script/generate_schema.rb  # Regenerate schema types
bundle exec rake                         # Default: test
```

## Wire Protocol Quick Reference

Messages are newline-delimited JSON-RPC 2.0:
```
{"jsonrpc":"2.0","id":1,"method":"session/new","params":{"cwd":"/home/user"}}\n
```

**Agent methods** (client -> agent): `initialize`, `authenticate`, `session/new`, `session/load`, `session/prompt`, `session/cancel`, `session/set_mode`, `session/set_config_option`

**Client methods** (agent -> client): `session/update`, `session/request_permission`, `fs/read_text_file`, `fs/write_text_file`, `terminal/create`, `terminal/output`, `terminal/release`, `terminal/wait_for_exit`, `terminal/kill`

## Dependencies

- Runtime: `async` (~> 2.0), `async-io` (~> 1.0)
- Dev: `minitest`, `minitest-reporters`, `rake`, `rubocop`

## Do NOT

- Edit files under `lib/agent_client_protocol/schema/` manually — they are code-generated
- Edit `lib/agent_client_protocol/meta.rb` manually — it is code-generated
- Use Thread-based concurrency — use `async` fibers instead
- Use snake_case in JSON wire messages — the protocol uses camelCase
- Add runtime dependencies beyond `async` and `async-io` without discussion
