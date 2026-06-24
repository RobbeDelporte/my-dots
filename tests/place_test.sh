#!/usr/bin/env bash
# Unit tests for upsert_position() in eww/place.sh (sourced, not executed).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/../eww/place.sh"

pass=0; fail=0
check() { # name expected-file actual-file
  if diff -q "$2" "$3" >/dev/null; then echo "PASS: $1"; ((pass++))
  else echo "FAIL: $1"; diff "$2" "$3" | sed 's/^/    /'; ((fail++)); fi
}

tmpd="$(mktemp -d)"
trap 'rm -rf "$tmpd"' EXIT

# --- replace an existing entry, preserving comments + other entries ---
conf="$tmpd/replace.conf"
cat > "$conf" <<'EOF'
# header comment
# keep me

a.jpg = top right | 120px 320px
b.jpg = center | 0px 0px
EOF
upsert_position "$conf" "a.jpg" "top left | 740px 300px"
cat > "$tmpd/replace.expected" <<'EOF'
# header comment
# keep me

a.jpg = top left | 740px 300px
b.jpg = center | 0px 0px
EOF
check "replace existing entry, preserve rest" "$tmpd/replace.expected" "$conf"

# --- append when the key is not present ---
conf="$tmpd/append.conf"
cat > "$conf" <<'EOF'
# header
a.jpg = top right | 120px 320px
EOF
upsert_position "$conf" "b.jpg" "top left | 10px 20px"
cat > "$tmpd/append.expected" <<'EOF'
# header
a.jpg = top right | 120px 320px
b.jpg = top left | 10px 20px
EOF
check "append new entry" "$tmpd/append.expected" "$conf"

# --- create the file when it does not exist ---
conf="$tmpd/new.conf"
upsert_position "$conf" "c.jpg" "top left | 5px 5px"
printf 'c.jpg = top left | 5px 5px\n' > "$tmpd/new.expected"
check "create missing file" "$tmpd/new.expected" "$conf"

# --- a commented-out line that looks like the key must NOT be treated as a match ---
conf="$tmpd/comment.conf"
cat > "$conf" <<'EOF'
# a.jpg = old commented spec
a.jpg = top right | 1px 1px
EOF
upsert_position "$conf" "a.jpg" "top left | 2px 2px"
cat > "$tmpd/comment.expected" <<'EOF'
# a.jpg = old commented spec
a.jpg = top left | 2px 2px
EOF
check "comment resembling key is preserved, real entry replaced" "$tmpd/comment.expected" "$conf"

check_eq() { # name expected actual
  if [[ "$2" == "$3" ]]; then echo "PASS: $1"; ((pass++))
  else echo "FAIL: $1 -> got '$3', expected '$2'"; ((fail++)); fi
}

# --- current_entry: parse anchor + offset, strip px ---
conf="$tmpd/entry.conf"
cat > "$conf" <<'EOF'
# comment
a.jpg = top right | 120px 320px
b.jpg = center
c.jpg = bottom left | -40px 0px
EOF
check_eq "current_entry anchor+offset" "top right|120|320" "$(current_entry a.jpg)"
check_eq "current_entry anchor only -> 0 0" "center|0|0" "$(current_entry b.jpg)"
check_eq "current_entry negative offset" "bottom left|-40|0" "$(current_entry c.jpg)"
check_eq "current_entry absent -> default" "center right|60|0" "$(current_entry missing.jpg)"

echo "== $pass passed, $fail failed =="
[[ $fail -eq 0 ]]
