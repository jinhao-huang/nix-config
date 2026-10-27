# macOS 安装

[English](darwin.md) | [中文首页](../README.zh-CN.md)

以普通用户身份在仓库根目录操作。先选择机器的用途；该名称与硬件型号、macOS 主机名无关：

```sh
deploy_host=laptop # Use desktop on the desktop Mac.
```

每次打开新的 shell 都需要重新设置这个变量。

## 首次激活前

开始前需要已安装 Nix 和 Git。检查 [hosts/darwin.nix](../hosts/darwin.nix) 中所选角色的 `username`、`homeDirectory`、`authorizedKeyFiles` 和应用选择。若启用 Hermes，现在就准备[模型设置和秘密文件](../modules/hermes/README.zh-CN.md)；否则本次激活保持关闭。

如果构建需要透明代理，先将 Surge Mac 官方版本放到 `/Applications/Surge.app`，打开应用并启用增强模式（Enhanced Mode）。激活时，Homebrew Bundle 会接管已有应用，将其纳入 `surge` cask 管理。

先登录 Proton Pass，避免 SSH agent 的 launch agent 在未认证时启动：

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
```

## 首次激活

完成上述准备后，激活一次 nix-darwin。即使尚无 `darwin-rebuild` 命令，也可执行：

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host"
```

Nix 可能询问是否信任本 flake 的 `cache.numtide.com` substituter 和公钥。如果信任仓库和缓存，可选择 `Allow always` 或 `yes for now`。拒绝后不会使用该缓存，部分软件包可能需要本地构建。激活完成后重启终端，加载新的环境。

## GitHub CLI 登录

激活后登录一次，后续 shell 会复用已保存的登录状态：

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

这些参数保留现有 agent 配置，协议选择及其对认证的影响见 [GitHub CLI、SSH 与签名](../modules/gh/README.zh-CN.md)。系统凭据存储可用时，GitHub CLI 会把令牌保存在其中。不要将令牌写入 Nix 值；无界面的自动化任务应从运行时秘密存储注入 `GH_TOKEN`。

<a id="hermes"></a>

## Hermes

Hermes 是可选功能，`laptop` 和 `desktop` 默认关闭。若已在激活前启用，现在可以打开 CLI/TUI：

```sh
hermes --tui
```

启用 gateway 后，使用以下命令检查：

```sh
launchctl print "gui/$UID/org.nix-community.home.hermes-agent"
tail -n 50 ~/Library/Logs/hermes-agent.err.log
```

Surge 负责出站网络。之后需要启用或升级 Hermes 时，按 [Hermes 配置与维护指南](../modules/hermes/README.zh-CN.md)准备，再使用日常重新构建流程，不运行 `hermes update`。

## 远程访问与 Harness

- [Tailscale 入站访问](../modules/tailscale/README.zh-CN.md)说明设备注册、连接检查和日志查看方法；出站流量继续由 Surge 处理。
- [macOS 远程登录](../profiles/system/darwin/remote-login/README.zh-CN.md)与 Tailscale SSH 使用各自独立的授权机制。
- 打开由 Homebrew 安装的 **DeepSeek Harness**，在 **Settings → Models** 中添加 API key。凭据和会话保存在 `~/.dsh`。[Harness 策略](../modules/deepseek-harness/default.nix)关闭遥测、额外会话日志上传和桌面产品分析；模型请求仍会发送任务上下文。

## 维护与恢复

日常重新构建和输入更新见[中文首页](../README.zh-CN.md)。下面的 Proton Pass 步骤用于故障恢复和主动退出，不属于首次安装流程。

如果先激活、后登录，先停止 agent，登录后重新激活：

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
nix run .#deploy -- switch "$deploy_host"
```

主动退出登录前也要先停止 agent，让已加载的 SSH 密钥退出内存：

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

再次登录后执行 `switch`，在当前用户会话重新加载 agent。之后的新用户会话会自动加载。
