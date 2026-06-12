#!/system/bin/sh
# lite-mem — memory relief for the low-RAM ZTE F50.
#   1) add an extra zstd-compressed zram swap device
#   2) raise vm.swappiness / vfs_cache_pressure
#   3) disable a configurable list of background bloat
# All reversible (see uninstall.sh). Idempotent — safe to re-run.

MODDIR=/data/adb/modules/lite-mem
DATADIR=/data/lite-mem
LOG="$DATADIR/lite-mem.log"
BLOAT_LIST="$DATADIR/bloat.list"
ZRAM_DEV_FILE="$DATADIR/zram_dev"          # remembers which zram device we created
ZRAM_SIZE_MB="${LITE_MEM_ZRAM_MB:-512}"    # extra zram size (override via prop/env)
SWAPPINESS="${LITE_MEM_SWAPPINESS:-200}"

mkdir -p "$DATADIR"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG" 2>/dev/null; }

# rotate log
[ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 262144 ] && : > "$LOG"

# Wait for /data to be fully ready.
sleep 20

# ─── 1) extra zram swap (zstd) ────────────────────────────────────────────
add_zram() {
    [ -e /sys/class/zram-control/hot_add ] || { log "no zram hot_add support — skipping zram"; return; }

    # If we already created one and it's still an active swap, do nothing.
    if [ -f "$ZRAM_DEV_FILE" ]; then
        local d; d=$(cat "$ZRAM_DEV_FILE" 2>/dev/null)
        if grep -q "/dev/block/zram${d} " /proc/swaps 2>/dev/null; then
            log "zram${d} already active — skip"
            return
        fi
    fi

    local n
    n=$(cat /sys/class/zram-control/hot_add 2>/dev/null)
    [ -z "$n" ] && { log "hot_add failed"; return; }
    # zstd if available, else lz4
    if grep -q zstd /sys/block/zram${n}/comp_algorithm 2>/dev/null; then
        echo zstd > /sys/block/zram${n}/comp_algorithm 2>/dev/null
    fi
    echo $((ZRAM_SIZE_MB * 1024 * 1024)) > /sys/block/zram${n}/disksize 2>/dev/null
    /system/bin/mkswap /dev/block/zram${n} >/dev/null 2>&1
    # priority 5: used alongside the OEM zram0
    /system/bin/swapon /dev/block/zram${n} -p 5 2>/dev/null \
        || /system/bin/swapon -p 5 /dev/block/zram${n} 2>/dev/null
    if grep -q "/dev/block/zram${n} " /proc/swaps 2>/dev/null; then
        echo "$n" > "$ZRAM_DEV_FILE"
        log "added zram${n}: ${ZRAM_SIZE_MB}MB $(cat /sys/block/zram${n}/comp_algorithm 2>/dev/null | grep -oE '\[[a-z0-9-]+\]')"
    else
        log "swapon zram${n} failed; rolling back"
        echo 1 > /sys/block/zram${n}/reset 2>/dev/null
        echo "$n" > /sys/class/zram-control/hot_remove 2>/dev/null
    fi
}

# ─── 2) vm tunables ───────────────────────────────────────────────────────
tune_vm() {
    for p in /proc/sys/vm/vm_swappiness /proc/sys/vm/swappiness; do
        [ -w "$p" ] && echo "$SWAPPINESS" > "$p" 2>/dev/null
    done
    [ -w /proc/sys/vm/vfs_cache_pressure ] && echo 200 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
    [ -w /proc/sys/vm/dirty_ratio ] && echo 60 > /proc/sys/vm/dirty_ratio 2>/dev/null
    log "vm tuned: swappiness=$SWAPPINESS vfs_cache_pressure=200"
}

# ─── 3) disable background bloat ──────────────────────────────────────────
debloat() {
    [ -r "$BLOAT_LIST" ] || { log "no bloat.list — skip debloat"; return; }
    while IFS= read -r pkg; do
        case "$pkg" in ""|\#*) continue ;; esac
        if pm list packages 2>/dev/null | grep -q "package:${pkg}$"; then
            pm disable-user --user 0 "$pkg" >/dev/null 2>&1 \
                && log "disabled $pkg" || log "could not disable $pkg"
        fi
    done < "$BLOAT_LIST"
}

add_zram
tune_vm
debloat
log "lite-mem applied"
