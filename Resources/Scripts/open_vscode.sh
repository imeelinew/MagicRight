#!/bin/zsh
LOG="$HOME/Library/Logs/magicright.log"
[ "$(/usr/bin/stat -f%z "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && /bin/mv "$LOG" "$LOG.1"
exec >>"$LOG" 2>&1
echo "=== $(date) [vscode] argc=$# ==="
for dir in "$@"; do
    /usr/bin/open -a "Visual Studio Code" "$dir" && echo "OK: $dir" || echo "FAIL: $dir"
done
