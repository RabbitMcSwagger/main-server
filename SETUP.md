# Cross-device setup

How this repo's tooling reaches a phone, a tablet, and the desktop.

## Plugins — needs the setup script

`.claude/settings.json` declares eight plugins across five marketplaces. Those
declarations are necessary but **not sufficient**: a project-scope file cannot
register a marketplace that lives on a network location.

Claude Code's rule, quoted from the binary:

> a marketplace on a network location must be declared under
> `extraKnownMarketplaces` in USER or managed settings (project/local scope
> cannot vouch for it)

`<repo>/.claude/settings.json` is project scope. So at session start the four
git-sourced marketplaces are not merely skipped — they are never enumerated.
A cloud session's own diagnostics confirm it:

```json
{"event":"headless_marketplace_reconcile_completed",
 "data":{"installed_count":1,"failed_count":0,"skipped_count":0}}
{"event":"plugins_sync_no_changes","data":{"count":0,"had_manifest":false}}
```

`installed_count: 1` is `claude-plugins-official` alone, which is built in and
needs no vouching. Zero failures and zero skips because the other four were
filtered out before the loop ran.

The fix is to register them at **user** scope from the environment setup
script, which is what `scripts/cloud-session-setup.sh` does. Keep the
`extraKnownMarketplaces` block in `.claude/settings.json` — it still documents
intent, and the CLI reads it to name each marketplace on registration.

| Plugin | Marketplace |
| --- | --- |
| `superpowers` | `anthropics/claude-plugins-official` |
| `session-report` | `anthropics/claude-plugins-official` |
| `notion` | `anthropics/claude-plugins-official` |
| `imessage` | `anthropics/claude-plugins-official` |
| `ponytail` | `DietrichGebert/ponytail` |
| `watch` | `bradautomates/claude-video` |
| `humanizer` | `blader/humanizer` |
| `caveman` | `JuliusBrussee/caveman` |

`github@claude-plugins-official` is deliberately **not** in that list. Its
`.mcp.json` authenticates with `Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}`, and
with that variable unset the header goes out unresolved — every cloud session
opened with `Error POSTing to endpoint: bad request: Authorization header is
badly formatted`. Setting it would mean pasting a PAT into the environment's
plaintext variables box (see the credentials row below). It buys nothing:
cloud sessions already carry an authenticated `github` MCP server pointed at
the same `api.githubcopilot.com/mcp/`, exposing the same `mcp__github__*`
tools.

Two further conditions:

- The cloud environment needs network access at **Trusted** or above to reach
  GitHub for each marketplace clone.
- Workspace trust (`hasTrustDialogAccepted`) is not required to register or
  install, but while it is false Claude Code logs `Skipping plugin monitor -
  workspace trust not accepted`, and plugin-supplied hooks may not load. The
  setup script sets it; see the comment there before reusing that step.

## GSD — configured, no action needed

GSD is the npm package `get-shit-done-cc`. It is not a plugin, so it cannot be
declared in `.claude/settings.json`. It installs 66 skills, 33 agents, and a
payload directory under `~/.claude/`, which is machine-local and not part of
the clone.

Rather than vendoring 4.5 MB of generated files into this repo — where they
would immediately start drifting from the published package — it installs from
the cloud environment's setup script.

The `Kira` cloud environment carries a setup script and its network access is
`Full`, but the script only ran `npm install -g get-shit-done-cc`. That puts
the package on disk and nothing more — verified in a cloud session, where
`get-shit-done-cc@1.42.3` was present globally while `~/.claude/skills/` held
two entries and `~/.claude/agents/` did not exist.

Installing the package is only half the job. `bin/install.js` is what populates
`~/.claude`, and it must be run explicitly:

```bash
npm install -g get-shit-done-cc || true
node "$(npm root -g)/get-shit-done-cc/bin/install.js" --claude --global || true
```

With that second line, the same session went to 67 GSD skills and 33 agents.

Note the package ships no bare `gsd` binary — only `get-shit-done-cc`,
`gsd-sdk` and `gsd-tools`. `npx gsd --version` is therefore misleading: it
finds nothing locally and silently downloads an unrelated registry package
named `gsd`. Do not use it as an install check. Use:

```bash
npm list -g --depth=0 | grep get-shit-done-cc
```

Notes on the setup script:

- `|| true` keeps an intermittent registry failure from blocking session start.
  A setup script that exits non-zero fails the whole session.
- The environment cache keeps what the script installs, so this does not
  reinstall on every session.
- `bin/install.js --claude --global` writes hooks and a statusline into
  `~/.claude/settings.json` using absolute paths (`/opt/node22/bin/node`,
  `/root/.claude/hooks/...`). That is fine at user scope, which never leaves
  the container. Do not run it with `--local`, which would write those paths
  into this repo and break the portability rule in `CLAUDE.md`.
- The full profile installs 67 skills, roughly 12k tokens of cold-start
  description overhead. `--profile=standard` cuts that to ~13 skills / ~700
  tokens if that trade is worth it.
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
| `extraKnownMarketplaces` for network sources | Project scope cannot vouch for them. Register at user scope from the setup script. |
| Plugins enabled only in `~/.claude/settings.json` | User scope does not transfer. This repo declares them instead. |
| MCP servers added at user or local scope | Those write `~/.claude.json`. Use `claude mcp add --scope project` to write a committed `.mcp.json`. |
| The desktop's GSD hooks | Every command in them hardcodes `C:/Program Files/nodejs/node.exe` and `C:/Users/bossk/...`. On Ubuntu each one exits 127. They are deliberately not committed. |
| Credentials of any kind | The cloud environment has no secret store. Its **Environment variables** box is plaintext and labelled "visible to anyone using this environment". Anything needing a real secret does not belong in a cloud session. |

## Skills on claude.ai

Cowork and cloud sessions also load whatever skills are enabled on the
claude.ai account, synced at session start. That is the other route for making a
personal skill available everywhere without committing it here. Manage them
under **Customize** in the Desktop app sidebar, or in the skills settings on
claude.ai.
