# macOS Tailscale 入站访问

[English](README.md) | [中文首页](../../README.zh-CN.md)

本模块运行用户态 Tailscale daemon，处理入站访问；Surge 继续处理出站流量。系统路由、DNS 和共享 Surge profile 保持不变。自定义模块避开了 nix-darwin `services.tailscale` 会添加的 DNS resolver 文件。

它应是主机上唯一的 Tailscale daemon；Surge 内嵌的客户端独立运行。

## 注册与连接

`enabled = true` 要求建立连接，但退出登录时不会主动发起浏览器认证。首次注册时，不修改已锁定的偏好，而是执行：

```sh
sudo tailscale debug localapi POST login-interactive
sudo tailscale status --json
```

第一条命令通常没有响应正文。认证是异步的，如果 `AuthURL` 仍为空，等几秒后再次查询状态。在浏览器打开该 URL 并批准设备，确认 `BackendState` 变为 `Running`。

连接时使用 `sudo tailscale ip -4` 返回的本节点地址，不要使用 Surge 节点的地址。之后启动会复用现有身份。认证停滞时，查看下方日志。

普通 TCP/UDP 流量会转发到 `127.0.0.1` 的相同端口，因此服务必须监听该地址，通常只能看到本地来源地址。可达的 localhost 服务也会被暴露给获准连接的设备，tailnet 规则应限制设备和端口。

Tailscale SSH 已启用，需要同时允许 TCP 22 和以本地账号登录的 SSH 策略。它使用独立的服务器与认证，与 macOS 远程登录、`authorized_keys` 无关。

## 维护

两个平台模块均通过 `modules.tailscale.package` 选择 daemon 和 CLI。flake 从 `nixpkgs-unstable` 选择 Tailscale；需要新版本或 Go 安全修复时，更新该输入。激活前使用所选软件包的 `tailscale version` 核对两者版本。每周检查发行信息，优先处理适用的安全公告。

客户端更新检查和自动应用更新均已关闭，由 Nix 管理安装。新构建只有在激活重新加载 daemon 后才生效。

入站访问和 SSH 在 [Darwin profile](../../profiles/system/darwin/default.nix) 中配置。Nix 生成锁定的原生配置，因此不通过 CLI 修改偏好，也不使用 `up`/`login` 完成注册。激活配置变更会重新加载 daemon，可能中断连接。需要清除偏好时，显式设置 `false` 或空列表；省略字段可能保留旧值。

[原生配置 schema](https://tailscale.com/docs/reference/tailscaled/tailscaled-config-file)仍处于 alpha 阶段，`debug localapi` 也不是稳定 CLI 接口，更新 Tailscale 时应核对两者。

节点身份和运行状态位于 `/var/lib/tailscale-ingress`，禁用模块后仍保留，Nix 回滚不会恢复它们。凭据和状态应保存在 Git 与 Nix store 之外。

查看服务状态与日志：

```sh
sudo launchctl print system/com.tailscale.tailscaled
sudo tailscale debug daemon-logs
```
