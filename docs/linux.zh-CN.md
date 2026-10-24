# Linux 安装与服务

[English](linux.md) | [中文首页](../README.zh-CN.md)

在 `iscas-r750xa` 上，以 `huangjh` 身份在本仓库目录使用已有 Lix 安装操作，不使用 sudo。Home Manager 管理用户环境，主机操作系统和 Nix daemon 仍由管理员维护。主机数据位于 [hosts/linux.nix](../hosts/linux.nix)，字段与服务选项见[配置参考](configuration.zh-CN.md)。

## 首次激活

切换前，把必需的实验室环境初始化逻辑迁入受管理的 shell 模块，检查 `authorizedKeyFiles`，并准备 [sing-box 输入文件](#sing-box)。若不需要 sing-box，在主机清单中设置 `singBox.enable = false`。

```sh
nix run .#deploy -- switch iscas-r750xa -b before-hm
```

`-b before-hm` 会备份冲突文件，但不会保留这些旧文件的行为。激活要求启用用户 linger，并会尝试开启；若被拒绝，切换会中止。增加 `-n` 可预览激活，但仍可能构建或下载软件包，并初始化本地主机清单。构建与更新见[中文首页](../README.zh-CN.md)；Nix 连接异常可先用 `nix store ping` 检查。

## Shell 与 SSH

登录 shell 仍为 Bash，需要时显式启动 `zsh` 或 tmux。若需要 Git 签名，使用 `ssh -A iscas-r750xa` 连接，并转发包含签名密钥的 agent。本地 SSH 覆盖配置写入 `~/.ssh/config.local`。

Home Manager 根据主机的 `authorizedKeyFiles` 列表生成 `~/.ssh/authorized_keys`，系统 SSH daemon 必须读取该路径。切换后保留当前会话，并另开一次普通 SSH 连接验证。Tailscale SSH 保持启用，使用独立的授权策略。

## Tailscale

激活后注册用户态 daemon：

```sh
tailscale-user debug localapi POST login-interactive
tailscale-user status --json
```

打开状态中的 `AuthURL`，批准设备接入。通过 `tailscale-user ip -4` 查看地址。共享服务器应使用专用 tag，在 [tailnet 策略](https://tailscale.com/docs/reference/syntax/grants)中允许所需的入站 TCP 22 和以 `huangjh` 身份登录的 SSH，并移除访问其他设备的权限。仅关闭出站代理不能限制访问。

查看日志：`journalctl --user -u tailscaled`。

## sing-box

在 Git 之外创建 `~/.config/sing-box/subscription.curl`：目录权限为 `0700`，文件权限为 `0600`。文件通过 HTTPS 请求原生 sing-box JSON：

```text
url = "https://subscription.example/private-token?format=json"
```

也可将 `singBox.nodesFile` 指向私有 JSON 文件，文件权限为 `0600`，内容包含 `{"outbounds": [...]}`，并设置 `singBox.subscription.requestFile = null`。两种来源可以合用，不支持分享链接。端口、实验室网络直连规则和输入约束见[选项参考](configuration.zh-CN.md#modulessing-boxnodesfile)。

用 `with-proxy git fetch` 代理单个命令，或用 `with-proxy bash` 启动代理 shell。包装命令要求代理已经运行；修改端口或凭据后需启动新 shell。仅能通过 tailnet 到达的目标，需要单独使用用户态 Tailscale 出站通道。

输入校验失败时会保留正在运行的代理。如果启动恢复失败，恢复上一代 Home Manager 配置和保存的私有配置；二进制程序不会自动回滚。服务日志见 `journalctl --user -u sing-box`，私有诊断快照位于 `~/.local/state/sing-box/snapshots/`。

## Hermes

完成 [Hermes 主机配置与秘密文件准备](../modules/hermes/README.zh-CN.md)后，执行[切换](../README.zh-CN.md#构建与激活)并打开新 shell。用户 linger 使 gateway 在退出登录后继续运行；需要交互时再打开 CLI/TUI：

```sh
systemctl --user status hermes-agent
journalctl --user -u hermes-agent -n 50 --no-pager
with-proxy hermes --tui
```

应实际验证模型回复和 Telegram 收发。gateway 生命周期通过 `systemctl --user` 管理。启用 sing-box 时，gateway 通过 `with-proxy` 启动，并随代理重启；不需要代理时可直接运行 `hermes`。

修改设置或秘密文件后切换，也会重启活跃的 Hermes 服务。禁用或删除数据前，先查看[状态归属与移除步骤](../modules/hermes/README.zh-CN.md#数据路径与移除)。

升级时更新 `hermes-agent` flake 输入并切换，不运行 `hermes update`。先备份 `~/.hermes`：Home Manager 回滚不会恢复应用状态。`hermes --version` 可能显示 `v0.0.0`，应结合输出的 commit 和 `flake.lock` 识别版本。Nix 属于上游的 [Tier 2 平台](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support/)。

## DeepSeek Harness

启用 MagicDNS 和 tailnet HTTPS 证书，并允许目标设备访问 Serve 配置的 HTTPS 端口，默认是 443。连接 Tailscale 后，在以下日志中找到最新完整启动 URL，连同其中的私有令牌一起打开：

```sh
journalctl --user -u deepseek-harness -b --no-pager
```

日志含有秘密，应限制访问。认证后收藏不带令牌的干净 URL；认证过期时重新打开启动 URL。用 `tailscale-user serve status` 检查入口，并用 `systemctl --user status deepseek-harness deepseek-harness-proxy tailscale-serve` 检查相关服务。
