#!/bin/sh
# Install Swarm: download an archive, check it against checksums.txt, unpack it to
# <root>/versions/<version>, point <root>/current at it and link swarm onto PATH.
# It installs none of Swarm's requirements; it names what is missing. Rerunning is safe,
# and an older version stays on disk for rolling back (see OPERATIONS.md, "Upgrade").
#
# Repo private (needs `gh auth login`):
#   gh api -H 'Accept: application/vnd.github.raw' repos/scottlarkin/swarm-release/contents/install.sh | sh
# Repo public:
#   curl -fsSL https://raw.githubusercontent.com/scottlarkin/swarm-release/main/install.sh | sh
# Options (after `sh -s --` when piped): --version vX.Y.Z (default: latest release);
#   --file PATH, a local archive, checked when a checksums.txt sits beside it.
# Environment: SWARM_INSTALL_ROOT (default ~/.local/share/swarm); SWARM_INSTALL_BIN, where the swarm
#   link goes (default ~/.local/bin); SWARM_RELEASE_BASE, a URL
#   directory holding the archive and checksums.txt, fetched with curl in place of GitHub (tests).
# POSIX sh only: macOS has bash 3.2 and BSD tar, sed and mktemp.
# Everything is inside main, called on the last line, so a truncated download runs nothing.
main() {
  set -eu
  repo=scottlarkin/swarm-release
  root=${SWARM_INSTALL_ROOT:-$HOME/.local/share/swarm}
  bin=${SWARM_INSTALL_BIN:-$HOME/.local/bin}
  version= file=
  die() { echo "install.sh: $*" >&2; exit 1; }
  sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
  while [ $# -gt 0 ]; do
    case $1 in
      --version) [ $# -gt 1 ] || die "--version needs a value"; version=${2#v}; shift 2 ;;
      --file) [ $# -gt 1 ] || die "--file needs a value"; file=$2; shift 2 ;;
      *) die "unknown option $1; use --version vX.Y.Z or --file PATH" ;;
    esac
  done
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) target=darwin-arm64 ;;
    Linux-x86_64) target=linux-x64
      if [ -e /etc/NIXOS ]; then # the linux-x64 archive has a stub loader there; only a local nixos-x64 build runs
        target=nixos-x64
        [ -n "$file${SWARM_RELEASE_BASE:-}" ] || die "NixOS cannot run the linux-x64 archive: its loader is a stub. Build from source (README, Packaged setup)."
      fi ;;
    *) die "no archive for $(uname -s)-$(uname -m); published: darwin-arm64 and linux-x64" ;;
  esac
  [ ! -e "$bin/swarm" ] || [ -h "$bin/swarm" ] || die "$bin/swarm exists and is not a link; move it aside and rerun"
  mkdir -p "$root/versions" "$bin" && tmp=$(mktemp -d "$root/.install-XXXXXX") && mkdir "$tmp/dl"
  trap 'rm -rf "$tmp"' EXIT; trap 'exit 1' HUP INT TERM
  if [ -n "$file" ]; then
    [ -f "$file" ] || die "no such file: $file"
    archive=$file sums=$(dirname "$file")/checksums.txt
  else
    via=curl base=${SWARM_RELEASE_BASE:-}
    [ -n "$base" ] || ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1 || via=gh
    [ $via = gh ] || command -v curl >/dev/null 2>&1 || die "this needs curl, or gh signed in with \`gh auth login\`; neither is available"
    if [ -z "$version" ]; then # a private repo has no /releases/latest redirect for curl, so gh asks
      [ -z "$base" ] || die "SWARM_RELEASE_BASE needs --version"
      if [ $via = gh ]; then version=$(gh release view --repo "$repo" --json tagName --jq .tagName) || die "gh found no release in $repo; pass --version vX.Y.Z"
      else version=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest" | sed 's#.*/tag/##'); fi
      version=${version#v}
      case $version in "" | latest | */*) die "could not resolve the latest release (a private repo needs \`gh auth login\`); or pass --version vX.Y.Z" ;; esac
    fi
    archive=$tmp/dl/swarm-$version-$target.tar.gz sums=$tmp/dl/checksums.txt
    echo "Downloading swarm $version for $target with $via"
    if [ $via = gh ]; then
      gh release download "v$version" --repo "$repo" --dir "$tmp/dl" --pattern "${archive##*/}" --pattern checksums.txt
    else
      base=${base:-https://github.com/$repo/releases/download/v$version}
      curl -fsSL -o "$archive" "$base/${archive##*/}" && curl -fsSL -o "$sums" "$base/checksums.txt"
    fi || die "download failed. While the repo is private, run \`gh auth login\` first; then rerun."
  fi
  name=${archive##*/}
  if [ -f "$sums" ]; then
    awk -v n="$name" '$2 == n' "$sums" > "$tmp/want"
    [ -s "$tmp/want" ] || die "$sums has no line for $name; not installing"
    (cd "$(dirname "$archive")" && sha -c "$tmp/want" >/dev/null) || die "checksum mismatch for $name; not installing"
    echo "sha256 verified: $name"
  else echo "UNVERIFIED: no checksums.txt beside $archive"; fi
  mkdir "$tmp/x" && tar -xzf "$archive" -C "$tmp/x"
  set -- "$tmp"/x/swarm-*
  [ $# -eq 1 ] && [ -x "$1/bin/swarm" ] || die "unexpected archive layout in $name"
  top=${1##*/}
  case $top in swarm-*-"$target") ;; *) die "$name holds $top, but this host takes swarm-<version>-$target; nothing was changed" ;; esac
  version=${top#swarm-}; version=${version%-*-*} # swarm-<version>-<target>
  if [ -e "$root/versions/$version" ]; then echo "$version is already installed; keeping it (remove $root/versions/$version to reinstall)"
  else mv "$1" "$root/versions/$version"; fi
  from=$(readlink "$root/current" 2>/dev/null || true)
  ln -sfn "versions/$version" "$root/current"
  ln -sfn "$root/current/bin/swarm" "$bin/swarm"
  echo "Installed swarm $version: $bin/swarm -> $root/current/bin/swarm"
  moved=
  [ -z "$from" ] || [ "$from" = "versions/$version" ] || { moved=1; echo "current moved from $from to versions/$version. A running daemon is still the old one: run swarm daemon stop, then swarm daemon start."; }
  missing= openssl=
  command -v herdr >/dev/null 2>&1 || missing="$missing
  Herdr: not on PATH (https://herdr.dev)"
  command -v claude >/dev/null 2>&1 || command -v codex >/dev/null 2>&1 || missing="$missing
  a native agent CLI: neither claude nor codex is on PATH"
  command -v ps >/dev/null 2>&1 || missing="$missing
  ps (procps): not on PATH; the daemon uses it to identify agent processes"
  { command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; } || missing="$missing
  Docker with the compose plugin: not usable here"
  for f in /usr/lib*/libcrypto.so.3 /usr/lib/*/libcrypto.so.3; do [ ! -e "$f" ] || openssl=1; done
  case $target in
    linux-x64) [ -n "$openssl" ] || missing="$missing
  OpenSSL 3 (libcrypto.so.3): not found under /usr/lib" ;;
    darwin-arm64) macos=$(sw_vers -productVersion 2>/dev/null || true) # its Erlang is built for 15, with OpenSSL inside it
      case ${macos%%.*} in
        '' | *[!0-9]*) missing="$missing
  macOS 15 or later: could not read this Mac's version" ;;
        *) [ "${macos%%.*}" -ge 15 ] || missing="$missing
  macOS 15 or later: this is macOS $macos" ;;
      esac ;;
  esac
  [ -z "$missing" ] || echo "Missing, and not installed by this script:$missing"
  case ":$PATH:" in *":$bin:"*) cmd=swarm ;; *) cmd=$bin/swarm; echo "$bin is not on PATH; add it, or use the full path." ;; esac
  [ -n "$moved" ] || echo "Next: run herdr, then run $cmd init in the shell it opens."
}
main "$@"
