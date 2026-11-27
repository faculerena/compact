# compactf

compactf is the Compact compiler with faster compilation and key generation. Each
release is a stock compactc release plus the compactf changes. The output, keys
included, matches stock byte for byte except for `compiler-commit` in
`compiler/*.json`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/faculerena/compact/compactf-0.36.1/compactf/install.sh | bash
# a specific version
curl -fsSL https://raw.githubusercontent.com/faculerena/compact/compactf-0.36.1/compactf/install.sh | bash -s -- --version 0.36.1
```

The installer downloads `compactf-<version>-<target>.tar.gz` from the `fast-<version>`
release, checks its sha256, and unpacks it into `~/.compactf/versions/<version>/<target>/`,
the same layout as `~/.compact/versions`. It then writes the `compactf` command to
`~/.local/bin`. Options: `--version`, `--bin-dir DIR`, `--force`, `--uninstall`.
Environment: `COMPACTF_HOME`, `COMPACTF_REPO`.

## Use

```sh
compactf compile [+VERSION] <compactc args>   # like `compact compile`
compactf [+VERSION] <compactc args>           # like compactc
compactf format [+VERSION] <args>             # format-compact
compactf fixup  [+VERSION] <args>             # fixup-compact
compactf list                                 # installed versions; * is the default
compactf default VERSION
compactf update [VERSION]
compactf uninstall
```

Key generation runs one zkir process per circuit in parallel. Set the number of jobs
with `--zk-jobs N` or `COMPACT_ZK_JOBS`. `COMPACT_ZK_JOB_MB` is the memory budgeted
per job when the default number of jobs is chosen. It defaults to 1536 in 0.36.1,
whose fast zkir-v3 needs less memory, and to 5120 in 0.35.0, which uses stock zkir.

## Releases

`.github/workflows/compactf-release.yml` runs on each push to a `compactf-<version>`
branch. It builds `nix build .#compactc-binary` on the four targets, compiles the
examples with keys using both compactf and stock `compactc-v<version>`, and fails if
their output differs. It then uploads the tarballs and `install.sh` to a **draft**
release `fast-<version>`. Publish the draft by hand. The tags are not called
`compactf-v*` because `compact-release.yml` matches tags that start with `compact`.
