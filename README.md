# Runzivo Sandboxes for Orca

Run each [Orca](https://www.onorca.dev) workspace in its own [Runzivo](https://runzivo.dev) sandbox: an isolated Firecracker microVM that Orca reaches over standard SSH. Run Claude Code, Codex or any other tool inside it with your own accounts. Compute is charged in equivalent minutes from your Runzivo workspace credits; there is no separate Orca plan or payment.

Start with the website's [Agent Sandboxes overview](https://runzivo.dev/sandboxes/), [CLI setup](https://runzivo.dev/docs/cli/) and [sign-in guide](https://runzivo.dev/docs/sign-in/). This repository covers the plugin's setup, recipes and troubleshooting. The [Orca plugin listing](https://www.onorca.dev/plugins/runzivo/rzv-orca-plugin) shows the published version.

## Requirements

- Orca 1.4.246 or later on macOS or Linux, with OpenSSH and Git, and **Settings > Experimental > Cloud VM** turned on
- A Runzivo account and a workspace with credit
- The `rzv` CLI 0.24.0 or later (sign-ins renew automatically until 14 days without use or 30 days after sign-in, whichever comes first):

  ```sh
  curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh
  ```

## Set up

1. Sign in and pick the workspace Orca should use:

   ```sh
   rzv login
   rzv workspaces select <workspace>
   ```

2. Optional: choose the disk and lifetime for new Orca workspaces (defaults: 20 GiB, 8 hours):

   ```sh
   rzv orca defaults --disk-gib 40 --lifetime 24h
   ```

3. In Orca, turn on **Settings > Experimental > Cloud VM**, then open **Settings > Plugins > Add plugin > From a Git URL** and paste
   `https://github.com/Runzivo/rzv-orca-plugin#v0.1.1`. Review the access it asks for (four VM recipes, no code) and enable it.

## Use

Create a workspace and choose a **Runzivo sandbox** size under **Run on**. Orca creates the sandbox, copies in the commit you selected, connects over SSH and opens the workspace in `/workspace/<repo>`.

- **Sleep** stops the sandbox and its compute charge. Its whole disk stays, including `/workspace` and tool sign-ins in your home directory; running processes end.
- **Wake** starts the same sandbox again. Nothing is duplicated.
- **Delete** deletes the sandbox and every file in it. Push your work first.

A sandbox lives 8, 12 or 24 hours from its first run, never longer, even while asleep. `rzv orca status` shows each one's expiry, time left and credits used.

## Documentation

| Page                                           | What it covers                                  |
| ---------------------------------------------- | ----------------------------------------------- |
| [Sizes, lifetime and billing](docs/sizes.md)   | VM sizes, disk, region, lifetime and charges    |
| [Security](docs/security.md)                   | What reaches the VM, SSH certificates, accounts |
| [Troubleshooting](docs/troubleshooting.md)     | Common errors and how to fix them               |
| [Testing](docs/testing.md)                     | Checks and the live end-to-end test             |
| [Releasing](docs/releasing.md)                 | Versions, tags and the Orca directory           |

The commands the recipes run are documented in the CLI: [Orca workspaces](https://github.com/Runzivo/rzv-cli/blob/main/docs/orca.md).

Suggest improvements and vote on ideas through the [public roadmap](https://runzivo.dev/roadmap/).

The plugin is MIT licensed ([LICENSE](LICENSE)). The `rzv` CLI and the Runzivo service keep their own licenses.
