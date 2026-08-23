(** Extraction boundary for the stage-indexed residualizer. *)

From Stdlib Require Import Extraction.
Require Import CertifiedStagedPass.

Extraction Language OCaml.
Extraction "certified_staged_extracted.ml" residualize run.

