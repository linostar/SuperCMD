# Add Stop control to interrupt a running command

## Goal
A hung command currently locks its row: the Run button is disabled while running and the Process is never retained, so it can only be killed by quitting the app. Let the user stop a running command from its row and immediately run it again.

## Acceptance Criteria
1. While a command is running, the row's Run button shows a stop icon (SF Symbol "stop.fill") and is enabled; pressing it stops the command.
2. Stop sends SIGTERM to the command's entire process group (the shell and every child it spawned, including pipelines); if the group is still alive after 2 seconds, SIGKILL is sent to the group.
3. After the command exits (normally or via Stop), isRunning is false, the button shows the play icon again, and pressing it reruns the command in the same row.
4. Output printed before the stop stays visible and a final line "[interrupted]" is appended when the exit was caused by Stop.
5. The output pipe is read until EOF before the run is considered finished, so the tail of the output is never dropped on normal exit or on Stop.
6. Output chunks are decoded without dropping data when a multi-byte UTF-8 character is split across reads.
7. When the output panel is visible and the command is not running, a separate chevron button collapses it (preserving the existing collapse ability now that the main button is Run/Stop).
8. Deleting a row whose command is running stops that command's process group before the row is removed.
9. If spawning or signalling fails, the error is shown in the row output and via dataManager.latestError (no silent failure).
10. The Run/Stop and collapse buttons are keyboard-focusable and have accessibility labels ("Run <name>", "Stop <name>", "Hide output").
11. The project builds with zero errors and zero new warnings.
12. Heavy output (e.g. `yes`) never freezes the UI: output reaches the main thread in batches at most every 100ms and is capped at 256 KB, keeping the most recent part behind an "[earlier output truncated]" line, so Stop stays clickable.

## Approach
All changes live in Views/CommandRowView.swift. Foundation's Process cannot place the child in its own process group, so terminate() would only signal the shell and orphan its children; replace it with posix_spawn using POSIX_SPAWN_SETPGROUP (pgid = child pid) so killpg reaches the whole tree. Keep the shell invocation identical (/bin/<shell> -c <command>), stdout and stderr on one pipe read via FileHandle, read on a background thread until EOF, and reap the shell with a blocking waitpid on a second background thread; a per-run DispatchGroup completes when both are done. Row state gains the running pid, that DispatchGroup and a wasInterrupted flag. The SIGKILL escalation is a 2-second DispatchQueue.main.asyncAfter that fires if the run has not finished or any process in the group is still alive (killpg(pid, 0)); either condition guarantees the group id has not been reused. Output is batched to the main thread every 100ms and capped at 256 KB.

## Steps
1. Add row state for the running pid and wasInterrupted; replace Process in runCommand() with posix_spawn (SETPGROUP, one pipe for stdout/stderr) and a process-exit DispatchSource that reaps with waitpid.
2. Make output reading drain fully on exit and decode UTF-8 safely across chunk boundaries.
3. Add stopCommand(): set wasInterrupted, killpg SIGTERM, schedule SIGKILL after 2s if the same pid is still running; surface errno failures.
4. Rework the Run button: play when idle, stop.fill when running, never disabled; add the chevron collapse button shown only when output is visible and idle; add accessibility labels.
5. Call stopCommand() in handleDeleteTap() before deleting when running; append "[interrupted]" on interrupted exit.
6. Build with xcodebuild, then manually verify with "sleep 100", "yes | head -c 1000000000 | wc -c", "trap '' TERM; sleep 100" (forces the SIGKILL path), and a normal "ls -l".

## Deferred Ideas
- Run commands as a login shell (-lc) so Homebrew PATH works — separate fix from the earlier review.
- Stop hard-coding the shell path as /bin/<shell> — separate fix from the earlier review.
- Edit form allows saving empty fields — separate fix from the earlier review.
- Kill running commands when the menu window closes or the app quits.
- A process that leaves the group (setsid/daemon) but keeps the output pipe open leaves the row "running"; Stop cannot reach it. Needs a separate "detach" path.
- Pin GRDB to a version range instead of branch = master (forces a full-history clone and floats on upstream changes).
- Show the exit code (e.g. "[exit 1]") when a command exits non-zero without being stopped.

Last revised: 2026-10-14
