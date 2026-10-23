# Hermes

[English](README.md) | [中文首页](../../README.zh-CN.md)

Linux profile 通过官方 Home Manager 服务模块运行 Hermes。配置和凭据以声明式方式管理，会话与记忆保持可写。

<a id="per-host-configuration"></a>

## 每台主机的配置

在 [hosts/linux.nix](../../hosts/linux.nix) 中设置 `hermes`，字段对应官方 [`services.hermes-agent` 选项](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup#home-manager-module)。设置 `hermes.enable = false` 可在单台主机上禁用。共享默认值位于 [Linux profile](../../profiles/home/linux.nix)。

<a id="local-overrides"></a>

### 本地覆盖

将主机专属值写入被 Git 忽略的 `hosts/inventory.local.nix`。Hermes 属性递归合并，标量和列表替换已跟踪的值。下面以 OpenAI 兼容端点为例，使用前替换示例值：

```nix
{
  iscas-r750xa.hermes = {
    settings.model = {
      provider = "custom";
      default = "private-model-id";
      base_url = "https://llm.example.internal/v1";
      api_mode = "chat_completions";
    };
    environment.TELEGRAM_ALLOWED_USERS = "123456789";
  };
}
```

本地 Nix 值仍会进入 Nix store。密钥和令牌应放入私有文件，使用[部署命令](../../README.zh-CN.md#构建与激活)加载本地覆盖。

## 秘密文件与 Telegram

已跟踪的主机配置启用 Telegram，并读取 `/home/huangjh/.config/hermes/secrets.env`。切换前创建该文件，所有者为当前用户，文件权限为 `0600` 或 `0400`，父目录权限为 `0700`：

```dotenv
OPENAI_API_KEY=replace-on-the-server
TELEGRAM_BOT_TOKEN=replace-on-the-server
```

`TELEGRAM_ALLOWED_USERS` 使用逗号分隔的数字用户 ID。如果要接收主动消息或 cron 结果，还需设置 `environment.TELEGRAM_HOME_CHANNEL`。

激活会拒绝缺少模型设置、秘密文件不可读或权限过宽、缺少 bot token、用户 ID 无效，以及允许 Telegram 公开访问等情况。所需输入必须在切换前存在，但构建时不需要。这些检查不会验证外部服务的认证是否成功。

## 配置归属

修改配置或秘密文件后都要执行 `switch`。激活会替换完整的 `config.yaml`，同步 `.env`，并锁定交互式配置。配置变更应修改 Nix，不运行 setup 或修改配置的交互命令。环境文件在公开值之后按顺序合并，后面的文件覆盖前面的文件。

模块使用上游 `moduleCommon.nix` 渲染完整的原生 `configFile`，因此从 Nix 中删除的设置也会从生成文件中消失。更新输入时应检查该接口。

运行管理与升级见 [Linux 安装与服务](../../docs/linux.zh-CN.md#hermes)。
