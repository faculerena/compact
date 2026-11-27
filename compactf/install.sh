#!/usr/bin/env bash
# Install compactf: the Compact compiler with faster compilation and key generation.
#
#   curl -fsSL https://raw.githubusercontent.com/faculerena/compact/compactf-0.36.1/compactf/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --version 0.35.0
#
# Options:
#   --version VERSION   compiler version to install (default: see DEFAULT_VERSION)
#   --bin-dir DIR       where the `compactf` command goes (default: ~/.local/bin)
#   --force             replace a `compactf` in the bin dir that this script did not install
#   --uninstall         remove compactf (all versions and the command)
#
# Environment: COMPACTF_HOME (default ~/.compactf), COMPACTF_REPO (default faculerena/compact).
#
# Each version is a stock Compact release plus the compactf speed changes. Its output,
# keys included, is the same as stock's apart from the compiler-commit field. The files
# go in $COMPACTF_HOME/versions/<version>/<target>/ with the same layout as a stock
# release in ~/.compact/versions; the stock `compact` tool is not touched.

set -euo pipefail

DEFAULT_VERSION="0.36.1"
REPO="${COMPACTF_REPO:-faculerena/compact}"
COMPACTF_HOME="${COMPACTF_HOME:-$HOME/.compactf}"
BIN_DIR="$HOME/.local/bin"
VERSION=""
FORCE=""
UNINSTALL=""
MARKER="# compactf launcher, written by compactf/install.sh"

say() { printf 'compactf: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || die "--version needs a value"; VERSION="$2"; shift 2 ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    --bin-dir) [ $# -ge 2 ] || die "--bin-dir needs a value"; BIN_DIR="$2"; shift 2 ;;
    --bin-dir=*) BIN_DIR="${1#*=}"; shift ;;
    --force) FORCE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)
      echo "usage: install.sh [--version VERSION] [--bin-dir DIR] [--force] [--uninstall]"
      echo "  default version $DEFAULT_VERSION, bin dir ~/.local/bin, files in \$COMPACTF_HOME (~/.compactf)"
      exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
VERSION="${VERSION#v}"
VERSION="${VERSION:-$DEFAULT_VERSION}"
LAUNCHER="$BIN_DIR/compactf"

is_ours() { [ -f "$1" ] && grep -qF "$MARKER" "$1"; }

if [ -n "$UNINSTALL" ]; then
  if is_ours "$LAUNCHER"; then rm -f "$LAUNCHER"; say "removed $LAUNCHER"; fi
  if [ -d "$COMPACTF_HOME" ]; then rm -rf "$COMPACTF_HOME"; say "removed $COMPACTF_HOME"; fi
  exit 0
fi

case "$(uname -s)/$(uname -m)" in
  Linux/x86_64|Linux/amd64) TARGET=x86_64-unknown-linux-musl ;;
  Linux/aarch64|Linux/arm64) TARGET=aarch64-unknown-linux-musl ;;
  Darwin/arm64|Darwin/aarch64) TARGET=aarch64-darwin ;;
  Darwin/x86_64) TARGET=x86_64-darwin ;;
  *) die "no compactf build for $(uname -s) $(uname -m); builds exist for Linux and macOS on x86_64 and arm64" ;;
esac

if command -v curl > /dev/null; then
  fetch() { curl --proto '=https' --tlsv1.2 -fsSL --retry 3 -o "$2" "$1"; }
elif command -v wget > /dev/null; then
  fetch() { wget -q -O "$2" "$1"; }
else
  die "needs curl or wget"
fi
if command -v sha256sum > /dev/null; then
  sha256() { sha256sum "$1" | awk '{ print $1 }'; }
elif command -v shasum > /dev/null; then
  sha256() { shasum -a 256 "$1" | awk '{ print $1 }'; }
else
  die "needs sha256sum or shasum"
fi
command -v tar > /dev/null || die "needs tar"

if [ -e "$LAUNCHER" ] && ! is_ours "$LAUNCHER" && [ -z "$FORCE" ]; then
  die "$LAUNCHER exists and was not installed by this script; pass --force to replace it, or --bin-dir to put compactf elsewhere"
fi

ASSET="compactf-$VERSION-$TARGET.tar.gz"
URL="https://github.com/$REPO/releases/download/fast-$VERSION/$ASSET"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "downloading compactf $VERSION for $TARGET"
fetch "$URL" "$TMP/$ASSET" || die "could not download $URL (is $VERSION a compactf release? see https://github.com/$REPO/releases)"
fetch "$URL.sha256" "$TMP/$ASSET.sha256" || die "could not download $URL.sha256"
want="$(awk '{ print $1; exit }' "$TMP/$ASSET.sha256")"
got="$(sha256 "$TMP/$ASSET")"
[ -n "$want" ] && [ "$want" = "$got" ] || die "checksum mismatch for $ASSET: expected $want, got $got"

DEST="$COMPACTF_HOME/versions/$VERSION/$TARGET"
mkdir -p "$TMP/x"
tar -xzf "$TMP/$ASSET" -C "$TMP/x"
for f in compactc compactc.bin zkir-v3; do
  [ -f "$TMP/x/$f" ] || die "$ASSET has no $f"
done
chmod +x "$TMP/x"/*
"$TMP/x/compactc" --version > /dev/null 2>&1 || die "the downloaded compiler does not run on this machine"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv "$TMP/x" "$DEST"
printf '%s\n' "$VERSION" > "$COMPACTF_HOME/default"

mkdir -p "$BIN_DIR"
cat > "$TMP/compactf" <<'LAUNCHER_EOF'
#!/usr/bin/env bash
# compactf launcher, written by compactf/install.sh
#
#   compactf [compile] [+VERSION] <compactc arguments>   run the compiler (like `compact compile`)
#   compactf format [+VERSION] <format-compact arguments>
#   compactf fixup  [+VERSION] <fixup-compact arguments>
#   compactf list                 installed versions; * marks the default
#   compactf default VERSION      make VERSION the default
#   compactf update [VERSION]     install VERSION (default: the installer's default)
#   compactf uninstall            remove compactf
#
# Keys need the public parameters, which zkir-v3 downloads on first use to
# ~/.cache/midnight/zk-params (or $MIDNIGHT_PP), as with stock compact.
set -euo pipefail
COMPACTF_HOME="${COMPACTF_HOME:-$HOME/.compactf}"
REPO="${COMPACTF_REPO:-faculerena/compact}"
INSTALLER="https://raw.githubusercontent.com/$REPO/compactf-0.36.1/compactf/install.sh"
case "$(uname -s)/$(uname -m)" in
  Linux/x86_64|Linux/amd64) TARGET=x86_64-unknown-linux-musl ;;
  Linux/aarch64|Linux/arm64) TARGET=aarch64-unknown-linux-musl ;;
  Darwin/arm64|Darwin/aarch64) TARGET=aarch64-darwin ;;
  Darwin/x86_64) TARGET=x86_64-darwin ;;
  *) echo "compactf: unsupported platform $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

installed() {
  local d
  for d in "$COMPACTF_HOME"/versions/*/"$TARGET"; do
    [ -x "$d/compactc" ] && basename "$(dirname "$d")"
  done
}

run_installer() {
  local self; self="$(cd "$(dirname "$0")" && pwd -P)"
  if command -v curl > /dev/null; then
    curl --proto '=https' --tlsv1.2 -fsSL "$INSTALLER" | bash -s -- --bin-dir "$self" "$@"
  else
    wget -q -O - "$INSTALLER" | bash -s -- --bin-dir "$self" "$@"
  fi
}

case "${1:-}" in
  list)
    def="$(cat "$COMPACTF_HOME/default" 2>/dev/null || true)"
    for v in $(installed); do
      if [ "$v" = "$def" ]; then echo "* $v"; else echo "  $v"; fi
    done
    exit 0 ;;
  default)
    [ $# -eq 2 ] || { echo "usage: compactf default VERSION" >&2; exit 2; }
    v="${2#+}"; v="${v#v}"
    [ -x "$COMPACTF_HOME/versions/$v/$TARGET/compactc" ] || { echo "compactf: $v is not installed (compactf update $v)" >&2; exit 1; }
    printf '%s\n' "$v" > "$COMPACTF_HOME/default"
    exit 0 ;;
  update)
    shift
    if [ $# -ge 1 ]; then run_installer --version "${1#+}"; else run_installer; fi
    exit $? ;;
  uninstall)
    run_installer --uninstall
    exit $? ;;
esac

tool=compactc
case "${1:-}" in
  compile|c) shift ;;
  format|fmt|f) tool=format-compact; shift ;;
  fixup|fix|fx) tool=fixup-compact; shift ;;
esac

v=""
case "${1:-}" in
  +*) v="${1#+}"; v="${v#v}"; shift ;;
esac
[ -n "$v" ] || v="$(cat "$COMPACTF_HOME/default" 2>/dev/null || true)"
[ -n "$v" ] || { echo "compactf: no version installed (compactf update)" >&2; exit 1; }
dir="$COMPACTF_HOME/versions/$v/$TARGET"
[ -x "$dir/compactc" ] || { echo "compactf: version $v is not installed; installed: $(installed | tr '\n' ' ')" >&2; exit 1; }
[ -x "$dir/$tool" ] || { echo "compactf: version $v has no $tool" >&2; exit 1; }
PATH="$dir:$PATH"
exec "$dir/$tool" "$@"
LAUNCHER_EOF
chmod +x "$TMP/compactf"
mv -f "$TMP/compactf" "$LAUNCHER"

say "installed compactf $VERSION in $DEST"
say "command: $LAUNCHER ($("$LAUNCHER" --version 2>/dev/null || echo '?'))"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "note: $BIN_DIR is not on your PATH; add it, e.g. export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
