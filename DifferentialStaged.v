(** Specialization, differentiation, and finite accumulation for a total DSL. *)

Inductive Expr : Type :=
| Const : nat -> Expr
| Static : Expr
| Var : Expr
| Add : Expr -> Expr -> Expr
| Mul : Expr -> Expr -> Expr.

Fixpoint eval (static dynamic : nat) (e : Expr) : nat :=
  match e with
  | Const n => n
  | Static => static
  | Var => dynamic
  | Add x y => eval static dynamic x + eval static dynamic y
  | Mul x y => eval static dynamic x * eval static dynamic y
  end.

Fixpoint specialize (static : nat) (e : Expr) : Expr :=
  match e with
  | Const n => Const n
  | Static => Const static
  | Var => Var
  | Add x y => Add (specialize static x) (specialize static y)
  | Mul x y => Mul (specialize static x) (specialize static y)
  end.

Theorem specialize_correct :
  forall static dynamic e,
    eval 0 dynamic (specialize static e) = eval static dynamic e.
Proof.
  induction e; simpl; intros; try reflexivity;
    rewrite IHe1, IHe2; reflexivity.
Qed.

Fixpoint derivative (e : Expr) : Expr :=
  match e with
  | Const _ => Const 0
  | Static => Const 0
  | Var => Const 1
  | Add x y => Add (derivative x) (derivative y)
  | Mul x y =>
      Add (Mul (derivative x) y) (Mul x (derivative y))
  end.

Theorem specialize_derivative_commutes :
  forall static e,
    derivative (specialize static e) = specialize static (derivative e).
Proof.
  induction e; simpl; intros; try reflexivity;
    rewrite IHe1, IHe2; reflexivity.
Qed.

(** Formal derivative soundness, expressed as the product-rule polynomial
    identity.  [eval (derivative e)] is the DSL's derivative semantics. *)
Theorem derivative_product_rule :
  forall static dynamic x y,
    eval static dynamic (derivative (Mul x y)) =
    eval static dynamic (Add (Mul (derivative x) y)
                            (Mul x (derivative y))).
Proof. reflexivity. Qed.

Fixpoint sum (f : nat -> nat) (n : nat) : nat :=
  match n with
  | O => 0
  | S n' => f n' + sum f n'
  end.

Definition integrate (e : Expr) (static count : nat) : nat :=
  sum (fun dynamic => eval static dynamic e) count.

Theorem integrate_specialize_commutes :
  forall static count e,
    integrate (specialize static e) 0 count = integrate e static count.
Proof.
  intros static count.
  induction count as [| count IH]; intros e; simpl; auto.
  rewrite (specialize_correct static count e).
  apply IH.
Qed.

Definition example : Expr :=
  Mul (Add Static Var) (Add Var (Const 2)).

Example specialized_example :
  eval 0 3 (specialize 5 example) = 40.
Proof. vm_compute. reflexivity. Qed.

Example derivative_example :
  eval 5 3 (derivative example) = 16.
Proof. vm_compute. reflexivity. Qed.

Example integrated_example :
  integrate (specialize 5 example) 0 3 = integrate example 5 3.
Proof. apply integrate_specialize_commutes. Qed.
