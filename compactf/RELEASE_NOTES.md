compactf @VERSION@: the Compact compiler @VERSION@ with faster compilation and key generation.

It is stock compactc @VERSION@ plus the compactf changes (commit `@COMMIT@`). Its output, the proving and verifying keys included, is the same as stock's apart from the `compiler-commit` field in `compiler/*.json`. CI checks this against the stock release on each target.

- Witness-disclosure analysis runs in two stages: a quick pass that stops at the first leak, and the full pass only to report one.
- Proving keys are generated in parallel, one `zkir-v3` process per circuit (`--zk-jobs N` or `COMPACT_ZK_JOBS`; by default it follows processors and memory).
- `zkir-v3` is midnight-zkir 3.2.1 with faster key generation ([faculerena/midnight-zkir@0be067e](https://github.com/faculerena/midnight-zkir/tree/compactf)). It writes the same key bytes as stock.
- Large manifests are hashed in parallel.

## Install

```sh
curl -fsSL https://github.com/faculerena/compact/releases/download/fast-@VERSION@/install.sh | bash -s -- --version @VERSION@
```

This installs `compactf` in `~/.local/bin` and the compiler in `~/.compactf/versions/@VERSION@/`. Your stock `compact` / `~/.compact` is left alone.

```sh
compactf compile src/contract.compact managed/contract   # same arguments as `compact compile`
compactf src/contract.compact managed/contract           # same, as with compactc
compactf --version
compactf list | compactf default VERSION | compactf update [VERSION] | compactf uninstall
```

Generated code targets `@midnight-ntwrk/compact-runtime` as stock @VERSION@ does. The first key generation downloads the public parameters to `~/.cache/midnight/zk-params`, as stock does.

Targets: x86_64 and arm64 Linux (static), x86_64 and arm64 macOS. Each tarball has a `.sha256`, and `SHA256SUMS` lists all of them.
