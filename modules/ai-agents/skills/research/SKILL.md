---
name: research
description: Investigate topics, technical comparisons, or background questions against primary sources and deliver a cited report. Use for substantive research; answer quick factual lookups and status questions directly.
---

Scope the investigation to the user's decision and reuse evidence already gathered in the session. Delegate independent source investigation to a **background agent** when it will meaningfully reduce elapsed time; handle small or tightly coupled investigations directly. Give the agent the question, scope, and evidence requirements below. Its notes are working material; the coordinating agent checks the evidence and owns the final report.

## Evidence

- Investigate against **primary sources**: official docs, source code, specs, first-party APIs, or the original speaker's publication. Follow claims back to the source that owns them; secondary summaries can supply leads.
- Link factual claims to their supporting sources near the claim. For changing information, record the research date and relevant version, commit, or publication date.
- Distinguish verified facts, inference, recommendations, and unresolved questions. A video description or third-party transcript does not establish an exact quotation or timestamp from the original recording.
- For repository comparisons, separate upstream changes from intentional local adaptations and account for supporting files as well as `SKILL.md`.

## Deliverable

Default to a single HTML report in the OS temporary directory with a fresh, descriptive filename. Persist a report in the repository only when the user explicitly requests it; then follow the project's format and location conventions. Honor an explicitly requested output format.

Copy [assets/report.html](assets/report.html) and fill its content rather than regenerating its styles. Replace `{{REPORT_LANG}}` with the language code, `{{REPORT_TITLE}}` with an HTML-escaped title, and `<!-- REPORT_CONTENT -->` with semantic HTML. Keep the existing CSS unless the content demonstrates a layout need. The template supports headings, tables inside `.table-wrap`, native `<details>`, inline diagrams, and `.comparison` columns. Give scrolling table containers an accessible name and `tabindex="0"` for keyboard scrolling. Use a project's established report template when one exists.

Routine reports use this template without loading `frontend-design`. A separately requested website, application interface, or visual redesign can use that skill's design workflow.

Write for the reader's decision:

- Lead with the answer and the most consequential findings. Keep evidence and uncertainty visible alongside the recommendations they affect.
- Use tables or diagrams where they clarify relationships, anchor navigation for long reports, and native `<details>` for secondary evidence. Keep conclusions and material limitations outside collapsed sections.
- Cover the requested scope in the explanation; link to source files and diffs instead of embedding them in full by default. Include full material when the user needs a standalone offline archive or when it is essential to the decision.
- Keep the report self-contained with inline CSS and SVG; core content and diagrams must render without network access or script execution. Add custom JavaScript only when a concrete reading or exploration task needs it. Search, filters, animations, and custom print controls are optional features, not routine report requirements.
- Follow the global language policy for rendered prose, labels, and diagram text. Keep markup, identifiers, and code comments in English.

Keep Markdown or structured research notes only when needed for agent handoff or ongoing maintenance; a second deliverable is not required by default.

## Verify and present

Open the report with the available file-preview or browser tool. When browser inspection is available, check the new content: main findings, long headings, tables, diagrams, and source links. For a new or modified template, also check narrow layouts, keyboard access, printing, and script-independent content; for new controls, exercise their behavior. Reuse established template checks when its layout and behavior are unchanged. Fix actual readability or functional problems, and stop once these checks pass. State when visual verification was unavailable.

Give the user a concise answer and a clickable absolute path to the HTML report. The report contains the detailed findings and their sources; the conversation should carry the decision and important limitations.
