# Failed task cleanup

## Participants

- Andrei Makarov

## Decisions

- Record a checked-in migration job that raises as failed.
- Check out every successfully checked-in job on success, pause, and exception.
- Serialize current_jobs updates by locking and reloading each task row.
- Persist failed status and checkout in one task update.
- Let checkout bypass migration-file validation after work has started.
- Mark continuation dispatch errors as failed after the current job checks out.
- Clear a migration class's pending enqueue request on every exit.
- Keep completed_at for successful completion only.
- Leave cancelled out until an operator cancellation operation exists.

## Effects

- A focused regression run reproduced five failures covering unavailable files, invalid migration classes, execution exceptions, leaked enqueue state, and paused jobs.
- RFC 0006 adds failed to the public task status contract.
- Regression coverage includes foreground batching with one available job slot.
- Regression coverage reproduced lost job slots from stale task instances and cleanup blocked by a missing migration file.
- Regression coverage reproduced a queue error leaving a task performing without an active or scheduled job.

## Next

- Release the fix and repair affected task rows after confirming their queue jobs are no longer running.

## Source

- RFC 0006.
- lib/data_migration/job.rb.
- lib/data_migration/task.rb.
- spec/data_migration/job_spec.rb.
