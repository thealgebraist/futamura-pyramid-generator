From Stdlib Require Import Extraction.
Require Import DifferentialStaged.

Extraction Language OCaml.
Extraction "differential_extracted.ml"
  DifferentialDSL.integrate
  DifferentialDSL.example.
