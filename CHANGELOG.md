# Changelog / 更新日志

## v0.2.1 — npx discovery and interface refinement / npx 发现与界面优化

### English

- Show the GUI version in the window toolbar.
- Discover Harness packages previously downloaded through
  `npx @deepseek-ai/dsh`, in addition to global `dsh` installations.
- Reorganize the toolbar so workspace, app identity, runtime status, restart,
  and logs have distinct roles without duplicated titles.
- Replace the sparse first-run screen with clear choices for an existing local
  installation or a GUI-managed npm installation.

> This release is unsigned and unnotarized. macOS Gatekeeper may block the first
> launch. Use Finder's **Open** action or **System Settings → Privacy & Security →
> Open Anyway** if you intentionally downloaded the DMG from this repository.

### 简体中文

- 在窗口顶部工具栏显示 GUI 版本。
- 除全局 `dsh` 安装外，自动发现此前通过 `npx @deepseek-ai/dsh` 下载的 Harness。
- 重新组织顶部工具栏，清晰区分工作区、App 标识、Runtime 状态、重启和日志，
  不再重复显示标题。
- 重构首次设置页，明确区分使用本机已有安装与由 GUI 从 npm 安装两种路径。

> 此版本未签名、未公证，macOS Gatekeeper 可能阻止首次启动。如果你确认 DMG
> 来自本仓库，可以使用 Finder 的**打开**操作，或前往**系统设置 → 隐私与安全性
> → 仍要打开**。

## v0.2.0 — Local-first runtime setup / 本机优先 Runtime 设置

### English

- Removed the fixed Harness seed runtime from the DMG.
- Added automatic discovery for common local `dsh` installation paths.
- Added a file picker for users whose existing Harness is not found automatically.
- Added a first-run choice to install the current Harness release from npm when
  no local or managed runtime exists.
- Kept App-managed updates with `pending`, `active`, and `previous` runtime states.
- Local Harness installations remain externally managed and are never overwritten
  by the GUI.
- Added runtime-source selection and source/path/version details to the Runtime panel.
- The DMG continues to include Node.js and npm so first-run installation does not
  require a separate developer environment.
- Current DMG targets Apple Silicon (`arm64`) and requires macOS 14 or later.

> This release is unsigned and unnotarized. macOS Gatekeeper may block the first
> launch. Use Finder's **Open** action or **System Settings → Privacy & Security →
> Open Anyway** if you intentionally downloaded the DMG from this repository.

### 简体中文

- 从 DMG 中移除了固定的 Harness seed runtime。
- 增加常见本机 `dsh` 安装路径的自动发现。
- 自动检测遗漏已有 Harness 时，可以通过文件选择器定位 `dsh`。
- 本机和 App 管理目录都没有 runtime 时，首次启动页会询问是否从 npm 安装当前版本。
- 保留 App 管理版本的 `pending`、`active` 和 `previous` 更新状态。
- 本机 Harness 始终由外部包管理器或用户管理，GUI 不会覆盖它。
- Runtime 面板新增来源选择以及来源、路径和版本信息。
- DMG 继续内置 Node.js 和 npm，因此首次安装 Harness 不要求用户配置开发环境。
- 当前 DMG 面向 Apple Silicon（`arm64`），要求 macOS 14 或更高版本。

> 此版本未签名、未公证，macOS Gatekeeper 可能阻止首次启动。如果你确认 DMG
> 来自本仓库，可以使用 Finder 的**打开**操作，或前往**系统设置 → 隐私与安全性
> → 仍要打开**。

## v0.1.0 — Initial community preview / 首个社区预览版

### English

- Native SwiftUI and WKWebView shell for the DeepSeek Harness localhost Web UI.
- Bundles Node.js, npm, and `@deepseek-ai/dsh` `0.1.0-rc.6`.
- Reuses existing Harness configuration in `~/.dsh` without copying it into the
  app or DMG.
- Supports managed runtime updates, pending activation, and one previous runtime
  fallback.
- Includes workspace selection, restart control, runtime management, and logs.
- Current DMG targets Apple Silicon (`arm64`) and requires macOS 14 or later.

> This release is unsigned and unnotarized. macOS Gatekeeper may block the first
> launch. Use Finder's **Open** action or **System Settings → Privacy & Security →
> Open Anyway** if you intentionally downloaded the DMG from this repository.

### 简体中文

- 使用 SwiftUI 与 WKWebView 封装 DeepSeek Harness localhost Web UI。
- 内置 Node.js、npm 和 `@deepseek-ai/dsh` `0.1.0-rc.6`。
- 沿用 `~/.dsh` 中已有的 Harness 配置，不会将其复制进 App 或 DMG。
- 支持 runtime 更新、pending 启用流程和一个上一版本回退入口。
- 支持选择工作区、重启 Harness、管理 runtime 和查看日志。
- 当前 DMG 面向 Apple Silicon（`arm64`），要求 macOS 14 或更高版本。

> 此版本未签名、未公证，macOS Gatekeeper 可能阻止首次启动。如果你确认 DMG
> 来自本仓库，可以使用 Finder 的**打开**操作，或前往**系统设置 → 隐私与安全性
> → 仍要打开**。
