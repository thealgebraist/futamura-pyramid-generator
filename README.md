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

`third_projection.cpp` performs a bootstrap/self-application check on the
compiler generator. Because `spec_to_header.cpp` is already a minimal,
fixed-schema compiler generator, its third projection is identity-shaped: no
semantic work can be erased without changing the language. The residual
compiler generator is nevertheless emitted and compiled as an independent
artifact:

```sh
clang++ -std=c++23 -Wall -Wextra -pedantic third_projection.cpp -o third_projection
./third_projection spec_to_header.cpp residual_spec_to_header.cpp
clang++ -std=c++23 -Wall -Wextra -pedantic \
  residual_spec_to_header.cpp -o residual_spec_to_header
./residual_spec_to_header pyramid_language.spec > residual_language.hpp
cmp pyramid_language.hpp residual_language.hpp
```

Conceptually:

```text
compiler + fixed compiler-generator description -> compiler generator
```

The identity-shaped result is evidence that the current generator is already
at its useful residual boundary, rather than evidence of a new runtime layer.

Online Wikidata acquisition is intentionally a separate adapter. Keeping the
generator dependency-free makes its specification, semantics, and staging
boundary easy to audit.
