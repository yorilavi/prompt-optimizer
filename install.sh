#!/usr/bin/env sh
# install.sh — install or update the prompt-optimizer skill for Claude Code.
#
# Three install paths, auto-detected:
#   1. LOCAL COPY  — run from inside the unzipped skill folder
#   2. UPDATE      — re-run after a previous git-clone install (does git pull)
#   3. CLONE       — fresh install from GitHub (works under `curl ... | sh`)
#
# Works on macOS, Linux, WSL, and Git Bash on Windows.
#
# Usage:
#   sh install.sh
# or remotely:
#   curl -fsSL https://raw.githubusercontent.com/yorilavi/prompt-optimizer/main/install.sh | sh

set -eu

SKILL_NAME="prompt-optimizer"
REPO_URL="https://github.com/yorilavi/prompt-optimizer.git"
REMOTE_PATTERN="yorilavi/prompt-optimizer"
SKILLS_DIR="${HOME}/.claude/skills"
TARGET="${SKILLS_DIR}/${SKILL_NAME}"

# Resolve script directory if we have a path to ourselves. Under `curl | sh`
# this resolves to something useless and we'll fall through to clone mode.
SCRIPT_DIR=""
if [ -n "${0:-}" ] && [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
fi

require_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git is required but was not found on PATH." >&2
    echo "Install git first (https://git-scm.com/downloads), then re-run this script." >&2
    exit 1
  fi
}

backup_existing() {
  if [ -d "${TARGET}" ]; then
    BACKUP="${TARGET}.bak.$(date +%s)"
    echo "Existing install found at ${TARGET}"
    echo "Backing it up to ${BACKUP}"
    mv "${TARGET}" "${BACKUP}"
  fi
}

mode_local_copy() {
  echo "Mode: local copy (using files in ${SCRIPT_DIR})"
  mkdir -p "${SKILLS_DIR}"

  if [ -d "${TARGET}/.git" ]; then
    echo "Refusing to overwrite the existing git checkout at ${TARGET} with local files."
    echo "Either run 'git pull' inside that directory, or remove it and re-run this script."
    exit 1
  fi

  backup_existing
  mkdir -p "${TARGET}"
  cp "${SCRIPT_DIR}/SKILL.md" "${TARGET}/"
  [ -f "${SCRIPT_DIR}/CHANGELOG.md" ] && cp "${SCRIPT_DIR}/CHANGELOG.md" "${TARGET}/"
}

mode_update() {
  echo "Mode: update (existing git checkout at ${TARGET})"
  require_git
  ( cd "${TARGET}" && git pull --ff-only )
}

mode_clone() {
  echo "Mode: fresh clone from ${REPO_URL}"
  require_git
  mkdir -p "${SKILLS_DIR}"
  backup_existing
  git clone --depth 1 "${REPO_URL}" "${TARGET}"
}

# Detection
if [ -n "${SCRIPT_DIR}" ] && [ "${SCRIPT_DIR}" = "${TARGET}" ]; then
  echo "You're running install.sh from inside the target directory (${TARGET})."
  echo "Use 'git pull' here to update, or run install.sh from another location."
  exit 0
elif [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/SKILL.md" ]; then
  mode_local_copy
elif [ -d "${TARGET}/.git" ]; then
  EXISTING_REMOTE="$(cd "${TARGET}" && git remote get-url origin 2>/dev/null || true)"
  case "${EXISTING_REMOTE}" in
    *${REMOTE_PATTERN}*) mode_update ;;
    *)
      echo "ERROR: existing git checkout at ${TARGET} has an unfamiliar remote:" >&2
      echo "       ${EXISTING_REMOTE:-(none set)}" >&2
      echo "Refusing to touch it. Move it aside and re-run if you want a fresh install." >&2
      exit 1
      ;;
  esac
else
  mode_clone
fi

# Verify
if [ ! -f "${TARGET}/SKILL.md" ]; then
  echo "ERROR: install verification failed — SKILL.md not present at ${TARGET}" >&2
  exit 1
fi

VERSION="$(awk '/^[[:space:]]+version:/ {print $2; exit}' "${TARGET}/SKILL.md" 2>/dev/null || echo '?')"

echo ""
echo "Installed ${SKILL_NAME} v${VERSION} at:"
echo "  ${TARGET}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or start a new session)."
echo "  2. Try:  /prompt-optimizer"
echo "     or ask Claude to use the prompt optimizer skill."
echo "  3. Re-run this script any time to update."
