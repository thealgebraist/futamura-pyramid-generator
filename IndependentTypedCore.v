(** Independent Coq semantics for the intrinsically typed core DSL.

    This file intentionally does not import [typed_core.ml] or any extracted
    artifact.  It is an independent derivation used as a cross-check. *)

Inductive expr : Type -> Type :=
| ENat : nat -> expr nat
| EBool : bool -> expr bool
| EAdd : expr nat -> expr nat -> expr nat
| EEqNat : expr nat -> expr nat -> expr bool
| EIf : forall A, expr bool -> expr A -> expr A -> expr A.

Fixpoint eval {A : Type} (e : expr A) : A :=
  match e with
  | ENat n => n
  | EBool b => b
  | EAdd x y => eval x + eval y
  | EEqNat x y => Nat.eqb (eval x) (eval y)
  | EIf _ test yes_branch no_branch =>
      if eval test then eval yes_branch else eval no_branch
  end.

Definition nontrivial_example : expr nat :=
  @EIf nat (EEqNat (EAdd (ENat 2) (ENat 3)) (ENat 5))
      (EAdd (ENat 7) (EAdd (ENat 8) (ENat 9)))
      (ENat 0).

Example independent_result : eval nontrivial_example = 24.
Proof. vm_compute. reflexivity. Qed.

Definition independent_result_nat : nat := eval nontrivial_example.
