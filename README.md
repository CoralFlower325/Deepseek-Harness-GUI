# DeepSeek Harness Mac

一个使用 SwiftUI 与 `WKWebView` 构建的非官方 macOS GUI。应用在后台启动
DeepSeek Harness 的 localhost Web 服务，并把完整 Web UI 加载到原生窗口中。

> 本项目是社区制作的非官方外壳，与 DeepSeek 或 LobeHub 没有隶属或背书关系。

## 工作方式

应用使用自己管理的 Node、npm 和 `@deepseek-ai/dsh` runtime：

1. 从 `dsh web --host 127.0.0.1 --port 0` 启动本地服务。
2. 从 Harness 输出中读取实际 localhost URL。
3. 使用 `WKWebView` 加载 Web UI。
4. 从 npm registry 查询并下载新的 Harness 版本。
5. 新版成功输出 Web URL 后才切换为当前版本，并保留上一版本入口。

Harness 只监听 `127.0.0.1`，不会由本项目开放为局域网服务。

## 安装

面向普通用户的 Release DMG 应当包含：

- macOS App
- Node.js 与 npm
- 一个初始版本的 DeepSeek Harness

因此，从 GitHub Releases 下载完整 DMG 的用户不需要预先安装 Node、npm 或
DeepSeek Harness。打开 DMG 后，将 `DeepSeek Harness.app` 拖入
`Applications` 即可。

仓库中的源码不包含生成后的 engine、runtime 或 DMG。开发者从源码构建时需要
先安装 Node.js 和 npm，然后运行：

```bash
./scripts/prepare-runtime.sh 0.1.0-rc.6
./scripts/build-app.sh
./scripts/package-dmg.sh
```

版本参数可以替换为准备发布的明确版本。省略版本参数时，准备脚本会使用 npm
registry 当前的 latest 版本。

## 配置与 API Key

应用沿用 DeepSeek Harness 的默认用户目录：

```text
~/.dsh/
```

因此，用户此前通过 Harness 保存的模型设置、API Key、profile 和会话会继续
生效。`~/.dsh` 不在项目目录中，也不会被构建脚本复制进 App 或 DMG。

不要把自己的 `~/.dsh`、`.env`、更新日志或带个人路径的截图提交到仓库。

## Runtime 更新

应用管理的版本存放在：

```text
~/Library/Application Support/DeepSeekHarnessMac/runtimes/
```

更新流程使用 App 内置 npm 安装明确版本的 `@deepseek-ai/dsh`。安装完成的版本
先标记为 `pending`，成功启动后才成为 `active`；旧版本记录为 `previous`。

更新策略包括：

- 检测到新版后询问用户（默认）
- 自动下载，并在适当的重启时启用
- 固定当前版本

## 已知问题与可能发生的情况

### 不会自动使用系统里已经安装的 `dsh`

当前版本只使用 DMG 内置 runtime 或由 App 下载到 Application Support 的
runtime。即使 `/opt/homebrew/bin`、`/usr/local/bin` 或 npm 全局目录已经存在
`dsh`，App 也不会自动切换过去。

这不影响现有配置：App 仍会复用同一个 `~/.dsh`。未来可以增加“使用系统
Harness”或“选择 dsh 可执行文件”，但 App 管理的 runtime 仍适合作为默认值。

### GitHub 源码包不能代替 Release DMG

GitHub 自动生成的 Source code ZIP/TAR 只包含源码，不包含 Node、npm 或 seed
runtime。普通用户应下载 Releases 页面中的 DMG；源码包面向开发者。

### 未签名或未公证的 App 可能被 Gatekeeper 阻止

本地构建脚本只尝试 ad-hoc 签名。公开分发前应在发布环境中使用 Apple
Developer ID 对 App 签名并提交 Apple 公证。未完成正式签名和公证的构建可能
显示“无法验证开发者”，不应描述为可无提示安装的正式版本。

### npm 安装可能受网络或 registry 状态影响

首次运行完整 Release DMG 不依赖联网下载 Harness，但检查更新和安装新版需要
访问 npm registry。网络不可用时，App 会继续使用已有 runtime。

准备和更新脚本允许 npm 执行依赖包的安装脚本，因为 Harness 的部分依赖包含
需要安装阶段准备的本地组件。如果组织策略禁止 npm 安装脚本，runtime 准备或
更新可能失败，详细输出位于 Runtime 面板显示的更新日志路径。

### Harness 仍处于快速迭代阶段

新版可能改变命令行输出、Web UI 或磁盘数据格式。App 依赖
`dsh web: http://127.0.0.1:...` 这一就绪输出。若上游改变该格式，GUI 会停留在
启动状态或显示退出信息。

“尝试上一版本”只回退可执行 runtime，不保证旧版能够读取已经被新版修改的
用户数据格式。

### 运行环境限制

- 最低系统版本：macOS 14
- Web UI 只在 localhost 上运行
- 工作目录首次默认为用户主目录，可从工具栏重新选择并保存
- App 本体升级和 Harness runtime 升级是两条独立路径

## 项目目录

```text
Sources/DeepSeekHarnessMac/   Swift 源码
Resources/Info.plist          App 元数据
Resources/AppIcon.icns        macOS 图标
Resources/AppIcon-source.png  图标源 PNG
scripts/prepare-runtime.sh    准备 Node、npm 和初始 Harness
scripts/build-app.sh          构建并组装 App Bundle
scripts/package-dmg.sh        生成拖拽式 DMG
```

下列目录均为本机构建产物，不应提交：

```text
.build/
dist/
Resources/engine/
Resources/seed-runtime/
```

## 图标来源

应用图标 PNG 来源由贡献者标注为
[LobeHub](https://github.com/lobehub/lobehub)。LobeHub 的品牌图标集合由
[Lobe Icons](https://github.com/lobehub/lobe-icons) 提供，Lobe Icons 使用 MIT
许可证。具体说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

DeepSeek 名称和标志属于其相应权利人。使用该图标不表示 DeepSeek 或 LobeHub
对本项目的认可或背书。

## 许可证

本仓库编写的 Swift 代码与构建脚本使用 MIT License，见 [LICENSE](LICENSE)。
随 Release 构建下载或捆绑的软件和图标分别适用其自身许可证，见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
