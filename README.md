# config-backup-snapshotter

[![ci](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/ci.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/ci.yml)
[![test](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/test.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/test.yml)
[![shellcheck](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/shellcheck.yml)
[![bash-compat](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/bash-compat.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/bash-compat.yml)
[![markdown-lint](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/markdown-lint.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/markdown-lint.yml)
[![links](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/links.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/links.yml)
[![content-policy](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/content-policy.yml/badge.svg)](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/content-policy.yml)
[![license: all rights reserved](https://img.shields.io/badge/license-all%20rights%20reserved-lightgrey)](LICENSE)

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
  bash config_backup_snapshotter.sh snapshot before_export_change

# make changes, then:
bash config_backup_snapshotter.sh diff     # what did I actually change?
bash config_backup_snapshotter.sh list     # the change journal
```

## Requirements

Bash 4.2 or newer, GNU coreutils (`cp`, `date`, `head`, `sha256sum`), GNU findutils, and `diff`.

## Tests

```bash
bash test/run_all_tests.sh;
```

The harness runs the bats suite in `test/` and fails if it executed zero tests. The suite exercises snapshotting, the diff exit codes, retention pruning, and listing, all against temporary fixtures so it touches nothing real.

## Continuous integration

Each badge above is its own GitHub Actions workflow in `.github/workflows/`. Every workflow runs on each push and pull request, can be re-run by hand from the Actions tab, and links to its run history.

| Workflow | A green badge means |
|---|---|
| [`ci`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/ci.yml) | `bash test/run_all_tests.sh` passed on Python 3.9 and 3.12 and reported a non-zero count of executed tests, and shellcheck found nothing at style severity. |
| [`test`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/test.yml) | `bash test/run_all_tests.sh` passed on Python 3.9 and 3.12. The run fails if any suite fails or if zero tests executed, and the job summary lists each suite with its test count. |
| [`shellcheck`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/shellcheck.yml) | Every shell script outside `test/fixtures/` parses with `bash -n` and has no shellcheck findings at style severity. |
| [`bash-compat`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/bash-compat.yml) | The test suite passed under every Bash release from the floor stated in Requirements through 5.3, each built from its release source. |
| [`markdown-lint`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/markdown-lint.yml) | Every Markdown file passes markdownlint. |
| [`links`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/links.yml) | Every link in every Markdown file resolved on the latest run. It also runs weekly, because a link can break with no commit here. |
| [`content-policy`](https://github.com/revisualize/config-backup-snapshotter/actions/workflows/content-policy.yml) | Every tracked file meets the publishing rules: UTF-8, LF line endings, no em dashes, scripts documented as `bash name.sh`, and vendor-neutral wording. |

A badge reports the latest run of those checks. What the tool needs on your own host is listed under Requirements.

## License and use

View-only, all rights reserved. This is a reference sample of my work, not open-source. See `LICENSE`.

The full body of work, and how to hire me, are at **[revisualized.com](https://revisualized.com)**.
