(** Stage-indexed residual code.

    The stage index is phantom at runtime but real to the Coq type checker.
    Quotation raises the stage and [run] proves that quotation preserves the
    represented value. *)

From Stdlib Require Import Lia.

Inductive code : nat -> Type :=
| CConst : forall level, nat -> code level
| CInput : forall level, code level
| CAdd : forall level, code level -> code level -> code level
| CQuote : forall level, code level -> code (S level).

Fixpoint run {level} (input : nat) (c : code level) : nat :=
  match c with
  | CConst _ n => n
  | CInput _ => input
  | CAdd _ a b => run input a + run input b
  | CQuote _ inner => run input inner
  end.

Definition quote {level} (c : code level) : code (S level) :=
  CQuote level c.

Lemma quote_preserves : forall level (c : code level),
  forall input, run input (quote c) = run input c.
Proof.
  intros level c input; reflexivity.
Qed.

(** A residualizer for arithmetic expressions.  The source has no runtime
    stage parameter: specialization chooses a residual code level explicitly. *)
Inductive source : Type :=
| SConst : nat -> source
| SInput : source
| SAdd : source -> source -> source.

Fixpoint residualize {level} (e : source) : code level :=
  match e with
  | SConst n => CConst level n
  | SInput => CInput level
  | SAdd a b => CAdd level (residualize a) (residualize b)
  end.

Fixpoint eval_source (input : nat) (e : source) : nat :=
  match e with
  | SConst n => n
  | SInput => input
  | SAdd a b => eval_source input a + eval_source input b
  end.

Lemma residualize_correct : forall level e,
  forall input,
  run input (residualize (level := level) e) = eval_source input e.
Proof.
  intros level e; induction e as [n| |a IHa b IHb]; intros input; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite IHa, IHb; reflexivity.
Qed.

Theorem staged_residualization_correct : forall level e,
  forall input,
  run input (residualize (level := level) e) = eval_source input e.
Proof.
  apply residualize_correct.
Qed.
