# Release guide

This project currently publishes unsigned community-preview builds. Do not
describe a release as signed or notarized unless those steps were actually
performed with an Apple Developer ID.

## Prepare a release

1. Choose an app version and update `CFBundleShortVersionString` and
   `CFBundleVersion` in `Resources/Info.plist`.
2. Choose an explicit `@deepseek-ai/dsh` version and update the version shown in
   both README files and `CHANGELOG.md`.
3. Commit and push all source and documentation changes.
4. Prepare the bundled runtime and build the DMG:

```bash
./scripts/prepare-runtime.sh <dsh-version>
./scripts/build-app.sh
./scripts/package-dmg.sh
```

The DMG is written to `dist/Deepseek-Harness-GUI-v<app-version>-<arch>.dmg`.

## Publish with GitHub CLI

Create release notes that clearly state the supported macOS version,
architecture, bundled Harness version, and unsigned/unnotarized status. Then
publish the ignored DMG as a Release asset:

```bash
gh release create v<app-version> \
  dist/Deepseek-Harness-GUI-v<app-version>-<arch>.dmg \
  --target main \
  --title "DeepSeek Harness GUI v<app-version> — Unsigned Community Preview" \
  --notes-file CHANGELOG.md \
  --latest
```

Do not commit the DMG, app bundle, Node.js engine, or seed runtime to Git.
