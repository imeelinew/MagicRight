#!/bin/zsh
LOG="$HOME/Library/Logs/magicright.log"
[ "$(/usr/bin/stat -f%z "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && /bin/mv "$LOG" "$LOG.1"
exec >>"$LOG" 2>&1
echo "=== $(date) [cut-items] argc=$# ==="
emulate -L zsh
setopt local_options no_nomatch

state_dir="$HOME/Library/Application Support/MagicRight"
state_file="$state_dir/cut-items.bin"
tmp_file=$(/usr/bin/mktemp /tmp/sr-cut.XXXXXX) || exit 1

if ! /bin/mkdir -p "$state_dir"; then
    /bin/rm -f "$tmp_file"
    /usr/bin/osascript -e "display notification \"无法创建状态目录\" with title \"剪切\""
    exit 1
fi

typeset -a selected

for raw_path in "$@"; do
    [ -e "$raw_path" ] || continue
    path="${raw_path:A}"

    duplicate=0
    nested_under_existing=0
    typeset -a next_selected
    next_selected=()

    for existing in "${selected[@]}"; do
        if [ "$path" = "$existing" ]; then
            duplicate=1
            next_selected+=("$existing")
            continue
        fi

        if [ -d "$existing" ] && [ "${path#"$existing"/}" != "$path" ]; then
            nested_under_existing=1
            next_selected+=("$existing")
            continue
        fi

        if [ -d "$path" ] && [ "${existing#"$path"/}" != "$existing" ]; then
            echo "DROP nested child: $existing (covered by $path)"
            continue
        fi

        next_selected+=("$existing")
    done

    selected=("${next_selected[@]}")

    if [ "$duplicate" -eq 1 ]; then
        echo "SKIP duplicate: $path"
        continue
    fi
    if [ "$nested_under_existing" -eq 1 ]; then
        echo "SKIP nested child: $path"
        continue
    fi

    selected+=("$path")
    echo "CUT: $path"
done

count="${#selected[@]}"

if [ "$count" -eq 0 ]; then
    /bin/rm -f "$tmp_file"
    /usr/bin/osascript -e "display notification \"请先选中文件或文件夹\" with title \"剪切\""
    exit 0
fi

for path in "${selected[@]}"; do
    printf '%s\0' "$path" >> "$tmp_file"
done

/bin/mv "$tmp_file" "$state_file"
/usr/bin/osascript -e "display notification \"已暂存 $count 项 | 前往目标文件夹后点击粘贴\" with title \"剪切\""
echo "OK: cut items stored count=$count"
