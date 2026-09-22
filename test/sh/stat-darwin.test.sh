#!/bin/sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)

set +e
stat -c %y /bin/sh >"$work/red.out" 2>"$work/red.err"
red=$?
set -e
[ "$red" -ne 0 ]
grep -q "illegal option" "$work/red.err"

funcs=$(awk '
  /^file_mtime\(\) \{/ {p=1}
  /^file_ctime\(\) \{/ {p=1}
  p {print}
  /^}$/ && p {c++; if (c==2) exit}
' "$root/checksum-comparator.sh")
# shellcheck disable=SC1090
eval "$funcs"

older="$work/older"
newer="$work/newer"
: >"$older"
: >"$newer"
touch -t 202001010000 "$older"
touch -t 202001020000 "$newer"
old_m=$(file_mtime "$older")
new_m=$(file_mtime "$newer")
[ "$new_m" \> "$old_m" ]
[ -n "$(file_ctime "$newer")" ]
echo "checksum stat darwin ok (stat -c exit $red, older $old_m, newer $new_m)"
rm -rf "$work"
