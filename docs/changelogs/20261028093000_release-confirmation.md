# Release confirmation

## Decisions

- Cut patch 2.0.1 for the release operator workflow.
- Reject end of input at the confirmation prompt while accepting an entered empty line or yes.

## Effects

- The confirmation spec failed before the helper was added and passed afterward.
- Updated CHANGELOG.md, the version constant, and path-gem lockfile entries.

## Next

- Review the changes and publish only after the normal clean-tree release gate passes.

## Source

- usr/bin/release.rb
- usr/lib/release_version_check.rb
- spec/release_confirmation_spec.rb
