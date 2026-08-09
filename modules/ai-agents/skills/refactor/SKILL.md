---
name: refactor
description: Execute scoped, behavior-preserving code simplifications in an already-selected area. Use when the user asks to refactor, simplify, clean up, remove duplication or dead code, or reduce the maintenance cost of specific code. Use improve-codebase-architecture to discover codebase-wide opportunities, codebase-design to redesign an interface or seam, and a review workflow to assess a completed change.
---

# Refactor

Make selected code easier to understand and change while preserving its exact observable behavior.

## 1. Establish ground truth

- Read the repository instructions and inspect the target, its callers, neighboring conventions, tests, and relevant history.
- Inspect the worktree before editing. Preserve unrelated user changes.
- State the invariants: inputs, outputs, error modes, side effects, ordering, configuration, and public behavior that must remain unchanged.
- Derive validation from the repository rather than assuming commands. Run the narrowest useful pre-change baseline when practical.
- Record existing failures or coverage gaps before changing code.

This step is complete when the scope, invariants, and verification path are explicit.

## 2. Choose a simplification

Prefer the smallest coherent change that removes concepts or moving parts:

- Delete dead code and pass-through indirection.
- Flatten control flow when it reduces the reader's mental stack.
- Consolidate duplicated policy where one implementation serves real callers.
- Keep a helper when its name carries a useful concept.
- Introduce an abstraction only when it hides complexity behind a smaller interface.

Apply the deletion test to a proposed extraction: deleting a useful module should spread its hidden complexity back into callers. If deletion merely removes indirection, keep the code direct.

Preserve the public interface unless the user explicitly selected an interface change. When the interface or seam is the real decision, use `codebase-design` before implementing. When the target itself is unknown, use `improve-codebase-architecture` instead.

This step is complete when the proposed diff reduces complexity rather than relocating it.

## 3. Implement the selected change

- Apply one coherent simplification at a time.
- Keep feature work and unrelated cleanup out of the diff.
- Follow the repository's compatibility and deprecation policy; do not invent fallback paths.
- Preserve behavioral tests. Update tests only when test structure is itself in scope or the user approved an interface change.
- Remove imports, helpers, configuration, and comments made obsolete by the refactor.
- Do not create commits unless the user asks.

Pause only when alternatives would materially change public behavior, ownership, or interface shape, or when the invariants cannot be established safely.

This step is complete when the selected simplification is applied with no unrelated changes.

## 4. Verify and report

- Run the repository-required formatter, linter, evaluator, tests, and builds in proportion to the change.
- Inspect the final diff for behavior drift, leftover dead code, accidental compatibility layers, and unrelated edits.
- Compare the result against every stated invariant.
- Report what complexity disappeared, the verification evidence, and any residual uncertainty.

Completion requires fresh evidence that the relevant behavior remains intact. If full verification is unavailable, state the exact gap instead of claiming completion.
