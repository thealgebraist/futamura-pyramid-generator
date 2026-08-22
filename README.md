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

Online Wikidata acquisition is intentionally a separate adapter. Keeping the
generator dependency-free makes its specification, semantics, and staging
boundary easy to audit.
