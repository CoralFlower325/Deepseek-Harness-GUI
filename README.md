<p align="center">
  <img src="Resources/AppIcon-source.png" alt="DeepSeek Harness GUI icon" width="128" />
</p>

<h1 align="center">DeepSeek Harness GUI for macOS</h1>

<p align="center">
  An unofficial native macOS shell for the localhost Web UI of DeepSeek Harness.
</p>

<p align="center">
  <a href="#english">English</a> · <a href="#简体中文">简体中文</a> ·
  <a href="https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest">Download</a>
</p>

> [!WARNING]
> The current DMG is an unsigned, unnotarized community preview. macOS may block
> its first launch. Read [Installing an unsigned build](#installing-an-unsigned-build)
> before downloading. This project is not affiliated with or endorsed by DeepSeek
> or LobeHub.

---

## English

### Overview

DeepSeek Harness GUI wraps the official DeepSeek Harness localhost Web UI in a
native SwiftUI window. The app starts `dsh web` as a child process, discovers the
dynamic localhost address printed when the service is ready, and loads that URL
in `WKWebView`.

The downloadable DMG contains Node.js, npm, and a seed DeepSeek Harness runtime.
End users therefore do not need to install a command-line runtime before opening
the app.

### Highlights

- Native SwiftUI window with the complete Harness Web UI.
- Dynamic localhost port; no fixed-port conflict.
- Self-contained Release DMG with Node.js, npm, and a seed Harness runtime.
- Existing Harness profiles, sessions, model settings, and API keys remain in
  the standard `~/.dsh` directory.
- Runtime updates are downloaded independently of the macOS app.
- New runtimes become active only after they print a usable Web URL.
- One previous runtime is retained as an executable fallback.
- Selectable workspace, restart control, runtime manager, and process logs.

### Requirements

The current `v0.1.0` binary release supports:

- macOS 14 or later
- Apple Silicon (`arm64`)
- Internet access when calling model providers or downloading runtime updates

Intel Macs are not included in the current prebuilt DMG. The source can be built
on another Mac with a compatible Swift and Node.js toolchain.

### Download and install

1. Open the [latest GitHub Release](https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest).
2. Download `Deepseek-Harness-GUI-v0.1.0-arm64.dmg`.
3. Open the DMG.
4. Drag **DeepSeek Harness.app** into **Applications**.
5. Start the app and choose a workspace from the toolbar when needed.

The GitHub-generated **Source code** ZIP and TAR files are developer sources;
they do not contain Node.js, npm, or the seed Harness runtime. End users should
download the DMG asset instead.

#### Installing an unsigned build

The current community preview has no Apple Developer ID signature and has not
been notarized. Gatekeeper may display an unidentified-developer warning.

Try the standard macOS flow:

1. In Finder, Control-click **DeepSeek Harness.app** and choose **Open**.
2. If macOS still blocks it, open **System Settings → Privacy & Security**.
3. Find the message about DeepSeek Harness and choose **Open Anyway**.

Only continue if you intentionally downloaded the app from this repository.
The project does not ask users to disable Gatekeeper globally.

### Existing installations and user data

The app always uses the standard Harness home directory:

```text
~/.dsh/
```

This preserves settings created by the official CLI, including model profiles,
sessions, and API-key configuration. The Swift wrapper does not copy `~/.dsh`
into the application bundle, repository, or DMG.

The current release does **not** discover or execute a system-installed `dsh`
from Homebrew, `/usr/local/bin`, `/opt/homebrew/bin`, or a global npm directory.
It uses only:

1. the seed runtime embedded in the DMG; or
2. runtimes installed by this app under Application Support.

Existing configuration is reused even though the system executable is not.

### Runtime management

Managed runtimes and version state are stored under:

```text
~/Library/Application Support/DeepSeekHarnessMac/
├── runtime-state.json
├── runtime-update.log
└── runtimes/<version>/
```

The app queries the npm registry for `@deepseek-ai/dsh`. A downloaded version is
first recorded as `pending`; it becomes `active` only after the process prints a
usable `dsh web: http://127.0.0.1:...` address. The former active version becomes
`previous`.

Available update policies:

- Ask before installing an available version (default)
- Download updates automatically
- Pin the current runtime

Runtime rollback only changes the executable version. It cannot guarantee that
an older preview runtime can read data already modified by a newer release.

### Architecture

```text
SwiftUI app
   ├── starts bundled Node.js
   ├── launches @deepseek-ai/dsh web --host 127.0.0.1 --port 0
   ├── reads the ready URL from process output
   └── loads the localhost UI in WKWebView

~/.dsh
   └── official Harness settings, profiles, API keys, and sessions

~/Library/Application Support/DeepSeekHarnessMac
   └── app-managed runtime versions and update state
```

The Web service binds to `127.0.0.1`; this wrapper does not expose it as a LAN
server.

### Build from source

Prerequisites:

- macOS with a Swift 6-compatible toolchain
- Node.js and npm
- `hdiutil`, included with macOS

Build a release with an explicit Harness version:

```bash
git clone https://github.com/CoralFlower325/Deepseek-Harness-GUI.git
cd Deepseek-Harness-GUI
./scripts/prepare-runtime.sh 0.1.0-rc.6
./scripts/build-app.sh
./scripts/package-dmg.sh
```

Outputs are placed in `dist/`. Generated Node.js, npm, runtime, app, and DMG
files are ignored by Git.

The included scripts intentionally produce an unsigned app. A maintainer who
wants a trusted distribution must add Developer ID signing and Apple
notarization in their own release environment.

### Known limitations

- The current prebuilt release is Apple Silicon only.
- The current release is unsigned and unnotarized.
- A system-installed `dsh` executable is not automatically detected.
- Runtime installation and updates require access to the npm registry.
- Harness is evolving quickly; changes to its CLI ready message or Web behavior
  may require an app update.
- The DMG is relatively large because it includes Node.js, npm, Harness, and its
  runtime dependencies.
- App updates and Harness runtime updates are separate processes.

### Repository layout

```text
Sources/DeepSeekHarnessMac/   Swift application source
Resources/Info.plist          macOS bundle metadata
Resources/AppIcon.icns        macOS application icon
Resources/AppIcon-source.png  source artwork used for the icon
scripts/prepare-runtime.sh    prepares Node.js, npm, and seed Harness
scripts/build-app.sh          builds the unsigned app bundle
scripts/package-dmg.sh        creates the drag-to-Applications DMG
```

### Credits and license

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) provides
  the CLI and Web UI embedded by Release builds.
- The application icon was identified by the contributor as coming from the
  [LobeHub](https://github.com/lobehub/lobehub) ecosystem. LobeHub publishes its
  brand icon collection through [Lobe Icons](https://github.com/lobehub/lobe-icons).

The original Swift wrapper and build scripts are available under the MIT
License. Bundled software and artwork retain their own licenses and brand rights.
See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

## 简体中文

### 项目简介

DeepSeek Harness GUI 是一个非官方 macOS 原生外壳，用于在 SwiftUI 窗口中运行
DeepSeek Harness 的 localhost Web UI。应用在后台启动 `dsh web`，读取服务就绪
后输出的动态本地地址，再通过 `WKWebView` 加载完整界面。

可下载的 DMG 内置 Node.js、npm 和一个初始 DeepSeek Harness runtime，因此普通
用户无需提前安装命令行环境即可启动应用。

### 主要功能

- 使用 SwiftUI 原生窗口承载完整 Harness Web UI。
- 自动使用动态 localhost 端口，避免固定端口冲突。
- Release DMG 内置 Node.js、npm 和初始 Harness runtime。
- 沿用标准 `~/.dsh`，保留已有 profile、会话、模型设置和 API Key。
- Harness runtime 可以独立于 macOS App 下载更新。
- 新 runtime 只有在输出可加载的 Web URL 后才会启用。
- 保留一个上一版本 runtime，提供可执行版本回退入口。
- 支持选择工作区、重启 Harness、管理 runtime 和查看进程日志。

### 系统要求

当前 `v0.1.0` 二进制版本支持：

- macOS 14 或更高版本
- Apple Silicon（`arm64`）
- 调用模型服务或下载 runtime 更新时需要网络

当前预编译 DMG 不包含 Intel Mac 版本。开发者可以在具有兼容 Swift 和 Node.js
工具链的其他 Mac 上从源码构建。

### 下载与安装

1. 打开 [最新 GitHub Release](https://github.com/CoralFlower325/Deepseek-Harness-GUI/releases/latest)。
2. 下载 `Deepseek-Harness-GUI-v0.1.0-arm64.dmg`。
3. 打开 DMG。
4. 将 **DeepSeek Harness.app** 拖入 **Applications（应用程序）**。
5. 启动应用，并根据需要从工具栏选择工作区。

GitHub 自动生成的 **Source code** ZIP/TAR 只是开发源码，不包含 Node.js、npm 或
初始 Harness runtime。普通用户应下载 Release 中的 DMG 附件。

#### 安装未签名版本

当前社区预览版没有 Apple Developer ID 签名，也没有经过 Apple 公证。首次启动
时，Gatekeeper 可能提示无法验证开发者。

可以使用 macOS 标准流程：

1. 在 Finder 中按住 Control 点击 **DeepSeek Harness.app**，选择**打开**。
2. 如果仍被阻止，打开**系统设置 → 隐私与安全性**。
3. 找到关于 DeepSeek Harness 的提示，选择**仍要打开**。

只有在你确认 DMG 来自本仓库时才应继续。本项目不会要求用户全局关闭
Gatekeeper。

### 已安装 Harness 与用户数据

应用始终沿用 Harness 的标准用户目录：

```text
~/.dsh/
```

因此，官方 CLI 创建的模型 profile、会话和 API Key 配置会继续生效。Swift 外壳
不会把 `~/.dsh` 复制进 App、源码仓库或 DMG。

当前版本**不会**从 Homebrew、`/usr/local/bin`、`/opt/homebrew/bin` 或 npm 全局
目录中发现并运行系统已有的 `dsh`。它只使用：

1. DMG 内置的 seed runtime；或
2. 本应用安装到 Application Support 的 runtime。

也就是说，已有配置会复用，但系统中的 `dsh` 可执行程序不会被复用。

### Runtime 管理

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

可选更新策略：

- 检测到新版后询问（默认）
- 自动下载更新
- 固定当前 runtime

Runtime 回退只切换可执行版本，不保证旧预览版能够读取已被新版修改的数据格式。

### 架构

```text
SwiftUI App
   ├── 启动内置 Node.js
   ├── 运行 @deepseek-ai/dsh web --host 127.0.0.1 --port 0
   ├── 从进程输出读取就绪 URL
   └── 在 WKWebView 中加载 localhost UI

~/.dsh
   └── 官方 Harness 设置、profile、API Key 和会话

~/Library/Application Support/DeepSeekHarnessMac
   └── App 管理的 runtime 版本和更新状态
```

Web 服务只绑定 `127.0.0.1`；本外壳不会将其开放为局域网服务。

### 从源码构建

需要：

- 带有 Swift 6 兼容工具链的 macOS
- Node.js 和 npm
- macOS 自带的 `hdiutil`

使用明确的 Harness 版本构建：

```bash
git clone https://github.com/CoralFlower325/Deepseek-Harness-GUI.git
cd Deepseek-Harness-GUI
./scripts/prepare-runtime.sh 0.1.0-rc.6
./scripts/build-app.sh
./scripts/package-dmg.sh
```

输出位于 `dist/`。生成的 Node.js、npm、runtime、App 和 DMG 都已被 Git 忽略。

仓库中的脚本会有意生成未签名 App。需要可信公开分发的维护者，应在自己的发布
环境中增加 Developer ID 签名和 Apple 公证。

### 已知限制

- 当前预编译版本只支持 Apple Silicon。
- 当前版本未签名、未公证。
- 不会自动发现系统已安装的 `dsh` 可执行程序。
- 安装和更新 runtime 需要访问 npm registry。
- Harness 迭代较快；如果 CLI 就绪输出或 Web 行为变化，可能需要更新 App。
- DMG 内置 Node.js、npm、Harness 和运行依赖，因此体积较大。
- App 本体升级与 Harness runtime 升级是两条独立路径。

### 仓库结构

```text
Sources/DeepSeekHarnessMac/   Swift 应用源码
Resources/Info.plist          macOS Bundle 元数据
Resources/AppIcon.icns        macOS 应用图标
Resources/AppIcon-source.png  图标源文件
scripts/prepare-runtime.sh    准备 Node.js、npm 和初始 Harness
scripts/build-app.sh          构建未签名 App Bundle
scripts/package-dmg.sh        生成拖拽安装式 DMG
```

### 来源与许可证

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供 Release
  构建中使用的 CLI 和 Web UI。
- 图标来源由贡献者标注为 [LobeHub](https://github.com/lobehub/lobehub) 生态；
  LobeHub 通过 [Lobe Icons](https://github.com/lobehub/lobe-icons) 提供品牌图标集合。

本仓库原创的 Swift 外壳和构建脚本采用 MIT License。随 Release 捆绑的软件和
图标分别适用其自身许可证及品牌权利。详见 [LICENSE](LICENSE) 和
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
