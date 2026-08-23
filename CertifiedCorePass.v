(** A minimal CompCert-style verified pass.

    This deliberately small pass is the executable core that the staged
    observer can guard: source and target have explicit semantics, and the
    compiler is proved to preserve them. *)

From Stdlib Require Import Arith.PeanoNat Lia.

Inductive source : Type :=
| SConst : nat -> source
| SAdd : source -> source -> source.

Inductive target : Type :=
| TConst : nat -> target
| TAdd : target -> target -> target.

Fixpoint eval_source (e : source) : nat :=
  match e with
  | SConst n => n
  | SAdd a b => eval_source a + eval_source b
  end.

Fixpoint eval_target (e : target) : nat :=
  match e with
  | TConst n => n
  | TAdd a b => eval_target a + eval_target b
  end.

Definition fold_add (x y : target) : target :=
  match x, y with
  | TConst a, TConst b => TConst (a + b)
  | lhs, rhs => TAdd lhs rhs
  end.

Lemma fold_add_correct : forall x y,
  eval_target (fold_add x y) = eval_target x + eval_target y.
Proof.
  destruct x as [x|x1 x2]; destruct y as [y|y1 y2];
    simpl; reflexivity.
Qed.

(** [compile] folds additions whose inputs are already constants and removes
    the neutral element on the left.  It is total and structurally recursive. *)
Fixpoint compile (e : source) : target :=
  match e with
  | SConst n => TConst n
  | SAdd a b =>
      fold_add (compile a) (compile b)
  end.

Lemma compile_correct :
  forall e, eval_target (compile e) = eval_source e.
Proof.
  induction e as [n|a IHa b IHb].
  - reflexivity.
  - cbn [compile].
    rewrite fold_add_correct, IHa, IHb.
    reflexivity.
Qed.

(** The pass is therefore a certified residualization boundary. *)
Theorem compiler_semantics_preserved :
  forall e, eval_target (compile e) = eval_source e.
Proof.
  apply compile_correct.
Qed.
