#!/usr/bin/env sh
# install.sh — install the prompt-optimizer skill for Claude Code.
# Works on macOS, Linux, WSL, and Git Bash on Windows.
# Run from inside the unzipped skill folder:  sh install.sh

set -eu

SKILL_NAME="prompt-optimizer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
TARGET="${SKILLS_DIR}/${SKILL_NAME}"

# No-op if we're running from inside the install target itself (author dev case).
if [ "${SCRIPT_DIR}" = "${TARGET}" ]; then
  echo "Already running from the install target (${TARGET}). Nothing to copy."
  exit 0
fi

# Sanity: script directory must contain SKILL.md.
if [ ! -f "${SCRIPT_DIR}/SKILL.md" ]; then
  echo "ERROR: SKILL.md not found in ${SCRIPT_DIR}." >&2
  echo "Run this script from inside the unzipped skill folder (where SKILL.md lives)." >&2
  exit 1
fi

mkdir -p "${SKILLS_DIR}"

# Back up any existing install so we never silently overwrite user changes.
if [ -d "${TARGET}" ]; then
  BACKUP="${TARGET}.bak.$(date +%s)"
  echo "Existing install found at ${TARGET}"
  echo "Backing it up to ${BACKUP}"
  mv "${TARGET}" "${BACKUP}"
fi

mkdir -p "${TARGET}"
cp "${SCRIPT_DIR}/SKILL.md" "${TARGET}/"
[ -f "${SCRIPT_DIR}/CHANGELOG.md" ] && cp "${SCRIPT_DIR}/CHANGELOG.md" "${TARGET}/"

if [ ! -f "${TARGET}/SKILL.md" ]; then
  echo "ERROR: install verification failed — SKILL.md not present at ${TARGET}" >&2
  exit 1
fi

VERSION="$(awk '/^  version:/ {print $2; exit}' "${TARGET}/SKILL.md" 2>/dev/null || echo '?')"

echo ""
echo "Installed ${SKILL_NAME} v${VERSION} at:"
echo "  ${TARGET}"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or start a new session)."
echo "  2. Try:  /prompt-optimizer"
echo "     or ask Claude to use the prompt optimizer skill."
echo "  3. List installed skills with /skills to confirm it loaded."
