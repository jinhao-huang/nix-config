# Linux 安装与服务

[English](linux.md) | [中文首页](../README.zh-CN.md)

以 Home Manager 管理的 Linux 用户身份在本仓库目录操作，使用已安装的 Nix 或 Lix，不使用 sudo。Home Manager 管理用户环境，主机操作系统和 Nix daemon 仍由管理员维护。主机数据位于 [hosts/linux.nix](../hosts/linux.nix)，字段与服务选项见[配置参考](configuration.zh-CN.md)。

## 首次激活前

开始前需要已有 Nix 或 Lix 和 Git。检查所选主机条目的 `username`、`homeDirectory` 和 `authorizedKeyFiles`，把必需的 shell 初始化逻辑迁入受管理的模块。保留已有 SSH 会话，直到激活后测试新的连接。

切换前准备好每个已启用的功能：

- sing-box：准备[下面的输入文件](#sing-box-输入文件)，或在清单中设置 `singBox.enable = false`。
- Hermes：准备[模型设置和秘密文件](../modules/hermes/README.zh-CN.md)。若模型尚未准备好，本次激活设置 `hermes.enable = false`。启用 Telegram 时，还需提前准备 bot token 和允许访问的用户 ID。
- GHCR：需要时在清单中设置 `dockerGhcr`。认证在激活后完成；拉取镜像所需的 Docker 和 Compose 由主机提供。
- Harness 与 Tailscale Serve：检查清单中的 `deepseekHarness.publicHost` 和 HTTPS 设置，tailnet 注册在激活后完成。

激活要求 systemd 用户管理器可用，并启用用户 linger。激活时会尝试开启 linger；若权限被拒绝，需要管理员开启。主机管理员也负责 Nix daemon 和 Docker 网络。

### sing-box 输入文件

在 Git 之外创建 `~/.config/sing-box/subscription.curl`：目录权限为 `0700`，文件权限为 `0600`。文件通过 HTTPS 请求原生 sing-box JSON：

```text
url = "https://subscription.example/private-token?format=json"
```

也可将 `singBox.nodesFile` 指向私有 JSON 文件，文件权限为 `0600`，内容包含 `{"outbounds": [...]}`，并设置 `singBox.subscription.requestFile = null`。两种来源可以合用，不支持分享链接。端口、实验室网络直连规则和输入约束见[选项参考](configuration.zh-CN.md#modulessing-boxnodesfile)。

## 首次激活

完成上述准备后，在仓库根目录激活一次。将 `example-host` 替换为目标主机清单的键名：

```sh
deploy_host=example-host
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host" -b before-hm
```

`switch` 先构建，再激活。`-b before-hm` 会备份冲突文件，但不会保留旧文件的行为。linger 检查失败时，切换会中止。增加 `-n` 可预览激活，但仍可能构建或下载软件包，并初始化本地主机清单。激活后打开新 shell，加载受管理的命令和环境变量，再继续下方检查与认证；各功能无需再次激活。

之后修改配置或秘密文件时，使用日常的[构建与激活流程](../README.zh-CN.md#构建与激活)。Nix 连接异常可先用 `nix store ping` 检查。

## Shell 与 SSH

Home Manager 不修改账号的登录 shell，需要时显式启动 `zsh` 或 tmux。若需要 Git 签名，使用 `ssh -A <ssh-host>` 连接，将占位符替换为目标主机的 SSH 别名，并转发包含签名密钥的 agent。本地 SSH 覆盖配置写入 `~/.ssh/config.local`。

Home Manager 激活时合并主机 `authorizedKeyFiles` 列表中的公钥，在权限为 `0700` 的 `.ssh` 目录中生成当前用户所有、权限为 `0600` 的普通文件 `~/.ssh/authorized_keys`。每次激活都会原子替换该文件，因此应修改主机的公钥列表。这里需要自定义激活步骤，因为 `home.file` 会创建指向 Nix store 的符号链接，而允许组写入的 store 目录无法通过 OpenSSH 的 `StrictModes` 检查。该步骤遵守 dry-run，复制失败时保留原文件。

系统 SSH daemon 必须读取该路径。切换后保留当前会话，并另开一次普通 SSH 连接验证。Tailscale SSH 保持启用，使用独立的授权策略。

## Tailscale

首次激活后，为用户态 daemon 注册一次；后续激活会复用已保存的身份：

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

若 `AuthURL` 为空，等几秒后再次查询状态。在浏览器打开该 URL，批准设备接入。通过 `tailscale-user ip -4` 查看地址。共享服务器应使用专用 tag，在 [tailnet 策略](https://tailscale.com/docs/reference/syntax/grants)中允许所需的 SSH 端口和受管理 Linux 账号，并移除访问其他设备的权限。仅关闭出站代理不能限制访问。

查看日志：`journalctl --user -u tailscaled`。

## sing-box

启用后，激活流程会使用前面准备的输入启动代理。用 `with-proxy git fetch` 代理单个命令，或用 `with-proxy bash` 启动代理 shell。包装命令要求代理已经运行；修改端口或凭据后需启动新 shell。仅能通过 tailnet 到达的目标，需要单独使用用户态 Tailscale 出站通道。

检查用户服务时，`with-proxy` 保留已有的 `XDG_RUNTIME_DIR`；变量未设置时，使用 `/run/user/<UID>`。因此，缺少该变量的 Tailscale SSH 会话也能直接使用已运行的代理，无需手动配置 shell。包装命令不会创建运行目录或启动用户管理器。

输入校验失败时会保留正在运行的代理。如果启动恢复失败，恢复上一代 Home Manager 配置和保存的私有配置；二进制程序不会自动回滚。服务日志见 `journalctl --user -u sing-box`，私有诊断快照位于 `~/.local/state/sing-box/snapshots/`。

## 私有容器镜像

若已启用 GHCR 集成，拉取私有镜像前完成 [GitHub CLI 认证](../modules/docker-ghcr/README.zh-CN.md#认证)。Docker daemon 和 Compose 仍由主机维护。

## Hermes

若已在激活前启用并准备好 Hermes，现在检查 gateway 并打开 CLI/TUI。只使用 CLI 时跳过服务检查。启用 sing-box 时按下例使用 `with-proxy`，否则直接运行 `hermes --tui`。用户 linger 使 gateway 在退出登录后继续运行：

```sh
systemctl --user status hermes-agent
journalctl --user -u hermes-agent -n 50 --no-pager
with-proxy hermes --tui
```

应实际验证模型回复，启用 Telegram 时再验证消息收发。gateway 生命周期通过 `systemctl --user` 管理。启用 sing-box 时，gateway 通过 `with-proxy` 启动，并随代理重启。

修改设置或秘密文件后切换，也会重启活跃的 Hermes 服务。禁用或删除数据前，先查看[状态归属与移除步骤](../modules/hermes/README.zh-CN.md#数据路径与移除)。

之后启用 Hermes、升级或备份状态时，按 [Hermes 维护指南](../modules/hermes/README.zh-CN.md#maintenance)操作。

## DeepSeek Harness

启用 MagicDNS 和 tailnet HTTPS 证书，并允许目标设备访问 Serve 配置的 HTTPS 端口，默认是 443。连接 Tailscale 后，在以下日志中找到最新完整启动 URL，连同其中的私有令牌一起打开：

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

日志含有秘密，应限制访问。认证后收藏不带令牌的干净 URL；认证过期时重新打开启动 URL。用 `tailscale-user serve status` 检查入口，并用 `systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve` 检查相关服务。
