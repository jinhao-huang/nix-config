---
name: research
description: Investigate topics, technical comparisons, or background questions against primary sources and deliver a concise, cited report with a clear answer. Use for substantive research; answer quick factual lookups and status questions directly.
---

Research thoroughly; publish selectively. Identify the question the reader needs answered and the constraints that could change the answer. Reuse evidence already gathered in the session. Stop expanding the investigation when the requested questions have supported answers and remaining unknowns are explicit.

Delegate independent source investigation when authorized and useful. Request findings with evidence, not report chapters; the coordinating agent verifies them and writes one coherent report.

## Evidence

- Investigate against **primary sources**: official docs, source code, specs, first-party APIs, or the original speaker's publication. Follow claims back to the source that owns them; secondary summaries can supply leads.
- Link factual claims to their supporting sources near the claim. For changing information, record the research date and relevant version, commit, or publication date.
- Distinguish verified facts, inference, recommendations, and unresolved questions. A video description or third-party transcript does not establish an exact quotation or timestamp from the original recording.
- For repository comparisons, separate upstream changes from intentional local adaptations and account for supporting files as well as `SKILL.md`.

## Write the answer

Choose content before choosing layout:

- Open with two or three short sentences that directly answer the question, give the main reason, and state any condition that would change the answer. A reader who stops there should understand the recommendation. Put dates and version metadata on a separate compact line.
- Rank findings by their effect on the reader's decision. Each paragraph or table row earns its place by answering a requested question, explaining a consequential tradeoff, or enabling the next action. Keep source inventories, investigation history, and exhaustive checks in working notes unless the user needs them.
- Give each point one home. The opening previews the answer; the body adds evidence or explanation. Merge sections that repeat the same reasoning. Cover meaningful alternatives; omit options already ruled out by the user's constraints.
- Use the smallest structure that fits: answer, reasons or comparison, then action and material limitations. Broader reports can follow the user's subquestions. Headings should state a finding or name a concrete question; avoid generic headings that could appear in any report.
- For ordinary research, aim for 800–1,500 Chinese characters or 400–700 English words of main prose, excluding code and citations. This is a target, not a quota. Explicitly broad or detailed requests may need more; every added section must answer part of that request. Depth comes from stronger evidence and clearer explanation, not a larger inventory of facts.

Use plain language:

- Write short sentences with a concrete subject and verb. Keep paragraphs focused on one point. Use familiar words; explain an unavoidable technical term where it first matters. Reserve option names, paths, hashes, and implementation detail for places where the reader needs them.
- Explain the practical consequence with the fact: what changes, why it matters, or what the reader should do. For an unfamiliar design, show one small example or a simple data flow before introducing its schema or abstractions.
- Use tables for comparisons along a few decision-relevant dimensions, with short cells. Use prose for reasoning and numbered steps for actions. A table or diagram should reduce reading effort, not add another rendering of the same explanation.
- Keep uncertainty beside the conclusion it qualifies. State the specific missing evidence and its consequence; consolidate verification status in one short note. Distinguish facts from recommendations where it affects trust, without labeling every sentence.

## Package the report

Default to a single HTML report in the OS temporary directory with a fresh, descriptive filename. Persist a report in the repository only when the user explicitly requests it; then follow the project's format and location conventions. Honor an explicitly requested output format.

Copy [assets/report.html](assets/report.html) and fill its content. Replace `{{REPORT_LANG}}` with the language code, `{{REPORT_TITLE}}` with an HTML-escaped title, and `<!-- REPORT_CONTENT -->` with semantic HTML. Keep the existing CSS unless the content demonstrates a layout need. Use a project's established report template when one exists. The template provides layout primitives, not a list of sections to fill.

Routine reports use this template without loading `frontend-design`. A separately requested website, application interface, or visual redesign can use that skill's design workflow.

Keep the main reading path short. Link to source files and diffs. Use native `<details>` only for useful supporting evidence or implementation instructions; prune that material too. Keep conclusions, prerequisites, and material risks visible. Include full source material when essential to the decision or requested for an offline archive. Add anchor navigation only when the report needs it.

Keep the report self-contained with inline CSS and SVG; core content must render without network access or script execution. Use `.table-wrap` for tables, with an accessible name and `tabindex="0"`. Add custom JavaScript only for a concrete reading or exploration task. Follow the global language policy for rendered prose; keep markup, identifiers, and code comments in English.

Keep Markdown or structured research notes only when needed for agent handoff or ongoing maintenance; a second deliverable is not required by default.

## Verify and present

Before opening the report, make an editorial pass:

- Read only the opening and headings. They should reveal the answer, the decisive reasons, and any important condition. Replace topic announcements with actual findings.
- Remove paragraphs that add no new evidence, explanation, tradeoff, or action. Check the length target and eliminate repeated conclusions, incidental background, and unnecessary detail before moving useful extras into `<details>`.
- Check that shortening preserved every requested answer, its supporting sources, and conditions that could change the recommendation. Brevity must not hide uncertainty or imply unperformed verification.

Open the report with the available file-preview or browser tool. Check the opening, headings, tables, diagrams, and source links. For a changed template, also check narrow layouts, keyboard access, printing, and script-independent content; exercise new controls. Reuse established template checks when unchanged. Fix observed problems and stop when these checks pass. State when visual verification was unavailable.

Give the user a brief direct answer, the decisive reason or limitation, and a clickable absolute path to the report. The conversation must be understandable on its own; leave the supporting detail in the report.
