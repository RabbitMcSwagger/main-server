#!/usr/bin/env bash
# Register the marketplaces this repo depends on, then install the two plugins
# that are sourced from outside the official marketplace repo.
#
# Why this exists: Claude Code reads `extraKnownMarketplaces` from operator
# scopes only (policy / flag / user settings). A committed project file is
# "repo-authored" and is ignored unless the workspace trust dialog has been
# accepted, which a fresh cloud container never does. So the four git
# marketplaces in .claude/settings.json cannot self-register, and every
# enabledPlugins entry that names them is dropped as "marketplace not
# registered". `claude plugin marketplace add` writes user scope, which is
# honoured.
#
# Idempotent: re-adding an existing marketplace succeeds. `|| true` on every
# line so an offline or rate-limited run never fails its caller — a setup
# script that exits non-zero fails session start.
#
# Run once per machine (desktop), or from the cloud environment setup script.
set -u

for url in \
  https://github.com/DietrichGebert/ponytail.git \
  https://github.com/bradautomates/claude-video.git \
  https://github.com/blader/humanizer.git \
  https://github.com/JuliusBrussee/caveman.git
do
  claude plugin marketplace add "$url" --scope user || true
done

# In-tree plugins (github, imessage, session-report) arrive with the official
# marketplace. These two point at external repos and need an explicit fetch.
for plugin in superpowers@claude-plugins-official notion@claude-plugins-official; do
  claude plugin install "$plugin" --scope user || true
done
