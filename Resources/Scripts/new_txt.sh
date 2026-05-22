#!/bin/zsh
LOG="$HOME/Library/Logs/magicright.log"
[ "$(/usr/bin/stat -f%z "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && /bin/mv "$LOG" "$LOG.1"
exec >>"$LOG" 2>&1
echo "=== $(date) [txt] argc=$# ==="
printf 'arg: %s\n' "$@"
for dir in "$@"; do
    name="未命名.txt"
    i=1
    while [ -e "$dir/$name" ]; do
        name="未命名 $i.txt"
        i=$((i+1))
    done
    target="$dir/$name"
    if /usr/bin/touch "$target"; then
        echo "OK: $target"
        /usr/bin/osascript -e "tell application \"Finder\" to update (POSIX file \"$dir\" as alias)"
    else
        echo "FAIL: $target"
    echo "NOTICE: 新建 txt 文件: 创建失败: $target"
    fi
done
