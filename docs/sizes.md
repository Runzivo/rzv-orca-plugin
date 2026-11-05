# Sizes, lifetime and billing

## Sizes

The plugin adds one **Run on** choice per size. Runzivo offers a size only where it has room for it; a size that is not on offer fails before anything is created.

| Choice in Orca                  | vCPU | RAM   | Rate while running        |
| ------------------------------- | ---- | ----- | ------------------------- |
| Runzivo sandbox, 2 vCPU, 8 GB   | 2    | 8 GB  | 1 equivalent minute/min   |
| Runzivo sandbox, 4 vCPU, 16 GB  | 4    | 16 GB | 2 equivalent minutes/min  |
| Runzivo sandbox, 8 vCPU, 32 GB  | 8    | 32 GB | 4 equivalent minutes/min  |
| Runzivo sandbox, 16 vCPU, 64 GB | 16   | 64 GB | 8 equivalent minutes/min  |

## Disk

Each sandbox gets a temporary disk at `/workspace`, 20 GiB unless you set 5 to 64 GiB with `rzv orca defaults --disk-gib`. It is deleted with the sandbox.

## Region

Runzivo places the sandbox. Sandboxes run in Montréal, Canada today. There is no region choice yet.

## Lifetime

8 hours by default; `rzv orca defaults --lifetime 12h` or `24h` where Runzivo offers them (`rzv sandboxes list` shows what is on offer). The lifetime starts when the sandbox first runs and keeps running while it is stopped. At the end the VM stops and its files are deleted. Nothing extends it: create a new Orca workspace instead.

## Billing

Compute is charged per minute while the sandbox runs, from the Runzivo workspace's credits, at the rate above. A stopped (asleep) sandbox is not charged. Creating or waking a sandbox needs credit; if credit runs out the sandbox stops. Orca charges nothing for this plugin.

Orca shows no cost or expiry in its own interface. The create log shows the expiry and hourly rate, and `rzv orca status` shows the expiry, time left and credits used for every sandbox Orca made.

Back to the [README](../README.md).
