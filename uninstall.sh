#!/system/bin/sh
# Reverse everything lite-mem did: swapoff + remove our zram, re-enable the
# disabled packages. /data/lite-mem (log + bloat.list) is kept.
DATADIR=/data/lite-mem

# 1) swap off + hot-remove our zram device
if [ -f "$DATADIR/zram_dev" ]; then
    d=$(cat "$DATADIR/zram_dev" 2>/dev/null)
    if [ -n "$d" ]; then
        /system/bin/swapoff /dev/block/zram${d} 2>/dev/null
        echo 1 > /sys/block/zram${d}/reset 2>/dev/null
        echo "$d" > /sys/class/zram-control/hot_remove 2>/dev/null
    fi
fi

# 2) re-enable everything we disabled
if [ -r "$DATADIR/bloat.list" ]; then
    while IFS= read -r pkg; do
        case "$pkg" in ""|\#*) continue ;; esac
        pm enable "$pkg" >/dev/null 2>&1
    done < "$DATADIR/bloat.list"
fi
