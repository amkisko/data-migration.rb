# Coverage, pressure, and release review

## Decisions

- Require 100% line coverage of packaged `lib/` before cutting 2.1.0.
- Run a pressure-cooker episode with calibrate, L1 ceilings, and N=10 prove cycles alongside engineering audit.
- Ship as minor 2.1.0: new rake CLI surface plus prior issue fixes already on main.

## Effects

- Suite: 79 examples, 0 failures; lib line coverage 100% (290/290).
- Pressure calibrate passed with distinct stage wall_ms; L1 gate passed 10 consecutive proves after timing headroom adjust.
- Job enqueue no longer mutates the migration class each perform; uses a per-instance singleton method.
- Release package prep: VERSION 2.1.0, CHANGELOG dated 2026-11-09, pressure binding committed.

## Next

- Run `ruby usr/bin/release.rb` on a clean tree and confirm the publish prompt.

## Source

- docs/issues/20261109151732_pressure-benchmark.md
- CHANGELOG.md
- lib/data-migration.rb
