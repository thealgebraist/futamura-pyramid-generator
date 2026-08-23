From Stdlib Require Import Extraction.
Require Import CertifiedPyramidCompiler.

Extraction Language OCaml.
Extraction "certified_pyramid_compiler_extracted.ml" compile_query run_compiled.

