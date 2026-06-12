#!/system/bin/sh
ui_print " "
ui_print "  Lite Mem (zram + debloat) v1.0.0"
ui_print "  ================================"
ui_print " "
ui_print "  - extra zstd zram swap"
ui_print "  - vm.swappiness=200, vfs_cache_pressure=200"
ui_print "  - disables background bloat (editable list)"
ui_print " "

mkdir -p /data/lite-mem
chmod 755 /data/lite-mem

# Seed the default bloat list (only if absent — never clobber user edits).
if [ ! -f /data/lite-mem/bloat.list ]; then
cat > /data/lite-mem/bloat.list <<'EOF'
# Packages disabled on boot by lite-mem (pm disable-user --user 0).
# One package per line. Lines starting with # are ignored.
# Safe ZTE telemetry / device-management / aftersale bloat:
com.zte.analytics
com.zte.neopush
com.zte.zdm
com.zte.zdmdaemon
com.zte.zdmdaemon.install
com.zte.flagreset
cn.zte.aftersale
com.android.aftersaleservice
com.android.printservice.recommendation
EOF
chmod 644 /data/lite-mem/bloat.list
ui_print "  Seeded /data/lite-mem/bloat.list (edit to customize)"
fi

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/system/bin/lite-mem" 0 0 0755

ui_print " "
ui_print "  [OK] Installed. Reboot to apply (or run service.sh)."
ui_print "  Shell CLI:  lite-mem status"
ui_print "              lite-mem webui off   (kill ZTE web panel, save ~25MB)"
ui_print "              lite-mem webui on    (restore it)"
ui_print "  Tune size:  LITE_MEM_ZRAM_MB (default 512)."
ui_print " "
