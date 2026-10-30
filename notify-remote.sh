#!/bin/sh
# cmus-notify 0.1.0 needs track fields even when cmus is stopped.
umask 077
response=$(cmus-remote "$@") || exit $?
# The daemon parses volume as unsigned; cmus uses -1 for unavailable mixers.
response=$(printf '%s\n' "$response" |
    awk '/^set vol_(left|right) -/ { $3 = 0 } { print }')
cache_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/cmus-notify"
mkdir -p "$cache_dir" || exit 1
cache="$cache_dir/last-track"

if printf '%s\n' "$response" | grep -q '^file '; then
    printf '%s\n' "$response" |
        awk '/^file / { track = 1 } /^set / { track = 0 } track' > "$cache.tmp.$$"
    mv "$cache.tmp.$$" "$cache"
    printf '%s\n' "$response"
else
    if [ ! -s "$cache" ]; then
        printf 'file \nduration 0\nposition 0\n' > "$cache"
    fi
    # Preserve the last song on stop, while keeping current player settings.
    printf '%s\n' "$response" | awk -v cache="$cache" '
        NR == 1 { print; next }
        !inserted && /^set / {
            while ((getline line < cache) > 0) print line
            close(cache)
            inserted = 1
        }
        { print }
    '
fi
