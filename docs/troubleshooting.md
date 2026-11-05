# Troubleshooting

Orca shows each step's output when a recipe fails. The lines that start with `rzv:` come from the CLI.

| Message                                         | Fix                                                                                       |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `install the rzv CLI first`                     | Install `rzv` (see the README). Orca looks on `PATH`, then `~/.local/bin/rzv`.            |
| `this rzv has no orca commands`                 | Update `rzv` with the installer.                                                          |
| `Your sign-in has expired`                      | Run `rzv login`.                                                                          |
| `is not on offer here now`                      | Pick another size, or another lifetime with `rzv orca defaults --lifetime`.               |
| `sandbox_limit_reached`                         | The workspace runs its maximum. Put another Orca workspace to sleep or delete one.        |
| `credit_exhausted`                              | Add credit to the Runzivo workspace.                                                      |
| `SSH is not enabled`                            | SSH is off in this Runzivo environment; Orca needs it.                                    |
| `reached its lifetime`                          | The sandbox expired and its files are gone. Delete the Orca workspace and create another. |
| `Orca asked for schema "1"`                     | Update Orca to 1.4.246 or later.                                                          |
| `Refusing to replace a symlink ... ssh/config`  | Add `Include ~/.ssh/rzv/*.conf` to the top of your managed SSH config yourself.           |

## Use another rzv or profile

Orca runs recipes with its own environment. To use an `rzv` that is not on `PATH`, set `RZV_BIN` in the environment Orca starts with. The recipes use the active `rzv` profile (`rzv profiles use <name>`); later steps use the profile the sandbox was created with.

## Find a sandbox by hand

```sh
rzv orca status
rzv sandboxes ssh <sandbox-id>
rzv sandboxes delete <sandbox-id>
```

Back to the [README](../README.md).
