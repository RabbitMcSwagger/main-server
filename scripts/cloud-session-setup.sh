#!/bin/bash
# Cloud environment setup script for main-server.
#
# Paste the body of this file into the cloud environment's setup script
# (claude.ai/code -> environment chip -> Cloud -> gear icon).
#
# Why this is needed: a network-location marketplace declared in a PROJECT
# file (<repo>/.claude/settings.json) is not vouched for by Claude Code --
# only USER or managed settings can register one. So the four git-sourced
# marketplaces in this repo's settings.json are never enumerated at session
# start, and nothing under them installs. This script registers them at user
# scope instead, which is what the CLI does natively.
#
# Every step is `|| true`: a setup script that exits non-zero fails the whole
# session. All steps are idempotent and safe to re-run.

set -u

# Checkout root of this repo inside the cloud container.
REPO_DIR="${CLAUDE_PROJECT_DIR:-/home/user/main-server}"

# ---------------------------------------------------------------- 1. GSD ---
# get-shit-done-cc is an npm package, not a plugin, so it cannot be declared
# in .claude/settings.json. Installing the package only puts it on disk --
# bin/install.js is what populates ~/.claude/skills and ~/.claude/agents.
npm install -g get-shit-done-cc || true
node "$(npm root -g)/get-shit-done-cc/bin/install.js" --claude --global || true
# Swap in --profile=standard for ~13 skills (~700 desc tokens) instead of the
# full 67 (~12k) if cold-start context budget matters more than coverage.

# -------------------------------------------------------- 2. Marketplaces ---
# claude-plugins-official is built in, but "built in" only takes effect once a
# session starts and reads this repo's .claude/settings.json. While this script
# runs there is no session, so installing from it here resolves nothing and
# fails silently. Register it explicitly like the rest; the add is idempotent.
for url in \
  anthropics/claude-plugins-official \
  https://github.com/DietrichGebert/ponytail.git \
  https://github.com/bradautomates/claude-video.git \
  https://github.com/blader/humanizer.git \
  https://github.com/JuliusBrussee/caveman.git
do
  claude plugin marketplace add "$url" || true
done

# ------------------------------------------------------------- 3. Plugins ---
PLUGINS=(
  superpowers@claude-plugins-official
  session-report@claude-plugins-official
  notion@claude-plugins-official
  ponytail@ponytail
  watch@claude-video
  humanizer@humanizer
  caveman@caveman
)

# Keep the install output. `|| true` is what stops a failed install from
# failing the whole session, and it is also what made the last failure
# undiagnosable -- nothing on disk said which plugin did not land, or why.
LOG="$HOME/.claude/main-server-setup.log"
mkdir -p "$(dirname "$LOG")"
: >"$LOG"
for plugin in "${PLUGINS[@]}"; do
  claude plugin install "$plugin" >>"$LOG" 2>&1 || true
done

# `claude plugin install` does not report failure reliably in its exit status,
# so check the postcondition instead: what actually registered.
missing=""
installed="$(claude plugin list 2>/dev/null || true)"
for plugin in "${PLUGINS[@]}"; do
  case "$installed" in
    *"> $plugin"*) ;;
    *) missing="$missing $plugin" ;;
  esac
done
if [ -n "$missing" ]; then
  echo "SETUP WARNING: declared but not installed:$missing"
  echo "SETUP WARNING: install output is in $LOG"
fi

# --------------------------------------------------- 4. Workspace trust ----
# Optional. Without it Claude Code logs "Skipping plugin monitor - workspace
# trust not accepted", and plugin-supplied hooks (superpowers, ponytail and
# watch all ship a hooks/ directory) may not load. Marketplace registration
# and plugin install above do NOT require it.
#
# This marks the cloned repo as trusted without a prompt. That is reasonable
# for an ephemeral single-tenant cloud container running your own repo; do not
# copy this line onto a machine where the checkout is not solely yours.
REPO_DIR="$REPO_DIR" node -e '
  const fs = require("fs"), os = require("os"), path = require("path");
  const f = path.join(os.homedir(), ".claude.json");
  const repo = process.env.REPO_DIR;
  let d = {};
  try { d = JSON.parse(fs.readFileSync(f, "utf8")); } catch {}
  d.projects = d.projects || {};
  d.projects[repo] = { ...(d.projects[repo] || {}), hasTrustDialogAccepted: true };
  fs.writeFileSync(f, JSON.stringify(d, null, 2));
' || true
