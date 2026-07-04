#!/bin/bash

# Hàm thực hiện Backup
function do_backup() {
    echo "[BACKUP] Dang quet va dong goi du lieu ma hoa..."
    mkdir -p "$BACKUP_DIR"
    tar -cz -C / /opt/openlist/data /tmp/.config/qBittorrent /tmp/.local/share/qBittorrent 2>/dev/null | \
    openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$BACKUP_PASS" -out "$BACKUP_DIR/$BACKUP_FILENAME"
    echo "[BACKUP] Da luu tru an toan vao $BACKUP_DIR/$BACKUP_FILENAME!"
}

# Hàm thực hiện Restore
function do_restore() {
    if [ -f "$BACKUP_DIR/$BACKUP_FILENAME" ]; then
        echo "[RESTORE] Thuc hien giai nen phuc hoi..."
        openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$BACKUP_PASS" -in "$BACKUP_DIR/$BACKUP_FILENAME" | tar -xz -C / 2>/dev/null
        echo "[RESTORE] Xong!"
    fi
}

# Lắng nghe hành động gọi từ Entrypoint chính
case "$1" in
    restore)
        do_restore
        ;;
    backup)
        do_backup
        ;;
    watch)
        last_run=0
        inotifywait -m -e modify,create,delete,move -r /opt/openlist/data /tmp/.config/qBittorrent 2>/dev/null | while read path action file; do
            now=$(date +%s)
            if (( now - last_run > 300 )); then
                last_run=$now
                echo "[INOTIFY] Phat hien thay doi cấu hình, đang auto-backup sau 5 phut..."
                sleep 300
                do_backup
            fi
        done
        ;;
esac
