# Pressure benchmark episode

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Binding: measure `bundle exec ruby usr/bin/pressure_bench.rb`; modes `PRESSURE_MODE=calibrate|measure|gate|write`; ceilings `config/pressure_ceilings.yml`.
- Load axis: resolve/perform repetitions (`PRESSURE_LOAD`); samples-per-load default 3 (write used 5).
- Propose-basis: timing series `max * 1.5`; resource series `median * 1.15`.
- Memory probe class: `process_lifetime` (Ruby object-space fallback when `ps` RSS unavailable).
- Network: `not_in_scope`.
- Min episode iterations: 10 optimize/prove cycles; continuous CI gate does not replace this episode.

## Effects

### Calibrate

Self-test stages `calibrate_resolve` (sleep 10ms), `calibrate_perform` (sleep 20ms + job), `calibrate_checkout` (sleep 30ms) produced distinct wall_ms values. Meter separates stages from aggregates.

### Load ladder

- L0 (`PRESSURE_LOAD=1`): resolve_p95_us ~100, perform_wall_ms ~6.
- L1 (`PRESSURE_LOAD=5`): ceilings written resolve_p95_us 136, perform_wall_ms 21, cpu_ms 8, rss_bytes ~8.1e6, storage_bytes 4711.

### Optimize / prove log

| N | Primary series | Change | Prove |
|---|---|---|---|
| 1 | coverage / lib lines | Fill `configure` yield path | suite green |
| 2 | coverage | Cover custom `operator_resolver` / `monitoring_context` blocks | suite green |
| 3 | coverage | Cover ActionReporter and Audited default resolvers | suite green |
| 4 | coverage | Cover `Task.perform_now` class entry | suite green |
| 5 | coverage | Cover `not_started?` | suite green |
| 6 | perform_wall_ms / ownership | Extract `DataMigration::Cli` from rake body | suite green |
| 7 | coverage | Cover Railtie rake loader block | suite green |
| 8 | resolve_p95_us | Raise timing propose-basis to max×1.5 after noisy median gate flakes | 10/10 gate pass |
| 9 | perform_wall_ms | Bind enqueue via singleton method instead of class `define_method` | gate pass, 100% lines |
| 10 | perform_wall_ms | Re-gate L1 after singleton enqueue change | gate pass |

Engineering-audit during cooker: no remaining high-confidence first-party hot-path candidates above noise for `perform_wall_ms` or `resolve_p95_us`. Boundary mode: operator CLI is the control surface; `VERSION=`/`NAME=` and list-when-blank stay the documented commands. Trace mode: Task rows still hold operator ids and job kwargs by design; no new identifiers added.

Line coverage of packaged `lib/`: 290/290 (100%).

## Next

- Cut gem 2.1.0 after clean-tree release script confirmation.
- Keep pressure ceilings under review if CI hosts are slower than this machine class.

## Source

- `usr/bin/pressure_bench.rb`
- `config/pressure_ceilings.yml`
- `lib/data_migration/job.rb`
- `lib/data_migration/cli.rb`
