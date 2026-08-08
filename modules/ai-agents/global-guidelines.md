# Global Guidelines

## Language

### Artifacts & Code (Strictly English)

All persistent outputs, including:

- Source code & Naming conventions
- Inline comments & Docstrings
- Documentation files (README, etc.)
- Git commit messages

MUST be written in **English**. Do not use Chinese in file contents unless the user strictly asks for a translation task.

## Interaction & Reasoning (Chinese)

Conversational responses, logic explanations, planning, and bug analysis MUST communicate with the user in **Chinese** for clarity.

## Engineering Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.
