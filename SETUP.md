# Cross-device setup

How this repo's tooling reaches a phone, a tablet, and the desktop.

## What already works, with no action

`.claude/settings.json` is committed, so any Claude Code session that clones
this repo installs these plugins at session start:

| Plugin | Marketplace |
| --- | --- |
| `superpowers` | `anthropics/claude-plugins-official` |
| `session-report` | `anthropics/claude-plugins-official` |
| `notion` | `anthropics/claude-plugins-official` |
| `imessage` | `anthropics/claude-plugins-official` |
| `github` | `anthropics/claude-plugins-official` |
| `ponytail` | `DietrichGebert/ponytail` |
| `watch` | `bradautomates/claude-video` |
| `humanizer` | `blader/humanizer` |
| `caveman` | `JuliusBrussee/caveman` |

Two conditions apply:

- The cloud environment needs network access at the **Trusted** level or above,
  so it can reach GitHub to fetch each marketplace.
- On a local machine, `extraKnownMarketplaces` from a project file only takes
  effect after the workspace trust dialog is accepted for this folder.

## GSD — configured, no action needed

GSD is the npm package `get-shit-done-cc`. It is not a plugin, so it cannot be
declared in `.claude/settings.json`. It installs 66 skills, 33 agents, and a
payload directory under `~/.claude/`, which is machine-local and not part of
the clone.

Rather than vendoring 4.5 MB of generated files into this repo — where they
would immediately start drifting from the published package — it installs from
the cloud environment's setup script.

**This is already set up.** The `Kira` cloud environment carries this setup
script, and its network access is `Full`:

```bash
#!/bin/bash
# Install GSD (get-shit-done-cc) so its skills and agents are available in
# cloud sessions. || true keeps an intermittent npm failure from blocking
# session start, which a non-zero exit would do.
npm install -g get-shit-done-cc || true
```

Notes on that script:

- `|| true` keeps an intermittent registry failure from blocking session start.
  A setup script that exits non-zero fails the whole session.
- The environment cache keeps what the script installs, so this does not
  reinstall on every session.
- Changes to an environment apply to **new** sessions, not running ones.

To change it later: <https://claude.ai/code> → the environment chip in the
composer → **Cloud** → hover `Kira` → the gear icon.

Check the pinned version against the desktop:

```bash
npm view get-shit-done-cc version
```

The desktop is on 1.42.3.

## What does not travel, by design

| Thing | Why |
| --- | --- |
| `~/.claude/skills/`, `~/.claude/agents/` | Machine-local. Commit to this repo's `.claude/` or enable on claude.ai instead. |
| Plugins enabled only in `~/.claude/settings.json` | User scope does not transfer. This repo declares them instead. |
| MCP servers added at user or local scope | Those write `~/.claude.json`. Use `claude mcp add --scope project` to write a committed `.mcp.json`. |
| The desktop's GSD hooks | Every command in them hardcodes `C:/Program Files/nodejs/node.exe` and `C:/Users/bossk/...`. On Ubuntu each one exits 127. They are deliberately not committed. |
| Credentials of any kind | Use the environment's API credentials store. |

## Skills on claude.ai

Cowork and cloud sessions also load whatever skills are enabled on the
claude.ai account, synced at session start. That is the other route for making a
personal skill available everywhere without committing it here. Manage them
under **Customize** in the Desktop app sidebar, or in the skills settings on
claude.ai.
