# Agent teams under herdr — how `therdr` works and why it's needed

Written 2026-07-27 after debugging this the long way. If Claude Code teammates
ever stop appearing in panes, start here.

## The stack

```
iTerm2 window
└── one iTerm2 session
      └── herdr            <- the workspace manager: sidebar, spaces, tabs, panes
            └── a herdr pane
                  └── tmux            <- added by `therdr`
                        └── claude    <- teammates split THIS tmux
```

The thing that trips people up: **herdr is not a shell inside iTerm2's pane
system — it is a full-screen TUI that owns its own panes.** iTerm2 sees exactly
one session. So anything that splits *iTerm2* lands beside herdr, not inside it.

## The setting that actually matters

Claude Code picks a teammate backend via `--teammate-mode`
(`auto` | `tmux` | `iterm2` | `in-process`; config key `teammateMode`, default
`auto`). Under herdr, `auto` is wrong in **both** directions:

| Where you run it | `auto` resolves to | Result |
|---|---|---|
| Outside tmux (plain herdr pane) | `iterm2` | **Spawn fails**: `Failed to create iTerm2 split pane: Session '<uuid>' not found` |
| Inside tmux | `in-process` | Teammates work, but are **invisible** — no pane is ever created |

`--teammate-mode tmux` is the fix. That's the one load-bearing flag in `therdr`.

### Why the iTerm2 path fails specifically

herdr sessions are daemon-backed and survive an iTerm2 restart — that's the
point of herdr. But `ITERM_SESSION_ID` is captured when the shell starts. Quit
and reopen iTerm2 (e.g. the ⌘Q needed to activate its Python API) and every
surviving herdr shell still advertises a session ID that no longer exists.
Claude Code resolves the current session by that ID, doesn't find it, and the
teammate spawn dies. New shells are fine; long-lived herdr ones are not.

Diagnose with:

```bash
echo "$ITERM_SESSION_ID"          # what this shell thinks it is
osascript -e 'tell application "iTerm2" to tell current session of current window to get id'
```

If they disagree, that's the bug.

## Usage

```bash
therdr                 # start/attach a claude team session for this directory
therdr --model opus    # extra args pass straight through to claude
```

- Session is named per-directory (`therdr-<dirname>`), so re-running reattaches
  instead of stacking. Detach `Ctrl-b d`.
- Outside herdr it starts herdr first and tells you to re-run inside a pane.
- Already inside tmux it just runs claude with the right flag.

**Gotcha that cost an hour:** the function only exists in shells started *after*
it lands in `zshrc`. An existing herdr pane keeps its old shell — `source
~/.zshrc` or open a new pane, otherwise `therdr` simply isn't defined.

**How to confirm it's live:** a tmux status bar along the bottom
(`[therdr-<dir>] 0:claude*`), and:

```bash
ps aux | grep '[t]eammate-mode'   # expect: claude --teammate-mode tmux
```

No status bar means no tmux, which means teammates silently degrade to
in-process.

## Permissions

Teammates inherit the lead's permission mode, and shift+tab only cycles
manual / accept-edits / plan — **"bypass permissions on" is unreachable unless
the process was launched with `--dangerously-skip-permissions`**. So `therdr`
passes it by default; every teammate it spawns comes up in bypass too. Opt out
for a single run with `THERDR_NO_BYPASS=1 therdr`.

## Verified behaviour

Spawning a subagent from a `therdr` session takes the tmux pane count 1 → 2,
the new pane titled after the agent type, and the main pane renders a team
roster (`⏺ main`, `◯ <teammate>`). That is a real Agent-tool teammate — shared
context, structured results, addressable via `SendMessage` — not a separate CLI
being puppeteered.

## The other helper: `agentpane`

Different job. `agentpane <name> [cwd] [prompt]` spawns a **separate** Claude
into its own herdr pane via herdr's socket API (`herdr pane split` +
`herdr agent start`). Those are independent sessions you drive from outside:

```bash
herdr agent read <name>               # see its screen
herdr agent prompt <name> "..."       # send an instruction
herdr agent send-keys <name> 1 enter  # answer a permission prompt
herdr agent list                      # status of all of them
```

Useful for long-running independent work; **not** a team — no shared context,
no structured return. Use `therdr` when you want real teammates.

Note when driving them: permission prompts vary in option count. Blindly sending
`2` answers "No" on a two-option prompt.
