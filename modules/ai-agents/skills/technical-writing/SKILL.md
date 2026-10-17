---
name: technical-writing
description: Write, revise, or review README files and developer documentation for concise, task-focused prose. Excludes research reports, agent instructions, and format-only conversion.
license: MIT
---

# Technical writing

Write so the intended reader can find the answer and use it on the first reading.
Follow the requested language and the target project's terminology and conventions.
Use `writing-for-agents` for agent instructions and `research` for research reports.

## Choose the content

- Identify what the reader needs to understand, decide, or do. Use the request and
  existing context; ask only when a missing answer would change the document.
- Read the target document and the implementation, configuration, or nearby
  examples needed for the change. Keep a narrow edit narrow.
- Lead with the answer or outcome. Include background when it explains a necessary
  condition or decision; keep investigation notes outside the document.
- Give each point one home. Extend the document that owns the information and
  link to it elsewhere instead of maintaining competing descriptions.

## Fit the document to the reader's task

| Document | What belongs |
| --- | --- |
| README | Project purpose, the shortest usable starting path, and links to further documentation. |
| Tutorial | A concrete result to build, a learning path, and visible results along the way. |
| How-to | Prerequisites, actions, necessary choices, and a way to confirm success. |
| Reference | Complete lookup facts for the stated scope: names, defaults, constraints, and errors. |
| Explanation | The mechanism, reasons, alternatives, and tradeoffs behind one topic. |

Use these distinctions to choose content, not to impose a fixed outline. A README
can introduce several kinds of documentation. Split and link only when doing so
helps readers find what they need; do not fill sections for completeness alone.

## Write and prune

- Use real symbols, paths, flags, and command names. Keep one term per concept;
  avoid invented labels and synonym changes that make readers learn extra names.
- Prefer ordinary words and direct verbs. Make the actor clear when it matters;
  passive voice is useful when the actor is unknown or irrelevant.
- Keep each sentence focused, with its necessary condition or consequence. Vary
  length naturally rather than turning the document into clipped fragments.
- Put prerequisites and consequential warnings before the actions they affect.
  Present the common path before alternatives when that order is safe and clear.
- Cut empty setup, repeated conclusions, inflated claims, and decorative emphasis.
  A paragraph should add a needed fact, explanation, tradeoff, or action.
- Use paragraphs for reasoning, numbered steps for sequences, and tables for
  comparisons or repeated lookup fields. Let the content determine the layout.
- Apply English grammar guidance only to English. Judge wording and punctuation
  in context; use readability rather than fixed sentence lengths or banned words.

## Finish the document

Read the opening and headings together: can the intended reader locate the answer?
Check changed claims, examples, and links against their sources. Preserve scope,
conditions, uncertainty, attribution, and completion status; do not invent details
to make prose sound specific. When editing, retain independent information unless
the request authorizes selection or summarization. Preserve code, commands, data,
and link targets unless changing them is part of the task.

For Chinese prose, load and follow [humanizer-zh](../humanizer-zh/SKILL.md) for the
final language edit. Reuse a completed pass if the text has not changed.

When a document format needs its own skill, read its requirements before authoring
and regenerate the artifact after the final text edit. Deliver the finished text
and relevant verification, without intermediate drafts or self-scoring rituals.
