# macOS 安装

[English](darwin.md) | [中文首页](../README.zh-CN.md)

以普通用户身份在仓库根目录操作。先选择机器的用途；该名称与硬件型号、macOS 主机名无关：

```sh
deploy_host=laptop # Use desktop on the desktop Mac.
```

每次打开新的 shell 都需要重新设置这个变量。

## 首次激活前

开始前需要已安装 Nix 和 Git。检查 [hosts/darwin.nix](../hosts/darwin.nix) 中所选角色的 `username`、`homeDirectory`、`authorizedKeyFiles` 和应用选择。若已启用 Hermes，请在激活前核对[凭据来源](../modules/hermes/README.zh-CN.md#秘密文件与激活)。

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

[桌面机角色](../hosts/darwin.nix)启用了 Hermes 和 Dashboard。切换前，将 MiniMax 中国区订阅 Key 存入主机清单中 `MINIMAX_CN_API_KEY` 引用的 Proton Pass 字段。新聊天默认使用 MiniMax。要在当前聊天中改用 DeepSeek，输入 `/model deepseek-flash --provider deepseek --session`。

在使用 MiniMax 的 Dashboard 聊天中上传图片，模型会直接读取图片内容。

要用浏览器访问，先完成 [HTTPS 设置](../modules/tailscale/README.zh-CN.md#hermes-over-https)。激活后也可以在终端运行：

```sh
hermes --tui
```

启用 gateway 后，使用以下命令检查：

```sh
launchctl print "gui/$UID/org.nix-community.home.hermes-agent"
tail -n 50 ~/Library/Logs/hermes-agent.err.log
```

Surge 负责出站网络。之后需要启用或升级 Hermes 时，按 [Hermes 配置与维护指南](../modules/hermes/README.zh-CN.md)准备，再使用日常重新构建流程，不运行 `hermes update`。

## Telegram MCP

两台 Mac 都通过 [Home Manager launch agent](../modules/telegram-mcp/default.nix) 运行同一个[固定版本的镜像](https://github.com/users/jinhao-huang/packages/container/package/telegram-mcp)。打开 OrbStack，并设为登录时启动。Docker 停止时也能通过 SSH 切换配置。Agent 在 macOS 登录会话中运行。

`switch` 会创建 `telegram/` 和 `downloads/`，权限为 `0700`。使用默认 XDG 路径时，笔记本在 `~/.local/share/telegram-mcp/` 下创建，桌面机在 `~/.local/share/metaweave/` 下创建。缺少凭据时，`switch` 会提示预期路径。

检出 `v3.3.20`，按[上游登录与迁移指南](https://github.com/chigwell/telegram-mcp/blob/v3.3.20/README.md#quick-start)分别在两台 Mac 上登录。先把 API 凭据写入检出目录下的临时 `.env`，生成会话字符串后也存入该文件，再执行迁移。将 `PATH` 换成对应 Mac 上 `telegram/` 目录中 `telegram.session` 的完整路径。

```sh
uv sync --locked --no-dev --no-install-project --no-build
uv run --no-sync python session_string_generator.py
uv run --no-sync python migrate_session.py --target PATH
```

迁移成功后，删除临时 `.env`，再写入 `~/.config/nix-config/telegram-mcp.env`。以不带引号的 `KEY=value` 格式填写 `TELEGRAM_API_ID` 和 `TELEGRAM_API_HASH`，两台可复用同一组值。在 `TELEGRAM_ALLOWED_CHAT_IDS` 中填入需要访问的 Telegram 聊天 ID 或 `@用户名`，用逗号分隔。会话文件和凭据文件都使用 `0600` 权限。若设置 `TELEGRAM_PROXY_*`，代理地址须能从 OrbStack 访问。

将 MCP 客户端的 Streamable HTTP 地址设为 `http://127.0.0.1:8765/mcp`。两台 Mac 都开放只读工具和同一组[写工具](../profiles/home/darwin.nix)。连接后检查容器状态和客户端列出的工具，再下载一份小附件，确认文件写入本机 `downloads/` 目录。

```sh
docker --context orbstack compose -f ~/.config/nix-config/telegram-mcp/compose.yaml ps
```

启动日志在 `~/Library/Logs/telegram-music.log`。编辑环境文件后，运行 `launchctl kickstart -k "gui/$UID/org.nix-community.home.telegram-music"` 重启。

<a id="music-library"></a>

## 音乐库

在桌面 Mac 上把 [Metaweave](https://github.com/jinhao-huang/metaweave) 克隆到[主机清单](../hosts/darwin.nix)的 `musicLibrary.checkout` 路径。缺少技能文件时，`switch` 会提示。切换配置后，在检出目录安装锁定的运行环境。锁文件更新后重跑此命令。

```sh
uv sync --locked --no-dev --no-build --managed-python
```

`switch` 会创建 `music-library` profile，它有独立的会话和记忆，与 `default` 共用 Proton Pass 中的模型凭据。在桌面 Mac 配好 [Telegram MCP](#telegram-mcp)，再运行 `hermes -p music-library mcp test telegram-music` 检查连接。

在现有 Dashboard 中选择 `music-library` profile，然后新建聊天。说明频道和任务，发送前审阅确切内容。Telegram MCP 将不超过 200 MiB 的附件保存到 Mac 的下载目录。超过上限时，用 Telegram 客户端下载到这台 Mac。收到网页分享时，按 Skill 的流程下载并把文件交到这台 Mac，再开始验收。任务记录放在曲库之外。就地整理通过已配置的 SSH 主机在 NAS 上执行，首次就地整理前需在 NAS 上安装 Skill 的独立运行环境。

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
