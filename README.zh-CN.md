<p align="center">
  <img src="Resources/AppIcon-source.png" alt="DeepSeek Harness GUI 图标" width="128" />
</p>

<h1 align="center">DeepSeek Harness GUI for macOS</h1>

<p align="center">
  在 macOS 原生窗口中运行 DeepSeek Harness localhost Web UI 的非官方社区项目。
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>简体中文</strong> ·
  <a href="https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest">下载</a>
</p>

<p align="center">
  <a href="https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest"><img src="https://img.shields.io/github/v/release/CoralFlower325/Deepseek-Harness-GUI?display_name=tag&sort=semver" alt="最新版本" /></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-000000?logo=apple" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Apple%20Silicon-arm64-0a84ff" alt="Apple Silicon arm64" />
  <img src="https://img.shields.io/badge/release-unsigned%20preview-f5a623" alt="未签名预览版" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/CoralFlower325/Deepseek-Harness-GUI" alt="MIT License" /></a>
</p>

> [!WARNING]
> 当前 DMG 是未签名、未公证的社区预览版，macOS 可能阻止首次启动。下载前请阅读
> [安装未签名版本](#安装未签名版本)。本项目与 DeepSeek 或 LobeHub 没有隶属或
> 背书关系。

## 项目简介

DeepSeek Harness GUI 是一个非官方 macOS 原生外壳，用于在 SwiftUI 窗口中运行
DeepSeek Harness 的 localhost Web UI。应用在后台启动 `dsh web`，读取服务就绪
后输出的动态本地地址，再通过 `WKWebView` 加载完整界面。

可下载的 DMG 内置 Node.js 和 npm，但不再固化任何 Harness 版本。首次启动时，
App 优先使用本机已有的 `dsh`；如果没有发现，用户可以定位已有可执行文件，或
确认从 npm 将当前版本安装到 Application Support。

<p align="center">
  <a href="docs/images/app-preview.png">
    <img src="docs/images/app-preview.png" alt="DeepSeek Harness GUI v0.2.1 在 macOS 上运行本机发现的 Harness" width="1100" />
  </a>
  <br />
  <sub>DeepSeek Harness GUI v0.2.1 正在使用本机发现的 Harness；点击图片可查看原始分辨率 PNG。</sub>
</p>

## 主要功能

- 使用 SwiftUI 原生窗口承载完整 Harness Web UI。
- 自动使用动态 localhost 端口，避免固定端口冲突。
- Release DMG 内置 Node.js 和 npm，但不固化 Harness 版本。
- 自动发现常见位置及 `npx` 缓存中的本机 `dsh`，并支持用户手动选择可执行文件。
- 为尚未安装 Harness 的用户提供首次启动安装入口。
- 沿用标准 `~/.dsh`，保留已有 profile、会话、模型设置和 API Key。
- Harness runtime 可以独立于 macOS App 下载更新。
- 新 runtime 只有在输出可加载的 Web URL 后才会启用。
- 保留一个上一版本 runtime，提供可执行版本回退入口。
- 支持选择工作区、重启 Harness、管理 runtime 和查看进程日志。

## 系统要求

当前 `v0.2.1` 二进制版本支持：

- macOS 14 或更高版本
- Apple Silicon（`arm64`）
- 调用模型服务或下载 runtime 更新时需要网络

当前预编译 DMG 不包含 Intel Mac 版本。开发者可以在具有兼容 Swift 和 Node.js
工具链的其他 Mac 上从源码构建。

## 下载与安装

1. 打开[最新 GitHub Release](https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest)。
2. 下载 `Deepseek-Harness-GUI-v0.2.1-arm64.dmg`。
3. 打开 DMG。
4. 将 **DeepSeek Harness.app** 拖入 **Applications（应用程序）**。
5. 启动应用，并根据需要从工具栏选择工作区。

GitHub 自动生成的 **Source code** ZIP/TAR 只是开发源码，不包含内置 Node.js/npm
引擎。普通用户应下载 Release 中的 DMG 附件。

### 安装未签名版本

当前社区预览版没有 Apple Developer ID 签名，也没有经过 Apple 公证。首次启动
时，Gatekeeper 可能提示无法验证开发者。

可以使用 macOS 标准流程：

1. 在 Finder 中按住 Control 点击 **DeepSeek Harness.app**，选择**打开**。
2. 如果仍被阻止，打开**系统设置 → 隐私与安全性**。
3. 找到关于 DeepSeek Harness 的提示，选择**仍要打开**。

只有在你确认 DMG 来自本仓库时才应继续。本项目不会要求用户全局关闭
Gatekeeper。

## 已安装 Harness 与用户数据

应用始终沿用 Harness 的标准用户目录：

```text
~/.dsh/
```

因此，官方 CLI 创建的模型 profile、会话和 API Key 配置会继续生效。Swift 外壳
不会把 `~/.dsh` 复制进 App、源码仓库或 DMG。

自动模式会依次检查用户此前选择的路径、常见 Homebrew/用户级目录、此前通过
`npx @deepseek-ai/dsh` 下载的包，以及 App 继承的 `PATH`，并优先使用发现的本机
`dsh`。如果自动检测漏掉已有安装，可以点击**选择 dsh…**手动定位可执行文件。

如果既没有本机版本，也没有 App 管理版本，首次启动页会提供两种设置路径和一个
独立的重新检测操作：

1. 定位已经安装的 `dsh`；
2. 确认从 npm 下载并安装当前版本。

## Runtime 管理

应用管理的 runtime 和版本状态存放在：

```text
~/Library/Application Support/DeepSeekHarnessMac/
├── runtime-state.json
├── runtime-update.log
└── runtimes/<version>/
```

应用从 npm registry 查询 `@deepseek-ai/dsh`。下载完成的版本先记录为 `pending`；
只有进程输出可用的 `dsh web: http://127.0.0.1:...` 地址后才会成为 `active`，
原 active 版本会成为 `previous`。

本机安装仍由 Homebrew/npm 或用户自行管理，GUI 不会覆盖它。GUI 仍可显示 npm
中的可用版本，并将其下载为独立的 App 管理版本。

可选更新策略：

- 检测到新版后询问（默认）
- 自动下载更新
- 固定当前 runtime

Runtime 回退只切换可执行版本，不保证旧预览版能够读取已被新版修改的数据格式。

## 架构

```text
SwiftUI App
   ├── 自动发现或接受用户选择的本机 dsh
   ├── 否则使用内置 Node.js/npm 安装 @deepseek-ai/dsh
   ├── 运行 dsh web --host 127.0.0.1 --port 0
   ├── 从进程输出读取就绪 URL
   └── 在 WKWebView 中加载 localhost UI

~/.dsh
   └── 官方 Harness 设置、profile、API Key 和会话

~/Library/Application Support/DeepSeekHarnessMac
   └── App 管理的 runtime 版本和更新状态
```

Web 服务只绑定 `127.0.0.1`；本外壳不会将其开放为局域网服务。

## 从源码构建

需要：

- 带有 Swift 6 兼容工具链的 macOS
- Node.js 和 npm
- macOS 自带的 `hdiutil`

准备内置 Node.js/npm 引擎并构建：

```bash
git clone https://github.com/CoralFlower325/Deepseek-Harness-GUI.git
cd Deepseek-Harness-GUI
./scripts/prepare-engine.sh
./scripts/build-app.sh
./scripts/package-dmg.sh
```

输出位于 `dist/`。生成的 Node.js、npm、runtime、App 和 DMG 都已被 Git 忽略。

仓库中的脚本会有意生成未签名 App。需要可信公开分发的维护者，应在自己的发布
环境中增加 Developer ID 签名和 Apple 公证。

## 已知限制

- 当前预编译版本只支持 Apple Silicon。
- 当前版本未签名、未公证。
- 如果没有本机或历史 App 管理版本，首次设置需要访问 npm registry。
- GUI 可以发现和启动本机 Harness，但不会修改或升级该安装。
- Harness 迭代较快；如果 CLI 就绪输出或 Web 行为变化，可能需要更新 App。
- DMG 仍内置 Node.js 和 npm，以便在没有开发环境时安装 Harness。
- App 本体升级与 Harness runtime 升级是两条独立路径。

## 仓库结构

```text
Sources/DeepSeekHarnessMac/   Swift 应用源码
Resources/Info.plist          macOS Bundle 元数据
Resources/AppIcon.icns        macOS 应用图标
Resources/AppIcon-source.png  图标源文件
scripts/prepare-engine.sh     准备内置 Node.js/npm 引擎
scripts/build-app.sh          构建未签名 App Bundle
scripts/package-dmg.sh        生成拖拽安装式 DMG
```

## 参与贡献

欢迎提交可复现的问题报告和范围明确的 Pull Request。贡献前请阅读
[CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)。维护者的未签名版本发布流程见
[docs/RELEASING.md](docs/RELEASING.md)。

报告问题时，请提供 macOS 版本、CPU 架构、App 版本、Harness runtime 版本、
可复现步骤以及必要的日志片段。请勿发布 API Key 或 `~/.dsh` 的内容。

## 来源与许可证

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供 Release
  构建中使用的 CLI 和 Web UI。
- 图标来源由贡献者标注为 [LobeHub](https://github.com/lobehub/lobehub) 生态；
  LobeHub 通过 [Lobe Icons](https://github.com/lobehub/lobe-icons) 提供品牌图标集合。

本仓库原创的 Swift 外壳和构建脚本采用 MIT License。随 Release 捆绑的软件和
图标分别适用其自身许可证及品牌权利。详见 [LICENSE](LICENSE) 和
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
