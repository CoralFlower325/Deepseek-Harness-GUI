# Third-party notices

This repository contains a native macOS wrapper for software and artwork from
other projects. Those projects are not maintained by this repository.

## DeepSeek Harness

Release builds download and bundle `@deepseek-ai/dsh` from npm. DeepSeek
Harness is maintained at:

- https://github.com/deepseek-ai/deepseek-harness

Its package includes its own license and third-party notices. The build scripts
keep the package files inside the generated runtime.

## Node.js and npm

Release builds bundle Node.js and npm so that end users do not need to install
them separately. Their license files remain part of the generated engine and
dependency trees. Generated engine files are intentionally excluded from this
source repository.

## Application icon

`Resources/AppIcon-source.png` was obtained from the LobeHub project ecosystem,
as identified by the contributor:

- https://github.com/lobehub/lobehub
- https://github.com/lobehub/lobe-icons

LobeHub publishes its AI/LLM brand icon collection through Lobe Icons, which is
MIT licensed. The DeepSeek name and logo remain associated with their respective
brand owner. Inclusion of the icon does not imply endorsement of this project by
DeepSeek or LobeHub.
