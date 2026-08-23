#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/futamura-sanity.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

cc="${CXX:-clang++}"
ocamlc="${OCAMLC:-ocamlc}"
flags="-std=c++23 -Wall -Wextra -Wpedantic"

echo "[1/9] pure OCaml interpreter: 16 cases"
"$ocamlc" -o "$tmp/core16" \
  "$root/core_specializer.ml" "$root/core_specializer_tests.ml"
test "$("$tmp/core16" | grep -c '^PASS ')" -eq 16

echo "[2/9] pure OCaml long specialization: 8 cases"
"$ocamlc" -o "$tmp/corelong" \
  "$root/core_specializer.ml" "$root/core_specializer_long_tests.ml"
test "$("$tmp/corelong" | grep -c '^PASS long ')" -eq 8

echo "[3/9] second projection: pure OCaml compiler"
"$ocamlc" -o "$tmp/second" \
  "$root/core_specializer.ml" "$root/core_second_projection.ml" \
  "$root/core_second_projection_tests.ml"
test "$("$tmp/second" | grep -c '^PASS ')" -eq 4

echo "[3b/11] total Futamura stages 1-3"
cp "$root/core_futamura_n.mli" "$tmp/core_futamura_n.mli"
cp "$root/core_futamura_n.ml" "$tmp/core_futamura_n.ml"
cp "$root/core_specializer.ml" "$tmp/core_specializer.ml"
(
  cd "$tmp"
  "$ocamlc" -c core_specializer.ml
  "$ocamlc" -c core_futamura_n.mli
  "$ocamlc" -I . -c core_futamura_n.ml
  "$ocamlc" -I . -o core_futamura_n \
    core_specializer.ml core_futamura_n.ml "$root/core_futamura_n_tests.ml"
)
"$tmp/core_futamura_n" | grep -q 'PASS total Futamura stages 1-3'

echo "[3b-extra] typed OpenGL-shaped DSL and AArch64 stage 3 artifact"
cp "$root/core_specializer.ml" "$root/core_futamura_n.ml" "$root/core_futamura_n.mli" \
  "$root/opengl_dsl.ml" "$root/opengl_dsl_tests.ml" "$root/opengl_emit.ml" "$tmp/"
(
  cd "$tmp"
  "$ocamlc" -c core_specializer.ml
  "$ocamlc" -c core_futamura_n.mli
  "$ocamlc" -o opengl_dsl_tests core_specializer.cmo core_futamura_n.ml \
    opengl_dsl.ml opengl_dsl_tests.ml
  ./opengl_dsl_tests | grep -q 'PASS OpenGL-shaped typed void-pointer DSL and stage 3'
  "$ocamlc" -o opengl_emit core_specializer.cmo core_futamura_n.ml \
    opengl_dsl.ml opengl_emit.ml
  ./opengl_emit > generated_opengl_arm64.c
)
"$cc" --target=aarch64-none-elf -x c -std=c11 -ffreestanding -Werror \
  -c "$tmp/generated_opengl_arm64.c" -o "$tmp/generated_opengl_arm64.o"

echo "[3c/12] intrinsically typed total DSL"
"$ocamlc" -o "$tmp/typed_core" \
  "$root/typed_core.ml" "$root/typed_core_tests.ml"
"$tmp/typed_core" | grep -q 'PASS intrinsically typed total DSL'

echo "[3d/13] independent Coq/OCaml typed-DSL result"
if command -v coqc >/dev/null 2>&1; then
    (cd "$root" && coqc -q IndependentTypedCore.v)
else
    echo "coqc not found" >&2
    exit 1
fi
"$ocamlc" -o "$tmp/independent_compare" \
  "$root/typed_core.ml" "$root/independent_compare.ml"
"$tmp/independent_compare" | grep -q 'PASS independent Coq/OCaml result: 24'

echo "[3d-extra] compare against extracted Coq result"
(cd "$root" && coqc -q IndependentTypedCoreExtraction.v)
cp "$root/independent_typed_core_result.ml" "$tmp/"
cp "$root/independent_typed_core_result.mli" "$tmp/"
"$ocamlc" -I "$tmp" -c "$tmp/independent_typed_core_result.mli"
"$ocamlc" -I "$tmp" -o "$tmp/independent_extracted_compare" \
  "$tmp/independent_typed_core_result.ml" "$root/typed_core.ml" \
  "$root/independent_extracted_compare.ml"
"$tmp/independent_extracted_compare" | grep -q 'PASS extracted Coq/OCaml result: 24'

echo "[3e/14] independent Coq/OCaml stage recurrence"
if command -v coqc >/dev/null 2>&1; then
    (cd "$root" && coqc -q IndependentStageN.v)
else
    echo "coqc not found" >&2
    exit 1
fi
sed 's/core_futamura_n/stage_n/g' "$root/core_futamura_n.mli" > "$tmp/stage_n.mli"
sed 's/core_futamura_n/stage_n/g' "$root/core_futamura_n.ml" > "$tmp/stage_n.ml"
"$ocamlc" -c "$tmp/stage_n.mli"
"$ocamlc" -I "$tmp" -c "$tmp/stage_n.ml"
sed 's/Core_futamura_n/Stage_n/g' "$root/independent_stage_compare.ml" > "$tmp/independent_stage_compare.ml"
"$ocamlc" -I "$tmp" -o "$tmp/independent_stage_compare" \
  "$root/core_specializer.ml" "$tmp/stage_n.cmo" \
  "$tmp/independent_stage_compare.ml"
"$tmp/independent_stage_compare" | grep -q 'PASS independent Coq/OCaml stage results: 10,7'

echo "[4/9] non-executing resource analysis"
"$ocamlc" -o "$tmp/resources" \
  "$root/core_specializer.ml" "$root/resource_sanity.ml" \
  "$root/resource_sanity_driver.ml"
test "$("$tmp/resources" | grep -c '^case ')" -eq 8
test "$("$tmp/resources" | grep -c 'WARNING: branching shape')" -eq 4

echo "[5/9] C++ second-stage schema compiler"
"$cc" $flags "$root/spec_to_header.cpp" -o "$tmp/spec_to_header"
"$tmp/spec_to_header" "$root/pyramid_language.spec" > "$tmp/generated.hpp"
cmp "$root/pyramid_language.hpp" "$tmp/generated.hpp"

echo "[6/9] C++ third projection"
"$cc" $flags "$root/third_projection.cpp" -o "$tmp/third_projection"
"$tmp/third_projection" "$root/pyramid_language.spec" "$tmp/fixed.cpp"
"$cc" $flags "$tmp/fixed.cpp" -o "$tmp/fixed"
"$tmp/fixed" > "$tmp/fixed.hpp"
cmp "$root/pyramid_language.hpp" "$tmp/fixed.hpp"

echo "[7/9] C++ query compiler and generated programs"
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

echo "[8/9] deterministic OCaml expression sweep"
"$ocamlc" -o "$tmp/fuzz" \
  "$root/core_specializer.ml" "$root/resource_sanity.ml" \
  "$root/core_fuzz_tests.ml"
"$tmp/fuzz" | grep -q 'PASS fuzz: 10000 deterministic expressions'

echo "[9/10] invalid DSL rejection"
if "$tmp/pyramid_generator" \
  'SELECT TOP 1 FROM PYRAMIDS WHERE BUILT_YEAR CONTAINS 2' \
  > /dev/null 2> "$tmp/error"; then
    echo "invalid numeric CONTAINS was accepted" >&2
    exit 1
fi
grep -q 'numeric CONTAINS' "$tmp/error"

echo "[10/11] Coq recursive tower observer"
if command -v coqc >/dev/null 2>&1; then
    (cd "$root" && coqc -q TypedTowerObserver.v && \
        coqc -q CertifiedCorePass.v && coqc -q CertifiedStagedPass.v && \
        coqc -q CertifiedProjection.v && \
        coqc -q CertifiedResource.v && \
        coqc -q CertifiedPyramidDSL.v && \
        coqc -q CertifiedPyramidParser.v && \
        coqc -q CertifiedPyramidCompiler.v && \
        coqc -q CertifiedExtraction.v && ocamlc -c certified_core_extracted.mli && \
        ocamlc -c certified_core_extracted.ml && \
        ocamlc -o certified_extracted_driver certified_core_extracted.cmo \
            certified_extracted_driver.ml && \
        ./certified_extracted_driver && \
        coqc -q CertifiedPyramidExtraction.v && \
        ocamlc -c certified_pyramid_extracted.mli && \
        ocamlc -c certified_pyramid_extracted.ml && \
        ocamlc -o certified_pyramid_driver certified_pyramid_extracted.cmo \
            certified_pyramid_driver.ml && \
        ./certified_pyramid_driver && \
        coqc -q CertifiedPyramidCompilerExtraction.v && \
        ocamlc -c certified_pyramid_compiler_extracted.mli && \
        ocamlc -c certified_pyramid_compiler_extracted.ml && \
        ocamlc -o certified_pyramid_compiler_driver \
            certified_pyramid_compiler_extracted.cmo \
            certified_pyramid_compiler_driver.ml && \
        ./certified_pyramid_compiler_driver && \
        coqc -q CertifiedPyramidEndToEndExtraction.v && \
        ocamlc -c certified_pyramid_end_to_end.mli && \
        ocamlc -c certified_pyramid_end_to_end.ml && \
        ocamlc -o certified_pyramid_end_to_end_driver \
            certified_pyramid_end_to_end.cmo \
            certified_pyramid_end_to_end_driver.ml && \
        ./certified_pyramid_end_to_end_driver && \
        coqc -q CertifiedStagedExtraction.v && \
        ocamlc -c certified_staged_extracted.mli && \
        ocamlc -c certified_staged_extracted.ml && \
        ocamlc -o certified_staged_driver certified_staged_extracted.cmo \
            certified_staged_driver.ml && \
        ./certified_staged_driver)
else
    echo "coqc not found" >&2
    exit 1
fi

echo "[10-extra] Coq fourth-projection type and equations"
(cd "$root" && coqc -q CertifiedFourthProjection.v)

echo "[10-extra-quoted] Coq quoted representation and typed stage 4"
(cd "$root" && coqc -q TypedQuotedFutamura.v)

echo "[11/11] extracted certified pass is compilable"
test -f "$root/certified_core_extracted.cmo"

echo "SANITY PASS: all checks succeeded"
