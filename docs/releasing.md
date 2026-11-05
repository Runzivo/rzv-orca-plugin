# Releasing

1. The `rzv` release with the `orca` commands is published.
2. Update `version` in `orca-plugin.json` and `CHANGELOG.md`, and run the checks in [Testing](testing.md), including the live test.
3. Merge, then tag the merge commit and push the tag:

   ```sh
   git tag -s v0.1.0 -m v0.1.0 && git push origin v0.1.0
   ```

4. The Orca directory lists public repositories with the `orca-plugin` topic and a `vX.Y.Z` tag:

   ```sh
   gh repo edit Runzivo/rzv-orca-plugin --add-topic orca-plugin
   ```

5. Check the listing at `https://www.onorca.dev/plugins/runzivo/rzv-orca-plugin`.

Orca asks users to review an update that adds recipes or raises the execution profile, so keep the plugin `declarative`. Changing what a step does belongs in `rzv`, which updates without a plugin release.

Back to the [README](../README.md).
