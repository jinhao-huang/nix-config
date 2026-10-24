# Hermes

[English](README.md) | [中文首页](../../README.zh-CN.md)

Linux 和 macOS 均使用官方 Home Manager 模块。Nix 管理程序、服务和默认配置；认证状态、会话、记忆、定时任务及本地创建的技能保持可写。

<a id="per-host-configuration"></a>

## 每台主机的配置

在 [hosts/linux.nix](../../hosts/linux.nix) 或 [hosts/darwin.nix](../../hosts/darwin.nix) 中设置 `hermes`，字段对应官方 [`services.hermes-agent` 选项](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup#home-manager-module)。`iscas-r750xa` 启用消息 gateway，`laptop` 和 `desktop` 默认关闭 Hermes 和 gateway。`hermes.enable = true` 安装 CLI 并管理配置；再设置 `hermes.gateway.enable = true`，就会在 Linux 运行 systemd 用户服务，在 macOS 运行 launchd agent。只使用 CLI/TUI 时保持 gateway 关闭。可选 Web 后端默认关闭。

[共享策略](../../profiles/home/hermes.nix) 关闭更新检查、自动借用 Codex／Claude 登录（`auth.adopt_external_logins`）和按需安装依赖（`security.allow_lazy_installs`）。需要额外依赖时，通过 `extraPackages`、`extraDependencyGroups` 或 `extraPythonPackages` 声明。平台 profile 负责环境提示和代理接线。

<a id="local-overrides"></a>

### 本地覆盖

将主机专属值写入被 Git 忽略的 `hosts/inventory.local.nix`，使用[部署命令](../../README.zh-CN.md#构建与激活)加载。Hermes 属性递归合并，标量和列表替换已跟踪的值。例如，在 Mac 上启用 CLI/TUI 时，替换下面的模型示例值：

```nix
{
  laptop.hermes = {
    enable = true;
    gateway.enable = false;
    settings.model = {
      provider = "custom";
      default = "private-model-id";
      base_url = "https://llm.example.internal/v1";
      api_mode = "chat_completions";
    };
    environmentFiles = [ "/Users/jinhaohuang/.config/hermes/secrets.env" ];
  };
}
```

服务器覆盖使用 `iscas-r750xa.hermes`。本地校验要求同时设置 `settings.model.provider` 和 `settings.model.default`；自定义端点还需正确的 `base_url` 和 API 协议。Telegram 需要 `environment.TELEGRAM_ALLOWED_USERS`，值为逗号分隔的数字用户 ID。如果要接收主动消息或 cron 结果，还需设置 `environment.TELEGRAM_HOME_CHANNEL`。

本地 Nix 值仍会进入 Nix store，密钥和令牌应保存在私有运行时文件中。已跟踪的清单不提供模型或允许访问的用户 ID；为已启用的主机切换配置前，先准备这些值。

## 秘密文件与激活

Linux 主机读取 `/home/huangjh/.config/hermes/secrets.env`。创建该文件时，所有者为当前用户，权限使用 `0600` 或 `0400`，父目录使用 `0700`：

```dotenv
OPENAI_API_KEY=replace-on-the-server
TELEGRAM_BOT_TOKEN=replace-on-the-server
```

模型凭据变量应与实际提供商匹配。只使用 CLI 的 Mac 不需要 Telegram token。激活会拒绝缺少模型设置、秘密文件不可读或权限过宽、缺少 Telegram token、用户 ID 无效，以及允许 Telegram 公开访问等情况。构建不需要运行时秘密文件；这些校验也不验证外部认证是否成功。

修改设置或秘密文件后执行 `switch`。激活流程会：

1. 在 Home Manager 写入边界之前校验输入，并在应用状态前再次校验。
2. 创建或修复 Hermes 状态根目录及受管理状态子目录，将权限设为 `0700`。新状态文件使用私有 umask。
3. 替换完整的 `config.yaml`，并以 `0600` 权限原子替换 `.env`。公开值在前，私有文件按顺序追加，后面的值覆盖前面的值。环境声明全部清空时，生成空 `.env`，撤销此前安装的值。
4. 在原生服务安装完成后，为配置或环境变化重启活跃的 systemd 服务或已加载的 launchd agent。配置和环境内容未变时，不额外请求重启；重启失败则保留待处理标记，在下次切换时重试。

软件包和服务定义的变化仍由原生服务管理器处理。只使用 CLI 时没有后台服务需要重启，切换后打开新的 CLI 会话。两个平台的服务管理器均使用 `0077` umask 启动 Hermes。Dry run 不写状态，也不重启服务。状态准备复用上游文档复制、认证初始值和插件处理逻辑；渲染和状态准备依赖上游 `moduleCommon.nix`，更新输入时应检查该接口。回归检查命令：

```sh
nix build --no-link .#checks.aarch64-darwin.hermes-runtime
```

## 配置归属与隔离

受管模式会阻止常规 setup、配置修改、更新和 gateway 安装命令。持久默认值应修改 Nix 后切换。受管标记属于应用约定，并非文件系统权限边界：账号所有者仍可编辑普通文件，切换会恢复受管理的 YAML 和环境值。

每个聊天的 `/model`、`/reasoning` 选择、`hermes auth add/remove`、OAuth token 刷新、记忆、cron 任务和可写技能仍可改变运行状态。切换不会重置这些选择或回滚数据库。上游文档选项采用文件复制，从声明中删除文件条目不会删除旧副本。

终端使用 `local` backend 和真实用户 HOME。工作目录是起始位置，并非沙箱；工具可以按当前用户权限访问其他路径。关闭外部登录借用会阻止自动采用 Codex／Claude 登录，但不限制 shell 读取那些文件。

## 数据路径与移除

| 数据 | Linux 主机 | macOS 启用后 |
| --- | --- | --- |
| 状态根目录（`hermesHome`） | `/home/huangjh/.hermes` | `/Users/jinhaohuang/.hermes` |
| 工作目录（`workingDirectory`） | `/home/huangjh/hermes-workspace` | `/Users/jinhaohuang/hermes-workspace` |
| 秘密源文件（`environmentFiles`） | `/home/huangjh/.config/hermes/secrets.env` | 显式指定的运行时路径；上面的示例使用 `~/.config/hermes/secrets.env` |
| 服务日志 | `hermes-agent`／`hermes-backend` 的用户 journal | `~/Library/Logs/hermes-agent.log`、`hermes-agent.err.log`；启用后端时还有对应的 `hermes-backend` 文件 |

状态根目录包含 `config.yaml`、凭据副本 `.env`、`.managed`、可能产生的 `auth.json` 和 MCP tokens，以及 `state.db`、会话、记忆、cron 任务及输出、技能、插件、缓存和应用日志。`.restart-needed` 是私有的空文件，用于标记待处理的服务重启。路径可以按主机覆盖，删除前应核对实际配置。

设置 `hermes.enable = false` 并切换，会移除受管理的程序和服务。随后确认 gateway、后端和交互进程都已停止。禁用会保留状态、工作文件、秘密源文件和受管标记。永久删除是独立操作：先备份需要保留的内容，再明确删除选定的状态根目录、workspace、专用秘密文件和 macOS 日志文件。旧 Home Manager／nix-darwin generation 会继续引用软件，直到清理 generation 并执行垃圾回收；Linux journal 的保留策略独立管理。

额外功能可能在这些目录之外创建数据，例如 `~/.config/browser-harness` 下的浏览器 harness 数据、临时 socket、`~/.local/bin` 下的自建 profile 启动命令，以及被调用工具写入的文件。这些内容应逐项检查，不能盲目删除共享工具目录。卸载也无法撤销对其他项目的修改，或删除外部服务保存的消息和记录。

平台操作命令见 [Linux 安装](../../docs/linux.zh-CN.md#hermes)或 [macOS 安装](../../docs/darwin.zh-CN.md#hermes)。
