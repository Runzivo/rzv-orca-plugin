# Testing

## Every change

```sh
scripts/10-build-recipes.sh && git diff --exit-code recipes/
orca plugin validate .
shellcheck scripts/*.sh
```

CI runs the first and third. `orca plugin validate` needs the Orca CLI, so run it before tagging.

The `rzv orca` commands have their own tests in the CLI repository (fake Core server, stubbed `git` and `ssh`).

## Live end-to-end test

`scripts/20-shared-e2e.sh` checks the whole lifecycle against a live Runzivo environment with a signed-in `rzv` profile:

1. `orca vm recipe doctor` (static) and `--provision`: Orca runs create, validates the result against its own schema, runs destroy, and nothing is left behind.
2. create, then create again with the same Orca workspace id: the same sandbox.
3. SSH through the generated config: the exact commit and branch, remotes with no token, `scp`.
4. Expiry and lifetime fields.
5. suspend: stopped, and credits do not grow while stopped.
6. resume: the same sandbox and files over a new SSH connection; credits grow while running.
7. destroy: the sandbox is deleting or deleted and its SSH config is gone.

```sh
RZV_PROFILE=<profile> scripts/20-shared-e2e.sh
```

It needs a free sandbox slot, runs about ten minutes, and deletes what it made even when it fails. Evidence (logs, results, no credentials) is written to `$E2E_EVIDENCE` or a printed temporary directory. Set `E2E_SIZE` and `E2E_LIFETIME` to test other choices.

Back to the [README](../README.md).
