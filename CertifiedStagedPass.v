(** Stage-indexed residual code.

    The stage index is phantom at runtime but real to the Coq type checker.
    Quotation raises the stage and [run] proves that quotation preserves the
    represented value. *)

From Stdlib Require Import Lia.

Inductive code : nat -> Type :=
| CConst : forall level, nat -> code level
| CAdd : forall level, code level -> code level -> code level
| CQuote : forall level, code level -> code (S level).

Fixpoint run {level} (c : code level) : nat :=
  match c with
  | CConst _ n => n
  | CAdd _ a b => run a + run b
  | CQuote _ inner => run inner
  end.

Definition quote {level} (c : code level) : code (S level) :=
  CQuote level c.

Lemma quote_preserves : forall level (c : code level),
  run (quote c) = run c.
Proof.
  intros level c; reflexivity.
Qed.

(** A residualizer for arithmetic expressions.  The source has no runtime
    stage parameter: specialization chooses a residual code level explicitly. *)
Inductive source : Type :=
| SConst : nat -> source
| SAdd : source -> source -> source.

Fixpoint residualize {level} (e : source) : code level :=
  match e with
  | SConst n => CConst level n
  | SAdd a b => CAdd level (residualize a) (residualize b)
  end.

Fixpoint eval_source (e : source) : nat :=
  match e with
  | SConst n => n
  | SAdd a b => eval_source a + eval_source b
  end.

Lemma residualize_correct : forall level e,
  run (residualize (level := level) e) = eval_source e.
Proof.
  intros level e; induction e as [n|a IHa b IHb]; simpl.
  - reflexivity.
  - rewrite IHa, IHb; reflexivity.
Qed.

Theorem staged_residualization_correct : forall level e,
  run (residualize (level := level) e) = eval_source e.
Proof.
  apply residualize_correct.
Qed.

