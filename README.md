# config-backup-snapshotter

![ci](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/ci.yml/badge.svg)

Dated, manifested snapshots of the configuration files you care about, so that "what changed, and when" has an answer instead of a shrug. Snapshot before a change window, diff afterward, and keep a bounded history as an accidental-change journal.

## What it does

- `snapshot [label]` copies each watched file into a timestamped directory, records a `sha256` manifest, and prunes to the newest N snapshots.
- `diff` shows a unified diff of every watched file against the most recent snapshot, and exits non-zero when anything changed.
- `list` prints the snapshot history with a file count per snapshot.

Rollback is deliberately manual: the snapshots are plain copies, so you restore one with `cp`. Nothing here is magic, which is the point.

## Configuration

All via environment, with sane defaults:

- `CONFIG_SNAPSHOT_ROOT` where snapshots live (default `/var/lib/config_backup_snapshotter`)
- `CONFIG_SNAPSHOT_RETENTION` how many to keep (default `10`)
- `CONFIG_SNAPSHOT_WATCHED` colon-separated list of files to watch

## Usage

```bash
CONFIG_SNAPSHOT_WATCHED="/etc/fstab:/etc/exports" \
  ./config_backup_snapshotter.sh snapshot before_export_change

# make changes, then:
./config_backup_snapshotter.sh diff     # what did I actually change?
./config_backup_snapshotter.sh list     # the change journal
```

## Tests

```bash
bats test/
```

The suite exercises snapshotting, the diff exit codes, retention pruning, and listing, all against temporary fixtures so it touches nothing real.

## Continuous integration

Every push runs `shellcheck` and `bats` on GitHub Actions. The badge is green only when both pass.

## License and use

View-only, all rights reserved. This is a reference sample of my work, not open-source. See `LICENSE`.

The full body of work, and how to hire me, are at **revisualized.com**.
