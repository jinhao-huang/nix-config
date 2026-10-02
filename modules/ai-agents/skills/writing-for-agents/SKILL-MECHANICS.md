# Skill mechanics

The skill-specific branch of [writing-for-agents](SKILL.md): discovery, invocation, dependency loading, and routers.

## Discovery and invocation

The skill description is a context pointer: explain what the skill does and which distinct requests should reach it. Keep it narrow enough to avoid triggering on unrelated work.

Preserve an existing skill's invocation policy. For a new skill, keep automatic discovery enabled unless the user requests explicit-only invocation. A focused description can target a user request without removing the skill from discovery.

Invocation policy is client-specific:

- Clients supporting `disable-model-invocation: true` in `SKILL.md` use it for explicit-only skills.
- Codex uses `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for explicit-only skills.

When maintaining a skill across clients, keep these settings consistent with the intended policy. A command example or slash-prefixed skill name in prose does not itself load the skill.

## Dependency loading

When a workflow needs another skill, explicitly tell the agent to load and read its `SKILL.md`, then follow the relevant instructions. Use the client's skill loader if available, or read the referenced file and its required supporting documents. Resolve relative references from the skill containing the link, not the working project.

Use a direct relative link for dependencies shipped alongside the skill. Read them where they become relevant, rather than loading every possible branch at the start. Preserve explicit-only boundaries: suggest those skills for the user to invoke rather than invoking them autonomously.

## Splitting by invocation

Split off a skill when it has a distinct capability that should be discoverable independently or is needed by multiple workflows. Each added description spends context; each explicit-only skill asks the human to remember another entry point. Keep shared reference in the existing skill or a linked plain file when independent discovery adds no value.

## Router skills

A router can help when a set of explicit-only skills becomes hard to navigate. It should recommend available skills and explain which user intent each serves. It does not grant permission to invoke explicit-only skills, install missing dependencies, or perform the actions they describe.
