#!/usr/bin/env bash
# Live check that cancelling a create the way Orca does (SIGTERM, then
# SIGKILL 5 seconds later) deletes the sandbox it made. Same requirements as
# 20-shared-e2e.sh; run it after that one, with a free sandbox slot.
#
#   RZV_PROFILE=<profile> scripts/30-shared-cancel.sh
set -euo pipefail

rzv="${RZV_BIN:-$(command -v rzv)}"
work="$(mktemp -d "${TMPDIR:-/tmp}/rzv-orca-cancel.XXXXXX")"
evidence="${E2E_EVIDENCE:-$work/evidence}"
mkdir -p "$evidence"
repo="$work/fixture"
instance="orca-cancel-$(date +%s)-$$"
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$evidence/cancel-log.txt" >&2; }
fail() { log "FAIL: $*"; exit 1; }
find_ids() { # ids of sandboxes whose name ends with this run's instance suffix
  "$rzv" orca status --json | python3 -I -c 'import json,sys; suffix=sys.argv[1]
for s in json.load(sys.stdin)["sandboxes"]:
    if s["name"].endswith(suffix): print(s["id"], s["status"])' "$1"
}

git init -q -b main "$repo"
git -C "$repo" -c user.name=E2E -c user.email=e2e@example.com commit -q --allow-empty -m fixture
commit="$(git -C "$repo" rev-parse HEAD)"
# The sandbox name ends with the first 8 letters and digits of the instance id.
suffix="$(printf '%s' "${instance#orca-}" | tr -cd 'a-z0-9' | cut -c1-8)"

cleanup() {
  status=$?
  while read -r id _; do
    [ -n "$id" ] && "$rzv" sandboxes delete "$id" --json >/dev/null 2>&1 || true
  done < <(find_ids "$suffix" 2>/dev/null || true)
  rm -rf "$repo"
  if [ "$status" -eq 0 ]; then log "PASS"; else log "exit $status"; fi
}
trap cleanup EXIT

log "start create, then SIGTERM it once its sandbox exists"
env ORCA_VM_INSTANCE_ID="$instance" ORCA_WORKSPACE_NAME="cancel" ORCA_RECIPE_RESULT_SCHEMA_VERSION=2 \
  ORCA_REPO_PATH="$repo" ORCA_REPO_REF_HEAD="$commit" ORCA_REPO_BRANCH=main \
  "$rzv" orca create > "$evidence/cancel.stdout" 2> "$evidence/cancel.stderr" &
pid=$!
for _ in $(seq 1 60); do
  [ -n "$(find_ids "$suffix")" ] && break
  kill -0 "$pid" 2>/dev/null || fail "create ended before the sandbox appeared"
  sleep 1
done
id="$(find_ids "$suffix" | awk 'NR==1{print $1}')"
[ -n "$id" ] || fail "no sandbox appeared within 60 seconds"
log "sandbox $id exists; sending SIGTERM"
kill -TERM "$pid"
for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
if kill -0 "$pid" 2>/dev/null; then kill -KILL "$pid"; fail "create still ran 5 seconds after SIGTERM"; fi
wait "$pid" || true
[ ! -s "$evidence/cancel.stdout" ] || fail "a cancelled create printed a result"
grep -q "Deleted sandbox $id after the failed create" "$evidence/cancel.stderr" || fail "create did not report deleting $id"
st="$("$rzv" sandboxes get "$id" --json 2>/dev/null | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["sandbox"]["status"])' || echo deleted)"
case "$st" in deleting|deleted|cleanup_pending) log "status after cancel: $st" ;; *) fail "status after cancel: $st" ;; esac
[ ! -e "$HOME/.ssh/rzv/$id.conf" ] || fail "SSH config left behind"
