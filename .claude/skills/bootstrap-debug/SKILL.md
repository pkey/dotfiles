---
name: bootstrap-debug
description: Investigate dotfiles bootstrap failures by reading the most recent saved bootstrap log and identifying what failed and why.
disable-model-invocation: false
---

# Bootstrap Debug

Investigate the most recent failed `./bootstrap.sh` run.

## Where the logs are

Bootstrap saves a timestamped log to `$DOTFILES/.bootstrap-logs/` whenever the run hits errors (gitignored). The live log of the current/last run is always at `/tmp/cfix_bootstrap.log`. The ERR-trap summary, if any, is at `/tmp/cfix_last_error`.

## Process

1. **Find the latest log.** If the user passes a path, use that. Otherwise:
   ```bash
   ls -t "$DOTFILES/.bootstrap-logs"/*.log 2>/dev/null | head -1
   ```
   If none exist, fall back to `/tmp/cfix_bootstrap.log`. If still nothing, tell the user and stop.

2. **Pull out the failures.** Errors typically look like:
   - `Error:` / `error:` lines (Homebrew formula errors, etc.)
   - `... has failed!` / `... failed!` (bootstrap's own status lines)
   - `❌` markers
   - `brew bundle failed!` summary

   ```bash
   grep -nE '(^Error[: ]|^error[: ]| failed!|has failed!|❌)' <log>
   ```

   Then read 10–20 surrounding lines for each hit to get context.

3. **Also check `/tmp/cfix_last_error`** if it exists — it has the trapped command, line number, and exit code from the last `set -e` failure.

4. **Diagnose.** Common patterns:
   - `Error: same file:` during `brew` pour → stale backup in `~/Library/Caches/Homebrew/Backup/`. Suggest removing the conflicting file or `brew uninstall --force <pkg>` then reinstall.
   - `post-install step did not complete successfully` → suggest `brew postinstall <pkg> --verbose`.
   - `Tier 2 configuration` warnings on macOS pre-release → noise, not the cause; ignore.
   - `brew bundle failed! N Brewfile dependencies failed to install` → the real error is earlier in the log, find it.
   - Network / `curl` failures → likely transient, suggest retry.

5. **Report.** Give the user:
   - Which log was inspected (path)
   - Each failure: what failed, the relevant excerpt, the likely cause
   - A concrete next step per failure (command to run or file to edit)

Keep the report compact — don't paste the entire log, only the relevant excerpts.
