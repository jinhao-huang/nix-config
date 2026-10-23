# 开发指南

[English](development.md) | [中文首页](../README.zh-CN.md)

## 架构与归属

flake 将主机数据、profile 和功能模块组合为 Darwin 系统及独立 Linux 用户环境。profile 相关术语见[术语表](../GLOSSARY.zh-CN.md)。

| 位置 | 职责 |
| --- | --- |
| [flake.nix](../flake.nix) | 输入、软件包来源、配置组合、导出软件包及检查。 |
| [hosts](../hosts) | 主机数据，包括每台机器的应用选择；`default.nix` 校验并合并可选 `host-local` 中的 Pi 和 Linux Hermes 覆盖配置。 |
| [profiles/home](../profiles/home) | `common.nix` 管理共享 CLI 策略，`darwin.nix` 和 `linux.nix` 管理各平台用户选择。 |
| [profiles/system/darwin](../profiles/system/darwin) | 共享 macOS 设置、偏好、应用和远程登录；将共享应用与每台主机的应用列表合并。 |
| [modules](../modules) | 可独立复用的功能、功能选项和配套数据。 |
| [packages](../packages) | 自定义 derivation，包括部署命令和配置参考生成器。 |

Darwin 集成 Home Manager，并管理系统 Lix 安装。Linux 选择激活和 shell 工具，操作系统与 Nix daemon 仍归管理员维护。Linux profile 通过模块选项连接 sing-box、Harness 后端、cookie 代理和 Tailscale Serve，并检查回环端口互不冲突。

## 模块约定

共享功能选择放在所属 profile，每台机器的应用列表留在主机清单。profile 专属辅助逻辑放在该 profile 附近，功能数据放在模块旁，例如 SSH 清单、Starship 符号。只有必须作用于所有已配置 Home Manager 用户的策略才使用 `home-manager.sharedModules`，其余模块从对应 profile 导入。系统功能由系统 profile 选择，用户功能由用户 profile 选择。

单入口功能提供 `default.nix`。面向多个 evaluator 的功能分别提供 `home-manager.nix` 和 `nix-darwin.nix`，由 profile 导入匹配入口。在 evaluator 入口声明 `_class = "homeManager"` 或 `"darwin"`，通过 assertion 约束支持的平台。共享选项和内部实现留在功能目录中，自定义 derivation 使用 `packages/<name>/default.nix`。

## Agent 指南

[全局指南](../modules/ai-agents/global-guidelines.md)与用户 profile 中的机器上下文一同部署。修改任一项后，需要重新构建并切换，再开始新的 agent 会话。技能链接到源目录，编辑已有链接内容会实时生效；改变部署的技能集合则需要重新构建并切换。来源记录和技能验证见 [AI agent 维护](../modules/ai-agents/README.zh-CN.md)。

<a id="validation"></a>

## 验证

从仓库根目录执行。运行 flake 命令前，先把新文件加入 Git 索引；Git flake 会忽略未跟踪路径。修改 Nix 时，对每个改动的 Nix 文件运行 `nixfmt --check`。基础求值检查使用 `nix flake check --no-build`，但它不会构建 checks，也不会构建完整 Darwin 系统闭包。

| 变更范围 | 切换前的额外验证 |
| --- | --- |
| 共享 Darwin 或集成的 Home Manager | `nix build --no-link .#darwinConfigurations.laptop.system .#darwinConfigurations.desktop.system` |
| 单台 Darwin 主机 | `darwin-rebuild build --flake .#laptop`，或改用 `desktop`。 |
| Linux 用户 profile | 先运行 `nix flake check --all-systems --no-build`，再在 Linux builder 上显式求值并构建 `homeConfigurations.<name>.activationPackage`。 |
| 软件包 | 构建受影响的导出软件包，检查 hash、支持平台和适用的 `meta.mainProgram`；软件包输出改变时还要对所有 system 求值。 |
| sing-box 运行逻辑或 linger 辅助程序 | 除相关 Linux 检查外，运行 `python3 modules/sing-box/tests.py`。 |
| 内置技能或来源元数据 | `nix build --no-link .#checks.aarch64-darwin.ai-agent-skills`；Linux 替换为本机 system。 |
| 配置参考 | 按下文重新生成，再运行 `nix build --no-link .#checks.aarch64-darwin.configuration-reference`；Linux 替换为本机 system。 |

Linux 激活包注册为 `checks.<system>.<name>-home`。当前服务器可显式执行：

```sh
nix eval --raw .#homeConfigurations.iscas-r750xa.activationPackage.drvPath
nix build --no-link .#homeConfigurations.iscas-r750xa.activationPackage
```

<a id="generated-reference"></a>

## 生成配置参考

服务选项的描述和示例在所属 Nix 选项声明中修改；主机和 Pi 说明在 [configuration-intro.md](configuration-intro.md) 中修改。之后执行：

```sh
nix run .#update-configuration-reference
```

[英文 configuration.md](configuration.md) 是生成文件，应修改源文件后重新生成。`configuration-reference` 软件包同时导出机器可读的 `options.json`。生成过程不读取秘密，也不激活服务。中文参考的维护方式见下文。

<a id="documentation-sync"></a>

## 文档同步规则

英文文档与简体中文版本必须在同一次变更中维护。行为、前置条件、命令、主机字段、选项名、类型、默认值、示例、验证方式或维护流程发生变化时，都要检查两种语言的文档。无论修正最初发生在哪一种语言，只要改变含义，就要同步另一种。行为以代码和 Nix 声明为准；文档冲突时，先核对实现，再修正两种版本。

中文文件放在英文文件同一目录，使用相同基本文件名和 `.zh-CN.md` 后缀。每个文档提供语言切换链接，有中文版本的导航目标优先链接到中文。命令、标识符、路径、字面值和代码示例保持一致，翻译解释性正文；代码和 agent 输入仍遵守原有语言约定。同步范围如下：

| 英文文档 | 中文文档 |
| --- | --- |
| [README.md](../README.md) | [README.zh-CN.md](../README.zh-CN.md) |
| [GLOSSARY.md](../GLOSSARY.md) | [GLOSSARY.zh-CN.md](../GLOSSARY.zh-CN.md) |
| [docs/darwin.md](darwin.md) | [docs/darwin.zh-CN.md](darwin.zh-CN.md) |
| [docs/linux.md](linux.md) | [docs/linux.zh-CN.md](linux.zh-CN.md) |
| [docs/development.md](development.md) | [docs/development.zh-CN.md](development.zh-CN.md) |
| [docs/configuration.md](configuration.md) | [docs/configuration.zh-CN.md](configuration.zh-CN.md) |
| [modules/ai-agents/README.md](../modules/ai-agents/README.md) | [modules/ai-agents/README.zh-CN.md](../modules/ai-agents/README.zh-CN.md) |
| [modules/hermes/README.md](../modules/hermes/README.md) | [modules/hermes/README.zh-CN.md](../modules/hermes/README.zh-CN.md) |
| [modules/starship/README.md](../modules/starship/README.md) | [modules/starship/README.zh-CN.md](../modules/starship/README.zh-CN.md) |
| [modules/tailscale/README.md](../modules/tailscale/README.md) | [modules/tailscale/README.zh-CN.md](../modules/tailscale/README.zh-CN.md) |
| [profiles/system/darwin/remote-login/README.md](../profiles/system/darwin/remote-login/README.md) | [profiles/system/darwin/remote-login/README.zh-CN.md](../profiles/system/darwin/remote-login/README.zh-CN.md) |

`docs/configuration.md` 继续由 `docs/configuration-intro.md` 和 Nix 选项声明生成。修改这些源文件并重新生成英文参考后，手工同步完整中文参考，包括引言和每一个选项条目。中文参考直接维护，生成器不会覆盖它。保持选项标题及其锚点、类型、默认值、示例和声明来源链接对应一致；新增或删除选项时，两种语言的条目一并增删。生成的 `options.json` 保持机器可读格式，不翻译。

新增、移动或删除项目指南时，两种语言的文件、指向它们的链接和上表都要一起更新。仓库内置的第三方技能文档、agent 提示词、`AGENTS.md`、来源记录和许可证属于部署或 agent 输入，遵守原有语言约定，无需配套翻译。

交付文档变更前，应完成以下检查：

1. 对照实现和另一种语言，核对条件、限制与命令效果。
2. 重命名文件或修改标题后，检查相对链接与标题锚点。
3. 配置参考源发生变化时，重新生成并运行上文的 `configuration-reference` 检查，再核对中文参考的选项集合、类型、默认值和代码示例。
4. 校对中文表达，保留事实与不确定性。在交付说明中列出更新的文档对和已执行的验证；行为变更无需更新文档时，说明原因。
