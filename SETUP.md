# Cross-device setup

How this repo's tooling reaches a phone, a tablet, and the desktop.

## Plugins: one command per machine

`.claude/settings.json` is committed and declares all nine plugins under
`enabledPlugins`, plus the marketplaces they come from. Half of that works on
its own; half does not.

| Plugin | Marketplace | Arrives on its own? |
| --- | --- | --- |
| `github` | `anthropics/claude-plugins-official` | yes |
| `imessage` | `anthropics/claude-plugins-official` | yes |
| `session-report` | `anthropics/claude-plugins-official` | yes |
| `superpowers` | `anthropics/claude-plugins-official` | no — needs install |
| `notion` | `anthropics/claude-plugins-official` | no — needs install |
| `ponytail` | `DietrichGebert/ponytail` | no — needs marketplace |
| `watch` | `bradautomates/claude-video` | no — needs marketplace |
| `humanizer` | `blader/humanizer` | no — needs marketplace |
| `caveman` | `JuliusBrussee/caveman` | no — needs marketplace |

Run this once per machine, or from the cloud environment's setup script:

```bash
bash .claude/bootstrap-plugins.sh
```

It is idempotent, so re-running it is free.

### Why a committed file cannot do this

Claude Code reads `extraKnownMarketplaces` from **operator** scopes only —
policy settings, flag settings, and user settings. Project and local settings
are "repo-authored" and are skipped unless the workspace trust dialog has been
accepted for that folder. A cloud container never accepts it, so every
marketplace declared in `.claude/settings.json` is ignored and each plugin
naming one is dropped at startup:

```
Skipping orphaned enabledPlugins entry ponytail@ponytail: marketplace not registered
Skipped auto-recording ponytail@ponytail — enabled only by repo-authored settings
```

`enabledPlugins` has no such gate — it is read from the merged settings across
all scopes. That asymmetry is the whole problem. `claude plugin marketplace
add` writes user scope, which is why the bootstrap script works.

`claude-plugins-official` is the exception, and misleadingly so: Claude Code
carries a hardcoded fallback for that one marketplace, triggered by any
`@claude-plugins-official` entry in `enabledPlugins`. It registers regardless
of what the project file says.

`superpowers` and `notion` then fail for an unrelated reason — they are the only
two entries whose marketplace source points outside the marketplace repo
(`obra/superpowers` and `makenotion/claude-code-notion-plugin`), so they need a
separate fetch that the startup reconcile does not perform.

Note also that `claude plugin list` reads `installed_plugins.json`, which stays
empty for settings-declared plugins. It printing "No plugins installed" is not
evidence that anything is broken.

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
