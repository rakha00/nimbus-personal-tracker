#!/bin/sh
# Nightly backup of the PocketBase database.
# Keeps 14 days on the VPS and, once an rclone remote named "gdrive" exists, 60 days on Google Drive.
set -eu
DIR=/root/nimbus-backups
DB=/opt/nimbus/pb_data/data.db
mkdir -p "$DIR"
OUT="$DIR/nimbus-$(date +%Y-%m-%d).db"

# SQLite's online backup API gives a consistent copy while PocketBase keeps running.
python3 - "$DB" "$OUT" <<'PY'
import sqlite3, sys
src = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
ok = dst.execute("pragma integrity_check").fetchone()[0]
dst.close()
sys.exit(0 if ok == "ok" else f"integrity_check: {ok}")
PY
gzip -f "$OUT"
find "$DIR" -name 'nimbus-*.db.gz' -mtime +14 -delete

if rclone listremotes | grep -qx 'gdrive:'; then
  rclone copy "$DIR" gdrive:nimbus-backups --include 'nimbus-*.db.gz'
  rclone delete gdrive:nimbus-backups --min-age 60d
fi
echo "backup ok: $OUT.gz"
