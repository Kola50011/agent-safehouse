# Changelog

## [Unreleased]

### Upgrade Notes

- No special notes.

### Changed Sandboxing Profiles

- No profiles changed.

## [0.3.1] - 2026-03-12

### Bug Fixes

- Default sanitized execution now preserves common non-secret proxy, TLS, and browser-control environment variables, including `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, lowercase proxy variants, `NODE_EXTRA_CA_CERTS`, and `NO_BROWSER`.
- Tightened Java toolchain sandboxing so system `/Library/Java` runtimes stay read-only while per-user `~/Library/Java` installs remain writable, preventing accidental writes to globally installed JDKs.

### Changed Sandboxing Profiles

- [`profiles/30-toolchains/java.sb`](https://github.com/eugene1g/agent-safehouse/blob/v0.3.1/profiles/30-toolchains/java.sb): Split system and user Java grants so globally installed runtimes are read-only while per-user Java state stays writable.

## [0.3.0] - 2026-03-12

### Features

- New `--enable=xcode` integration: read-only access to Xcode developer roots, app bundles, and Command Line Tools; read/write access to per-user DerivedData, CoreSimulator, XCTestDevices, and CoreDevice state; CoreSimulator and CoreDevice mach service lookups. Enables `xcodebuild`, `simctl`, and `devicectl` under the sandbox.
- `SDKROOT` is now preserved in the default sanitized environment, so Xcode SDK-backed compilation works without `--env`.
- Added `safehouse update [--head]` subcommand for standalone installs to self-update from GitHub release assets or the latest `main` build.

### Bug Fixes

- Node toolchain profile now includes `~/.cache/puppeteer` alongside Playwright and Cypress cache paths.

### Chores

- Bumped NPM docs-site dependencies.
- Refactored live-test denial patterns into shared infrastructure.

### Changed Sandboxing Profiles

- [`profiles/55-integrations-optional/xcode.sb`](https://github.com/eugene1g/agent-safehouse/blob/v0.3.0/profiles/55-integrations-optional/xcode.sb): New profile granting Xcode developer roots plus scoped per-user build and simulator state.
- [`profiles/30-toolchains/node.sb`](https://github.com/eugene1g/agent-safehouse/blob/v0.3.0/profiles/30-toolchains/node.sb): Added Puppeteer cache path (`~/.cache/puppeteer`).

## [0.1.0] - 2026-03-11

### Upgrade Notes

- First tagged release.
