# Report job exceptions

## Decisions

- Remove `discard_on StandardError` from `DataMigration::Job` so raised migration failures reach ActiveJob adapters and host reporters.
- Keep task `failed` status and job-slot checkout from RFC 0006.

## Effects

- `DataMigration::Job.perform_now` re-raises after marking the task failed.
- Regression covers the ActiveJob entry path, not only direct `#perform`.

## Next

- Merge with issue #2; cut notes into `CHANGELOG.md` Unreleased until the next gem version.

## Source

- https://github.com/amkisko/data-migration.rb/issues/2
- `lib/data_migration/job.rb`
- `spec/data_migration/job_spec.rb`
- `rfcs/0006-failed-task-cleanup.md`
