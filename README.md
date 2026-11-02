# Swarm

Swarm coordinates native coding agents (Claude Code, Codex) through a manager, a dynamic roster and a task graph.
A durable daemon keeps the state; a terminal client shows live swarms and gives direct access to each agent's
[Herdr](https://herdr.dev) terminal. Several swarms can work in parallel. Agents decide how to delegate, use
worktrees, integrate results and clean up; a deliverable can be a PR, a branch, files or text.

Closed-source software. See [LICENSE](LICENSE).

> **Early software.** Expect rough edges. **The Mac archive has been run on one Mac, by its owner: v0.1.2 on macOS
> 26.6.2.** Nothing else has run it on a Mac. Read "About the Mac archive" below for what was
> and was not shown.

## Platforms

| Platform | Archive | Status |
| --- | --- | --- |
| Linux x86_64, glibc | `swarm-<version>-linux-x64.tar.gz` | Built in a Debian 12 container (glibc 2.36). The highest glibc symbol its binaries need is 2.34, by a scan of the binaries. A generic Linux archive of an earlier build has been run in Debian 13 and Ubuntu 24.04 containers. Other glibc distributions of that age or newer are expected to work, and have not been run. Needs OpenSSL 3 on the host. |
| macOS on Apple Silicon | `swarm-<version>-darwin-arm64.tar.gz` | **Run on one Mac, by its owner.** Built on Linux against a prebuilt macOS Erlang runtime. Its owner ran v0.1.2 on macOS 26.6.2 (M4 Pro); see "About the Mac archive". Other macOS versions and chips are untried. |

Not published: Intel Macs, Windows, Linux on ARM, and NixOS (the generic Linux archive cannot start there).

## What you need first

Swarm installs none of these; `install.sh` names whichever is missing.

- [Herdr](https://herdr.dev) on your `PATH`. Swarm drives agents through its panes.
- A native agent CLI that is installed and signed in: `claude` or `codex`.
- Docker with the compose plugin. The daemon keeps its state in Neo4j 5.26, and `swarm init` starts the one in the
  archive's compose file.
- Linux: OpenSSL 3 (`libcrypto.so.3`) and `ps`, which the daemon uses. macOS 15 or later on Apple Silicon: that is the build's minimum, a requirement, and only macOS 26.6.2 has been seen to run it.
  macOS: the published archive is built with OpenSSL 3 linked into its Erlang runtime, so no Homebrew OpenSSL is needed.
- To download: `curl`, or `gh` signed in. This repository is public, so `curl` needs no sign-in.

## Install

With `gh`, sign in once with `gh auth login`, then:

```sh
gh api -H 'Accept: application/vnd.github.raw' repos/scottlarkin/swarm-release/contents/install.sh | sh
```

The owner's Mac run installed this way. Or the same script by plain `curl`, which needs no sign-in:

```sh
curl -fsSL https://raw.githubusercontent.com/scottlarkin/swarm-release/main/install.sh | sh
```

The script downloads with `gh` when `gh auth status` succeeds and with `curl` otherwise. A `curl` fetch of the v0.1.2
archives and `checksums.txt` without signing in was checked to work, but **a full install by `curl` has not been run.**

The script detects your OS and CPU, downloads that archive and `checksums.txt`, stops unless the sha256 matches,
unpacks it to `~/.local/share/swarm/versions/<version>/`, points `~/.local/share/swarm/current` at it and links
`~/.local/bin/swarm`. It is short POSIX `sh`; read it before you pipe it. Add `--version vX.Y.Z` after `sh -s --`
for a release other than the latest. If `~/.local/bin` is not on your `PATH`, it says so.

Using an agent to install? Point it at [for-agents.md](for-agents.md)
(or paste: `Install Swarm following https://raw.githubusercontent.com/scottlarkin/swarm-release/main/for-agents.md`).
It reads without signing in, with `curl` or `gh`.

To check an archive yourself, download it and `checksums.txt` from the Releases page and compare
`sha256sum <archive>` (on a Mac, `shasum -a 256 <archive>`) with the archive's line in `checksums.txt`.

## First run

```sh
herdr            # opens a Herdr session; the next two commands run in the shell it gives you
swarm init
swarm tui
```

`swarm init` must run inside Herdr: a daemon started in a plain terminal cannot launch agents, so `init` refuses
there. It creates the private credentials and configuration for you, picks free local ports, starts Neo4j with
Docker, starts the daemon and finishes by running `swarm doctor`; it prints `doctor: ok` when that passes, and a later
`swarm doctor` reports `ok: true`. It never overwrites credentials that already exist and does not touch your agents'
own configuration. Nothing prints a password.

## Where to go next

The documentation is in the installed copy, at `~/.local/share/swarm/current/`:

- `README.md` for setup details and the TUI keys.
- `OPERATIONS.md` for running Swarm day to day: fresh setup, recovery, upgrade and rollback, the trust boundary. If an agent seems to ignore its messages, see its Troubleshooting table (Claude Code can show a setup dialog over an idle pane; choose "Don't show again").
- `examples/` for ready-made swarm profiles, and `roles/` for the role text agents are briefed with.

## Upgrade and roll back

Run `install.sh` again: the new version unpacks beside the old one and `current` moves. To go back, stop the daemon
(`swarm daemon stop`), repoint `current` (`ln -sfn versions/<old version> ~/.local/share/swarm/current` inside the
install root), then `swarm daemon start`. Old versions stay on disk. `OPERATIONS.md` has the full steps and what a
rollback does not undo.

## About the Mac archive

Be plain about what is known. The macOS runtime in the archive is a prebuilt Erlang for Apple Silicon, and the Swarm
daemon, the client and Bun are assembled around it on a Linux machine.

**Shown, by its owner on a real Mac (v0.1.2 on macOS 26.6.2, M4 Pro):**

- Install through `gh`, then `swarm init` and `swarm doctor`.
- The OpenSSL pin check passed, its control included.
- A real CLI swarm with a Claude and a Codex worker, which committed and reported.
- The TUI in a real terminal: the owner reports that it works. Which steps they took was not recorded.
- A `gh` install carried no quarantine attribute, only `com.apple.provenance`.

**Not yet run on a Mac:** `f` to attach to an agent, stopping a swarm, the task list table, a download by browser, a
full install by `curl`, and whether the OpenSSL `legacy.dylib` is still looked for under `/tmp`. They stay untested
until the owner's next run.

**What this does not show.** One Mac and one version. macOS 15 is the build's minimum, a requirement and not something
that was seen; the only other macOS that ran any Swarm archive was a hosted runner on 15.8.2, with the v0.1.0 archive.
A release other than v0.1.2 has not been shown on a Mac until this page says so.

**Signing.** The binaries are not notarized. All but Bun are ad-hoc signed, and Bun carries its upstream Developer ID
signature (measured on a hosted runner, v0.1.0 archive), so macOS may show a pop-up. A `gh` install left no
quarantine attribute on the Mac, and none from `gh` or `curl` on the hosted runner; a file downloaded by a browser may
carry one. If you hit a pop-up or a block, copy it word for word and say what `swarm doctor` printed and your macOS
version and chip.

## Support

Provided as-is, with no obligation to supply support, updates or maintenance — see [LICENSE](LICENSE).

## Third-party software

Third-party components and their licences are listed in [THIRD_PARTY.md](THIRD_PARTY.md).
