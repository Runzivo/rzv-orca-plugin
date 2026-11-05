#!/usr/bin/env bash
# Writes recipes/*.json, one per sandbox size, from the shared shell below.
# Run after changing it; CI fails when the committed recipes differ.
set -euo pipefail
cd "$(dirname "$0")/.."

# Finds rzv as Orca's shell sees it (a desktop app may not have the user's
# PATH), refuses an rzv without the orca commands, then hands over with exec
# so Orca's stdin (lifecycle JSON) and stdout (recipe JSON) pass straight through.
# shellcheck disable=SC2016 # expanded by the shell Orca runs, not here
locate='rzv="${RZV_BIN:-$(command -v rzv 2>/dev/null || true)}"; [ -n "$rzv" ] || rzv="$HOME/.local/bin/rzv"; [ -x "$rzv" ] || { echo "Runzivo: install the rzv CLI first: curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh" >&2; exit 127; }; "$rzv" help orca >/dev/null 2>&1 || { echo "Runzivo: this rzv has no orca commands. Update it: curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh" >&2; exit 127; }; exec "$rzv" orca'

# id|size|name|equivalent-minute multiplier
sizes='2vcpu-8gb|2vcpu-8gb|2 vCPU, 8 GB|1
4vcpu-16gb|4vcpu-16gb|4 vCPU, 16 GB|2
8vcpu-32gb|8vcpu-32gb|8 vCPU, 32 GB|4
16vcpu-64gb|16vcpu-64gb|16 vCPU, 64 GB|8'

json() { # JSON string literal for $1
  local s=${1//\\/\\\\}
  s=${s//\"/\\\"}
  printf '"%s"' "$s"
}

rm -f recipes/*.json
while IFS='|' read -r id size name rate; do
  {
    printf '{\n'
    printf '  "schemaVersion": 1,\n'
    printf '  "id": "runzivo-%s",\n' "$id"
    printf '  "name": %s,\n' "$(json "Runzivo sandbox, $name")"
    printf '  "description": %s,\n' "$(json "A Runzivo Firecracker microVM for this workspace: $name, ${rate}x equivalent minutes while running. Lifetime 8h by default (rzv orca defaults --lifetime 12h|24h); suspending stops the charge, deleting removes the VM and its files.")"
    printf '  "checkoutMode": "provisioned-root",\n'
    printf '  "create": %s,\n' "$(json "$locate create --size $size")"
    printf '  "suspend": %s,\n' "$(json "$locate suspend")"
    printf '  "resume": %s,\n' "$(json "$locate resume")"
    printf '  "destroy": %s\n' "$(json "$locate destroy")"
    printf '}\n'
  } > "recipes/runzivo-$id.json"
done <<< "$sizes"
