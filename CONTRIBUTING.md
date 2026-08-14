# Contributing

Thank you for helping improve DeepSeek Harness GUI. Keep changes focused on the
native macOS shell, runtime management, packaging, or documentation. Changes to
the Harness Web UI itself belong in the upstream
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) repository.

[简体中文](CONTRIBUTING.zh-CN.md)

## Before opening an issue

Search existing issues and confirm whether the behavior comes from this macOS
wrapper or from the upstream Harness Web UI.

A useful bug report includes:

- macOS version and CPU architecture
- app version and Harness runtime version
- a short, reproducible sequence of actions
- expected and actual behavior
- only the relevant process-log lines

Do not include API keys, provider credentials, or the contents of `~/.dsh`.

## Development setup

Requirements:

- macOS with a Swift 6-compatible toolchain
- Node.js and npm

```bash
git clone https://github.com/CoralFlower325/Deepseek-Harness-GUI.git
cd Deepseek-Harness-GUI
./scripts/prepare-engine.sh
swift build
```

To assemble the unsigned app and DMG:

```bash
./scripts/build-app.sh
./scripts/package-dmg.sh
```

Generated files under `.build/`, `dist/`, and `Resources/engine/` must remain
outside Git.

## Pull requests

- Explain the user-visible problem and the chosen fix.
- Keep unrelated formatting or refactoring out of the same change.
- Update both README files when user-facing behavior changes.
- Do not add user configuration, local paths, logs, credentials, or generated
  release binaries.
- State the macOS and architecture used to build the change.

By contributing, you agree that your contribution may be distributed under the
repository's MIT License.
