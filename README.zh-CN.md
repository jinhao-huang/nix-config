# 个人 Nix 环境

[English](README.md) | 简体中文

本仓库用 Nix flake 管理个人 macOS 工作站和 Linux 开发服务器上的用户环境。macOS 使用 nix-darwin 和 Home Manager；Linux 使用独立 Home Manager，主机操作系统和 Nix daemon 由管理员维护。

## 安装与文档

先准备 Nix 或 Lix 和 Git，再将仓库检出到 `~/nix-config`。profile 使用此位置建立 AI 技能的实时链接；若选择其他位置，激活前修改用户 profile 中的 `modules.ai-agents.repoRelativePath`。按对应平台指南依次完成准备、首次激活和认证。

| 任务 | 文档 |
| --- | --- |
| 配置 Mac，登录 GitHub CLI 和 Proton Pass | [macOS 安装](docs/darwin.zh-CN.md) |
| 配置 Linux 用户环境、SSH 和用户服务 | [Linux 安装与服务](docs/linux.zh-CN.md) |
| 修改主机字段、Pi 启动默认值或服务选项 | [配置参考](docs/configuration.zh-CN.md) |
| 理解架构、编写模块、验证变更 | [开发指南](docs/development.zh-CN.md) |
| 查阅 profile 等项目术语 | [术语表](GLOSSARY.zh-CN.md) |
| 维护中英文文档 | [文档同步规则](docs/development.zh-CN.md#documentation-sync) |

## 构建与激活

以下命令用于已配置机器的日常重新构建，首次激活按平台指南执行。以普通用户身份在仓库目录操作。macOS 选择 `laptop` 或 `desktop`；Linux 使用 [hosts/linux.nix](hosts/linux.nix) 中的主机名：

```sh
deploy_host=laptop # Or desktop; use your Linux inventory key on Linux.
nix run .#deploy -- build "$deploy_host"
nix run .#deploy -- switch "$deploy_host"
```

只想检查构建、不激活配置时使用 `build`。`switch` 构建并激活：macOS 内部调用 `sudo -H`，Linux 不使用 sudo。两者都会在缺少时创建被 Git 忽略的 `hosts/inventory.local.nix`，并加载其中的 [Pi 启动默认值](docs/configuration.zh-CN.md#pi-startup-defaults)和 [Hermes 覆盖配置](modules/hermes/README.zh-CN.md#per-host-configuration)。已有本地文件会保留。

密钥、令牌等秘密不能写入 Nix 值。本地覆盖文件即使被 Git 忽略，其值仍会进入 Nix store。

## 更新输入

```sh
nix flake update                # All inputs
nix flake update nixpkgs        # One input, for example
```

更新 `nix-homebrew` 时，必须同时更新全部四个 `homebrew-*` tap 输入：

```sh
nix flake update nix-homebrew homebrew-core homebrew-cask homebrew-steipete homebrew-jinhao-huang
```

`nix-homebrew` 的 `brew-src` 固定 Homebrew 版本，较新的 tap 可能要求更新的 cask DSL。若版本不匹配导致激活失败，查看 [Homebrew 配置中的激活处理说明](profiles/system/darwin/homebrew.nix)。更新后先完成[开发验证](docs/development.zh-CN.md#validation)，再构建并激活。
