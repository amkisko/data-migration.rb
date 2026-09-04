# RFC 0002: Problem and positioning

- Feature Name: problem-and-positioning
- Type: Informational
- Status: Stable
- Created: 2026-08-17
- Updated: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0003, RFC 0004, RFC 0005

## Summary

data-migration is a kit for operator-run data migrations on ActiveRecord, with ActiveJob for background batches. Tasks are recorded, re-runnable, and owned by an operator.

## Motivation

Schema migrations are the wrong place for one-shot data rewrites. A `db/migrate` file that rewrites millions of rows deploys with the schema, wraps work in a transaction, and has no operator pause. Operators should avoid implementing data migrations within schema migrations. Data migrations are not reversible, may be applied more than once, and stay under operator control.

Large rewrites need batching. Wrapping the whole job in a transaction can exhaust memory and stall the database. ActiveJob batches plus `DataMigration::Task` record progress. Status values are `started`, `performing`, `paused`, and `completed`. `jobs_limit` and `pause_minutes` cap concurrency.

The public contract is the generator (`bin/rails g data_migration`), the rake entry `bin/rails db:migrate:data`, the tasks table from `bin/rails g data_migration:install`, the Task status enum, and the Job helpers.

## Guide-level explanation

Install the gem. Generate the tasks table. Generate a migration with `bin/rails g data_migration create_users`. Run it with `bin/rails db:migrate:data 20241207120000_create_users`. Point `DataMigration.config.data_migrations_path` at `db/data_migrations` when the host uses another directory. Use ActiveJob for batches.

## Drawbacks

A second migrate path to operate. Non-reversible runs require backups. Batching requires `enqueue` from `perform`.

## Rationale and alternatives

A separate task table and rake task keep data rewrites off the schema migrate path. Putting data SQL inside schema migrations would ship with every deploy and would hide operator pause. A one-shot rake task without Task rows would run, then leave no recorded status for a later operator.

## Prior art

Rails `db:migrate`, data-migrate gems, ActiveJob. Contract detail is RFC 0003 through RFC 0005.

## Unresolved questions

Whether the Task status enum needs extra values across Rails versions (RFC 0003).

Whether job concurrency limits and pause behavior need extra rules when a second queue adapter is documented (RFC 0005).
