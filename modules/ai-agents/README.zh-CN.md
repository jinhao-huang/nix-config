# AI agent 技能

[English](README.md) | [中文首页](../../README.zh-CN.md)

[global-guidelines.md](global-guidelines.md) 保存自动加载的共享指令，HERO Anti-OverDefense 规则整合在 Scope Limits 和 Finished Prose 两节。上游版本、许可证和本地修改单独记录在 [global-guidelines.sources.json](global-guidelines.sources.json)，不放入加载的指令正文。更新 HERO 时，将所记录版本的上游 `RULES.md` 与整合后的规则比较，并同步更新来源记录和许可证。修改指令后，重新构建、切换并开启新的 agent 会话才会生效，见[Agent 指南](../../docs/development.zh-CN.md#agent-指南)。

每个仓库内置技能放在 `skills/<name>/`，连同它的脚本、参考资料、资源文件和专属许可证一起保存。目录名必须与 `SKILL.md` frontmatter 的 `name` 一致。

## 来源与更新

每个技能包都必须登记在 `skill-sources/<owner>-<repo>.json` 中，上游 owner 和仓库名使用小写。没有已记录外部上游、由本地维护的技能放在 `local.json`。来源记录中的路径相对于本模块，格式由 `checks/skill-sources.schema.json` 定义。多个技能共用的上游许可证放在对应来源记录旁。

更新上游时，将完整技能包与其固定 revision 比较，一并更新 revision、审阅日期和 adaptations。如果最初导入的 revision 未被记录，在 `revision_note` 中写明已经核实的比较基准。保留有关来源或许可证文本的已知不确定性。

## 部署与生效

Nix 通过指向这些技能包的链接组装 `~/.agents/skills`。已有内容的编辑实时生效；增加或移除技能需要重新构建并切换。

应用自带的技能目录通过所属用户 profile 的 `modules.ai-agents.externalSkills` 选择。Darwin profile 选择 Surge 自带技能，Linux 不安装它。

这里的技能、agent 提示词和来源记录属于部署输入，保留各自的原始语言约定；本中文说明的同步规则见[开发指南](../../docs/development.zh-CN.md#documentation-sync)。

## 验证

检查入口、校验器、schema 和失败用例位于 `checks/`。在仓库根目录执行静态检查；Linux 上替换为本机 system：

```sh
nix build --no-link .#checks.aarch64-darwin.ai-agent-skills
```

该检查运行校验器的失败用例，并检查来源覆盖、固定 revision 元数据、许可证路径、名称、描述、Claude/Codex 调用策略的一致性，以及相对 Markdown 链接。它也会拒绝技能包内容中的符号链接，因此应用的特定平台路径应留在 profile 中。
