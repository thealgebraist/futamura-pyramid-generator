# Futamura Pyramid Generator

A compact C++23 staged generator for a small SQL-like pyramid DSL.

The pipeline is:

```text
records file + SQL sentence
    -> schema-driven validation
    -> typed predicates
    -> residual C++23 loop
    -> generated database executable
```

Build the generator:

```sh
clang++ -std=c++23 -Wall -Wextra -pedantic pyramid_generator.cpp -o pyramid_generator
```

Records use the deliberately small format:

```text
NAME|COUNTRY|BUILT_YEAR|HEIGHT_M
Great Pyramid of Giza|Egypt|-2560|146.6
Pyramid of Khafre|Egypt|-2570|136.4
```

Generate a specialized program:

```sh
./pyramid_generator \
  'SELECT TOP 1 FROM PYRAMIDS WHERE NAME CONTAINS "Great"' \
  pyramids.records > pyramids.cpp
clang++ -std=c++23 -Wall -Wextra -pedantic pyramids.cpp -o pyramids
./pyramids
```

The generated program contains no SQL parser or general interpreter. The
generator validates the DSL first, then performs a Futamura-style first
projection: the fixed query is residualized into a direct C++ loop.

## Second projection

`spec_to_header.cpp` demonstrates the second Futamura projection. The fixed
language-specification interpreter is specialized by `pyramid_language.spec`
to produce the schema header used by the first-stage compiler:

```sh
clang++ -std=c++23 -Wall -Wextra -pedantic spec_to_header.cpp -o spec_to_header
./spec_to_header pyramid_language.spec > pyramid_language.hpp
```

Conceptually:

```text
interpreter + fixed DSL specification -> DSL compiler
```

The resulting `pyramid_language.hpp` is a generated compiler component. The
per-query stage then specializes that compiler with a validated query to emit
the residual database program.

## Third projection

`third_projection.cpp` performs real partial evaluation of the second-stage
compiler with respect to a fixed language specification. The residual
compiler no longer reads or parses a specification at runtime; it emits the
fixed schema directly:

```sh
clang++ -std=c++23 -Wall -Wextra -pedantic third_projection.cpp -o third_projection
./third_projection pyramid_language.spec fixed_spec_to_header.cpp
clang++ -std=c++23 -Wall -Wextra -pedantic \
  fixed_spec_to_header.cpp -o fixed_spec_to_header
./fixed_spec_to_header > fixed_language.hpp
cmp pyramid_language.hpp fixed_language.hpp
```

Conceptually:

```text
compiler + fixed compiler-generator description -> specialized compiler generator
```

The generated `fixed_spec_to_header.cpp` has no language-spec parser and no
runtime input. Its only remaining job is to emit the already-specialized
schema header.

Online Wikidata acquisition is intentionally a separate adapter. Keeping the
generator dependency-free makes its specification, semantics, and staging
boundary easy to audit.

## Pure OCaml core specializer

`core_specializer.ml` is a self-contained pure OCaml core written in the same
ADT-oriented language it specializes. It defines:

```text
expr -> value -> result
expr -> code -> residual OCaml
```

The specializer partially evaluates the interpreter with respect to static
subexpressions. The driver is the only file with I/O:

```sh
ocamlc -o core_specializer core_specializer.ml core_specializer_driver.ml
./core_specializer
```

The expected output is:

```text
9
(let x = (input + 1) in (if ((input + 1) = 4) then 10 else 20))
```

The core uses only algebraic data types, recursion, immutable lists, pattern
matching, and pure functions. The residual program is represented by another
ADT and rendered only at the boundary.

## Second projection in pure OCaml

`core_second_projection.ml` makes the second projection explicit. It defines a
language specification ADT and a generic interpreter parameterized by that
specification. Specializing the interpreter with `core_language` produces the
fixed `core_compiler` function:

```text
interpreter + fixed language specification -> compiler
```

Test it with:

```sh
ocamlc -o core_second_projection_tests \
  core_specializer.ml \
  core_second_projection.ml \
  core_second_projection_tests.ml
./core_second_projection_tests
```

## Non-executing resource sanity pass

`resource_sanity.ml` performs a separate structural pass over an expression.
It never calls `eval` or `specialize`. It estimates operation count, AST
memory, maximum depth, dynamic leaves, and the logarithmic growth shape. It
flags operation/memory budget violations and exponential-like branching before
the expensive pass is run:

```sh
ocamlc -o resource_sanity \
  core_specializer.ml resource_sanity.ml resource_sanity_driver.ml
./resource_sanity
```

## Full sanity suite

Run all pure OCaml tests, resource checks, C++ projection checks, generated
program cases, and invalid-input checks with:

```sh
./sanity_test.sh
```

The suite builds every stage in a temporary directory, so it does not depend
on stale generated artifacts in the repository.

It also runs 10,000 deterministic expression shapes through evaluation,
specialization, residual rendering, and resource estimation.
