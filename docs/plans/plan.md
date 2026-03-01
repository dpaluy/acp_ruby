# Ruby SDK for Agent Client Protocol (ACP) — Implementation Plan

See the full plan in the session transcript. This file serves as a persistent reference.

## Implementation Order

```
Epic 0  -> Epic 1  -> Epic 2  -> Epic 7  -> Epic 3  -> Epic 4
(AGENTS.md) (scaffold) (codegen)  (errors)  (transport) (router)
                                     |
                                     v
                              Epic 5 -> Epic 6
                           (interfaces) (connections)
                                     |
                                     v
                              Epic 8 -> Epic 9  -> Epic 10
                             (stdio)  (helpers)  (contrib)
                                     |
                                     v
                              Epic 11 -> Epic 12
                            (examples)  (integration tests)
```

## Key Architecture Decisions

- Concurrency: `async` gem (fibers) — closest to Python asyncio
- Schema types: Code-generated from `schema.json`
- Testing: Minitest with TDD
- Ruby version: >= 3.2
- Wire format: camelCase JSON, snake_case Ruby
