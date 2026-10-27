# GitHub CLI、SSH 与签名

[English](README.md) | [中文首页](../../README.zh-CN.md)

沿用本仓库现有的 SSH 工作流时，Git 协议选择 **SSH**。Git 传输、提交签名和 GHCR 认证分别配置，可以使用不同的凭据。

## 仓库策略

[共享 GitHub CLI 模块](default.nix)在 macOS 和 Linux 上声明相同的默认值：

```nix
programs.gh = {
  settings.git_protocol = "ssh";
  gitCredentialHelper.enable = false;
};
```

| 操作 | 配置与凭据 |
| --- | --- |
| Git fetch、pull、push | 仓库的 remote URL 决定使用 SSH 还是 HTTPS。SSH 通过 OpenSSH 及其 agent 配置使用认证密钥。`gh` 在 `gh repo clone` 等命令中优先选择 SSH，不改写已有 remote。 |
| 提交签名 | [Git 模块](../git/default.nix)默认启用 SSH 签名，通过 `key::` 指定公钥；对应私钥必须能通过 agent 使用。remote 使用 SSH 或 HTTPS 都可以签名。 |
| GitHub API 与 GHCR | `gh` 使用登录令牌。[Docker GHCR helper](../docker-ghcr/README.zh-CN.md)读取配置账号的令牌；拉取镜像不需要 SSH 密钥或 agent 转发。 |

`gitCredentialHelper.enable = false` 关闭的是 Home Manager 为 **Git HTTPS** 配置的 `gh` credential helper，不会关闭 **Docker** credential helper，也不妨碍 `gh` 登录。

## SSH 与 HTTPS 的取舍

| 选择 | 优点 | 使用条件 |
| --- | --- | --- |
| SSH | 复用已有 SSH 密钥和 agent；Git 认证不依赖 `gh` 的令牌。 | 执行 Git 的机器必须能使用 agent 或本机认证密钥；SSH 网络路由可能需要单独配置。 |
| HTTPS + `gh` | Git 可以复用 `gh` 登录，HTTPS 通常更容易适配 HTTP 代理。 | 修改共享 GitHub CLI 模块中的声明，启用 `programs.gh.gitCredentialHelper.enable`，并设置 `programs.gh.settings.git_protocol = "https"`，然后使用 HTTPS remote。SSH 签名仍需要签名 agent。 |

两种方式都支持加密连接，选择依据是可用凭据和网络条件。对本仓库现有的 agent 配置，建议保留 SSH。仅在登录提示中选择 HTTPS，不会改变已有的 SSH remote。见 GitHub 的 [remote URL 说明](https://docs.github.com/en/get-started/git-basics/about-remote-repositories)。

在 Linux 上，`with-proxy` 处理 `gh` 的 HTTP 请求，不负责 OpenSSH 传输。Git 偏好选择 SSH 后，`gh` 登录和 API 请求仍使用 HTTPS；Git 的 SSH 连接需要有单独可用的网络路由。

## 已有密钥与 agent

[Darwin profile](../../profiles/home/darwin.nix)使用 [Proton Pass agent](../proton-pass/default.nix)提供 Git 签名及 SSH 主机清单所需的密钥。[Linux SSH 流程](../../docs/linux.zh-CN.md#shell-与-ssh)通过显式转发 agent 提供签名能力；Linux profile 不启动 Proton Pass agent。Mac 上可用的密钥不会自动出现在 Linux 上，共享 SSH 模块默认关闭 agent 转发。

`authorizedKeyFiles` 中的公钥用于允许连接进入受管理账号，不会授予出站访问 GitHub 的权限，也不会选择 Git 签名密钥。GitHub 还区分 **Authentication keys** 和 **Signing keys**：只登记为签名用途的密钥不能用于 Git 认证。同一公钥若要承担两种用途，需要分别登记，也可以使用不同密钥。见 GitHub 的[密钥登记说明](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)。

登录时使用 `--git-protocol ssh --skip-ssh-key`，保持现有策略并跳过生成、上传密钥的提示。已有密钥继续由 agent 管理。这些参数不替代浏览器授权，也不替代 GHCR 所需的令牌。按现有的 [macOS 登录](../../docs/darwin.zh-CN.md#github-cli-登录)或 [GHCR 登录](../docker-ghcr/README.zh-CN.md#认证)流程完成一次认证即可；已有登录只在需要时补充 scope。参数含义见 [gh 登录说明](https://cli.github.com/manual/gh_auth_login)。

## 检查或纠正之前的协议选择

在执行 Git 的机器上，进入已有仓库后检查：

```sh
gh config get git_protocol --host github.com
git remote -v
ssh -T git@github.com
```

[SSH 检查](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)会报告认证成功的 GitHub 用户名；GitHub 不提供 shell，因此成功时也会以状态码 1 退出。这些 Git 检查不是 GHCR 的前置条件，缺少 SSH agent 不妨碍令牌认证。

Home Manager 管理 `~/.config/gh/config.yml`，`gh` 管理 `~/.config/gh/hosts.yml` 中的运行时账号设置及凭据存储。之前的登录可能留下主机级协议设置，覆盖声明的默认值。若第一条命令返回 `https`，可恢复该主机的 SSH 偏好，无需重新登录：

```sh
gh config set git_protocol ssh --host github.com
```

这套 SSH 工作流不需要运行 `gh auth setup-git`。Git 配置由 Nix 管理，持久的 Git credential helper 调整应写入 Nix。
