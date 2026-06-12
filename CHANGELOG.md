# Changelog

## v1.1.0 — 2026-06-13
- **Shell-toggleable ZTE web-panel kill.** New `lite-mem` CLI:
  - `lite-mem webui off` — `pm disable` + kill `com.zte.web` (the goform web
    panel on :8080/:9090). Frees ~25-30 MB and stops its ZTE-cloud telemetry.
    Survives reboot; re-asserted on boot from `/data/lite-mem/webui_off`.
  - `lite-mem webui on` — restore the web UI + goform.
  - `lite-mem status` — zram/swappiness/RAM/disabled-pkgs/web-panel overview.
  - Verified safe: hotspot (com.zte.host) and cellular (RIL) are unaffected.
  - Trade-off: while off, 192.168.0.1 and statusbot `/performance` `/qos`
    `/zte_setpw` are unavailable.

## v1.0.0 — 2026-06-12
- Initial release. Memory relief for the low-RAM ZTE F50 (~1.4GB):
  - Adds an extra zstd-compressed zram swap device (default 512MB).
  - Raises vm.swappiness=200 and vfs_cache_pressure=200.
  - Disables a configurable list of background bloat (ZTE analytics / neopush /
    zdm / aftersale / flagreset, print-recommendation) via `pm disable-user`.
  - Fully reversible: uninstall swaps off + hot-removes the zram and re-enables
    every disabled package. Edit `/data/lite-mem/bloat.list` to customize.
