# Swarm: instructions for an installing agent

You are installing Swarm for a person. This file is written for you, not for them. Follow it
literally; the ordering is real.

Swarm is a terminal tool for running a team of coding agents on one task, with a shared task graph
and a TUI to watch it. Installing it means: put the program on this machine, start its database
(Neo4j in Docker) and its daemon, and check that it is healthy. You do not create a swarm or launch
any agent; the person does that.

## What stays with the person

Do not do these yourself unless the person told you to in this conversation. Propose the exact
command and wait.

- **Signing in.** Logging in to Claude, Codex or pi, and `gh auth login` if the person wants `gh` to do the
  downloading (the release repository is public, so `curl` needs no sign-in). You cannot do either, and
  must not look for tokens to do it for them.
- **Anything that needs `sudo`, and installing prerequisites.** Herdr (https://herdr.dev), Docker
  with its compose plugin, a native agent CLI (`claude`, `codex` or `pi`), `ps` (the `procps` package,
  absent from minimal Linux images), and on Linux OpenSSL 3. The installer installs none
  of them and neither do you. Name what is missing and how to get it.
- **The folder trust dialog.** The first time Swarm starts an agent in a directory, Claude Code or Codex
  asks whether to trust it. That appears in the agent's own pane, later, when the person starts a swarm,
  and only they answer it; the brief then goes by itself. Codex's own sandbox can block a worker from the
  daemon; the owner runs Codex with `sandbox_mode = "danger-full-access"`. Tell the person about the dialog and
  the sandbox.
- **Consent for side effects.** `swarm init` starts a Neo4j container (about 1.5 GB of memory, and
  a first-time image download of several hundred MB) and a background daemon. Starting a Herdr
  server (step 4) leaves a process running after you finish. Ask before each.

## Never print the password

`swarm init` generates a database password and an API token and keeps them in the profile
directory (`~/.local/state/swarm` unless `SWARM_HOME` says otherwise), in `connection.json` and
`neo4j.env`, mode 600. **Never print, `cat`, paste, quote or summarise either file, and never put a
password or token in a command line, a message to the person or a file you write.** Do not run
`docker inspect` on the Neo4j container or paste a process listing: on first start Neo4j's own
entrypoint shows a one-time password there for a few seconds. If you have seen one anyway, say so
and do not repeat it. `swarm doctor` prints neither, and is the way to check.

## Steps

**1. Check the platform.** Run `uname -sm`.

- `Darwin arm64` is `darwin-arm64`. It needs macOS 15 or later (`sw_vers -productVersion`), the build's
  minimum, and carries its own OpenSSL, so Homebrew's is not needed. **That archive has been run on one
  real Mac, by its owner: v0.1.5, v0.1.4, v0.1.3 and v0.1.2 on macOS 26.6.2 (M4 Pro), v0.1.4 and v0.1.5 with real Claude and real Codex.** Not yet run on a Mac:
  a browser download and whether `legacy.dylib` is still looked for under `/tmp`. The binaries are not notarized, so
  macOS may show a pop-up: do not click past it for the person; ask them to copy its words to you. Tell the
  person that it is early software, run on one Mac only, before you go on, and continue only if they still want to.
- `Linux x86_64` is `linux-x64`. A current glibc distro is needed (Ubuntu 24.04 and Debian 13 were
  tried, and a `curl` install of v0.1.3 in Debian 12 as far as `swarm help`), with OpenSSL 3.
- If `[ -e /etc/NIXOS ]` is true, the published Linux archive does not run on NixOS, and the
  installer refuses to download it. Stop, unless the person gives you a `swarm-<version>-nixos-x64.tar.gz`
  they built from source (the README, "Packaged setup"): that one installs with
  `sh install.sh --file <path>`, and you take step 3 from there.
- Anything else: stop and say it is not supported.

**2. Check the prerequisites; install none.**

```sh
for t in herdr docker ps; do command -v "$t" || echo "missing: $t"; done   # each prints a path or "missing"
command -v claude || command -v codex || command -v pi || echo "missing: claude, codex or pi"   # one path is enough
docker compose version && docker info >/dev/null && echo "docker ok"
```

On a Mac also check that `sw_vers -productVersion` starts with 15 or more; on Linux,
`ls /usr/lib*/libcrypto.so.3 /usr/lib/*/libcrypto.so.3 2>/dev/null` should print one path (a distro that keeps
OpenSSL elsewhere, NixOS for one, prints nothing; mention it to the person, and let the daemon starting in
step 5 be the test, rather than stopping).
Report anything missing to the person and let them fix it. Do not continue past a missing Docker
or Herdr. (`install.sh` also lists what it cannot find, and `swarm init` refuses with a list.)

**3. Install.** The release repository is public, so `curl` needs no sign-in:

```sh
curl -fsSL https://raw.githubusercontent.com/scottlarkin/swarm-release/main/install.sh -o install.sh
```

Both routes have run: `gh` and `curl` on a Mac with v0.1.3, and `curl` in a Debian 12 container as far as
`swarm help`. If `gh auth status` succeeds, the
same script comes through `gh`, and `install.sh` then downloads with `gh` too:

```sh
gh api -H 'Accept: application/vnd.github.raw' repos/scottlarkin/swarm-release/contents/install.sh > install.sh
```

Do not ask the person to sign in to `gh` for this; if neither `curl` nor a signed-in `gh` is there, that is the
only time to ask.

It is short; read it, and show the person if they ask. The script is not inside the release archive, so
you need it even when the person has already given you an archive: fetch it as above, or use the copy
they give you. Then run `sh install.sh`. It downloads the
archive and `checksums.txt` (with `gh` when signed in, else `curl`), refuses to go on if the
checksum does not match, unpacks to `~/.local/share/swarm/versions/<version>/`, points
`~/.local/share/swarm/current` at it and links `~/.local/bin/swarm`. Options: `--version vX.Y.Z`
for a release other than the latest, `--file PATH` for an archive the person already has. The
environment variables `SWARM_INSTALL_ROOT` and `SWARM_INSTALL_BIN` move the install directory and the
link. Rerunning is safe and keeps older versions.

If `~/.local/bin` is not on `PATH`, the installer says so; use `~/.local/bin/swarm` wherever
this file says `swarm`.

**4. Get a shell inside Herdr.** `swarm init` starts the daemon, and a daemon must really run inside
Herdr to launch agents, so `swarm init` refuses outside it. Do **not** `export HERDR_ENV=1`
to get past that. Check `echo "${HERDR_ENV:-unset}"`:

- `1`: you are in a Herdr pane. Go to step 5.
- Anything else: you are not. Ask the person which they prefer.
  - **They do it (best when they are at this terminal).** They run `herdr` in a terminal, then
    `swarm init` in the shell it opens. Wait for them, then go to step 6.
  - **You do it.** Reasonable when the person asked you to do the whole install, but say first what
    it means for them: it starts a Herdr server, a background process that **keeps running after
    you finish** and that you do not stop. Its first workspace, named `swarm-setup`, holds the shell
    in which `swarm init` ran. They reach it later by running plain `herdr` in any terminal, which
    attaches to that server and shows the workspace (`herdr session list` names the session,
    `default`). If they would rather not have it, use the first route.

    ```sh
    herdr status                                      # if it already says "server: status: running", skip the next line
    nohup herdr server > "$HOME/herdr-server.log" 2>&1 &
    herdr workspace create --label swarm-setup --cwd "$HOME"
    ```

    The last command prints JSON; note `root_pane.pane_id` (for example `w1:p1`). That pane has
    `HERDR_ENV=1`. Run init in it and read the result back:

    ```sh
    herdr pane run <pane_id> 'swarm init; echo "init-exit=$?"'
    herdr pane read <pane_id>                          # repeat every few seconds until init-exit= appears
    ```

**5. Run `swarm init`** in a pane inside Herdr:

```sh
swarm init
```

It generates the credentials, picks free ports (Neo4j from 17474, the daemon from 4780), starts the
Neo4j container, sets the database password over HTTP, starts the daemon and runs `swarm doctor`. It
takes under a minute, more on the first run while Docker pulls the Neo4j image. Its exit code is 0
only when doctor says `ok`. Rerunning is safe: it keeps credentials and ports, and never resets,
recreates or removes a database. Only if a port is taken: `--port N`, `--neo4j-http-port N` or
`--project NAME`.

**6. Check, yourself.** From a shell where `swarm` works (not necessarily the pane):

```sh
swarm doctor; echo "exit=$?"
swarm daemon status
```

Expect `"ok": true`, exit 0 and `Daemon is serving.` The verdict is the `ok` field, and the exit code
follows it. Each check has a `status`, and these are the only ones doctor uses:

- `ok`: fine.
- `missing`: something is not there. Beside `recommended-agent` that is fine, it is optional. Beside
  `claude`, `codex` or `pi` it is fine as long as one of them is `ok`. Beside `herdr`, or a missing
  connection, it is not: go to the table.
- `unreachable`: Neo4j or the daemon did not answer. Ask the person to check Docker is running, run
  `swarm init` again (safe), and read `swarm daemon logs`.
- `misconfigured`: something answered but is wrong, for example the daemon was not started inside Herdr
  (`Start the daemon inside Herdr (HERDR_ENV=1)`), or it rejected the token. Report the check's
  `message` to the person. For the Herdr one, `swarm daemon stop` and start it again from a shell
  inside Herdr (step 4). Do not edit the profile files.
- `unverified`: doctor can report it, but no check produces it today. If you see it, report the
  message and do not guess.

Any check that is not `ok` and not one of the harmless `missing` cases above means doctor's verdict is
`ok: false`: do not call the install done.

**7. Hand back to the person.** Tell them:

- what you installed: the version, the path (`~/.local/share/swarm/current`), and that doctor
  said `ok`;
- how to open the TUI: in a shell inside Herdr, `swarm tui` (if they are not in Herdr, `herdr`
  first, then `swarm tui` in the shell it opens; `q` quits it). If you started the Herdr server
  yourself, tell them it is running, that plain `herdr` attaches to it, and that you left it for them;
- that they create a swarm from the TUI, that a folder trust dialog may appear in an agent's pane the first
  time, and that they must be signed in to Claude or Codex before agents can run;
- on a Mac, that this archive has been run on one Mac only (its owner's, v0.1.5, v0.1.4, v0.1.3 and v0.1.2 on macOS 26.6.2),
  and that a browser download and the `legacy.dylib` check are not yet run.

Do not create a swarm for them unless they ask. Later, to update: rerun `install.sh`; it says when
`current` moved, and then `swarm daemon stop` and `swarm daemon start` bring the daemon onto the
new version.

## What success looks like

- `install.sh` prints `sha256 verified: swarm-<version>-<target>.tar.gz`, then
  `Installed swarm <version>: ...`, then `Next: ...`.
- `swarm init` ends with `doctor: ok` and exit 0 (`Daemon is serving at http://127.0.0.1:<port>.`
  before it).
- `swarm doctor` shows `"ok": true` and exits 0; `swarm daemon status` says `Daemon is serving.`

## If something fails

| What you see | What it means and what to do |
| --- | --- |
| `this needs curl, or gh signed in with gh auth login` | Neither tool is usable. Ask the person to run `gh auth login` or install `curl`. |
| `download failed: swarm <version> for <target> ...` | The version does not exist for this platform, or the network failed. Check the version with the person and pass `--version vX.Y.Z`; rerun. |
| `could not resolve the latest release` | The latest release could not be read: none exists, or the network failed. Ask the person for the version and pass `--version vX.Y.Z`. |
| `checksum mismatch ... not installing` | Do not go on. Try once more; if it repeats, tell the person and do not work around it. |
| `has no line for ... not installing` | The release has no archive for this platform. Stop and say so. |
| `NixOS cannot run the linux-x64 archive` | Stop. Building from source is the person's call. |
| `holds swarm-..., but this host takes swarm-<version>-<target>` | A `--file` archive for another platform. Nothing was changed; use the right archive. |
| `<path>/swarm exists and is not a link` | A real file is in the way. Ask the person; never delete it. |
| `macOS 15 or later: this is macOS <version>` in the installer's list | The Mac archive needs macOS 15 or later. Tell the person; do not try to work around it. |
| `ps (procps): not on PATH` in the installer's list | The daemon needs `ps` to identify agent processes, and `swarm doctor` does not notice it is missing. Ask the person to install `procps` (or the OS's equivalent). |
| `swarm init needs, and cannot find:` followed by a list | Give the list to the person. Install nothing. Rerun after they have. |
| `You are outside Herdr` | Go to step 4. |
| `a reachable Docker daemon` is missing | Docker is installed but not running. Ask the person to start it. |
| `Port <n> (...) is in use` | Rerun with another `--port` or `--neo4j-http-port`, or ask the person. |
| `Compose project ... already holds a Neo4j database ... has no record of creating it` | A database from an earlier setup whose password is not here. Init will not touch it. Ask the person; never remove volumes. |
| `Neo4j ... rejects the password in connection.json` | The stored password and the database disagree. Nothing was reset. Ask the person; never delete the database to fix it. |
| `Taking over the swarm init lock of PID <n>, which is no longer running.` | Normal after an interrupted init. It carries on. |
| `Another swarm init is starting; run it again in a moment.` | Another init has just begun. Wait, then rerun. |
| `Another swarm init is running (PID <n>). If it is not, remove <lock>.` | Wait for it, then rerun. If the person says no init is running, they decide about the lock file; you do not remove it. |
| `Another swarm init may be running: <lock> exists and its owner is unknown. Remove it only after confirming none is.` | Same: wait, or ask the person. Never remove the lock on your own judgment. |
| `doctor: not ok`, then check lines | Run `swarm doctor` for the full report and `swarm daemon logs`. Report them to the person. Do not edit the files in the profile directory. |
| Stuck for minutes on `Creating Neo4j` | The first Docker image pull is slow. Wait; `docker logs <the container named in the output>` shows why if it stays stuck. |
