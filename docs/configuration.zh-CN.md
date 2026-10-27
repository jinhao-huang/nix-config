# 配置参考

[English](configuration.md) | [中文首页](../README.zh-CN.md)

本参考覆盖主机清单、Pi 启动默认值，以及本仓库提供的全部 sing-box、DeepSeek Harness、GHCR 认证和 Tailscale 选项。英文模块选项条目由 Nix 声明生成，包含类型、默认值、示例与源文件链接；本中文版本按[同步规则](development.zh-CN.md#documentation-sync)手工维护。

选项默认值描述模块本身，具体机器的实际值由 profile 和主机清单提供。没有默认值的选项，在启用对应功能时必须提供。

<a id="pi-startup-defaults"></a>

## Pi 启动默认值

在 [hosts/darwin.nix](../hosts/darwin.nix) 或 [hosts/linux.nix](../hosts/linux.nix) 中设置 `pi.model = { provider = "provider-id"; id = "model-id"; };` 和 `pi.thinkingLevel`。省略时使用 Pi 默认值，可接受的值见 [schema](../modules/pi/startup-defaults-type.nix)。

部署命令会在缺少时创建被 Git 忽略的 `hosts/inventory.local.nix`，保留已有文件，并在每次构建与切换时加载。Pi 覆盖示例为 `{ laptop.pi.thinkingLevel = "high"; }`。

省略字段表示继承，`null` 清除默认值，`model` 会同时替换 provider 和 ID。重新构建并切换后生效，Pi 全局设置保持只读。两个清单都不能存放凭据：被 Git 忽略的覆盖值也会进入 Nix store。

两个平台的主机条目都可包含 `hermes` 覆盖配置，见 [Hermes 本地覆盖](../modules/hermes/README.zh-CN.md#local-overrides)。其他覆盖字段会被拒绝。

直接运行 Nix 或 rebuild 命令时默认使用已跟踪的值；如需加载本地覆盖，必须传入 `--override-input host-local "path:$PWD/hosts/inventory.local.nix"`。

## Darwin 主机字段

编辑 [hosts/darwin.nix](../hosts/darwin.nix)，每个顶层属性名对应一个 `darwinConfigurations` 条目。每台主机的字段如下：

| 主机字段 | 用途或对应模块选项 |
| --- | --- |
| `system` | 软件包架构，例如 `aarch64-darwin`。 |
| `username` | 由 nix-darwin 和 Home Manager 管理的主要用户账号。 |
| `homeDirectory` | 主要用户的绝对 home 目录路径。 |
| `authorizedKeyFiles` | 公钥文件路径，传给 nix-darwin 的 `users.users.<name>.openssh.authorizedKeys.keyFiles`。 |
| `homebrew.casks` | 添加到 [Homebrew profile](../profiles/system/darwin/homebrew.nix) 共享应用列表的主机专属 cask；没有时使用 `[]`。 |
| `pi` | 可选 Pi 启动默认值，传给 `modules.pi.defaults`；见 [schema](../modules/pi/startup-defaults-type.nix)。 |
| `hermes` | 传给官方 `services.hermes-agent` 的属性集，两台 Mac 默认关闭。见 [Hermes 配置](../modules/hermes/README.zh-CN.md)。 |

## Linux 主机字段

编辑 [hosts/linux.nix](../hosts/linux.nix)，每个顶层属性名对应一个 `homeConfigurations` 条目。每台主机的字段如下：

| 主机字段 | 用途或对应模块选项 |
| --- | --- |
| `system` | 软件包架构，例如 `x86_64-linux` 或 `aarch64-linux`。 |
| `username` | `home.username`。 |
| `homeDirectory` | 绝对路径 `home.homeDirectory`。 |
| `authorizedKeyFiles` | 公钥文件路径，内容合并到 Home Manager 管理的 `~/.ssh/authorized_keys`。 |
| `pi` | 可选 Pi 启动默认值，传给 `modules.pi.defaults`；见 [schema](../modules/pi/startup-defaults-type.nix)。 |
| `deepseekHarness.publicHost` | `modules.deepseek-harness.service.publicHost`，使用节点实际的 MagicDNS 主机名。 |
| `dockerGhcr` | 可选属性集，传给 `modules.docker-ghcr`；通过指定的 GitHub CLI 账号认证 GHCR。见[安装与登录](../modules/docker-ghcr/README.zh-CN.md)。 |
| `deepseekHarness.port` | `modules.deepseek-harness.service.port`。 |
| `deepseekHarness.proxyPort` | `modules.deepseek-harness.service.proxyPort`。 |
| `deepseekHarness.httpsPort` | `modules.tailscale.serve.httpsPort`，Harness 公开端口随之设置。 |
| `singBox` | 传给 `modules.sing-box` 的属性集，提供 `listenPort` 和至少一个节点来源。 |
| `hermes` | 传给官方 `services.hermes-agent` 的属性集，包含模型、状态路径、私有环境文件路径和消息平台设置。 |

例如，主机中可以包含：

```nix
deepseekHarness = {
  port = 3080;
  proxyPort = 3081;
  httpsPort = 8443;
};
singBox = {
  listenPort = 21009;
  subscription.requestFile = "/home/alice/.config/sing-box/subscription.curl";
  routing.directDomainSuffixes = [ "internal" ];
};
```

下面每个 `modules.sing-box.<option>` 都可以在主机条目中用 `singBox.<option>` 设置，例如 `modules.sing-box.routing.directDomains` 对应 `singBox.routing.directDomains`。未设置时使用模块默认值，除非 profile 提供了值。Linux profile 默认启用 sing-box，可设置 `singBox.enable = false` 在单台主机上关闭。

必须配置 `singBox.subscription.requestFile`、`singBox.nodesFile` 或两者。两项默认均为 `null`，只使用本地输入时不会下载订阅。订阅请求、节点定义和代理凭据保存在私有运行时文件中，主机清单只需存放文件路径。

[Linux profile](../profiles/home/linux.nix) 启用功能并将 Serve 连接到私有 Harness 代理。公开 URL 与可信 authority 根据主机名和 HTTPS 端口派生：443 不写入 URL，其他 HTTPS 端口会写入。sing-box、Harness 后端和 Harness 代理必须使用不同的回环端口。Serve 的 HTTPS 端口属于 tailnet 监听端口，不参与这项回环端口冲突检查。

## 平台与配置范围

在 [SSH 公钥目录表](../modules/ssh/public-keys/default.nix)中登记共享公钥路径。[hosts/default.nix](../hosts/default.nix) 将目录表作为 `sshKeys` 传给两个平台的主机清单。按名称选择公钥，例如 `authorizedKeyFiles = [ sshKeys.personal ];`。

在 [hosts/linux.nix](../hosts/linux.nix) 或 [hosts/darwin.nix](../hosts/darwin.nix) 中为每台主机设置 `authorizedKeyFiles`。Linux 将文件内容合并到受管理的 `~/.ssh/authorized_keys`；Darwin 使用 nix-darwin 原生选项 `users.users.<name>.openssh.authorizedKeys.keyFiles`。空列表表示不通过该受管理来源授权任何密钥。文件只能包含公钥，不能加入私钥。Tailscale SSH 使用独立授权策略。

- sing-box 作为 Linux systemd 用户服务运行。
- GHCR 认证按主机启用，helper 使用主机提供的 Docker daemon 和 Compose。
- Hermes 支持 Linux 用户服务和 macOS launchd agent，两台 Mac 默认关闭。见[配置指南](../modules/hermes/README.zh-CN.md)。
- Harness 策略同时适用于 macOS 和 Linux。macOS 使用官方桌面应用，Web 后端和私有代理是 Linux 用户服务。
- Tailscale 的 `enable`、`incoming.enable` 和 `ssh.enable` 适用于 macOS 和 Linux；`outboundProxy` 与 `serve` 选项适用于 Linux。

共享启用开关和服务连接关系在平台 profile 中修改，软件包选择放在 [flake.nix](../flake.nix)。macOS 的 Tailscale 在[系统 profile](../profiles/system/darwin/default.nix) 中配置，Harness 策略在 [Home Manager profile](../profiles/home/darwin.nix) 中配置。

## 维护本参考

英文选项条目由 Nix 声明生成，引言来自 [configuration-intro.md](configuration-intro.md)。修改任一来源后，遵循[生成与验证流程](development.zh-CN.md#generated-reference)，再同步本页引言和全部受影响的选项条目。类型保留英文生成值，以便与英文参考逐项核对；默认值、示例和声明来源也与英文对应。

## 选项索引

- [`modules.deepseek-harness.enable`](#modulesdeepseek-harnessenable)
- [`modules.deepseek-harness.package`](#modulesdeepseek-harnesspackage)
- [`modules.deepseek-harness.service.enable`](#modulesdeepseek-harnessserviceenable)
- [`modules.deepseek-harness.service.port`](#modulesdeepseek-harnessserviceport)
- [`modules.deepseek-harness.service.proxyPort`](#modulesdeepseek-harnessserviceproxyport)
- [`modules.deepseek-harness.service.publicHost`](#modulesdeepseek-harnessservicepublichost)
- [`modules.deepseek-harness.service.publicPort`](#modulesdeepseek-harnessservicepublicport)
- [`modules.docker-ghcr.enable`](#modulesdocker-ghcrenable)
- [`modules.docker-ghcr.githubUser`](#modulesdocker-ghcrgithubuser)
- [`modules.sing-box.enable`](#modulessing-boxenable)
- [`modules.sing-box.listenPort`](#modulessing-boxlistenport)
- [`modules.sing-box.nodesFile`](#modulessing-boxnodesfile)
- [`modules.sing-box.package`](#modulessing-boxpackage)
- [`modules.sing-box.proxyCredentialsFile`](#modulessing-boxproxycredentialsfile)
- [`modules.sing-box.routing.directDomainSuffixes`](#modulessing-boxroutingdirectdomainsuffixes)
- [`modules.sing-box.routing.directDomains`](#modulessing-boxroutingdirectdomains)
- [`modules.sing-box.routing.directIpCidrs`](#modulessing-boxroutingdirectipcidrs)
- [`modules.sing-box.routing.proxyDomainSuffixes`](#modulessing-boxroutingproxydomainsuffixes)
- [`modules.sing-box.subscription.requestFile`](#modulessing-boxsubscriptionrequestfile)
- [`modules.tailscale.enable`](#modulestailscaleenable)
- [`modules.tailscale.incoming.enable`](#modulestailscaleincomingenable)
- [`modules.tailscale.outboundProxy.enable`](#modulestailscaleoutboundproxyenable)
- [`modules.tailscale.package`](#modulestailscalepackage)
- [`modules.tailscale.serve.enable`](#modulestailscaleserveenable)
- [`modules.tailscale.serve.httpsPort`](#modulestailscaleservehttpsport)
- [`modules.tailscale.serve.target`](#modulestailscaleservetarget)
- [`modules.tailscale.ssh.enable`](#modulestailscalesshenable)

## 模块选项

## modules\.deepseek-harness\.enable

是否启用 DeepSeek Harness 策略。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.package

DeepSeek Harness CLI 软件包。启用 Linux Web 服务时必须提供，由 flake 选择。macOS 使用官方桌面应用。

*类型：*
package

*示例：*

```nix
llm-agents.packages.${host.system}.dsh
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.service\.enable

是否启用持久运行的 Linux DeepSeek Harness Web 服务。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.service\.port

Harness 后端的回环端口，必须与代理端口不同。

*类型：*
integer between 1 and 65535 (both inclusive)

*默认值：*

```nix
3080
```

*示例：*

```nix
13080
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.service\.proxyPort

供 Tailscale Serve 使用、负责改写 cookie 的代理的回环端口。

*类型：*
integer between 1 and 65535 (both inclusive)

*默认值：*

```nix
3081
```

*示例：*

```nix
13081
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.service\.publicHost

tailnet HTTPS 主机名，不含协议或端口。启用 Web 服务时必须提供，由 Linux 主机清单中的 `deepseekHarness.publicHost` 设置。

*类型：*
string matching the pattern \[a-zA-Z0-9]\[a-zA-Z0-9\.-]\*

*示例：*

```nix
"server.example.ts.net"
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.deepseek-harness\.service\.publicPort

Web 服务对外公布的 HTTPS 端口。Linux profile 从 `modules.tailscale.serve.httpsPort` 派生该值。443 不出现在启动 URL 中；其他端口会同时进入 URL 和可信主机设置。

*类型：*
integer between 1 and 65535 (both inclusive)

*默认值：*

```nix
443
```

*示例：*

```nix
8443
```

*声明来源：*

- [modules/deepseek-harness/default\.nix](../modules/deepseek-harness/default.nix)

## modules\.docker-ghcr\.enable

是否通过 GitHub CLI 为 Docker 启用 GHCR 认证。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/docker-ghcr/default\.nix](../modules/docker-ghcr/default.nix)

## modules\.docker-ghcr\.githubUser

用于访问 ghcr.io 的 GitHub 账号，helper 读取该账号保存在 gh 中的令牌，不受 gh 当前活跃账号影响。需要在运行时以 `read:packages` 权限登录；令牌不会进入生成的 Docker 配置。

*类型：*
string matching the pattern \[A-Za-z0-9]\[A-Za-z0-9-]\*

*示例：*

```nix
"example-user"
```

*声明来源：*

- [modules/docker-ghcr/default\.nix](../modules/docker-ghcr/default.nix)

## modules\.sing-box\.enable

是否启用使用私有代理节点、带认证的本地 HTTP/SOCKS 代理。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.package

使用的 sing-box 软件包。

*类型：*
package

*默认值：*

```nix
pkgs.sing-box
```

*示例：*

```nix
pkgs.sing-box
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.listenPort

固定的回环 HTTP/SOCKS 端口，启用时必须提供。端口必须介于 1024 与 65535 之间，端口冲突会中止激活。Linux profile 还检查它是否与 Harness 后端及代理冲突。下列类型表示基础 Nix 类型，1024 下限由额外校验约束。

*类型：*
16 bit unsigned integer; between 0 and 65535 (both inclusive)

*示例：*

```nix
21009
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.nodesFile

私有运行时原生 sing-box JSON 文件，包含 `outbounds` 数组，最大 8 MiB。仅导入独立代理节点；监听器、路由、DNS 和代理组仍由模块管理。同一来源内的节点 tag 必须唯一，本地和订阅来源使用各自的 tag 命名空间。

修改在下次切换时生效，`null` 禁用本地节点输入。必须配置本选项、`subscription.requestFile` 或两者。路径必须是 Git 与 Nix store 之外的绝对路径。激活只会修复 sing-box 的 XDG 配置和状态目录内的权限；其他位置必须预先满足目录权限 `0700`、文件权限 `0600` 或 `0400`。文件必须归当前用户所有且可读，不能是符号链接，也不能具有多个硬链接。Nix 不会读取文件内容，不支持分享链接。

*类型：*
null or string

*默认值：*

```nix
null
```

*示例：*

```nix
"/home/alice/.config/sing-box/nodes.json"
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.proxyCredentialsFile

私有用户名/密码 JSON 文件，不存在时生成一次。路径必须是 Git 与 Nix store 之外的绝对路径。文件权限为 `0600`，作为运行时状态保存，Nix 不读取其内容。只会修复 sing-box 的 XDG 配置和状态目录内的权限；其他位置的自定义父目录必须已存在，权限为 `0700`。

*类型：*
string

*默认值：*

```nix
"${config.xdg.stateHome}/sing-box/auth.json"
```

*示例：*

```nix
"/home/alice/.local/state/sing-box/lab-auth.json"
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.routing\.directDomainSuffixes

本地域名后缀，不带开头的点，同时加入 `no_proxy`。

*类型：*
list of string

*默认值：*

```nix
[ ]
```

*示例：*

```nix
[
  "internal"
]
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.routing\.directDomains

额外的完整主机名，在本地解析并直连。始终包含 `localhost`。这些名称也会加入登录 shell 和 `with-proxy` 命令的 `no_proxy` 与 `NO_PROXY`。

*类型：*
list of string

*默认值：*

```nix
[ ]
```

*示例：*

```nix
[
  "git.lab.example"
]
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.routing\.directIpCidrs

额外的可直连校园网或局域网网段，使用 CIDR 格式。私有 IP 目标默认已直连。这些规则仅在 sing-box 内生效，不加入 `no_proxy`。

*类型：*
list of string

*默认值：*

```nix
[ ]
```

*示例：*

```nix
[
  "203.0.113.0/24"
]
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.routing\.proxyDomainSuffixes

在检查中国域名集合之前，先经代理节点访问的域名后缀。私有目标，以及显式直连域名、后缀和 CIDR 规则的优先级更高。

*类型：*
list of string

*默认值：*

```nix
[ ]
```

*示例：*

```nix
[
  "proxy.example"
]
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.sing-box\.subscription\.requestFile

私有运行时 curl 配置，包含 HTTPS 订阅 URL 和请求头。响应必须是包含 `outbounds` 数组的原生 sing-box JSON，最大 8 MiB。`null` 禁用订阅下载。必须配置本选项、`nodesFile` 或两者；两种来源加入同一 URLTest 组。

路径必须是 Git 与 Nix store 之外的绝对路径。激活只会修复 sing-box 的 XDG 配置和状态目录内的权限；其他位置必须预先满足目录权限 `0700`、文件权限 `0600` 或 `0400`。文件必须归当前用户所有且可读，不能是符号链接，也不能具有多个硬链接。Nix 不会读取文件内容。

*类型：*
null or string

*默认值：*

```nix
null
```

*示例：*

```nix
"/home/alice/.config/sing-box/lab.curl"
```

*声明来源：*

- [modules/sing-box/default\.nix](../modules/sing-box/default.nix)

## modules\.tailscale\.enable

是否启用用户态 Tailscale daemon。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/tailscale/options\.nix](../modules/tailscale/options.nix)

## modules\.tailscale\.package

使用的 tailscale 软件包。

*类型：*
package

*默认值：*

```nix
pkgs.tailscale
```

*声明来源：*

- [modules/tailscale/options\.nix](../modules/tailscale/options.nix)

## modules\.tailscale\.incoming\.enable

是否允许 tailnet 连接本地服务。用户态网络将普通 TCP/UDP 流量转发到回环地址，必须通过 tailnet 访问规则限制可连接的设备与端口。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/tailscale/options\.nix](../modules/tailscale/options.nix)

## modules\.tailscale\.outboundProxy\.enable

是否在 `127.0.0.1:1055` 启用本地 SOCKS5 和 HTTP 代理，用于访问 tailnet。仅在 Linux 可用，不会选择 exit node。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)

## modules\.tailscale\.serve\.enable

是否在 Linux 启用仅限 tailnet 的 HTTPS 反向代理。要求启用 `incoming.enable`、MagicDNS 和 tailnet HTTPS 证书，并允许访问所选 HTTPS 端口。启用 Serve 会解锁原生 daemon 偏好，让前台 CLI 管理映射；daemon 启动时，Nix 会重新应用偏好。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)

## modules\.tailscale\.serve\.httpsPort

Tailscale Serve 使用的 tailnet HTTPS 端口。

*类型：*
integer between 1 and 65535 (both inclusive)

*默认值：*

```nix
443
```

*示例：*

```nix
8443
```

*声明来源：*

- [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)

## modules\.tailscale\.serve\.target

回环 HTTP 后端，启用 Serve 时必须提供。Linux profile 根据 Harness 代理端口派生该 URL。映射仅在 systemd 服务存活期间存在，不启用 Funnel。

*类型：*
string matching the pattern http://127\[\.]0\[\.]0\[\.]1:\[0-9]+

*示例：*

```nix
"http://127.0.0.1:3081"
```

*声明来源：*

- [modules/tailscale/home-manager\.nix](../modules/tailscale/home-manager.nix)

## modules\.tailscale\.ssh\.enable

是否启用 Tailscale SSH。要求启用 `incoming.enable`，并在 tailnet 规则中允许 TCP 22 和以本地账号登录的 SSH 访问。

*类型：*
boolean

*默认值：*

```nix
false
```

*示例：*

```nix
true
```

*声明来源：*

- [modules/tailscale/options\.nix](../modules/tailscale/options.nix)
