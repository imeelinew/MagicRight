#!/bin/zsh
LOG="$HOME/Library/Logs/magicright.log"
[ "$(/usr/bin/stat -f%z "$LOG" 2>/dev/null || echo 0)" -gt 1048576 ] && /bin/mv "$LOG" "$LOG.1"
exec >>"$LOG" 2>&1
echo "=== $(date) [paste-cut-items] argc=$# ==="
emulate -L zsh
setopt local_options no_nomatch

state_dir="$HOME/Library/Application Support/MagicRight"
state_file="$state_dir/cut-items.bin"

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo "NOTICE: 粘贴: 请在目标文件夹空白处或文件夹本身使用"
    exit 0
fi

dest="$1"
if [ ! -s "$state_file" ]; then
    echo "NOTICE: 粘贴: 当前没有已剪切的项目"
    exit 0
fi

# TTL: 状态超过 24h 视为过期，清空 + 通知，避免误粘贴很久以前剪切的内容
state_age=$(( $(/bin/date +%s) - $(/usr/bin/stat -f%m "$state_file" 2>/dev/null || echo 0) ))
if [ "$state_age" -gt 86400 ]; then
    /bin/rm -f "$state_file"
    echo "NOTICE: 粘贴: 已剪切内容超过 24 小时，已自动清空"
    exit 0
fi

dest="${dest:A}"
tmp_keep=$(/usr/bin/mktemp /tmp/sr-cut-keep.XXXXXX) || exit 1
moved=0
kept=0
missing=0
same_dir_kept=0
recursive_kept=0
failed_kept=0

while IFS= read -r -d '' src; do
    if [ ! -e "$src" ]; then
        missing=$((missing+1))
        echo "MISSING: $src"
        continue
    fi

    src="${src:A}"
    src_parent="${src:h}"
    src_name="${src:t}"
    stem="${src_name:r}"
    ext="${src_name:e}"

    if [ "$src_parent" = "$dest" ]; then
        printf '%s\0' "$src" >> "$tmp_keep"
        kept=$((kept+1))
        same_dir_kept=$((same_dir_kept+1))
        echo "KEEP same-dir: $src"
        continue
    fi

    if [ -d "$src" ]; then
        if [ "$dest" = "$src" ] || [ "${dest#"$src"/}" != "$dest" ]; then
            printf '%s\0' "$src" >> "$tmp_keep"
            kept=$((kept+1))
            recursive_kept=$((recursive_kept+1))
            echo "KEEP recursive-dir: $src"
            continue
        fi
        suffix=""
    elif [ "$stem" = "$src_name" ]; then
        suffix=""
    else
        suffix=".$ext"
    fi

    candidate="$dest/$src_name"
    i=1
    while [ -e "$candidate" ]; do
        if [ -d "$src" ] || [ "$suffix" = "" ]; then
            candidate="$dest/$src_name $i"
        else
            candidate="$dest/$stem $i$suffix"
        fi
        i=$((i+1))
    done

    if /bin/mv "$src" "$candidate"; then
        moved=$((moved+1))
        echo "MOVE: $src -> $candidate"
    else
        printf '%s\0' "$src" >> "$tmp_keep"
        kept=$((kept+1))
        failed_kept=$((failed_kept+1))
        echo "FAIL move: $src -> $candidate"
    fi
done < "$state_file"

if [ "$kept" -gt 0 ]; then
    /bin/mv "$tmp_keep" "$state_file"
else
    /bin/rm -f "$tmp_keep" "$state_file"
fi

msg="已粘贴 $moved 项"
if [ "$missing" -gt 0 ]; then
    msg="$msg | 丢失 $missing 项"
fi
if [ "$kept" -gt 0 ]; then
    msg="$msg | 保留 $kept 项待重试"
fi
    echo "NOTICE: 粘贴: $msg"
echo "DONE: moved=$moved missing=$missing kept=$kept same_dir_kept=$same_dir_kept recursive_kept=$recursive_kept failed_kept=$failed_kept dest=$dest"
