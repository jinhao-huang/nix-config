# Linux 安装与服务

[English](linux.md) | [中文首页](../README.zh-CN.md)

以 Home Manager 管理的 Linux 用户身份在本仓库目录操作，使用已安装的 Nix 或 Lix，不使用 sudo。Home Manager 管理用户环境，主机操作系统和 Nix daemon 仍由管理员维护。主机数据位于 [hosts/linux.nix](../hosts/linux.nix)，字段与服务选项见[配置参考](configuration.zh-CN.md)。

## 首次激活前

开始前需要已有 Nix 或 Lix 和 Git。检查所选主机条目的 `username`、`homeDirectory` 和 `authorizedKeyFiles`，把必需的 shell 初始化逻辑迁入受管理的模块。保留已有 SSH 会话，直到激活后测试新的连接。

切换前准备好每个已启用的功能：

- sing-box：准备[下面的输入文件](#sing-box-输入文件)，或在清单中设置 `singBox.enable = false`。
- Hermes：切换前先[发布 Dashboard 凭据](#hermes)。
- GHCR：需要时在清单中设置 `dockerGhcr`。认证在激活后完成；拉取镜像所需的 Docker 和 Compose 由主机提供。
- Tailscale Serve：检查清单中的 `tailnetHost`。激活后再注册到 tailnet。

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
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
deploy_host=example-host
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host" -b before-hm
```

`switch` 先构建，再激活。`-b before-hm` 会备份冲突文件，但不会保留旧文件的行为。linger 检查失败时，切换会中止。增加 `-n` 可预览激活，但仍可能构建或下载软件包，并初始化本地主机清单。激活后打开新 shell，加载受管理的命令和环境变量，再继续下方检查与认证；各功能无需再次激活。

之后修改配置或秘密文件时，使用日常的[构建与激活流程](../README.zh-CN.md#构建与激活)。Nix 连接异常可先用 `nix store ping` 检查。

## Shell 与 SSH

Home Manager 不修改账号的登录 shell，需要时显式启动 `zsh` 或 tmux。若需要 Git 签名，使用 `ssh -A <ssh-host>` 连接，将占位符替换为目标主机的 SSH 别名，并转发包含签名密钥的 agent。本地 SSH 覆盖配置写入 `~/.ssh/config.local`。

Linux profile 在 `XDG_RUNTIME_DIR` 未设置或为空时使用 `/run/user/<UID>`，保留已有值。Bash 登录、交互和 SSH 命令会话都会加载 Home Manager 会话变量；Zsh 从 `.zshenv` 加载。因此，SSH 登录后可以直接使用 `systemctl --user`、`tailscale-user` 和 `with-proxy`。激活后重新连接以加载新环境。运行目录和用户管理器由主机的 systemd-logind 与 linger 管理，shell 启动过程不会创建目录或启动管理器。

Home Manager 激活时合并主机 `authorizedKeyFiles` 列表中的公钥，在权限为 `0700` 的 `.ssh` 目录中生成当前用户所有、权限为 `0600` 的普通文件 `~/.ssh/authorized_keys`。每次激活都会原子替换该文件，因此应修改主机的公钥列表。这里需要自定义激活步骤，因为 `home.file` 会创建指向 Nix store 的符号链接，而允许组写入的 store 目录无法通过 OpenSSH 的 `StrictModes` 检查。该步骤遵守 dry-run，复制失败时保留原文件。

系统 SSH 服务必须读取该路径，并监听 `127.0.0.1:22`。通过现有的系统 SSH 连接激活配置，再用 tailnet 主机名新建连接，验证公钥登录后关闭原会话。

## Tailscale

首次激活后，为用户态 daemon 注册一次；后续激活会复用已保存的身份：

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

若 `AuthURL` 为空，等几秒后再次查询状态。在浏览器打开该 URL，批准设备接入。通过 `tailscale-user ip -4` 查看地址。

用户态 Tailscale 将 tailnet 的 TCP 22 转发给本机 OpenSSH，由 OpenSSH 验证 Linux 账号。共享服务器应使用专用 tag，在 [tailnet 策略](https://tailscale.com/docs/reference/syntax/grants)中只允许指定客户端访问 TCP 22，并移除服务器访问其他设备的权限。仅关闭出站代理不能限制访问。

查看日志：`journalctl --user -u tailscaled`。

## sing-box

启用后，激活流程会使用前面准备的输入启动代理。用 `with-proxy git fetch` 代理单个命令，或用 `with-proxy bash` 启动代理 shell。包装命令要求代理已经运行；修改端口或凭据后需启动新 shell。仅能通过 tailnet 到达的目标，需要单独使用用户态 Tailscale 出站通道。

输入校验失败时会保留正在运行的代理。如果启动恢复失败，恢复上一代 Home Manager 配置和保存的私有配置；二进制程序不会自动回滚。服务日志见 `journalctl --user -u sing-box`，私有诊断快照位于 `~/.local/state/sing-box/snapshots/`。

## 私有容器镜像

若已启用 GHCR 集成，拉取私有镜像前完成 [GitHub CLI 认证](../modules/docker-ghcr/README.zh-CN.md#认证)。Docker daemon 和 Compose 仍由主机维护。

## Hermes

首次切换 Linux 前，以及每次轮换密钥后，在已登录 Proton Pass 的 Mac 上进入仓库并发布凭据。

```sh
nix run .#hermes-secrets -- example-host
```

把 `example-host` 换成 Linux 清单中对应的 SSH 别名。注册到 tailnet 前，在 Mac 的 `~/.ssh/config.local` 中将该别名指向可连接的系统 SSH 地址。tailnet 主机名可用后，移除这项覆盖。命令读取[共用的 Hermes 凭据](../modules/hermes/README.zh-CN.md#秘密文件与激活)，经 SSH 替换 `~/.config/nix-config/hermes.env`。如果服务器的本地清单还有旧的 Hermes 密钥路径或 Telegram 覆盖，先移除再切换。Linux 执行 `switch` 时读取发布后的文件。

开启 MagicDNS 和 HTTPS 证书后，用以下命令确认新的 Serve 映射，再向自己的身份放行 TCP `9119`，并限制对后端端口的直接访问。打开 `https://<node>.ts.net:9119/chat`，确认未登录时会跳转到登录页，然后登录并发送一条消息。

```sh
systemctl --user status hermes-backend tailscale-serve-hermes
tailscale-user serve status
```

验证新部署后，删除已停用的 `~/.config/hermes/secrets.env`。升级和状态管理见 [Hermes 维护指南](../modules/hermes/README.zh-CN.md#maintenance)。

## DeepSeek Harness

启用 MagicDNS 和 tailnet HTTPS 证书。用 `tailscale-user serve status` 确认新的 Serve 映射后，在 tailnet 策略中向需要访问的设备放行 TCP `3080`，并限制对后端和 Cookie 代理端口的直接访问。连接 Tailscale 后，在以下日志中找到最新完整启动 URL，连同其中的私有令牌一起打开。

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

日志含有秘密，应限制访问。认证后收藏不带令牌的干净 URL；认证过期时重新打开启动 URL。用 `tailscale-user serve status` 检查入口，并用 `systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve` 检查相关服务。
