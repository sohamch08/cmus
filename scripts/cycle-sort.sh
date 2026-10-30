#!/bin/sh
# Cycle sorting in the flat library view (2), using cmus's current sort order.
umask 077
lock_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/cmus"
mkdir -p "$lock_dir" || exit 1
exec 9>"$lock_dir/sort.lock"
# Keep rapid key presses from reading the same old sort order.
flock 9 || exit 1

current=$(cmus-remote -C 'set lib_sort') || exit $?
case "$current" in
    *"'lib_sort=title'"*)
        next='albumartist album discnumber tracknumber title'
        label='Artist / album'
        ;;
    *"'lib_sort=albumartist album discnumber tracknumber title'"*)
        next='date title'
        label='Year'
        ;;
    *"'lib_sort=date title'"*)
        next='album discnumber tracknumber title'
        label='Album'
        ;;
    *)
        next='title'
        label='Title'
        ;;
esac

result=$(cmus-remote -C "set lib_sort=$next") || exit $?
if [ -n "$result" ]; then
    printf '%s\n' "$result" >&2
    exit 1
fi
cmus-remote -C "echo Sort: $label"
