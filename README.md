# lite-mem — zram + debloat for the low-RAM ZTE F50

Memory relief for the ZTE F50 (~1.4 GB RAM), where heavy apps (V2rayTun,
AdGuard Home) get killed by the low-memory-killer (LMK) — which, with a VPN
killswitch, takes the internet down and makes the screen flicker as the app
relaunches.

## What it does (on boot)

1. **Extra zstd zram swap** — hot-adds a second zram device (default 512 MB,
   zstd compression) on top of the OEM `zram0`, giving the LMK much more
   headroom (observed: free swap 492 MB → ~1 GB). Result: V2rayTun stops being
   killed.
2. **VM tuning** — `vm.swappiness=200`, `vfs_cache_pressure=200` so the kernel
   leans on the (cheap, compressed) zram before evicting processes.
3. **Debloat** — disables a configurable list of background bloat via
   `pm disable-user --user 0`. Defaults are ZTE telemetry / device-management /
   aftersale packages (analytics, neopush, zdm, aftersale, flagreset) plus the
   print-recommendation service.

## Configure

- `/data/lite-mem/bloat.list` — one package per line (`#` comments). Add/remove
  to taste; re-applied each boot.
- Size override: `LITE_MEM_ZRAM_MB` (default 512), `LITE_MEM_SWAPPINESS` (200).

## Usage

```
# inspect what it did
cat /data/lite-mem/lite-mem.log
cat /proc/swaps          # you should see a second zramN device
```

## Reversible

`uninstall.sh` swaps off + hot-removes the zram device and re-enables every
package it disabled. `/data/lite-mem` (log + bloat.list) is kept.

## Note on AdGuard Home

On this 1.4 GB device, AdGuard Home alone used ~491 MB RAM (a third of total),
which is what triggered the LMK cascade. If you run `adguardhome`, keep its
blocklists small — or leave it off. lite-mem does not touch adguardhome.
