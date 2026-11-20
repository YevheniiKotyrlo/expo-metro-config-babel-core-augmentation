#!/usr/bin/env bash
# Installs this app with npm and type-checks transformer.ts, which imports a type from
# @expo/metro-config/babel-transformer, with skipLibCheck off (tsconfig.transformer.json).
# The control (tsconfig.control.json) adds the package's own build/ts-declarations/babel-core.d.ts,
# the file build/babel-core.js's first line references and build/babel-core.d.ts does not.
# Exit status: 1 while transformer.ts fails with TS2724 on loadPartialConfigSync alone and the
# control passes; 0 once transformer.ts type-checks; 2 when a step fails or the result is neither.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logs="${REPRO_LOGS:-$root/.logs}"
message="has no exported member named 'loadPartialConfigSync'"

# The verdict from what the steps printed: ok, defect, or other (with the reason on the same line).
verdict() { # install status, versions status, doctor status, check status, check log, control status, control log
  local install_status="$1" versions_status="$2" doctor_status="$3" check_status="$4" check_log="$5" control_status="$6" control_log="$7"
  local errors defects
  if [ "$install_status" -ne 0 ]; then echo "other: npm install exited $install_status"; return; fi
  if [ "$versions_status" -ne 0 ]; then echo "other: printing the versions exited $versions_status"; return; fi
  if [ "$doctor_status" -ne 0 ]; then echo "other: expo-doctor exited $doctor_status"; return; fi
  errors="$(grep -c 'error TS' "$check_log")"
  if [ "$check_status" -eq 0 ] && [ "$errors" -eq 0 ]; then echo "ok: transformer.ts type-checks"; return; fi
  defects="$(grep -c "build/babel-core.d.ts.*error TS2724: .*$message" "$check_log")"
  if [ "$check_status" -eq 0 ] || [ "$errors" -eq 0 ] || [ "$defects" -ne "$errors" ]; then
    echo "other: tsc exited $check_status with $errors error(s), $defects of them TS2724 on loadPartialConfigSync"
    return
  fi
  if [ "$control_status" -ne 0 ] || grep -q 'error TS' "$control_log"; then
    echo "other: the control exited $control_status"
    return
  fi
  echo "defect: build/babel-core.d.ts fails TS2724 \"$message\", and type-checks once its build/ts-declarations/babel-core.d.ts is loaded"
}

run() { # log, command...
  local log="$1" status
  shift
  echo "\$ $*"
  (cd "$root" && "$@") >"$log" 2>&1
  status=$?
  echo "  exit $status"
  return "$status"
}

main() {
  local install_status versions_status=127 doctor_status=127 check_status=127 control_status=127 result status system node_version npm_version
  system="$(uname -srm)" || system=unknown
  node_version="$(node --version)" || return 2
  npm_version="$(npm --version)" || return 2
  echo "System: $system, node $node_version, npm $npm_version"
  mkdir -p "$logs"
  : >"$logs/check.log"
  : >"$logs/control.log"
  run "$logs/install.log" npm install --no-audit --no-fund --loglevel warn
  install_status=$?
  if [ "$install_status" -eq 0 ]; then
    (cd "$root" && node versions.js)
    versions_status=$?
    run "$logs/doctor.log" npx --yes expo-doctor@latest
    doctor_status=$?
    grep -E 'checks passed|No issues detected|✖' "$logs/doctor.log" | sed 's/^/  /'
    run "$logs/check.log" npx tsc -p tsconfig.transformer.json
    check_status=$?
    grep 'error TS' "$logs/check.log" | sed 's/^/  /'
    run "$logs/control.log" npx tsc -p tsconfig.control.json
    control_status=$?
    grep 'error TS' "$logs/control.log" | sed 's/^/  /'
  fi
  result="$(verdict "$install_status" "$versions_status" "$doctor_status" "$check_status" "$logs/check.log" "$control_status" "$logs/control.log")"
  case "$result" in
    ok:*) status=0 ;;
    defect:*) status=1 ;;
    *) status=2 ;;
  esac
  echo "SUMMARY (exit $status): $result"
  return "$status"
}

if [ "${REPRO_SOURCE_ONLY:-}" != 1 ]; then
  main "$@"
fi
