# TODO

Known issues and deferred work. Not a roadmap — just things that are understood but not yet fixed.

## Installer: run-from-target detection misses symlinked paths

**Where:** `install.sh` (the `"${SCRIPT_DIR}" = "${TARGET}"` check in the Detection block) and `install.ps1` (the `$ScriptDir -eq $Target` check).

**What:** The "you're running the installer from inside the target directory" guard is a literal string comparison. `SCRIPT_DIR` comes from `cd "$(dirname "$0")" && pwd` (resolved), while `TARGET` is built from `$HOME` verbatim (unresolved). If the two differ only by a symlink component — e.g. `HOME=/tmp/x` but the script is invoked via `/private/tmp/x/...` on macOS — the guard fails to fire.

**Why it matters:** When the guard misses, the script falls into local-copy mode. `backup_existing` then moves the target aside — which is the script's own directory — and the subsequent `cp "${SCRIPT_DIR}/SKILL.md"` fails with "No such file". Net result: an empty `prompt-optimizer/`, the real contents sitting in `prompt-optimizer.bak.<timestamp>/`, and exit 1. Destructive when it fires, though it needs an unusual `$HOME` (symlinked or non-canonical) to trigger. Normal macOS/Linux/Windows home directories are not affected.

**Fix sketch:** Compare canonical paths on both sides. In `install.sh`, resolve both with `cd … && pwd -P` (portable; avoids depending on `realpath`/`readlink -f`, which differ across macOS and Linux). In `install.ps1`, normalize both with `[System.IO.Path]::GetFullPath()` and compare case-insensitively (Windows paths are case-insensitive; `$env:USERPROFILE` can also carry a trailing slash).

**Test plan:** Sandboxed `HOME` pointing at a symlink (e.g. `ln -s "$real" "$link"; HOME="$link"`), invoke the script via the real path from inside the target. Expect the "running from inside the target" message and exit 0, with the target directory untouched. Repeat with `HOME` as the real path and invocation via the symlink.
