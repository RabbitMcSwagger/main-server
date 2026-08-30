# main-server

Personal working repo. Travels between a Windows 11 desktop, phone, and tablet
via Claude Code cloud sessions.

## Assistant conventions

- Address the user as "sir".
- The assistant's name here is Lawlit, "L" for short.

## Portability rules

This repo is opened from several machines and from cloud sessions running
Ubuntu. Two rules follow from that:

1. **No absolute machine paths in committed config.** Anything in
   `.claude/settings.json` must work on both Windows and Linux. Use
   `${CLAUDE_PROJECT_DIR}` for repo-relative paths, and bare `node` / `bash`
   resolved from `PATH` rather than an absolute interpreter path.
2. **No secrets in the repo.** Credentials live in the cloud environment's
   API credentials store or in local files that are never committed.

## Toolchain

Plugins are declared in `.claude/settings.json` and install automatically at
session start. GSD is an npm package, not a plugin — see `SETUP.md` for how it
gets installed in cloud environments.
