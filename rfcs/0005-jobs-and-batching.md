# RFC 0005: Jobs and batching

- Feature Name: jobs-and-batching
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0003

## Summary

`DataMigration::Job` runs a task on ActiveJob. `job_check_in!` enforces `jobs_limit`. `pause_minutes` reschedules the job. Calling `enqueue` from `perform` continues the task; omitting it marks the task completed.

## Motivation

Wrapping a whole rewrite in one transaction can exhaust memory and stall the database. Concurrency and pause are the operator valves. Changing those helpers without a numbered RFC breaks hosts that already batch on `enqueue`.

## Guide-level explanation

The job finds the Task, notifies monitoring, requires the migration file, and instantiates the class derived from the file name. `job_check_in!` records the ActiveJob id. A second check-in with the same id and different args raises `JobConflictError`. Crossing `jobs_limit` raises `JobConcurrencyLimitError`.

If `requires_pause?` is true, the job sets status `paused` and `perform_later` with `wait: pause_minutes.minutes`, then returns.

Otherwise status becomes `performing`, `perform` runs, then `job_check_out!`. If `perform` called `enqueue`, another Job is queued (or run inline when `background: false`). If `enqueue` was not called, status becomes `completed`.

## Reference-level explanation

The migration class MUST implement `perform`. Queue name comes from `DataMigration.config.job_queue_name`. Status names are RFC 0003. File-to-class mapping is RFC 0004.

## Registrar

Methods: `job_check_in!`, `job_check_out!`, `enqueue`. Errors: `JobConcurrencyLimitError`, `JobConflictError`.

## Drawbacks

Hosts must structure `perform` as batches that call `enqueue`. Pause waits are wall-clock, not load-based. Discarding on `StandardError` needs monitoring.

## Rationale and alternatives

One transaction for the whole rewrite is simpler and stalls the database. Sidekiq-only APIs would drop ActiveJob hosts. Doing nothing leaves operators to loop in rake with no concurrency cap.

## Prior art

ActiveJob, GoodJob batches, and Rails data-migrate without pause. RFC 0003 is the status machine this job drives.

## Unresolved questions

Whether job concurrency limits and pause behavior need extra rules when a second queue adapter is documented.
