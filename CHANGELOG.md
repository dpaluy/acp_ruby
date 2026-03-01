# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release: full ACP (Agent Client Protocol) SDK for Ruby
- Code-generated schema types from upstream `schema.json` (v0.10.8)
- Bidirectional JSON-RPC 2.0 transport over stdio (NDJSON framing)
- Agent and client connection classes with symmetric calling pattern
- Process management: `run_agent`, `spawn_agent_process`, `spawn_client_process`
- Helper functions for building content blocks, tool calls, session updates
- Contrib helpers: `SessionAccumulator`, `ToolCallTracker`, `PermissionBroker`
- Examples: echo agent, interactive client, duet (both sides in one process)
