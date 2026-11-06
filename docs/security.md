# Security

## What the plugin is

Four VM recipes in JSON. Each recipe command finds `rzv` and runs `rzv orca <step>`. The plugin ships no code or binaries; Orca shows it as **declarative**. All logic is in the `rzv` CLI, whose source is public.

## What reaches the sandbox

- The commit you selected in Orca, as a Git bundle made on your machine. Uncommitted changes stay on your machine.
- Your Git remotes, with any user name or password removed from `http(s)` URLs, and your `user.name` and `user.email`.
- Nothing else: no Git token, no SSH agent (agent forwarding is off), no Runzivo credential and no home directory.

Pushing from the sandbox needs credentials you set up inside it, such as `gh auth login` there.

## AI tools

Run Claude Code, Codex or other tools inside the sandbox and sign in to them there with your own accounts. Their credentials live in the sandbox and are deleted with it. Runzivo bills only the compute.

Only `/workspace` survives sleep. Waking a sandbox resets everything else, including your home directory: sign in to those tools again after a wake, and expect Orca to reinstall its remote runtime (a slower first connection). Your checkout and anything else under `/workspace` stay until the sandbox expires or is deleted.

## SSH

Orca connects with system OpenSSH through the config `rzv` writes in `~/.ssh/rzv/<sandbox>.conf` (included from `~/.ssh/config`):

- A user certificate valid for 15 minutes, renewed before each connection.
- Strict host verification against the Runzivo host CA for that one sandbox.
- No passwords, no agent or X11 forwarding.
- The connection runs through `rzv sandboxes ssh --stdio`, an authenticated relay; the sandbox has no public SSH port.

## Access

Every call uses your `rzv` sign-in (or `RZV_API_KEY`) and Runzivo's workspace roles: you can only create or reach sandboxes in workspaces where you have `sandboxes:write`. The plugin stores nothing but the sandbox id, workspace id and profile name in Orca's workspace data.

## Clean-up

A failed create deletes the sandbox it made. Deleting the Orca workspace deletes the sandbox and its SSH config. A sandbox Orca lost track of still expires at the end of its lifetime; `rzv orca status` lists them.

Back to the [README](../README.md).
