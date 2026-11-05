# rzv-orca-plugin agent guide

Runzivo-wide rules: [rzv-business/operating-policy.md](https://github.com/Runzivo/rzv-business/blob/main/operating-policy.md) (local checkout: ../rzv-business/operating-policy.md). This file adds only plugin guidance.

- The plugin stays `declarative`: recipe JSON only, no code or binaries. Lifecycle logic belongs in `rzv orca` in Runzivo/rzv-cli.
- Edit `scripts/10-build-recipes.sh`, never `recipes/*.json` by hand, then run it.
- Run `orca plugin validate .` before every tag, and the live test in docs/testing.md before a release.
- The repository is public: no internal hostnames, inventory, secrets or unreleased plans.
