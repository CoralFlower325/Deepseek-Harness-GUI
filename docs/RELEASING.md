# Release guide

This project currently publishes unsigned community-preview builds. Do not
describe a release as signed or notarized unless those steps were actually
performed with an Apple Developer ID.

## Prepare a release

1. Choose an app version and update `CFBundleShortVersionString` and
   `CFBundleVersion` in `Resources/Info.plist`.
2. Update both README files and `CHANGELOG.md` for the new app behavior and
   supported environment. Harness is not embedded in the DMG.
3. Commit and push all source and documentation changes.
4. Prepare the bundled Node.js/npm engine and build the DMG:

```bash
./scripts/prepare-engine.sh
./scripts/build-app.sh
./scripts/package-dmg.sh
```

The DMG is written to `dist/Deepseek-Harness-GUI-v<app-version>-<arch>.dmg`.

## Publish with GitHub CLI

Create release notes that clearly state the supported macOS version,
architecture, first-run Harness installation behavior, and unsigned/unnotarized
status. Then publish the ignored DMG as a Release asset:

```bash
gh release create v<app-version> \
  dist/Deepseek-Harness-GUI-v<app-version>-<arch>.dmg \
  --target main \
  --title "DeepSeek Harness GUI v<app-version> — Unsigned Community Preview" \
  --notes-file CHANGELOG.md \
  --latest
```

Do not commit the DMG, app bundle, or Node.js/npm engine to Git.
