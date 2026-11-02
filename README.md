# Swarm

Swarm coordinates native coding agents (Claude Code, Codex) through a manager, a dynamic roster and a task graph.
A durable daemon keeps the state; a terminal client shows live swarms and gives direct access to each agent's
[Herdr](https://herdr.dev) terminal. Several swarms can work in parallel. Agents decide how to delegate, use
worktrees, integrate results and clean up; a deliverable can be a PR, a branch, files or text.

Closed-source software. See [LICENSE](LICENSE).

> **Early software.** Expect rough edges. **The Mac archive has been run on one Mac, by its owner: v0.1.4, and before it
> v0.1.3 and v0.1.2, on macOS 26.6.2.** v0.1.5 has run there too, all but its sandbox hint, which v0.1.6 fixes. Nothing else has run it on a Mac, and v0.1.6 has not. Read "About the Mac archive" below for
> what was and was not shown.

## Platforms

| Platform | Archive | Status |
| --- | --- | --- |
| Linux x86_64, glibc | `swarm-<version>-linux-x64.tar.gz` | Built in a Debian 12 container (glibc 2.36). The highest glibc symbol its binaries need is 2.34, by a scan of the binaries. A generic Linux archive of an earlier build has been run in Debian 13 and Ubuntu 24.04 containers, and a full `curl` install of v0.1.3 in a Debian 12 container as a non-root user, as far as `swarm help`. Other glibc distributions of that age or newer are expected to work, and have not been run. Needs OpenSSL 3 on the host. |
| macOS on Apple Silicon | `swarm-<version>-darwin-arm64.tar.gz` | **Run on one Mac, by its owner.** Built on Linux against a prebuilt macOS Erlang runtime. Its owner ran v0.1.5, v0.1.4, v0.1.3 and v0.1.2 on macOS 26.6.2 (M4 Pro); see "About the Mac archive". Other macOS versions and chips are untried. |

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

The owner's Mac installed v0.1.2 this way and upgraded to v0.1.3. Or the same script by plain `curl`, which needs no sign-in:

```sh
curl -fsSL https://raw.githubusercontent.com/scottlarkin/swarm-release/main/install.sh | sh
```

The script downloads with `gh` when `gh auth status` succeeds and with `curl` otherwise. A `curl` install of v0.1.3 ran on
the owner's Mac, and a full `curl` install of v0.1.3 ran in a Debian 12 container as a non-root user, as far as `swarm help`.

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

**Shown, by its owner on a real Mac (macOS 26.6.2, M4 Pro).** v0.1.3, as reported by a Mac-side Claude, with no output
passed on:

- An upgrade from v0.1.2 through `gh`, and a `curl` install.
- `swarm init` and `swarm doctor`, and the OpenSSL pin check with its control.
- In the TUI: the new-swarm form, the task list table with its sorting, `f` to attach to an agent, and taking a swarm down.
- A launch at Claude's folder trust dialog: Enter refused while it was up and typed nothing; once it was answered, one
  Enter adopted the manager and sent its brief.
- A configured role and `swarm create --config`.
- A Codex worker kept its scratch file in a temporary directory outside its folder.
- Only `com.apple.provenance` on the programs, no quarantine attribute.

And v0.1.2: install through `gh`, and a real CLI swarm with a Claude and a Codex worker, which committed and reported.

**Codex on a Mac.** Codex's own sandbox can block a worker from the daemon; the owner runs Codex with `sandbox_mode = "danger-full-access"`.

**Not yet run on a Mac:** a download by browser, and whether the OpenSSL `legacy.dylib` is still looked for under
`/tmp` (the check needs `sudo`).

**v0.1.4, on the same Mac** (macOS 26.6.2, M4 Pro, codex-cli 0.166.0, Claude Code 2.1.316, real Claude and real Codex):

- The old daemon's stop named only the port, as expected; v0.1.4's named its PID and the port; `start` served and `doctor` was ok.
- The manager's harness from the configuration; the Directory cursor stayed at the end of the path.
- A launch at Claude's and at Codex's trust dialogs: nothing typed at the dialog, and the brief went by itself once it was answered. Codex kept its process through the answer. Codex asks for folder trust only inside a git repository.
- `swarm stop` closed a Codex pane; a replacement in the now-trusted folder was submitted with no dialog.
- `recommended-agent` chose a manager when none was configured.
- Take down and delete, which removed the swarm's saved files and left the connection file.

Not run: the `fs_usage` trace and the browser download.

**v0.1.5, on the same Mac** (codex-cli 0.166.0, Claude Code 2.1.316, real Claude and real Codex, Codex with `sandbox_mode = "danger-full-access"`): an install through `gh` and an upgrade from v0.1.4; each daemon's stop named its PID and the port; `doctor` was ok; `swarm create --config` chose the configured manager; a launch at Claude's trust dialog briefed itself once answered; the manager recruited a Codex worker, which wrote its file and messaged the manager; `swarm stop` closed each pane, with nothing typed; delete removed the swarm's saved files and kept the connection file. The sandbox hint (#271) did not fire under macOS Seatbelt in v0.1.5; v0.1.6 fixes it, not yet run on a Mac. Not run: the `fs_usage` trace and the browser download.

**What this does not show.** One Mac. macOS 15 is the build's minimum, a requirement and not something that was seen;
the only other macOS that ran any Swarm archive was a hosted runner on 15.8.2, with the v0.1.0 archive. A release other
than v0.1.5, v0.1.4, v0.1.3 and v0.1.2 has not been shown on a Mac until this page says so.

**Signing.** The binaries are not notarized. All but Bun are ad-hoc signed, and Bun carries its upstream Developer ID
signature (measured on a hosted runner, v0.1.0 archive), so macOS may show a pop-up. A `gh` install left no
quarantine attribute on the Mac, and none from `gh` or `curl` on the hosted runner; a file downloaded by a browser may
carry one. If you hit a pop-up or a block, copy it word for word and say what `swarm doctor` printed and your macOS
version and chip.

## Support

Provided as-is, with no obligation to supply support, updates or maintenance — see [LICENSE](LICENSE).

## Third-party software

Third-party components and their licences are listed in [THIRD_PARTY.md](THIRD_PARTY.md).
