# Changelog

## v1.0.0 — 2026-06-12
- Initial release. Memory relief for the low-RAM ZTE F50 (~1.4GB):
  - Adds an extra zstd-compressed zram swap device (default 512MB).
  - Raises vm.swappiness=200 and vfs_cache_pressure=200.
  - Disables a configurable list of background bloat (ZTE analytics / neopush /
    zdm / aftersale / flagreset, print-recommendation) via `pm disable-user`.
  - Fully reversible: uninstall swaps off + hot-removes the zram and re-enables
    every disabled package. Edit `/data/lite-mem/bloat.list` to customize.
