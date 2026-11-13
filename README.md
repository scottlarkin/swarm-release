# Swarm

Swarm coordinates native coding agents (Claude Code, Codex) through a manager, a dynamic roster and a task graph.
A durable daemon keeps the state; a terminal client shows live swarms and gives direct access to each agent's
[Herdr](https://herdr.dev) terminal. Several swarms can work in parallel. Agents decide how to delegate, use
worktrees, integrate results and clean up; a deliverable can be a PR, a branch, files or text.

Closed-source software. See [LICENSE](LICENSE).

> **Early software.** Expect rough edges. **The Mac archive has been run on one Mac, by its owner: v0.1.4, and before it
> v0.1.3 and v0.1.2, on macOS 26.6.2.** v0.1.5 has run there too, all but its sandbox hint, and v0.1.6 showed that hint working. v0.1.7 has run there too, in part: read "About the Mac archive" for what it did not cover. v0.1.8 has run there too, in part: read "About the Mac archive" for what it did not cover. v0.1.9 and v0.1.10 are published before their Mac runs: their Mac checks are run after publish. Nothing else has run it on a Mac. Read "About the Mac archive" below for
> what was and was not shown.

## Platforms

| Platform | Archive | Status |
| --- | --- | --- |
| Linux x86_64, glibc | `swarm-<version>-linux-x64.tar.gz` | Built in a Debian 12 container (glibc 2.36). The highest glibc symbol its binaries need is 2.34, by a scan of the binaries. A generic Linux archive of an earlier build has been run in Debian 13 and Ubuntu 24.04 containers, and a full `curl` install of v0.1.3 in a Debian 12 container as a non-root user, as far as `swarm help`. Other glibc distributions of that age or newer are expected to work, and have not been run. Needs OpenSSL 3 on the host. |
| macOS on Apple Silicon | `swarm-<version>-darwin-arm64.tar.gz` | **Run on one Mac, by its owner.** Built on Linux against a prebuilt macOS Erlang runtime. Its owner ran v0.1.8, v0.1.7, v0.1.5, v0.1.4, v0.1.3 and v0.1.2 on macOS 26.6.2 (M4 Pro); see "About the Mac archive". Other macOS versions and chips are untried. |

Not published: Intel Macs, Windows, Linux on ARM, and NixOS (the generic Linux archive cannot start there).

## What you need first

Swarm installs none of these; `install.sh` names whichever is missing.

- [Herdr](https://herdr.dev) on your `PATH`. Swarm drives agents through its panes.
- A native agent CLI that is installed and signed in: `claude`, `codex` or `pi`.
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

## What changed in v0.1.10

Each item was tested on Linux, and none with real Codex. v0.1.10 is published before its Mac run.

- **pi as a native agent (#322).** Swarm can run the pi coding agent beside Claude and Codex, through Herdr's `pi`
  agent kind. Choose it with `--provider pi` on `swarm brief` and `swarm manager`, `manager: {provider: pi}` in a
  configuration, or a `recommended-agent` line `pi --model M --thinking E`; with nothing chosen, the first installed of
  `claude`, `codex` and `pi` runs. `--model` takes pi's own `provider/id`, and `--effort` is pi's thinking level (`off`,
  `minimal`, `low`, `medium`, `high`, `xhigh`). A pi session starts on a conversation ID Swarm asks for
  (`--session-id`) and resumes it with `--session`. `swarm doctor` and `swarm init` count `pi` as a native agent.
  **Limits:** pi replaces its own command line with `pi` and writes nothing before its first prompt, so adopting a pi
  already running (Shift+A, `swarm adopt`) checks only that the pane's process is pi, not which conversation it is on;
  a launch or resume is unaffected. Run once on Linux, with a pi manager and one pi worker on a small model: launch,
  brief, a message from worker to manager, stop, and a resume on the same conversation. Not run: adopting a live pi, pi
  beside Claude or Codex in one swarm, a selector that chooses pi, and any Mac.
- **A brief at a trust dialog waits instead of failing (#319).** With Herdr 0.9.1 a new swarm's brief could be refused
  `not_attempted` at Claude's folder-trust dialog, because Herdr read the agent idle and the prompt box never appeared.
  A send that finds a dialog on screen now waits queued behind it, as one at a dialog Herdr recognises does, and is
  typed once the dialog is answered.
- **`daemon.log` records session actions (#320).** One info line for each session action created or moved to another
  state: swarm, agent, request ID, type, the change and the daemon's error sentence, with no message text, body or
  token.
- **A replacement on a large swarm can launch (#321).** `--replace-session` put recovery views in the new session's
  first prompt, which on a large swarm passed the 128 KB single-prompt limit. When they do not fit they now go in a
  private file beside the saved brief, which the brief names.
- **A recruiter's `stopped_heartbeats` watch sees its reports' PR pollers (#316)**, so a dead poller wakes the
  recruiter, naming the PR; a finished one is not listed.
- **Test and development fixes.** #317: three more labs run their agents in a disposable folder outside the checkout.
  #318: two heartbeat test cases hold by construction instead of by wall-clock timing.

## What changed in v0.1.9

Each item was tested on Linux, and none with real Codex. v0.1.9 is published before its Mac run: the owner runs its Mac
checks after publish, and "About the Mac archive" will say what they showed. The first four items fix what the v0.1.8
Mac run found.

- **The `x` menu offers Pause or Resume, never both (#307, #310).** The menu is now `Pause` or `Resume`, then
  `Take down`, `Delete`, `Archive` (or `Restore`) and `Recover`, so Take down is always second. Resume is offered when
  the swarm's control state is `pause_requested`, `paused`, `down_requested` or `down`, or when the runtime reads the
  manager down; otherwise, unknown states included, Pause. In v0.1.8 Pause came first and Resume second, so a down-arrow
  and Enter meant for Take down sent "Resume work" to a running manager. Items are hidden, not greyed out. **Limit:**
  checked by tests, not looked at in a real TUI.
- **New-swarm Directory: typing replaces the prefilled path (#309).** The prefill is a suggestion: the first printable
  key or a paste replaces it, and an arrow, Backspace or Esc first keeps it to edit. The step's hint says so. A path with
  a `~` after its start or a `//` is refused before anything is made: "Working directory "…" has a ~ after its start or
  a //, as when a path is typed onto another; type it again. Nothing was created." In v0.1.8, typing `~/swarm-v018/img`
  made `<home>/swarm-v018~/swarm-v018/img`. **Limits:** a real directory with `~` inside its name is refused too.
  Checked by tests, not looked at in a real TUI.
- **`held_reason` is one sentence in `swarm quiet` and `session_busy` (#306).** The daemon holds the sentence, gives it
  on each claim in `swarm sessions` and the live `control` frame, and `swarm quiet` reads it from there; `session_busy`'s
  text is unchanged. In v0.1.8 `quiet`'s was worded differently. **Limit:** a claim from an older daemon, with no
  sentence, reads "`<holder>` holds this agent's input".
- **Composer images continue the swarm's numbering (#311).** An image attached in a `c` message after the Goal's image 1
  is image 2, saved as `2-…`, not image 1 under a collision prefix: numbering continues past the highest number saved in
  the swarm's `attachments/`. **Limit:** checked by tests only.
- **`pr-poller.sh` runs `heartbeat.sh`, and its wakes change for PR owners (#312).** Its command line is the same. What
  an owner sees now:
  - A wake reads "Heartbeat for <you>: watch N (`pr_watch <part>`) changed …", names only the parts of the PR that
    changed, carries no PR text, and ends with the `swarm ack` command to run. **Ack each wake:** the next wake waits for
    that ack, so changes meanwhile come in one wake after it. A wake typed and not acked for 6 hours is sent once more.
  - A PR with no change still wakes its owner every 6 hours.
  - The first change wakes at once: the one-poll wait that folded a burst into one wake is gone.
  - Nothing escalates to the lead: a refused submit is retried each poll and logged, and a third failed read of a part
    in a row wakes the owner, not the lead. `--lead` is accepted and unused.
  - It exits once the PR is merged or closed and that wake is acked or typed, or cannot be delivered because its owner
    has no live session.
  - It logs only events, so a lead checks that it is running by its lock (`flock -n <state dir>/lock true` fails while
    it runs), not by the log's age. A recruiter's heartbeat sees a dead owner through `down_reports`; its
    `stopped_heartbeats` reads heartbeat state directories only, not a poller's.
  - It now needs `flock` and `timeout` (on a Mac, `brew install coreutils flock`), and a second poller on the same PR
    exits.
  **Limits:** run once before merge against a real draft PR, with a throwaway daemon, a real Claude owner and a 20 s
  interval: a comment wake and its ack, a push wake, catch-up after a restart, and an exit after the close in each of
  three cases (acked, typed and not acked, no live session). The 6 h beat and repeat were not waited out, and that PR
  ran no checks, so no checks wake was seen. The tests use a stub `gh` and a stub `swarm`, under bash 5.2 and 3.2. One
  older heartbeat test that counts repeats on a wall clock failed once under load.
- **Test and development fixes.** #314: `real_scenarios.py` runs its agents in a fresh `/var/tmp` folder outside any
  checkout, removes the folder only when every scenario passed, and removes that folder's trust entry from
  `~/.claude.json` at the end; three other labs still use folders in the checkout. #308: `verify-swarm-package.sh` no
  longer reads a stopped daemon's zombie as alive; the cause is inferred, not observed. #304: the thumbnails test waits
  for each resize to be handled; the race was not forced.

## What changed in v0.1.8

Each item was tested on Linux, and none with real Codex. Part of it has since run on the owner's Mac; the items below
say which, and "About the Mac archive" lists what was and was not shown. Most items fix what the v0.1.7 Mac run found.

- **Thumbnails of attached images (#300).** Each image named in the new-swarm Goal or in a `c` message gets a small
  picture above the editor, under its `image N · name · size` line, up to four. Only in a terminal that answers Kitty
  graphics, as OpenTUI detects it, and in a pane at least 30 rows tall; otherwise, or for a file that does not decode,
  the text line stays as before. A picture is sent once and placed again by ID as the layout moves, and is deleted when
  its reference, the form or the composer goes, on `f`, and when the TUI exits. **Limits:** checked against a fake
  terminal that answers like Kitty. **Ran on a Mac**, in Ghostty under Herdr 0.9.1 with `kitty_graphics = true`: the
  owner saw the pictures, and they stayed put and left nothing behind through redraws, delete, Ctrl+P and Ctrl+S, resize,
  tab and workspace switch, `f`, and quit and pane close. A very large screenshot stalls
  input for about 135 ms, once, as it is attached.
- **Blocked and waiting task icons.** A task's `statusIcon` may now be `blocked` (⊘, red: it needs someone else to act,
  named in its `state`) or `waiting` (◷, grey: it goes on by itself or on a known event, such as a free slot or CI). Both
  stand still where `loading` spins. An agent's load counts them apart from active, as `1 blocked · 1 waiting`; an agent
  at rest whose open tasks are all `waiting` reads as waiting in the TUI and `swarm quiet`, not quiet, and a `blocked`
  task still reads quiet, since a person owes it. The role text now says `loading` only while a task is worked, and
  when to switch. Found on a swarm where merged, sessionless and queued work all showed a spinner. **Limits:** the
  icons are only as true as the agents keep them, and a running swarm's agents follow the new role text only once
  re-briefed; old swarms, with only `loading` and `complete`, read as before. The glyphs are one cell in OpenTUI's
  measure, and **ran on a Mac** in Ghostty as one cell each, with titles and box edges aligned and the owner seeing no
  width issue.
- **`swarm delete` removes the swarm's attached images (#294).** Images pasted into a goal or a message, under
  `contexts/<swarm>/attachments/`, are now removed with the swarm and listed in its result, and the emptied
  `contexts/<swarm>` goes too. In v0.1.7 they stayed, unreported. Nothing is followed through a symlink: one there is
  listed as kept, and what it points to stays. An image that another swarm's saved goal names stays and is listed as
  kept, as when a goal is remade with `e` after a stopped startup. Checked by the operator on a live daemon, with two
  PNGs and a symlink.
- **`held_by` is one value in `swarm quiet` and `session_busy` (#295).** `held_by` is `"human"` for a person's TUI focus
  in both, and in `quiet` also `"dialog"`, another holder's name, or `null`; the sentence is in `held_reason`. A CLI
  error now reads `<code>: <sentence>. Details: <json>`, so the message no longer runs into its JSON. The
  relative-directory refusal's example is `~/project`. **Limit:** `session_busy` gives no `"dialog"`, since its check does
  not read the agent's screen.
- **A send refused for a pane too short to show Claude's prompt says so (#297, #298).** When a send gives up because
  Claude's prompt is not on screen and the pane is under 8 rows, the refusal names the pane's height and gives the
  `herdr pane move <pane> --new-tab` command. The daemon never moves a pane. The guides now put each new agent, poller
  and heartbeat pane in a new tab, not a split: a split shrinks the pane beside it. Found on a swarm whose manager had
  split one tab into 8 panes of 3 to 5 rows, whose sends were refused for about 40 minutes. **Limit:** the pane's height
  is read from Herdr's `pane get`, checked on Herdr 0.8.2 and, on the Mac, on 0.9.1, which has the field.
- **A probe for image previews in the TUI (#296).** `scripts/probe-kitty-image.ts` draws, redraws and deletes one Kitty
  image with OpenTUI, for the owner's Mac. It is a probe, not a feature. On the Mac, the image appeared; the thumbnails
  run (#300) has since shown that it stays put and leaves nothing behind.
- **A flaky integration test says why it failed (#299).** "Control restart closes real sockets …" failed once beside two
  other heavy test lanes: a fixed 5 s wait for a setup task found an empty mailbox. The test now waits for the task's
  message or its exit, up to 45 s, and names a crash or where a stall is. **Limit:** the failure was not reproduced, under
  CPU load up to a load average of 49.

## What changed in v0.1.7

Each item was tested on Linux, with real Herdr and real Claude where it says so, and none with real Codex, which does
not run on the host where it was built. Part of it has since run on the owner's Mac; the items below say which, and
"About the Mac archive" lists what was and was not shown.

- **A send to Claude types only at its prompt (#284).** Before typing, the daemon reads Claude's screen. With a menu such
  as `/status` in front of the prompt, or someone's draft in it, the send is `not_attempted` and nothing is typed; its
  sender submits it again once the prompt is back. Claude's grey suggested prompt counts as empty. A brief after a trust
  dialog waits up to 5 s for the prompt to be drawn. Real Claude: `/status`, `/config`, `/help` and a draft typed nothing.
  **Limits:** a menu opened between the read and the typing still takes the text, so `completed` still means typed;
  Codex is not checked this way.
- **A send held behind a person's focus says so (#286).** While a TUI is attached to an agent (`f`), sends to it wait.
  Now `session_busy` names the waiting request and `held_by` (`human` for a TUI's focus), `swarm quiet` lists it under
  `held` after a minute, and the focused TUI's top line counts the queued requests and says Ctrl+Q lets them in.
  **Limit:** claims are held in memory, so a past hold shows in the journal only as a gap between `queued` and `attempting`.
- **A launch refused before it started is `not_attempted` (#281).** Herdr's `agent_pane_busy`, or a pane that is not
  the launch's, now leaves the session absent, so the agent can be briefed again.
- **The TUI waits for a new swarm's pane to show its prompt (#285, #287).** The manager starts once the shell has
  finished its startup files, up to 30 s; past that the screen says what the pane last showed, and Enter waits again. If a
  launch is still refused, Enter on the startup screen prepares a fresh manager session instead of repeating the refused
  one. The prompt is read from the pane's visible screen. Tested with real Herdr on a slow shell and in the four-layer release test.
- **The new-swarm Directory must be absolute (#287, #288).** A relative path is refused before anything is created;
  `~/` and a bare `~` are the home directory.
- **Images in the Goal and in messages (#283).** Ctrl+V reads an image from the clipboard (`wl-paste` on Linux; on macOS
  a file copied in Finder, `pngpaste`, or `osascript`), and a pasted or dropped image path attaches the file. Images are
  copied under the swarm's `contexts/<swarm>/attachments/`, and the manager's brief tells it to open each one.
  `swarm delete` keeps them. In Ghostty, Cmd+V or Ctrl+Shift+V with only an image on the clipboard sends nothing, which
  is why the key is Ctrl+V. **Unproven:** Cmd+V with only an image on the clipboard, drag-and-drop and Ghostty's clipboard paste on Linux are the owner's checks. Ctrl+V of a PNG and of a file copied in Finder ran on the Mac.
- **Heartbeats (#278, #279, #282).** `roles/guides/heartbeat.sh` wakes a recruiter on a timer and when something it watches
  changes, so each recruiter keeps its own subtree current. A beat stays pending until acknowledged; one typed but
  unacknowledged for two intervals is followed by one `repeat:`. The recovery guide gives the watches for a recruiter's
  reports: down sessions, stopped heartbeats and quiet agents. It needs `jq`, `uuidgen`, `flock`, and
  `timeout` or `gtimeout`; it hashes with `sha256sum`, or `shasum` where that is missing. A stock macOS lacks `timeout` and
  `flock`, and the script names every missing tool at once with `brew install coreutils flock`. **Ran on a Mac** with a watch; the no-watch case under bash 3.2 (#291) was not shown there.
- **Role text (#277, #280).** A manager reads a quiet agent's last reply before deciding why it is idle, never submits
  Claude's grey suggestion, and replaces a session whose tools are refused. An agent waits on its own process, never on a
  host-wide process-name match. The worker brief's size is now watched, and no longer fails a test past 12000 bytes.

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

**v0.1.5, on the same Mac** (codex-cli 0.166.0, Claude Code 2.1.316, real Claude and real Codex, Codex with `sandbox_mode = "danger-full-access"`): an install through `gh` and an upgrade from v0.1.4; each daemon's stop named its PID and the port; `doctor` was ok; `swarm create --config` chose the configured manager; a launch at Claude's trust dialog briefed itself once answered; the manager recruited a Codex worker, which wrote its file and messaged the manager; `swarm stop` closed each pane, with nothing typed; delete removed the swarm's saved files and kept the connection file. The sandbox hint (#271) did not fire under macOS Seatbelt in v0.1.5; v0.1.6 fixes it.

**v0.1.6, on the same Mac** (codex-cli 0.166.0): an upgrade through `gh` from v0.1.5; the v0.1.5 daemon's stop named its PID and the port; `start` served and `doctor` was ok. Real Codex under `codex exec -s workspace-write` in a plain folder ran `swarm list` and got the sandbox line after the connection error. Under `sandbox-exec` denying localhost: the same line with Codex's variables set, the conditional line with only `SWARM_ACTOR`, and only the connection error for a person at a shell. The full swarm run was not repeated on v0.1.6, which changed only that client line. Not run: the `fs_usage` trace and the browser download.

**v0.1.7, on the same Mac** (codex-cli 0.166.0, Claude Code 2.1.316, herdr 0.9.1, Ghostty; the TUI driven in a Herdr pane by the Mac Claude). Passed:

- An upgrade from v0.1.6: "Installed swarm 0.1.7", `current` moved from `versions/0.1.6` to `versions/0.1.7`; stopping 0.1.6 printed "Daemon stopped: PID 88329 exited and port 4780 is free; native sessions remain in Herdr." `doctor` was ok.
- The new-swarm Directory field took typed text at the end, both before and after Ctrl+P and Ctrl+S.
- A startup at Claude's trust dialog showed `waiting_on_dialog` with nothing typed; once answered, the brief typed itself once in about 5 s. The selection source was config, claude/haiku, with a reason naming `config.yaml`.
- Directories: a relative "v017-rel" was refused ("Working directory must be an absolute path …", "Nothing was created.") and the folder was not made; "~/swarm-v017/start" became the absolute path under the home directory (`/Users/<you>/swarm-v017/start`); "Waiting for pane w7P:p1's shell to show its prompt" lasted about 6 s, then `waiting_on_dialog`, with no `pane_busy` and no 30 s timeout.
- The heartbeat under macOS bash with a watch: before `flock` was installed (coreutils already was) it printed "heartbeat: missing flock; on a Mac: brew install coreutils flock"; after `brew install flock` the baseline was 12:41:00 and a change beat came at 12:42:02. While the manager was busy it printed "pending (completed) … skipping this check" for up to 142 s; the beat was acked at 12:44:44 and beat 2 came at 12:44:45. Each beat typed once, with no stale repeat before 240 s (`--stale 2`), and Ctrl+C stopped it.
- Images, in part: Ctrl+V with PNG data and no `pngpaste` attached `image 1 · clipboard.png · 127 KB` (decoded with `osascript`); a png copied with Cmd+C in Finder, then Ctrl+V, attached the file itself; an AppleScript bare POSIX file reference attached nothing and said "No image attached: The clipboard holds no PNG image; install pngpaste to paste other image types". The manager read and described both images; the attachments are `-rw-------`. Ctrl+V of a PNG in the `c` composer attached it and the manager read it.
- A send held behind focus: attached with `f`, submit 1 said queued and nothing was typed; within about 8 s the top line read "1 queued request waits on this focus, the oldest since 12:46 PM · Ctrl+Q returns to Swarm and lets it be typed"; submit 2 was refused `session_busy` naming `submit-20d20f25…` with `held_by` "human"; after Ctrl+Q the request was typed once within 2 s and the manager replied.

Found on that run, fixed in v0.1.8 (#294, #295) and not in v0.1.7: `swarm delete` left `contexts/<id>/attachments/` (3 PNGs) behind and did not report them, a privacy gap; `swarm quiet`'s `held_by` is prose while `session_busy` says "human"; `session_busy`'s message runs into its JSON details; the relative-directory error's example is a Linux path.

Not run: the Codex steps 4 to 6 (optional, not rerun); Cmd+V with an image-only clipboard and with a copied file; drag-and-drop, of a name with a space and of two files; an image copied from a browser; `pngpaste`. The owner does these by hand. The heartbeat with no `--watch` under bash 3.2 (#291) is not shown: the Mac run used a watch. The `fs_usage` trace and the browser download were not run.

**v0.1.8, on the same Mac** (macOS 26.6.2, codex-cli 0.166.0, Claude Code 2.1.317, herdr 0.9.1 with `kitty_graphics = true`, Ghostty). The steps are numbered as in the Mac checklist. Passed:

- 1, upgrade: "Downloading swarm 0.1.8 for darwin-arm64 with gh", "sha256 verified", `current` moved from `versions/0.1.7` to `versions/0.1.8`. Stopping 0.1.7: "Daemon stopped: PID 6300 exited and port 4780 is free; native sessions remain in Herdr." `doctor` was ok.
- 13, thumbnails (#300): two Ctrl+V PNGs in the Goal. The owner saw the pictures and confirmed 13.1 to 13.6 "all good and clean": redraws, delete, Ctrl+P and Ctrl+S, resize, tab and workspace switch, `f` then Ctrl+Q with a composer draft, and quit and pane close. This is the first sighting on a Mac, and it settles the probe's open questions (#296): the image stays put and nothing is left behind.
- 14, `held_by` (#295): a quiet `.held` gave `held_by` "human" plus `held_reason`. The banner read "NATIVE TERMINAL / manager · 1 queued request waits on this focus, the oldest since 03:00 PM / Ctrl+Q returns to Swarm and lets it be typed." The second submit was refused `session_busy`, its sentence ending before `Details: {"held_by":"human","held_reason":…}`. After Ctrl+Q it was typed once and the manager replied.
- 15, a short pane (#297): `viewport_rows` was 7, so Herdr 0.9.1 has the field. The refusal read exactly "Claude's prompt is not on screen: pane w7S:p1 is 7 rows tall, too small to show it; nothing was typed. Give it its own tab (herdr pane move w7S:p1 --new-tab --workspace w7S --no-focus), then submit again". Nothing was typed; after the move, the message was typed once.
- 16, icons: `⊘` was red (247;118;142) and `◷` grey (115;122;162), one cell each in the list and the DAG, with titles and box edges aligned, and static. The owner saw no width issue.
- 17, delete (#294): "Removed 7 saved files", including the three attachments; `contexts/<id>` was gone and `agent-connection.json` stayed.

Found on that run, fixed in v0.1.9 (#306, #307, #309, #311) and not in v0.1.8: `quiet`'s `held_reason` and `session_busy`'s `held_reason` are different sentences; the `x` menu offers Resume to an unpaused swarm (a down-arrow and Enter meant for Take down sent "Resume work"); the new-swarm Directory prefill takes typed text at its end, so typing `~/swarm-v018/img` made `<home>/swarm-v018~/swarm-v018/img`; composer image numbering restarts per composer (not wrong).

Not run: any step not listed above, including the checklist's other steps and the Codex steps. The `fs_usage` trace and the browser download were not run.

**v0.1.9 and v0.1.10: not yet run on a Mac.** Each is published first; the owner runs the checklist's steps after
publish, and this section will say what they showed.

**What this does not show.** One Mac. macOS 15 is the build's minimum, a requirement and not something that was seen;
the only other macOS that ran any Swarm archive was a hosted runner on 15.8.2, with the v0.1.0 archive. A release other
than v0.1.8, v0.1.7, v0.1.5, v0.1.4, v0.1.3 and v0.1.2 has not been shown on a Mac until this page says so.

**Signing.** The binaries are not notarized. All but Bun are ad-hoc signed, and Bun carries its upstream Developer ID
signature (measured on a hosted runner, v0.1.0 archive), so macOS may show a pop-up. A `gh` install left no
quarantine attribute on the Mac, and none from `gh` or `curl` on the hosted runner; a file downloaded by a browser may
carry one. If you hit a pop-up or a block, copy it word for word and say what `swarm doctor` printed and your macOS
version and chip.

## Support

Provided as-is, with no obligation to supply support, updates or maintenance — see [LICENSE](LICENSE).

## Third-party software

Third-party components and their licences are listed in [THIRD_PARTY.md](THIRD_PARTY.md).
