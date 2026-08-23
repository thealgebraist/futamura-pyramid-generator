(** Compiler boundary for the certified pyramid DSL. *)

Require Import CertifiedPyramidDSL.
Require Import List.
Import ListNotations.

Record compiled_query : Type := {
  compiled_limit : nat;
  compiled_predicate : pyramid -> bool
}.

Definition compile_query (q : query) : compiled_query :=
  {| compiled_limit := limit q;
     compiled_predicate := fun p => matches q p |}.

Fixpoint run_compiled (c : compiled_query) (rows : list pyramid)
  : list pyramid :=
  match rows with
  | [] => []
  | p :: rest =>
      if compiled_predicate c p
      then match compiled_limit c with
           | O => []
           | S n => p :: (run_compiled
                           {| compiled_limit := n;
                              compiled_predicate := compiled_predicate c |}
                           rest)
           end
      else run_compiled c rest
  end.

Lemma compile_query_predicate : forall q p,
  compiled_predicate (compile_query q) p = matches q p.
Proof.
  reflexivity.
Qed.

Theorem compile_query_correct : forall q rows,
  run_compiled (compile_query q) rows = select q rows.
Proof.
  intros q rows; revert q.
  induction rows as [|p rows IH]; intros q; simpl.
  - reflexivity.
  - destruct (matches q p) eqn:hm.
    + destruct (limit q) as [|n] eqn:hl; simpl.
      * reflexivity.
      * f_equal.
        change (run_compiled
          (compile_query
             {| limit := n; required_id := required_id q;
                required_country := required_country q;
                required_year := required_year q;
                minimum_height_cm := minimum_height_cm q |}) rows =
          select
             {| limit := n; required_id := required_id q;
                required_country := required_country q;
                required_year := required_year q;
                minimum_height_cm := minimum_height_cm q |} rows).
        apply IH.
    + apply IH.
Qed.

Theorem compiled_respects_limit : forall q rows,
  length (run_compiled (compile_query q) rows) <= limit q.
Proof.
  intros q rows.
  rewrite compile_query_correct.
  apply select_respects_limit.
Qed.

Theorem compiled_rows_match : forall q rows,
  Forall (fun p => matches q p = true)
    (run_compiled (compile_query q) rows).
Proof.
  intros q rows.
  rewrite compile_query_correct.
  apply select_rows_match.
Qed.

Theorem compiled_rows_from_input : forall q rows p,
  In p (run_compiled (compile_query q) rows) -> In p rows.
Proof.
  intros q rows p hp.
  rewrite compile_query_correct in hp.
  apply select_rows_from_input with (q := q); exact hp.
Qed.

Theorem compiled_zero : forall q rows,
  limit q = 0 -> run_compiled (compile_query q) rows = [].
Proof.
  intros q rows hlimit.
  rewrite compile_query_correct.
  apply select_zero; exact hlimit.
Qed.
