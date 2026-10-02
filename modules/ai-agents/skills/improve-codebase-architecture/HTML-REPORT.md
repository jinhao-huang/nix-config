# HTML Report Format

Render the architectural review as one HTML file in the OS temporary directory. Use inline CSS and SVG so the content and diagrams work offline. Mermaid is an authoring option when a renderer is available; embed its SVG output rather than loading a browser runtime from a CDN.

## Scaffold

```html
<!doctype html>
<html lang="{{report language code}}">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{{localized architecture review title}} · {{repo name}}</title>
    <style>
      * { box-sizing: border-box; }
      body { margin: 0; background: #fafaf9; color: #0f172a; font: 1rem/1.6 system-ui, sans-serif; }
      main { max-width: 72rem; margin: auto; padding: clamp(1rem, 4vw, 3rem); }
      article { margin-block: 2rem; padding: 1.5rem; border: 1px solid #cbd5e1; background: white; }
      .comparison { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 22rem), 1fr)); gap: 1.5rem; }
      figure { margin: 0; min-width: 0; }
      svg { display: block; width: 100%; height: auto; }
      a { color: #4338ca; text-underline-offset: .2em; }
      :focus-visible { outline: 3px solid #4338ca; outline-offset: 3px; }
      code { overflow-wrap: anywhere; }
      @media print { body { background: white; } article { break-inside: avoid; } }
    </style>
  </head>
  <body>
    <main>
      <header>...</header>
      <section id="top-recommendation">...</section>
      <section id="candidates">...</section>
    </main>
  </body>
</html>
```

## Reading order

Show the repo, date, scope, and top recommendation first. Explain which candidate to tackle and why, with an anchor to its evidence. Add a short diagram legend where needed: solid box = module, dashed line = seam, red arrow = leakage, thick box = deep module.

Each candidate is an `<article>` containing:

- A title naming the deepening and a localized recommendation strength: `Strong`, `Worth exploring`, or `Speculative`.
- Files involved, with useful links where the preview environment supports them.
- Before and after diagrams placed side by side on wide screens and stacked on narrow ones.
- The problem, proposed change, and expected benefits, each tied to observed code.
- An ADR conflict callout only when the evidence justifies revisiting that decision.

Keep the main explanation concise. Use `<details>` for supporting evidence when it would interrupt the comparison; keep the recommendation and its material limitations visible.

## Diagram patterns

Choose the representation that explains the candidate:

- **Dependency or call graph:** boxes and arrows; emphasize the paths and leaked responsibilities that change. A rendered Mermaid flowchart or sequence diagram can work well here.
- **Cross-section:** horizontal bands showing each module a call passes through, then the consolidated responsibility.
- **Mass diagram:** rectangles for interface and implementation size, illustrating shallow versus deep. Label schematic proportions as illustrative when they are not measured.
- **Call-graph collapse:** nested calls before, one public interface with faded internals after.

Use SVG `viewBox`, readable labels, and accessible titles or figure captions. Pair color with labels or line styles. Diagrams should remain legible at the size the report displays them.

## Style and language

Use readable typography, generous spacing, and a restrained accent color. Spend visual complexity on the architecture comparison. Add custom interaction only when it materially helps inspect a candidate; static HTML and native disclosure elements are usually enough.

Follow the global language policy for all user-visible prose, labels, and diagrams. Keep markup, identifiers, and code comments in English. Use the project's `GLOSSARY.md` for domain terms and the [codebase-design vocabulary](../codebase-design/SKILL.md) for architecture. In a non-English report, retain canonical architecture terms inline or explain each once.

Name concrete gains in locality, leverage, or depth. Quantify affected call sites, tests, leaked responsibilities, or deleted shallow modules when the evidence supports it. Distinguish expected benefits from measured results.
