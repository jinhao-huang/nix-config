# macOS 远程登录

[English](README.md) | [中文首页](../../../../README.zh-CN.md)

两个 Darwin profile 都启用 Apple 内置 SSH 服务器。登录策略见 [default.nix](default.nix)，获准客户端的公钥见[主机清单](../../../../hosts/darwin.nix)。用户自行维护的 `~/.ssh/authorized_keys` 不会被使用。

## 权限与监听边界

- macOS“远程登录”用户列表是额外的访问检查；完全磁盘访问权限需要单独授权。
- TCP 22 由 launchd 管理，`sshd_config` 中的 `Port` 和 `ListenAddress` 不会改变监听方式。本 profile 不会把访问限制在 tailnet 内。
- 两个 profile 中的 [Tailscale SSH](../../../../modules/tailscale/README.zh-CN.md)使用独立授权，本 profile 的登录策略不适用于它。
- macOS 26 及更新版本上的 [FileVault SSH 解锁](https://github.com/apple-oss-distributions/OpenSSH/blob/main/apple_ssh_and_filevault.7)在普通 SSH 配置可用前使用密码认证。重启和解锁必须单独测试，仅确认正常 launchd 状态不能证明 Preboot SSH 状态正确。
