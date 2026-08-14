# 参与贡献

感谢你帮助改进 DeepSeek Harness GUI。请将修改集中在 macOS 原生外壳、runtime
管理、打包或文档。Harness Web UI 本身的问题应提交到上游
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 仓库。

[English](CONTRIBUTING.md)

## 提交 Issue 前

请先搜索已有 Issue，并判断问题来自本 macOS 外壳还是上游 Harness Web UI。

有效的问题报告应包含：

- macOS 版本和 CPU 架构
- App 版本和 Harness runtime 版本
- 简短、可复现的操作步骤
- 预期行为与实际行为
- 仅与问题相关的进程日志片段

请勿包含 API Key、模型服务凭据或 `~/.dsh` 的内容。

## 开发环境

需要：

- 带有 Swift 6 兼容工具链的 macOS
- Node.js 和 npm

```bash
git clone https://github.com/CoralFlower325/Deepseek-Harness-GUI.git
cd Deepseek-Harness-GUI
./scripts/prepare-runtime.sh 0.1.0-rc.6
swift build
```

组装未签名 App 和 DMG：

```bash
./scripts/build-app.sh
./scripts/package-dmg.sh
```

`.build/`、`dist/`、`Resources/engine/` 和 `Resources/seed-runtime/` 下的生成文件
不得提交到 Git。

## Pull Request

- 说明面向用户的问题以及采用的解决方式。
- 不要在同一个修改中混入无关格式化或重构。
- 用户可见行为变化时，同时更新中英文 README。
- 不要提交用户配置、本机路径、日志、凭据或生成的发布二进制文件。
- 说明构建修改时使用的 macOS 版本和 CPU 架构。

提交贡献即表示你同意该贡献可以按照本仓库 MIT License 发布。
