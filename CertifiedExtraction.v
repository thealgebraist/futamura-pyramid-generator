(** Extraction boundary for the verified arithmetic pass. *)

From Stdlib Require Import Extraction.
Require Import CertifiedCorePass.

Extraction Language OCaml.
Extraction "certified_core_extracted.ml" compile.

