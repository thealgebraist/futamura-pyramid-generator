From Stdlib Require Import Extraction.
Require Import CertifiedPyramidCompiler.

Extraction Language OCaml.
Extraction "certified_pyramid_end_to_end.ml" run_tokens.

