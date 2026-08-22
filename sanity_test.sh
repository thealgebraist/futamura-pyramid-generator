#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/futamura-sanity.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

cc="${CXX:-clang++}"
ocamlc="${OCAMLC:-ocamlc}"
flags="-std=c++23 -Wall -Wextra -Wpedantic"

echo "[1/8] pure OCaml interpreter: 16 cases"
"$ocamlc" -o "$tmp/core16" \
  "$root/core_specializer.ml" "$root/core_specializer_tests.ml"
test "$("$tmp/core16" | grep -c '^PASS ')" -eq 16

echo "[2/8] pure OCaml long specialization: 8 cases"
"$ocamlc" -o "$tmp/corelong" \
  "$root/core_specializer.ml" "$root/core_specializer_long_tests.ml"
test "$("$tmp/corelong" | grep -c '^PASS long ')" -eq 8

echo "[3/8] second projection: pure OCaml compiler"
"$ocamlc" -o "$tmp/second" \
  "$root/core_specializer.ml" "$root/core_second_projection.ml" \
  "$root/core_second_projection_tests.ml"
test "$("$tmp/second" | grep -c '^PASS ')" -eq 4

echo "[4/8] non-executing resource analysis"
"$ocamlc" -o "$tmp/resources" \
  "$root/core_specializer.ml" "$root/resource_sanity.ml" \
  "$root/resource_sanity_driver.ml"
test "$("$tmp/resources" | grep -c '^case ')" -eq 8
test "$("$tmp/resources" | grep -c 'WARNING: branching shape')" -eq 4

echo "[5/8] C++ second-stage schema compiler"
"$cc" $flags "$root/spec_to_header.cpp" -o "$tmp/spec_to_header"
"$tmp/spec_to_header" "$root/pyramid_language.spec" > "$tmp/generated.hpp"
cmp "$root/pyramid_language.hpp" "$tmp/generated.hpp"

echo "[6/8] C++ third projection"
"$cc" $flags "$root/third_projection.cpp" -o "$tmp/third_projection"
"$tmp/third_projection" "$root/pyramid_language.spec" "$tmp/fixed.cpp"
"$cc" $flags "$tmp/fixed.cpp" -o "$tmp/fixed"
"$tmp/fixed" > "$tmp/fixed.hpp"
cmp "$root/pyramid_language.hpp" "$tmp/fixed.hpp"

echo "[7/8] C++ query compiler and generated programs"
"$cc" $flags "$root/pyramid_generator.cpp" -o "$tmp/pyramid_generator"
cat > "$tmp/pyramids.records" <<'EOF'
Great Pyramid of Giza|Egypt|-2560|146.6
Pyramid of Khafre|Egypt|-2570|136.4
Pyramid of the Sun|Mexico|200|65.0
EOF

run_query() {
    name=$1
    query=$2
    expected=$3
    "$tmp/pyramid_generator" "$query" "$tmp/pyramids.records" > "$tmp/$name.cpp"
    "$cc" $flags "$tmp/$name.cpp" -o "$tmp/$name"
    "$tmp/$name" > "$tmp/$name.out"
    test "$(wc -l < "$tmp/$name.out" | tr -d ' ')" -eq "$expected"
}

run_query year 'SELECT TOP 1 FROM PYRAMIDS WHERE BUILT_YEAR=-2560' 1
run_query contains 'SELECT TOP 2 FROM PYRAMIDS WHERE NAME CONTAINS "Pyramid"' 2
run_query height 'SELECT TOP 2 FROM PYRAMIDS WHERE HEIGHT_M>=100' 2
run_query top 'SELECT TOP 2 FROM PYRAMIDS' 2

echo "[8/8] invalid DSL rejection"
if "$tmp/pyramid_generator" \
  'SELECT TOP 1 FROM PYRAMIDS WHERE BUILT_YEAR CONTAINS 2' \
  > /dev/null 2> "$tmp/error"; then
    echo "invalid numeric CONTAINS was accepted" >&2
    exit 1
fi
grep -q 'numeric CONTAINS' "$tmp/error"

echo "SANITY PASS: all checks succeeded"
