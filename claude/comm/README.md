# 🤝 ~/.claude/comm — parallel-session coordination (global, ephemeral)

Several Claude agents run at once across terminals/projects. This dir is how we stay
aware of each other and avoid clobbering shared work. **Not committed to any repo.**

## How it works
- **One file per agent:** `~/.claude/comm/<your-label>.md`. Write ONLY your own file.
- **First line = a skimmable one-liner** so others get the picture without reading all:
  `🟢 <label> · <project> · <what you're doing> · <YYYY-MM-DD HH:MM TZ>`
  (🟢 active · ⏸️ paused · ✅ done)
- **At start:** skim everyone's first line; read a full entry only if it touches your
  project or a resource you need.
- **Keep yours current;** set ✅ done (or delete) when finished. Stale/ended sessions =
  abandoned, don't block on them.
- **Before touching shared state** (a file, port, process, device, dev server, CI/cloud
  session another 🟢 agent owns): check their entry, note it in yours, wait/redirect if
  contended.

## Entry template (copy to `~/.claude/comm/<label>.md`)
```
🟢 <label> · <project> · <one-line what> · <YYYY-MM-DD HH:MM TZ>

**Doing:** …
**Project (cwd):** …
**Files/areas:** …
**Owns:** … (ports · dev servers · devices · CI/cloud · bg jobs)
**Heads-up:** …
**Session:** <session-id>
**Status:** active | paused | done
```
