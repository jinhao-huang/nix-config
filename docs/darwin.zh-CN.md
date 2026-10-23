# macOS 安装

[English](darwin.md) | [中文首页](../README.zh-CN.md)

以普通用户身份在仓库根目录操作。先选择机器的用途；该名称与硬件型号、macOS 主机名无关：

```sh
darwin_profile=laptop # Use desktop on the desktop Mac.
```

每次打开新的 shell 都需要重新设置这个变量。

## 首次激活

开始前需要已安装 Nix。如果构建需要透明代理，先将 Surge Mac 官方版本放到 `/Applications/Surge.app`，打开应用并启用增强模式（Enhanced Mode）。激活时，Homebrew Bundle 会接管已有应用，将其纳入 `surge` cask 管理。

先登录 Proton Pass，再激活 nix-darwin，避免 SSH agent 的 launch agent 在未认证时启动。即使尚无 `darwin-rebuild` 命令，也可执行：

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$darwin_profile"
```

Nix 可能询问是否信任本 flake 的 `cache.numtide.com` substituter 和公钥。如果信任仓库和缓存，可选择 `Allow always` 或 `yes for now`。拒绝后不会使用该缓存，部分软件包可能需要本地构建。激活完成后重启终端，加载新的环境。

## GitHub CLI 登录

激活后执行：

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

`--skip-ssh-key` 将 SSH 密钥管理留给 Proton Pass agent。系统凭据存储可用时，GitHub CLI 会把令牌保存在其中。不要将令牌写入 Nix 值；无界面的自动化任务应从运行时秘密存储注入 `GH_TOKEN`。

## Proton Pass 会话恢复与退出

如果先激活、后登录，先停止 agent，登录后重新激活：

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
nix run .#deploy -- switch "$darwin_profile"
```

主动退出登录前也要先停止 agent，让已加载的 SSH 密钥退出内存：

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

再次登录后执行 `switch`，在当前用户会话重新加载 agent。之后的新用户会话会自动加载。

## 远程访问与 Harness

- [Tailscale 入站访问](../modules/tailscale/README.zh-CN.md)说明设备注册、连接检查和日志查看方法；出站流量继续由 Surge 处理。
- [macOS 远程登录](../profiles/system/darwin/remote-login/README.zh-CN.md)与 Tailscale SSH 使用各自独立的授权机制。
- 打开由 Homebrew 安装的 **DeepSeek Harness**，在 **Settings → Models** 中添加 API key。凭据和会话保存在 `~/.dsh`。[Harness 策略](../modules/deepseek-harness/default.nix)关闭遥测、额外会话日志上传和桌面产品分析；模型请求仍会发送任务上下文。

日常重新构建和输入更新见[中文首页](../README.zh-CN.md)。
