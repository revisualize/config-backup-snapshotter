#!/usr/bin/env bats
# Tests for config_backup_snapshotter.sh. Run with: bats test/

setup() {
  export CONFIG_SNAPSHOT_ROOT="$(mktemp -d)"
  export CONFIG_SNAPSHOT_RETENTION=3
  WORK="$(mktemp -d)"
  printf 'alpha\n' > "${WORK}/a.conf"
  printf 'beta\n'  > "${WORK}/b.conf"
  export CONFIG_SNAPSHOT_WATCHED="${WORK}/a.conf:${WORK}/b.conf"
  source "${BATS_TEST_DIRNAME}/../config_backup_snapshotter.sh"
}
teardown() { rm -rf "${CONFIG_SNAPSHOT_ROOT}" "${WORK}"; }

@test "snapshot creates a dated directory with a manifest" {
  command_snapshot first
  local d; d="$(latest_snapshot_directory)"
  [ -d "${d}" ]
  grep -q "a.conf" "${d}/manifest.sha256"
}

@test "snapshot copies each watched file into the snapshot tree" {
  command_snapshot
  local d; d="$(latest_snapshot_directory)"
  [ -f "${d}${WORK}/a.conf" ]
  [ -f "${d}${WORK}/b.conf" ]
}

@test "diff returns 0 when nothing has changed" {
  command_snapshot
  run command_diff
  [ "${status}" -eq 0 ]
}

@test "diff returns 1 after a watched file changes" {
  command_snapshot
  printf 'alpha-modified\n' > "${WORK}/a.conf"
  run command_diff
  [ "${status}" -eq 1 ]
}

@test "retention keeps only the newest N snapshots" {
  for i in 1 2 3 4 5; do sleep 1.01; command_snapshot "s${i}"; done
  local kept; kept="$(find "${CONFIG_SNAPSHOT_ROOT}" -maxdepth 1 -name '2*' -type d | wc -l)"
  [ "${kept}" -eq 3 ]
}

@test "list reports the stored snapshots" {
  command_snapshot
  run command_list
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"files)"* ]]
}
