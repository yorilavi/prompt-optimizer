#!/usr/bin/env sh
# scripts/release.sh — cut a new versioned release in one command.
#
# What it does:
#   1. Bumps the version in every version-aware file:
#        - SKILL.md  metadata.version
#        - SKILL.md  body byline (**vX.Y.Z** and the "updated YYYY-MM-DD" date)
#        - README.md "current version: **vX.Y.Z**"
#        - INSTALL.md direct zip URL (refs/tags/vX.Y.Z.zip)
#   2. Promotes "## Unreleased" -> "## X.Y.Z — <today>" in CHANGELOG.md (if present).
#   3. Shows the diff and waits for your confirmation.
#   4. Commits, tags vX.Y.Z, pushes main, pushes the tag.
#      The push fires the verify-release Action as a backstop.
#   5. Creates the GitHub Release using the CHANGELOG section as release notes.
#
# Usage:
#   scripts/release.sh <version> [<title-suffix>]
#
# Examples:
#   scripts/release.sh 1.0.2
#   scripts/release.sh 1.0.2 "Smarter installer messaging"
#
# Requirements:
#   - git
#   - gh (GitHub CLI), authenticated as the repo owner
#   - clean working tree
#   - CHANGELOG.md has either an "## Unreleased" section to promote
#     or a pre-written "## X.Y.Z" section for the version you're cutting

set -eu

# ---------- args ----------

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <version> [<title-suffix>]" >&2
  echo "  version       MAJOR.MINOR.PATCH, no 'v' prefix (e.g. 1.0.2)" >&2
  echo "  title-suffix  optional short description appended to the release title" >&2
  exit 1
fi

NEW_VERSION="$1"
TITLE_SUFFIX="${2:-}"
TODAY="$(date +%Y-%m-%d)"

# ---------- validate ----------

case "$NEW_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *)
    echo "ERROR: version must be MAJOR.MINOR.PATCH (got '$NEW_VERSION')" >&2
    exit 1
    ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found on PATH" >&2; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo "ERROR: gh (GitHub CLI) not found on PATH" >&2; exit 1; }

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash first." >&2
  git status --short >&2
  exit 1
fi

if git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1; then
  echo "ERROR: tag v${NEW_VERSION} already exists locally" >&2
  exit 1
fi
if git ls-remote --tags origin "v${NEW_VERSION}" 2>/dev/null | grep -q .; then
  echo "ERROR: tag v${NEW_VERSION} already exists on origin" >&2
  exit 1
fi

if ! grep -qE "^## (Unreleased|${NEW_VERSION}([[:space:]]|$))" CHANGELOG.md; then
  echo "ERROR: CHANGELOG.md needs either an '## Unreleased' section to promote," >&2
  echo "       or a pre-written '## ${NEW_VERSION}' section." >&2
  exit 1
fi

CURRENT="$(awk '/^[[:space:]]+version:/ {print $2; exit}' SKILL.md)"
if [ -z "$CURRENT" ]; then
  echo "ERROR: could not find current version in SKILL.md" >&2
  exit 1
fi

if [ "$CURRENT" = "$NEW_VERSION" ]; then
  echo "ERROR: SKILL.md already at v${NEW_VERSION}. Nothing to bump." >&2
  exit 1
fi

if [ -n "$TITLE_SUFFIX" ]; then
  RELEASE_TITLE="v${NEW_VERSION} — ${TITLE_SUFFIX}"
else
  RELEASE_TITLE="v${NEW_VERSION}"
fi

echo "Bumping: v${CURRENT} -> v${NEW_VERSION}"
echo "Date:    ${TODAY}"
echo "Title:   ${RELEASE_TITLE}"
echo ""

# ---------- edit files ----------
# sed -i.bak works on both GNU and BSD/macOS sed.

# 1. SKILL.md metadata.version
sed -i.bak "s/^\([[:space:]]\{1,\}version:\) ${CURRENT}\$/\1 ${NEW_VERSION}/" SKILL.md

# 2. SKILL.md body byline version
sed -i.bak "s/\*\*v${CURRENT}\*\*/\*\*v${NEW_VERSION}\*\*/g" SKILL.md

# 3. SKILL.md body byline date — bump 'updated YYYY-MM-DD' to today
sed -i.bak "s|updated [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}|updated ${TODAY}|" SKILL.md

# 4. README.md current version
sed -i.bak "s/current version: \*\*v${CURRENT}\*\*/current version: \*\*v${NEW_VERSION}\*\*/" README.md

# 5. INSTALL.md zip URL
sed -i.bak "s|refs/tags/v${CURRENT}\\.zip|refs/tags/v${NEW_VERSION}.zip|g" INSTALL.md

# 6. CHANGELOG.md — promote Unreleased section if present
if grep -qE '^## Unreleased' CHANGELOG.md; then
  sed -i.bak "s/^## Unreleased\$/## ${NEW_VERSION} — ${TODAY}/" CHANGELOG.md
fi

# Clean up sed backups
find . -maxdepth 2 -name '*.bak' -not -path './.git/*' -delete

# ---------- review ----------

echo "Diff:"
echo "----"
git --no-pager diff
echo "----"
echo ""

printf "About to commit, tag v%s, push, and create the GitHub Release.\n" "$NEW_VERSION"
printf "Continue? [y/N] "
read -r answer
case "$answer" in
  y|Y|yes|YES) ;;
  *)
    echo "Aborted. To undo the file edits: git checkout -- ."
    exit 1
    ;;
esac

# ---------- commit, tag, push ----------

git add -A
git commit -m "Release ${RELEASE_TITLE}"
git tag -a "v${NEW_VERSION}" -m "${RELEASE_TITLE}"
git push origin main
git push origin "v${NEW_VERSION}"

# ---------- extract release notes from CHANGELOG ----------
# Escape dots so the version's regex matches only literal dots.
ESCAPED_VERSION="$(echo "$NEW_VERSION" | sed 's/\./[.]/g')"
NOTES_FILE="$(mktemp)"

awk -v re="^## ${ESCAPED_VERSION}([[:space:]]|$)" '
  $0 ~ re        { in_section = 1; next }
  in_section && /^## [0-9]/ { exit }
  in_section     { print }
' CHANGELOG.md > "$NOTES_FILE"

# Collapse runs of blank lines for cleaner release notes
awk 'NF { print; blank = 0; next }
     !blank { print; blank = 1 }' "$NOTES_FILE" > "${NOTES_FILE}.clean"
mv "${NOTES_FILE}.clean" "$NOTES_FILE"

if [ ! -s "$NOTES_FILE" ]; then
  echo "WARNING: extracted release notes are empty. Creating release with title only." >&2
  echo "(See ${NOTES_FILE} if you want to inspect what was extracted.)" >&2
  if gh release create "v${NEW_VERSION}" --title "$RELEASE_TITLE" --notes "Release v${NEW_VERSION}. See CHANGELOG.md for details."; then
    rm -f "$NOTES_FILE"
  fi
else
  if gh release create "v${NEW_VERSION}" --title "$RELEASE_TITLE" --notes-file "$NOTES_FILE"; then
    rm -f "$NOTES_FILE"
  else
    echo "" >&2
    echo "WARNING: GitHub Release creation failed (tag was pushed successfully)." >&2
    echo "Retry manually with:" >&2
    echo "  gh release create v${NEW_VERSION} --title \"$RELEASE_TITLE\" --notes-file \"$NOTES_FILE\"" >&2
    echo "(Notes file kept at $NOTES_FILE)" >&2
    exit 1
  fi
fi

echo ""
echo "Done."
echo "  Tag:     v${NEW_VERSION}"
echo "  Release: https://github.com/yorilavi/prompt-optimizer/releases/tag/v${NEW_VERSION}"
echo "  Actions: https://github.com/yorilavi/prompt-optimizer/actions"
