(** Two formally checked analogues: query compilation and normalization. *)

Require Import List.
Import ListNotations.

Module QueryCompilationAnalogue.

Definition Query := nat -> bool.

Fixpoint filter (q : Query) (rows : list nat) : list nat :=
  match rows with
  | nil => nil
  | row :: rest => if q row then row :: filter q rest else filter q rest
  end.

Definition interpreter (q : Query) (rows : list nat) : list nat :=
  filter q rows.

Definition compile (q : Query) : list nat -> list nat :=
  fun rows => filter q rows.

Theorem compiler_correct :
  forall q rows, compile q rows = interpreter q rows.
Proof. reflexivity. Qed.

Definition year_is (year : nat) : Query :=
  fun candidate => Nat.eqb candidate year.

Example compiled_query :
  compile (year_is 1970) (1970 :: 1969 :: 1970 :: nil) =
  1970 :: 1970 :: nil.
Proof. vm_compute. reflexivity. Qed.

End QueryCompilationAnalogue.

Module NormalizationAnalogue.

Inductive Term : Type :=
| Lit : nat -> Term
| Plus : Term -> Term -> Term.

Fixpoint denote (t : Term) : nat :=
  match t with
  | Lit n => n
  | Plus x y => denote x + denote y
  end.

Fixpoint normalize (t : Term) : Term :=
  match t with
  | Lit n => Lit n
  | Plus x y =>
      match normalize x, normalize y with
      | Lit n, Lit m => Lit (n + m)
      | nx, ny => Plus nx ny
      end
  end.

Theorem normalize_correct :
  forall t, denote (normalize t) = denote t.
Proof.
  induction t as [n | x IHx y IHy]; simpl; auto.
  destruct (normalize x) as [n | x'];
    destruct (normalize y) as [m | y']; simpl in *; rewrite ?IHx, ?IHy; reflexivity.
Qed.

Example normalized_term :
  normalize (Plus (Plus (Lit 2) (Lit 3)) (Lit 4)) = Lit 9.
Proof. reflexivity. Qed.

End NormalizationAnalogue.
