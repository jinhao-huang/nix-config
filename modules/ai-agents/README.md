# AI agent skills

English | [简体中文](README.zh-CN.md)

Shared always-loaded instructions live in [global-guidelines.md](global-guidelines.md).
HERO Anti-OverDefense rules are integrated into Scope Limits and Finished Prose.
Keep upstream revisions, licenses, and local adaptations in
[global-guidelines.sources.json](global-guidelines.sources.json), outside the
loaded instructions. When updating HERO, compare the recorded upstream `RULES.md`
with the integrated rules and update the source record and license together.
Guidance changes take effect after a rebuild, switch, and new agent session; see
[Agent guidance](../../docs/development.md#agent-guidance).

Keep each bundled skill in `skills/<name>/`, including its scripts, references,
assets, and any skill-specific license. Keep the directory name and the
`SKILL.md` frontmatter name identical.

Register every bundle in `skill-sources/<owner>-<repo>.json`, using lowercase
upstream owner and repository names. Use `local.json` for locally maintained
skills with no recorded external upstream. Source-record paths are relative to
this module; `checks/skill-sources.schema.json` defines the format. Shared upstream
licenses belong beside their source record.

For upstream updates, compare the complete bundle against its pinned revision,
then update the revision, review date, and adaptations together. If the original
import revision was not recorded, document a verified comparison baseline in
`revision_note`. Preserve any known uncertainty about origins or license text.

Nix assembles the installed directory at `~/.agents/skills` from links to these
bundles. Existing content edits are live; adding or removing skills requires a
rebuild and switch. Select application-owned skill directories with
`modules.ai-agents.externalSkills` in the owning home profile. The Darwin profile
selects Surge's bundled skill; Linux does not install it.

The check entry point, validator, schema, and failure cases live in `checks/`.
Run the static check from the repository root, substituting the native system
on Linux:

```sh
nix build --no-link .#checks.aarch64-darwin.ai-agent-skills
```

This runs the validator's failure cases and checks source coverage, fixed
revision metadata, license paths, names, descriptions, Claude/Codex invocation
policy agreement, and relative Markdown links. It also rejects symlinks in
bundled content so platform-specific application paths stay in profiles.
