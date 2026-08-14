# Changelog / 更新日志

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
