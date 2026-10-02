---
name: research
description: Research a question against primary sources and deliver a cited HTML report for human reading. Use for topic research, technical comparisons, docs or API fact-finding, or background reading.
---

Delegate source investigation to a **background agent** when available, and continue independent work while it reads. Give it the question, scope, and evidence requirements below. Its notes are working material; the coordinating agent checks the evidence and owns the final report. Without delegation support, do the investigation directly.

## Evidence

- Investigate against **primary sources**: official docs, source code, specs, first-party APIs, or the original speaker's publication. Follow claims back to the source that owns them; secondary summaries can supply leads.
- Link factual claims to their supporting sources near the claim. For changing information, record the research date and relevant version, commit, or publication date.
- Distinguish verified facts, inference, recommendations, and unresolved questions. A video description or third-party transcript does not establish an exact quotation or timestamp from the original recording.
- For repository comparisons, separate upstream changes from intentional local adaptations and account for supporting files as well as `SKILL.md`.

## Deliverable

Default to a single HTML report in the OS temporary directory with a fresh, descriptive filename. Persist a report in the repository only when the user explicitly requests it; then follow the project's format and location conventions. Honor an explicitly requested output format.

Design the report for the reader's decision:

- Lead with the answer and the most consequential findings. Keep evidence and uncertainty visible alongside the recommendations they affect.
- Use side-by-side comparisons, tables, timelines, or diagrams where they make relationships easier to understand. Add navigation for long reports and collapsible detail for supporting material. Use interaction only when it helps the reader compare, inspect, or choose.
- Use semantic HTML, readable typography, responsive layouts, and clear source links. Keep the report self-contained with inline CSS and, when useful, inline SVG or JavaScript; core content and diagrams must render without network access or script execution. Use native elements such as `<details>` before building custom controls.
- Follow the global language policy for rendered prose, labels, and diagram text. Keep markup, identifiers, and code comments in English.

Keep Markdown or structured research notes only when needed for agent handoff or ongoing maintenance; a second deliverable is not required by default.

## Verify and present

Open the report with the available file-preview or browser tool. When browser inspection is available, check that the main findings, tables, diagrams, links, and any controls are usable; fix rendering problems before delivering. State when visual verification was unavailable.

Give the user a concise answer and a clickable absolute path to the HTML report. The report contains the detailed findings and their sources; the conversation should carry the decision and important limitations.
