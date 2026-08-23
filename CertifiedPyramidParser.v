(** Token parser for a fixed, unambiguous pyramid-query grammar. *)

From Stdlib Require Import List.
Import ListNotations.
Require Import CertifiedPyramidDSL.

Inductive token : Type :=
| TokTop : nat -> token
| TokId : nat -> token
| TokCountry : nat -> token
| TokYear : nat -> token
| TokHeightAtLeast : nat -> token.

Definition parse (tokens : list token) : option query :=
  match tokens with
  | [TokTop n] => Some
      {| limit := n; required_id := None; required_country := None;
         required_year := None; minimum_height_cm := None |}
  | [TokTop n; TokId i] => Some
      {| limit := n; required_id := Some i; required_country := None;
         required_year := None; minimum_height_cm := None |}
  | [TokTop n; TokCountry c] => Some
      {| limit := n; required_id := None; required_country := Some c;
         required_year := None; minimum_height_cm := None |}
  | [TokTop n; TokYear y] => Some
      {| limit := n; required_id := None; required_country := None;
         required_year := Some y; minimum_height_cm := None |}
  | [TokTop n; TokHeightAtLeast h] => Some
      {| limit := n; required_id := None; required_country := None;
         required_year := None; minimum_height_cm := Some h |}
  | [TokTop n; TokId i; TokCountry c; TokYear y; TokHeightAtLeast h] => Some
      {| limit := n; required_id := Some i; required_country := Some c;
         required_year := Some y; minimum_height_cm := Some h |}
  | _ => None
  end.

Lemma parse_top : forall n,
  parse [TokTop n] = Some
    {| limit := n; required_id := None; required_country := None;
       required_year := None; minimum_height_cm := None |}.
Proof. reflexivity. Qed.

Lemma parse_rejects_empty : parse [] = None.
Proof. reflexivity. Qed.

Lemma parse_rejects_malformed : forall n,
  parse [TokId n] = None.
Proof. reflexivity. Qed.

Lemma parse_full_query : forall n i c y h,
  parse [TokTop n; TokId i; TokCountry c; TokYear y; TokHeightAtLeast h] =
  Some {| limit := n; required_id := Some i; required_country := Some c;
          required_year := Some y; minimum_height_cm := Some h |}.
Proof. reflexivity. Qed.
