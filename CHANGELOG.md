# CHANGELOG

## Unreleased

- Keep the data migration operator on the task when enqueueing and in monitoring context.

## 2.0.1 (2026-10-28)

- Confirm gem release from a clean tree before tagging.

## 2.0.0 (2026-09-04)

- BREAKING: Require Ruby 3.4 or newer.
- Add `rfcs/` starter pack: process (RFC 0001), positioning (RFC 0002), and Standards Track design RFCs 0003–0005 for task status, operator run path, and jobs.
- Report stopped data migrations as failed and release their job slots (RFC 0006).
- Serialize task job-slot updates across worker instances.
- Limit the gem package to runtime code and release documentation.

## 1.3.0

- Fix data migration tasks table generator
- Update README with better examples

## 1.2.0

- Wrap Task.status enum with ActiveRecord version check

## 1.1.0

- Fix gem main file name to be `data-migration.rb` instead of `data_migration.rb`

## 1.0.0

- Initial version
