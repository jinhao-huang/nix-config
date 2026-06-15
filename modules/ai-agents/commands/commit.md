---
description: Generate and execute a commit from staged changes
agent: commit
subtask: false
model: zhipuai-coding-plan/glm-5.2 
---

Run the commit workflow now.

Use the full current context, including:
- The current conversation context.
- Any command arguments: `$ARGUMENTS`.
- The currently staged Git changes.
- Recent Git commit history in this repository.

Expected behavior:
1. Generate a Conventional Commit message that matches repository style.
2. Execute `git commit` directly with the generated message.
3. Return the created commit hash and final commit message.
4. If there are no staged changes, stop and explain what to stage first.

Commit message length policy:
- Prefer the shortest message that is still accurate and useful.
- Default to a single-line Conventional Commit header for simple changes.
- Treat a change as simple when it has one clear purpose, is small or
  mechanical, affects only docs/config/formatting, or is an obvious bug fix.
- Do not add a body just to list changed files, repeat the header, or make a
  small change look more important.
- Use a multi-line body only when the staged changes are genuinely complex:
  multiple related concerns, non-obvious motivation, behavior/API/schema
  impact, migration details, compatibility risk, security/performance
  tradeoffs, or testing context that materially helps future readers.
- When a body is justified, keep it concise: 1-3 bullets focused on why,
  impact, and notable constraints rather than an exhaustive change log.
