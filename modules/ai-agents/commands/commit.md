---
description: Generate and execute a commit from staged changes
agent: commit
subtask: false
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
