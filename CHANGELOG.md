# Changelog

## Unreleased

### Added

- Four VM recipes, one per Runzivo sandbox size (2, 4, 8 and 16 vCPU). Each Orca workspace gets its own sandbox reached over SSH through `rzv`, with sleep (stop), wake (start) and delete. Needs `rzv` with the `orca` commands and Orca 1.4.246 or later.
