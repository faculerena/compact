compactf @VERSION@: the Compact compiler @VERSION@ with faster compilation and parallel key generation.

It is stock compactc @VERSION@ plus the compactf changes (commit `@COMMIT@`). Its output, the proving and verifying keys included, is the same as stock's apart from the `compiler-commit` field in `compiler/*.json`. CI checks this against the stock release on each target, with both the default zkir (v2) and `--feature-zkir-v3`.

- Witness-disclosure analysis runs in two stages: a quick pass that stops at the first leak, and the full pass only to report one.
- Proving keys are generated in parallel, one `zkir` process per circuit (`--zk-jobs N` or `COMPACT_ZK_JOBS`; by default it follows processors and memory).
- Large manifests are hashed in parallel.
- `zkir` and `zkir-v3` are stock 0.35.0's. The faster zkir-v3 key generation in compactf 0.36.1 is built on zkir 3.2.1 and is not part of this release.

## Install

```sh
curl -fsSL https://github.com/faculerena/compact/releases/download/fast-@VERSION@/install.sh | bash -s -- --version @VERSION@
```

This installs `compactf` in `~/.local/bin` and the compiler in `~/.compactf/versions/@VERSION@/`. Your stock `compact` / `~/.compact` is left alone. With both 0.35.0 and 0.36.1 installed, pick one per call with `compactf compile +0.35.0 ...`, or set the default with `compactf default 0.35.0`.

```sh
compactf compile src/contract.compact managed/contract   # same arguments as `compact compile`
compactf --version
compactf list | compactf default VERSION | compactf update [VERSION] | compactf uninstall
```

Generated code targets `@midnight-ntwrk/compact-runtime` as stock @VERSION@ does.

Targets: x86_64 and arm64 Linux (static), x86_64 and arm64 macOS. Each tarball has a `.sha256`, and `SHA256SUMS` lists all of them.
