---
name: research
description: Research a question against primary sources and save a temporary Markdown report; persist it in the repo only when explicitly requested. Use for topic research, docs or API fact-finding, or background reading.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. By default, save the report under the OS temporary directory with a fresh, descriptive filename so it does not land in the repo. If the user explicitly asks to preserve it as project documentation, match the repo's existing convention instead.
4. Treat a temporary report as user-facing working output and a repository report as a repository artifact; follow the global language policy for each.
5. Report the absolute path and give the user a concise summary of the findings.
