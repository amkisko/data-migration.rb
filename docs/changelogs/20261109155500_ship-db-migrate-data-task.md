# Ship db:migrate:data task

## Decisions

- Add a Railtie-loaded `db:migrate:data` rake task that selects migrations with `VERSION=` and/or `NAME=`.
- List available migrations and latest task status when both selectors are blank.
- Update generator USAGE, README, and RFC 0001/0002/0004 to the `bin/rails`-safe form.

## Effects

- Selector resolves timestamp, full stem, and name suffix.
- Generator USAGE no longer documents a positional `bin/rails` argument.

## Next

- Merge with issue #5.

## Source

- https://github.com/amkisko/data-migration.rb/issues/5
- `lib/data_migration/selector.rb`
- `lib/data_migration/railtie.rb`
- `lib/data_migration/tasks/data_migration.rake`
