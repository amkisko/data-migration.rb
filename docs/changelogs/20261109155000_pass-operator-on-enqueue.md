# Pass operator on enqueue

## Decisions

- Accept `operator:` on `perform_now`, `perform_later`, and `prepare`; store it on the Task before the job is enqueued.
- Fall back to `operator_resolver` when no operator is passed.
- Strip `operator` from job kwargs so ActiveJob receives only migration arguments.
- Assign monitoring `current_user` / audited user from the Task operator so ambient resolver state cannot override it.

## Effects

- Regression covers explicit kwargs operator, resolver fallback, and ActionReporter overwrite.

## Next

- Merge with issue #1.

## Source

- https://github.com/amkisko/data-migration.rb/issues/1
- `lib/data_migration/task.rb`
- `lib/data_migration/config.rb`
