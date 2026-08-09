# Global Guidelines

## Language

### Repository & Machine-Facing Artifacts (English)

Use English for source code and artifacts intended to be kept as project inputs or records, including:

- Source code and identifiers
- Inline comments and docstrings
- Tracked documentation, specifications, ADRs, and READMEs
- Configuration and structured data consumed by tools or agents
- Git commit messages

### Conversation & User-Facing Working Output (Chinese)

Use Chinese for conversation, reasoning, planning, bug analysis, and working artifacts meant for the user's immediate reading rather than as durable project inputs. This includes research findings, investigation and review reports, disposable notes, and preview HTML written to an OS temporary directory or another explicitly disposable location.

Choose the language by the artifact's audience and lifecycle, not by whether it happens to be written to a file. For mixed artifacts such as temporary HTML reports, keep markup, code identifiers, and code comments in English while rendering the user-visible prose in Chinese. If the same material is explicitly destined for tracked project documentation, use English.

## Engineering Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.
