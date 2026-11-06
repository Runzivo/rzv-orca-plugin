# Troubleshooting

Orca shows each step's output when a recipe fails. The lines that start with `rzv:` come from the CLI.

| Message                                         | Fix                                                                                       |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `install the rzv CLI first`                     | Install `rzv` (see the README). Orca looks on `PATH`, then `~/.local/bin/rzv`.            |
| `this rzv has no orca commands`                 | Update `rzv` with the installer.                                                          |
| `Your sign-in has ended`                        | Run `rzv login`. A session ends after 14 days without use or 30 days after sign-in, whichever comes first. |
| `is not on offer here now`                      | Pick another size, or another lifetime with `rzv orca defaults --lifetime`.               |
| `sandbox_limit_reached`                         | The service reports a configured sandbox limit. Check `rzv sandboxes list` and ask support if the limit is unexpected. |
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
