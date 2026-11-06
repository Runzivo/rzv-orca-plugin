#!/usr/bin/env bash
# End-to-end test of the Runzivo recipes against a live Runzivo environment.
# Uses the signed-in rzv profile (RZV_PROFILE, default: the active one) and
# needs Orca (for `orca vm recipe doctor`), git, ssh and python3.
#
#   RZV_PROFILE=<profile> scripts/20-shared-e2e.sh
#
# It creates at most one sandbox at a time and deletes everything it made,
# including after a failure. Evidence goes to $E2E_EVIDENCE (default: a temp
# directory, printed at the end). No credential is written there.
set -euo pipefail

rzv="${RZV_BIN:-$(command -v rzv)}"
case "$rzv" in *[!A-Za-z0-9/._-]*) echo "put rzv on a path without spaces or quotes, or set RZV_BIN" >&2; exit 2 ;; esac
size="${E2E_SIZE:-2vcpu-8gb}"
lifetime="${E2E_LIFETIME:-}"
work="$(mktemp -d "${TMPDIR:-/tmp}/rzv-orca-e2e.XXXXXX")"
evidence="${E2E_EVIDENCE:-$work/evidence}"
mkdir -p "$evidence"
repo="$work/fixture"
instance="orca-e2e-$(date +%s)-$$"
sandbox=""
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$evidence/log.txt" >&2; }
fail() { log "FAIL: $*"; exit 1; }
field() { python3 -I -c 'import json,sys; d=json.load(sys.stdin)
for k in sys.argv[1].split("."): d=d[k] if not isinstance(d,list) else d[int(k)]
print(d if not isinstance(d,(dict,list)) else json.dumps(d))' "$1"; }

cleanup() {
  status=$?
  if [ -n "$sandbox" ]; then
    log "cleanup: deleting $sandbox"
    "$rzv" sandboxes delete "$sandbox" --json >/dev/null 2>&1 || true
  fi
  rm -rf "$repo"
  if [ "$status" -eq 0 ]; then log "PASS"; else log "exit $status"; fi
  log "evidence: $evidence"
}
trap cleanup EXIT

# Orca's environment for one workspace create.
orca_env() {
  env ORCA_VM_INSTANCE_ID="$instance" ORCA_WORKSPACE_NAME="E2E check" \
    ORCA_RECIPE_RESULT_SCHEMA_VERSION=2 ORCA_REPO_PATH="$repo" \
    ORCA_REPO_REF_HEAD="$commit" ORCA_REPO_BRANCH="e2e-branch" ORCA_REPO_URL="$remote" "$@"
}
payload() { python3 -I -c 'import json,sys; print(json.dumps({"schemaVersion":1,"mode":sys.argv[1],"recipeResult":json.load(open(sys.argv[2]))}))' "$1" "$work/result.json"; }

log "rzv: $("$rzv" --version)"
"$rzv" help orca >/dev/null || fail "this rzv has no orca commands"
listing="$("$rzv" sandboxes list --json)"
echo "$listing" | python3 -I -c 'import json,sys; d=json.load(sys.stdin)
running=[s["id"] for s in d["sandboxes"] if s["status"] in ("pending","starting","running")]
assert not running, "sandboxes already running: %s" % running
print("sizes", d["sizes"], "lifetimes", d["lifetimes"])' | tee -a "$evidence/log.txt" >&2 || fail "the workspace has no free sandbox slot"

# A fixture repo whose remote carries a fake token that must never reach the VM.
git init -q -b main "$repo"
git -C "$repo" -c user.name=E2E -c user.email=e2e@example.com commit -q --allow-empty -m "fixture"
printf 'hello\n' > "$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" -c user.name=E2E -c user.email=e2e@example.com commit -q -m "readme"
remote="https://e2e-user:fake-token-1234@example.com/acme/fixture.git"
git -C "$repo" remote add origin "$remote"
commit="$(git -C "$repo" rev-parse HEAD)"
# Orca's doctor runs the shipped recipe commands verbatim, with RZV_BIN
# pointing at the rzv under test.
python3 -I - "$(dirname "$0")/../recipes/runzivo-$size.json" "$rzv" "$repo/orca.yaml" <<'PY'
import json, sys
recipe, rzv, out = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
pre = "RZV_BIN='%s'; " % rzv
lines = ["environmentRecipes:", "  - id: runzivo-e2e", "    name: Runzivo e2e", "    checkoutMode: provisioned-root"]
for step in ("create", "suspend", "resume", "destroy"):
    lines.append("    %s: %s" % (step, json.dumps(pre + recipe[step])))
open(out, "w").write("\n".join(lines) + "\n")
PY

log "1. Orca doctor (static)"
orca vm recipe doctor runzivo-e2e --repo-path "$repo" --json > "$evidence/doctor.json" || true
python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); d=d.get("result",d)
bad=[c for c in d["checks"] if c["status"]!="pass"]; print(json.dumps(bad)); sys.exit(1 if [c for c in bad if c["status"]=="fail"] else 0)' "$evidence/doctor.json" >&2 || fail "doctor reported a failure"

log "2. Orca doctor --provision (Orca runs create, validates the result, runs destroy)"
orca vm recipe doctor runzivo-e2e --repo-path "$repo" --provision --json > "$evidence/doctor-provision.json" || true
python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); d=d.get("result",d); print("ok", d.get("ok")); sys.exit(0 if d.get("ok") else 1)' "$evidence/doctor-provision.json" >&2 || fail "doctor --provision did not pass (see doctor-provision.json)"
left="$("$rzv" orca status --json | python3 -I -c 'import json,sys; print(sum(s["status"] in ("pending","starting","running","stopped") for s in json.load(sys.stdin)["sandboxes"]))')"
[ "$left" = 0 ] || fail "doctor --provision left $left sandbox(es) behind"

# doctor --provision deletes its sandbox asynchronously. On a small pool the
# next create can see 409 sandbox_capacity_busy until that delete finishes.
for _ in $(seq 1 40); do
  busy="$("$rzv" orca status --json | python3 -I -c 'import json,sys
print(sum(1 for s in json.load(sys.stdin)["sandboxes"] if s["status"] in ("pending","starting","stopping","deleting","cleanup_pending")))')"
  [ "$busy" = 0 ] && break
  sleep 15
done
log "3. create"
orca_env "$rzv" orca create --size "$size" ${lifetime:+--lifetime "$lifetime"} > "$work/result.json" 2> "$evidence/create.stderr"
sandbox="$(field userData.sandboxId < "$work/result.json")"
root="$(field connection.projectRoot < "$work/result.json")"
alias="$(field connection.target.configHost < "$work/result.json")"
cp "$work/result.json" "$evidence/create.result.json"
log "   sandbox $sandbox at $root via $alias"

log "4. create again with the same Orca instance returns the same sandbox"
orca_env "$rzv" orca create --size "$size" ${lifetime:+--lifetime "$lifetime"} > "$work/again.json" 2>> "$evidence/create.stderr"
[ "$(field userData.sandboxId < "$work/again.json")" = "$sandbox" ] || fail "a retried create made a second sandbox"

log "5. SSH: checkout, branch, remotes without the token, AI tool presence"
ssh -o BatchMode=yes "$alias" "cd $root && git rev-parse HEAD && git branch --show-current && git remote -v && cat README.md && uname -a && (command -v claude codex node || true)" > "$evidence/ssh.txt"
grep -q "^$commit$" "$evidence/ssh.txt" || fail "the sandbox checkout is not at $commit"
grep -q "^e2e-branch$" "$evidence/ssh.txt" || fail "wrong branch"
grep -q "fake-token" "$evidence/ssh.txt" && fail "a remote credential reached the sandbox"
grep -q "https://example.com/acme/fixture.git" "$evidence/ssh.txt" || fail "remote missing"
scp -q -o BatchMode=yes "$repo/README.md" "$alias:$root/copied.md" || fail "scp failed"

log "6. expiry and lifetime"
"$rzv" sandboxes get "$sandbox" --json > "$evidence/get-running.json"
python3 -I -c 'import json,sys,datetime as t; s=json.load(open(sys.argv[1]))["sandbox"]; want=int(sys.argv[2] or 8)
assert s["lifetime_hours"] in (want,0), s; assert s["expires_at"], s; assert 0 < s["remaining_seconds"] <= 24*3600, s
print("expires", s["expires_at"], "remaining", s["remaining_seconds"])' "$evidence/get-running.json" "${lifetime%h}" >&2 || fail "expiry fields wrong"

log "7. suspend stops the sandbox and its charge"
payload suspend | "$rzv" orca suspend 2> "$evidence/suspend.stderr"
c1="$("$rzv" sandboxes get "$sandbox" --json | tee "$evidence/get-stopped.json" | field sandbox.credits_used)"
[ "$(field sandbox.status < "$evidence/get-stopped.json")" = stopped ] || fail "not stopped"
sleep "${E2E_STOPPED_SECONDS:-90}"
c2="$("$rzv" sandboxes get "$sandbox" --json | field sandbox.credits_used)"
log "   credits while stopped: $c1 -> $c2"
[ "$c1" = "$c2" ] || fail "credits grew while stopped"

log "8. resume reconnects to the same sandbox and checkout"
payload resume | "$rzv" orca resume > "$work/resumed.json" 2> "$evidence/resume.stderr"
[ "$(field userData.sandboxId < "$work/resumed.json")" = "$sandbox" ] || fail "resume changed the sandbox"
ssh -o BatchMode=yes "$alias" "test -f $root/copied.md && cd $root && git rev-parse HEAD" | grep -q "^$commit$" || fail "files lost across suspend and resume"
sleep 65
c3="$("$rzv" sandboxes get "$sandbox" --json | field sandbox.credits_used)"
log "   credits after a running minute: $c2 -> $c3"
python3 -I -c 'import sys; sys.exit(0 if float(sys.argv[2]) > float(sys.argv[1]) else 1)' "$c2" "$c3" || fail "no equivalent minutes charged while running"

log "9. destroy deletes the sandbox and its SSH config"
payload destroy | "$rzv" orca destroy 2> "$evidence/destroy.stderr"
st="$("$rzv" sandboxes get "$sandbox" --json 2>/dev/null | field sandbox.status || echo deleted)"
case "$st" in deleting|deleted|cleanup_pending) ;; *) fail "status after destroy: $st" ;; esac
[ ! -e "$HOME/.ssh/rzv/$sandbox.conf" ] || fail "SSH config left behind"
sandbox=""
log "   status after destroy: $st"
