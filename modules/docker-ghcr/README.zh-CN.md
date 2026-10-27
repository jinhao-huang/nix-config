# 通过 GitHub CLI 认证 GHCR

[English](README.md) | [中文首页](../../README.zh-CN.md)

本模块使用 `gh` 的凭据直接从 GHCR 拉取私有镜像。Home Manager 安装 `docker-credential-ghcr`，并在 `~/.docker/config.json` 中声明 `credHelpers."ghcr.io" = "ghcr"`。Docker 和 Compose 仍由主机提供。在 Linux 主机清单中按需启用：

```nix
dockerGhcr = {
  enable = true;
  githubUser = "example-user";
};
```

helper 始终读取 [Linux 主机清单](../../hosts/linux.nix)中 `dockerGhcr.githubUser` 指定的账号，不受 `gh` 当前活跃账号影响。令牌留在 `gh` 的运行时凭据存储中，不复制到 Docker 配置，也不进入 Nix store。选项见[模块参考](../../docs/configuration.zh-CN.md#modulesdocker-ghcrenable)。

其他 Docker 客户端设置通过 `programs.docker-cli.settings` 声明。

## 认证

完成仓库统一的 [Linux 安装与首次激活](../../docs/linux.zh-CN.md#首次激活)后，以受管理的 Linux 用户身份认证一次。将 `example-user` 替换为配置中的 GitHub 账号。如果访问 GitHub 需要受管理的代理，在 `gh` 登录或刷新命令前加 `with-proxy`。

```sh
github_user=example-user
gh auth login --hostname github.com --web --scopes read:packages
gh auth status --hostname github.com
```

在浏览器中完成设备授权，登录配置中指定的账号。该账号必须有目标镜像包的读取权限，后续 shell 和镜像拉取会复用已保存的登录状态。已有登录时，按上例设置 `github_user`，用下面的命令选择账号、补充权限，无需重新登录：

```sh
gh auth switch --hostname github.com --user "$github_user"
gh auth refresh --hostname github.com --scopes read:packages
```

在包含 Compose 文件的项目目录中运行：

```sh
docker compose pull
```

镜像下载使用 Docker daemon 的网络配置，helper 不负责配置其代理。

## 凭据维护

通过 `gh` 登录、重新授权或退出，不对 GHCR 执行 `docker login` 或 `docker logout`。helper 拒绝 `store` 和 `erase` 操作，Docker 配置由 Home Manager 以只读文件管理。若已打开新 shell，先重新设置 `github_user`。移除账号使用：

```sh
gh auth logout --hostname github.com --user "$github_user"
```

缺少令牌时，helper 会提示登录。拉取仍返回 `denied` 时，检查账号、`read:packages`、镜像包的 Read 权限，以及组织是否要求 SSO 授权。执行 Compose 时，应使用登录 `gh` 的同一个受管理 Linux 用户，不使用 sudo。不要手动运行 helper 的 `get` 操作，其输出包含令牌。

协议检查使用假的 `gh`，不会访问真实凭据：

```sh
nix build --no-link .#checks.x86_64-linux.docker-credential-ghcr
```
