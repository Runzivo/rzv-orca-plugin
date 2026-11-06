# Changelog

## v0.1.1, 2026-11-06

### Changed

- Directory listing: a 4K cover and the Runzivo O icon, built from the Runzivo brand kit.

## v0.1.0, 2026-11-06

### Added

- Four VM recipes, one per Runzivo sandbox size (2, 4, 8 and 16 vCPU). Each Orca workspace gets its own sandbox reached over SSH through `rzv`, with sleep (stop), wake (start) and delete. Needs `rzv` 0.24.0 or later and Orca 1.4.246 or later. Tested live against Runzivo shared: Orca's `vm recipe doctor --provision`, one sandbox per workspace, SSH checkout without credentials, sleep/wake billing, 8/12/24 h lifetimes, delete and cancellation cleanup, and sessions that renew past 15 minutes.
