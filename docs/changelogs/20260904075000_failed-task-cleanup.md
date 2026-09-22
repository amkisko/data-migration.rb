# Failed task cleanup

## Decisions

- Add failed as a terminal task status.
- Preserve job backend error reporting by raising migration exceptions after recording task failure.
- Avoid storing exception text in task rows.
- Lock task rows while changing current_jobs.
- Persist failure status and job checkout together.

## Effects

- Failed and paused jobs no longer leave their job id in current_jobs.
- A failed batch cannot leak its enqueue request into a later run on the same worker thread.
- Foreground batching still works when jobs_limit is one.
- Missing migration files now leave a failed task instead of an unstarted task.
- Separate task instances no longer overwrite each other's active job slots.
- Checkout still completes when the migration file disappears after check-in.
- A queue error while dispatching the next batch leaves the task failed.

## Source

- RFC 0006.
- usr/docs/issues/20260904075000_failed-task-cleanup.md.
- CHANGELOG.md 2.0.0.
