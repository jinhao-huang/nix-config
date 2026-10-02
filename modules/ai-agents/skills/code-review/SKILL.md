---
name: code-review
description: Review a branch, pull request, or staged and unstaged changes for correctness, repository standards, and agreement with the requested behavior. Use when the user asks for code review or review since a commit, branch, or tag.
---

Review along two independent axes:

- **Standards:** correctness, maintainability, and the repository's documented conventions.
- **Spec:** whether the change implements the requested behavior and stays within scope.

Use parallel sub-agents when available so one assessment does not anchor the other. Both receive the same pinned review scope. Without delegation support, evaluate the axes separately.

## Pin the review scope

Use the scope already established by the user or conversation. Inspect `git status --short` and the relevant branch or PR metadata before choosing a comparison.

- **Current work:** `git diff HEAD` covers the net tracked changes in both the index and working tree. Include relevant untracked files from `git ls-files --others --exclude-standard`; Git diff does not include them. For an unborn branch, inspect the index and working files directly.
- **Staged only:** `git diff --cached`; do not add unstaged or untracked work.
- **Unstaged only:** `git diff`; inspect relevant untracked files when they belong to the requested work.
- **Branch or PR:** resolve the target branch and compute its merge-base with `HEAD` once. Review `git diff <base-sha> HEAD` and record `git log <base-sha>..HEAD --oneline`.
- **Since an exact commit or tag:** resolve that revision to a commit and compare directly against it. Use a merge-base only when the user wants branch divergence.

For a fixed-base review that includes work in progress, `git diff <base-sha>` includes tracked working-tree changes, and untracked files still need separate inspection. State which endpoint you selected. Respect narrower path scopes and exclude unrelated pre-existing edits.

Infer a missing baseline from the active task or PR when unambiguous; ask only if different plausible baselines would materially change the review. Validate refs before dispatch. An empty tracked diff is not an empty review until the scoped untracked files have been checked.

Capture the selected diff and untracked contents in temporary review artifacts when dispatching reviewers. Give both reviewers the resolved base and endpoint, changed-file list, and access to surrounding code. If the relevant files change during review, refresh the affected assessment before declaring it complete. Reviewing alone does not authorize modifying files, creating commits, or posting findings externally.

## Gather the requirements and standards

Use the user's explicit request, accepted decisions in this conversation, and any supplied spec or issue as the primary requirements. Fetch linked issues with available read-only tools when needed. Existing `docs/agents/issue-tracker.md` can describe the workflow, but setup is not a prerequisite for a review.

If requirements remain unclear, look for issue references in commits and relevant project specs. Ask only for a missing requirement that affects the result. If no spec is available, report that limitation and complete the Standards axis.

Read applicable `AGENTS.md`, `CLAUDE.md`, contribution guidance, and coding standards for the changed paths. Check the repository's validation commands and any available results. Automated checks handle mechanical rules; review should focus on issues those checks do not establish.

Use these design smells as heuristics where relevant: misleading names, duplicated logic, data clumps, feature envy, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, and middlemen. A smell earns a finding only when the changed code causes a concrete maintenance or correctness problem. Repository conventions override generic preferences.

## Review independently

The **Standards reviewer** receives the scope, applicable standards, and the design heuristics above. Ask it to inspect surrounding code and callers, identify introduced defects or meaningful convention violations, and cite the relevant rule where applicable. Separate documented violations from design judgement.

The **Spec reviewer** receives the same scope and the actual requirements. Ask it to identify missing or partial behavior, incorrect implementations, and unrequested behavior. Each finding must connect the changed code to a requirement or accepted decision.

Both reviewers report actionable findings with file and line, the triggering scenario, impact, evidence, and a proportional suggested correction. They should mark uncertainty and avoid presenting unsupported suspicions as confirmed bugs. Review changed behavior without treating unrelated existing defects as regressions.

## Aggregate

Check each finding against the code and requirements. Remove false positives and duplicates; retain its Standards or Spec attribution. Present confirmed findings by severity so important defects are easy to act on, then give a short result for each axis and any validation gaps. Do not modify the implementation unless fixes were requested.

If there are no findings, say so and identify the scope and limits of the review. A clean review does not establish that unrun tests passed.
