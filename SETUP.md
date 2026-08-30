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

## GSD — configured, but the script is missing its second line

GSD is the npm package `get-shit-done-cc`. It is not a plugin, so it cannot be
declared in `.claude/settings.json`. It carries 67 skills, 33 agents, and a
payload directory that belong under `~/.claude/`, which is machine-local and not
part of the clone.

Installing the package is only half of it. There is no `postinstall`, so
`npm install -g` just puts the tarball in the global `node_modules` and stops —
no skills, no agents, nothing under `~/.claude/`. The package's
`get-shit-done-cc` bin is the installer that deploys the payload, and it has to
be run explicitly.

Rather than vendoring 4.5 MB of generated files into this repo — where they
would immediately start drifting from the published package — it installs from
the cloud environment's setup script.

The `Kira` cloud environment already carries a GSD setup script and its network
access is `Full`, so the plumbing is in place. What it carries is the one-line
version, which installs the package without deploying it — so GSD is currently
present but inert in cloud sessions. Change the **Setup script** field to:

```bash
#!/bin/bash
# Install GSD (get-shit-done-cc) so its skills and agents are available in
# cloud sessions. || true keeps an intermittent npm failure from blocking
# session start, which a non-zero exit would do.
npm install -g get-shit-done-cc || true
get-shit-done-cc --claude --global || true
```

Notes on that script:

- Both lines are required. The first fetches the package; the second deploys
  ~3.5 MB of skills, agents, hooks, and a statusline into `~/.claude/`. Without
  the second line GSD is on disk but invisible to the session.
- `--claude --global` keeps the installer non-interactive. With no flags it
  prompts for runtime and location, which a setup script cannot answer.
- `|| true` keeps an intermittent registry failure from blocking session start.
  A setup script that exits non-zero fails the whole session.
- Changes to an environment apply to **new** sessions, not running ones.
- Re-running is safe. The installer migrates an existing install in place and
  preserves user files it did not write.
- npm prints a deprecation notice for this package ("no longer supported").
  The install still succeeds; the notice is upstream, not a local fault.

Where to edit it, now or later: <https://claude.ai/code> → the environment chip
in the composer → **Cloud** → hover `Kira` → the gear icon.

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
| The desktop's GSD hooks | Every command in them hardcodes `C:/Program Files/nodejs/node.exe` and `C:/Users/bossk/...`. On Ubuntu each one exits 127. They are deliberately not committed. The installer writes correct native paths on whichever machine it runs on, which is the other reason to let it run per environment rather than commit its output. |
| Credentials of any kind | Use the environment's API credentials store. |

## Skills on claude.ai

Cowork and cloud sessions also load whatever skills are enabled on the
claude.ai account, synced at session start. That is the other route for making a
personal skill available everywhere without committing it here. Manage them
under **Customize** in the Desktop app sidebar, or in the skills settings on
claude.ai.
