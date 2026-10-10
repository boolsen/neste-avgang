# Neste avgang

Next departures for saved bus favorites (exact platform + line) on Garmin watches. Norway (Entur) first.

## Setup
1. Install Connect IQ SDK Manager, latest SDK, devices Venu 3, Venu 3S, Venu 4 (41/45 mm) + Vivoactive 6.
2. Developer key: see `docs/superpowers/plans/2026-10-10-garmin-bus.md`, Task 1 Step 2 (`~/.garmin/developer_key.der`).

## Commands
- `make sim` – start simulator
- `make run DEVICE=venu445mm` – build + run in simulator
- `make test DEVICE=venu445mm` – unit tests (simulator must be running)
- `make build DEVICE=venu445mm` – build `bin/GarminBus-venu445mm.prg`
- `make icons` – regenerate launcher icons (per device) and `store/icon-500.png`
- `make export` – build store package `bin/NesteAvgang.iq`

Supported devices: venu3, venu3s, venu441mm, venu445mm, vivoactive6.

## Sideload
Copy `bin/GarminBus-<device>.prg` to `GARMIN/APPS/` on the watch via OpenMTP.

## Fixtures
Test fixtures are captured Entur responses in `test/fixtures/json/`. Regenerate `test/Fixtures.mc` with
`python3 -I tools/json2mc.py test/fixtures/json/*.json > test/Fixtures.mc`.

## Adding a language
Add `resources-<lang>/strings/strings.xml` (e.g. `resources-eng`) with the same ids and add the language to `manifest.xml`.

## Data
Data fra Entur (NLOD)
