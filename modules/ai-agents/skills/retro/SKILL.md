---
name: retro
description: Review a coding session to improve the agent's tools, checks, navigation, and guidance. Use when the user asks for a retrospective or for workflow improvements grounded in a completed session.
---

Look for changes to the agent's environment that would improve future runs.

1. Load and read the [writing-for-agents skill](../writing-for-agents/SKILL.md) before proposing instruction changes.
2. Read the session the user specifies; default to the current conversation. Use available logs and artifacts to distinguish what happened from what the agent merely planned or claimed. Report any missing evidence that limits the retrospective.
3. Identify recurring or costly friction in the categories below. Tie each candidate to a concrete event in the session and check whether an existing tool, check, or document already addresses it.
4. Present the strongest candidates in impact order: the observed problem, the smallest useful change, and how to tell whether it worked. If the user authorized improvements, implement those within the agreed scope and validate them; a retrospective alone calls for recommendations.

## Where to look

- **Navigation:** time lost locating code or conventions; add or sharpen a pointer at the place the agent actually looks.
- **Automated checks:** mechanical mistakes that a linter, type check, test, build, or CI check can reliably catch. Inspect existing checks first; repair an unwired check before creating another. Choose validation appropriate to the repository, including configuration evaluation and builds where those exercise the behavior.
- **Coding standards:** judgement that automation cannot capture. Amend an existing convention where possible, and remove contradictory or obsolete instructions. Both implementation and review must honor the applicable standards.
- **Instruction load:** repeated, irrelevant, or ineffective rules in skills and guidance. Prune or move detail behind a useful context pointer instead of accumulating instructions in global guidance.
- **Tool economy:** repeated expensive calls or noisy outputs. Prefer existing tool capabilities and focused calls; introduce a helper only when repeated use justifies maintaining it.
- **Information access:** missing logs, documentation, or read access that prevented a sound decision. Treat proposals for new access separately from permission to obtain it.

Improve the demonstrated failure mode. Avoid turning a single incident into a universal rule or treating the absence of a particular tool as proof it is needed.
