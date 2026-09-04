# RFC 0003: Task status

- Feature Name: task-status
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0005

## Summary

`DataMigration::Task` records operator-owned data migration progress. Status values are `started`, `performing`, `paused`, and `completed`. Table name is `data_migration_tasks`.

## Motivation

A one-shot rake task without Task rows runs, then leaves no recorded status for a later operator. Renaming enum values without a numbered RFC breaks in-flight rows.

## Guide-level explanation

`DataMigration::Task.prepare(name, pause_minutes:, jobs_limit:)` creates a row. Optional polymorphic `operator` is filled from `DataMigration.config.operator_resolver`. `pause_minutes` and `jobs_limit` are non-negative integers when present. Default `jobs_limit` comes from configuration.

## Reference-level explanation

Status strings: `started`, `performing`, `paused`, `completed`. `requires_pause?` is true when `pause_minutes` is positive and status is not paused. Job transitions that move these statuses are RFC 0005.

## Registrar

Status names: `started`, `performing`, `paused`, `completed`. Table: `data_migration_tasks`.

## Drawbacks

Every run writes a row. Operators must interpret paused versus completed. Enum growth is a later RFC.

## Rationale and alternatives

A boolean `done` flag would hide pause and in-flight work. Schema-migration `up`/`down` implies reversibility this kit refuses. Doing nothing leaves operators grepping logs.

## Prior art

Rails schema `schema_migrations` versions, GoodJob/ActiveJob status rows, and data-migrate gems that still ride `db/migrate`. RFC 0002 keeps data work off the schema path. RFC 0004 is the operator run path that creates these rows.

## Unresolved questions

Whether the status enum needs extra values when a second queue adapter is documented.
