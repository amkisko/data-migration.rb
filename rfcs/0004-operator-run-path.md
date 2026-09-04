# RFC 0004: Operator run path

- Feature Name: operator-run-path
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0003

## Summary

Operators generate data migrations under `db/data_migrations` and run them with `bin/rails db:migrate:data`. Data migrations are not reversible and may be applied more than once. README tells operators to avoid implementing data migrations within schema migrations; that Avoid is guidance, not a MUST in this RFC.

## Motivation

A `db/migrate` file that rewrites millions of rows deploys with the schema, wraps work in a transaction, and has no operator pause. Changing the rake task name or the default directory without a numbered RFC breaks operator runbooks.

## Guide-level explanation

Install the gem. Generate the tasks table with `bin/rails g data_migration:install`. Generate a migration with `bin/rails g data_migration create_users`. Run with `bin/rails db:migrate:data 20241207120000_create_users`. Point `DataMigration.config.data_migrations_path` at another directory when the host does not use `db/data_migrations`.

Planning, operator control, batching, tests for critical migrations, and a fresh backup before those runs stay on the operator.

## Reference-level explanation

Task rows validate that the migration file exists. The class name is derived from the file name after stripping a leading timestamp prefix (RFC 0005). Re-running the same file is allowed.

## Registrar

Commands: `bin/rails g data_migration`, `bin/rails g data_migration:install`, `bin/rails db:migrate:data`. Default path: `db/data_migrations`.

## Drawbacks

A second directory and rake task to teach. Non-reversible runs require backups. Re-apply means operators must make `perform` idempotent when they need it.

## Rationale and alternatives

Putting data SQL inside schema migrations would ship with every deploy and would hide operator pause. A one-shot rake task without Task rows would run, then leave no recorded status (RFC 0003). Doing nothing leaves hosts mixing data rewrites into `db/migrate`.

## Prior art

`data-migrate` and similar gems. Rails `db:migrate` as the anti-pattern for large rewrites. RFC 0002 states the Avoid guidance.

## Unresolved questions

Whether a host that uses a second directory layout needs a dedicated path RFC.
