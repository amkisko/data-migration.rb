# RFC 0006: Failed task cleanup

- Feature Name: failed-task-cleanup
- Type: Standards Track
- Status: Stable
- Created: 2026-09-04
- Author: Andrei Makarov
- Relates: RFC 0003, RFC 0005

## Summary

`DataMigration::Task` gains the terminal status `failed`. A job that starts migration work and then raises records that status, checks out its job entry, and clears its pending batch continuation. Job-slot changes are serialized per task.

## Motivation

A discarded ActiveJob could leave a task in `performing` with its job id in `current_jobs`. The row then claimed an active job and consumed a concurrency slot after execution had stopped. A paused job also returned before checking out.

The four existing statuses cannot report a terminal error. `completed` would claim that all migration work succeeded, while `started` and `paused` would claim that more execution was already expected.

## Guide-level explanation

Operators can query failed tasks through `DataMigration::Task.failed` or inspect `task.failed?`. A failed task keeps `completed_at` empty. Its `current_jobs` hash does not retain the job that stopped.

An operator may correct the migration and explicitly run the same task again through `perform_now` or `perform_later`. A successful retry moves through `performing` to `completed`.

## Reference-level explanation

The task status registrar includes `failed`.

When the migration file is unavailable, the job notifies the configured destination and writes `failed`.

After `job_check_in!` succeeds, a `StandardError` raised while loading, validating, executing, or completing the migration writes `failed` and continues raising. ActiveJob then applies the configured `discard_on StandardError` behavior. An error raised before check-in does not replace the status of another active job.

Every successful check-in has one checkout on success, pause, or exception. Successful migration execution checks out before starting or enqueueing a continuation, so `jobs_limit: 1` supports foreground batching.

Check-in and checkout lock and reload the task row before changing `current_jobs`. Separate workers cannot overwrite another worker's slot from a stale task instance. Failure status and checkout persist in the same update. Checkout skips migration-file validation so cleanup still succeeds if the file disappears after check-in.

An exception after checkout, including failure to enqueue a requested continuation, still marks the task as failed.

The per-thread `enqueue` request and arguments for the migration class are removed on every exit. A failed batch cannot enqueue its stale continuation during a later run on the same worker thread.

`completed_at` is written only when the migration finishes without requesting another batch. Failure does not write a completion time.

## Registrar

Status name: `failed`.

## Drawbacks

Code that treats the four previous status values as exhaustive must handle `failed`. Hosts do not receive a stored exception message from the task row and must use their job backend or monitoring service for error details. Job-slot writes for one task are serialized through its database row.

## Rationale and alternatives

Keeping `performing` preserves compatibility but reports stopped work as active and can block later jobs. Reusing `paused` suggests an automatic continuation that does not exist. Reusing `completed` hides unfinished data work.

A `cancelled` status is not added because the gem has no cancellation operation. Persisting exception text is also omitted because job backends already record errors and exception messages can contain private data.

## Prior art

ActiveJob distinguishes discarded execution from successful completion. GoodJob records terminal execution errors separately from running jobs.

## Unresolved questions

A later RFC may define cancellation if the gem adds an operator cancellation operation.
