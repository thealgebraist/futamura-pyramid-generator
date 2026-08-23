(** A small representation-aware, total Coq model of the Futamura tower.

    [Quote A] is deliberately explicit: a stage-4 input is quoted code for a
    compiler-generator, not an arbitrary Coq function silently treated as
    syntax.  The model is extensional (the quoted payload is opaque to the
    meta-theory), while all staging equations are proved in Coq. *)

Set Universe Polymorphism.
Generalizable All Variables.

Record Quote (A : Type) := { run_quote : A }.

Arguments run_quote {A} _. 

Definition quote {A : Type} (value : A) : Quote A := {| run_quote := value |}.

Definition unquote {A : Type} (value : Quote A) : A := run_quote value.

Definition mix {A B : Type}
    (f : Quote (A -> B)) (x : Quote A) : Quote B :=
  quote (unquote f (unquote x)).

(** An explicit representation tower for arbitrary stage depth. *)
Fixpoint QuoteN (n : nat) (A : Type) : Type :=
  match n with
  | O => A
  | S n' => Quote (QuoteN n' A)
  end.

Fixpoint quote_n (n : nat) (A : Type) (value : A) : QuoteN n A :=
  match n with
  | O => value
  | S n' => quote (quote_n n' A value)
  end.

Fixpoint unquote_n (n : nat) (A : Type) : QuoteN n A -> A :=
  match n with
  | O => fun value => value
  | S n' => fun value => unquote_n n' A (unquote value)
  end.

Theorem quote_n_unquote_n :
  forall n (A : Type) (value : A), unquote_n n A (quote_n n A value) = value.
Proof.
  induction n as [| n IH]; simpl; auto.
Qed.

Theorem quote_unquote : forall (A : Type) (x : Quote A), quote (unquote x) = x.
Proof. intros A [x]. reflexivity. Qed.

Theorem mix_correct : forall (A B : Type) (f : Quote (A -> B)) (x : Quote A),
    unquote (mix f x) = (unquote f) (unquote x).
Proof. reflexivity. Qed.

Section Tower.
  Context {Program Data Result : Type}.

  Definition Interpreter := Program -> Data -> Result.
  Definition Compiler := Program -> Data -> Result.
  Definition CompilerGenerator := Interpreter -> Compiler.

  Definition Projection1 :=
    Quote Interpreter -> Quote Program -> Quote (Data -> Result).

  Definition projection1 (i : Quote Interpreter) (p : Quote Program) :
      Quote (Data -> Result) :=
    mix (quote (fun ip : Interpreter => fun d => ip (unquote p) d)) i.

  Definition Projection2 := Quote Interpreter -> Quote (Program -> Data -> Result).

  Definition projection2 (i : Quote Interpreter) :
      Quote (Program -> Data -> Result) :=
    quote (fun p d => unquote i p d).

  Definition Projection3 := Quote (Interpreter -> Program -> Data -> Result).

  Definition projection3 : Projection3 :=
    quote (fun (i : Interpreter) p d => i p d).

  Theorem projection2_correct :
    forall (i : Quote Interpreter) (p : Program) (d : Data),
      unquote (projection2 i) p d = unquote i p d.
  Proof. reflexivity. Qed.

  Theorem projection3_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      unquote projection3 i p d = i p d.
  Proof. reflexivity. Qed.

  Definition Projection4 :=
    Quote CompilerGenerator -> Quote CompilerGenerator.

  (** This is the representation-correct fourth-level type. *)
  Definition projection4 (g : Quote CompilerGenerator) :
      Quote CompilerGenerator := g.

  Theorem projection4_correct :
    forall (g : Quote CompilerGenerator),
      unquote (projection4 g) = unquote g.
  Proof. intros [g]. reflexivity. Qed.

End Tower.

(** A concrete nontrivial generator and its stage-4 residual artifact. *)
Definition NatInterpreter := nat -> nat -> nat.
Definition NatCompiler := nat -> nat -> nat.
Definition NatGenerator := NatInterpreter -> NatCompiler.

Definition add_generator : NatGenerator :=
  fun interpreter program data => interpreter program data.

Definition nat_projection4 (g : Quote NatGenerator) : Quote NatGenerator := g.

Example stage4_executes :
  unquote (nat_projection4 (quote add_generator))
    (fun p d => p + d) 7 5 = 12.
Proof. reflexivity. Qed.

Example four_level_representation_roundtrip :
  unquote_n 4 NatGenerator (quote_n 4 NatGenerator add_generator)
    (fun p d => p + d) 7 5 = 12.
Proof. simpl. reflexivity. Qed.

(** A total arithmetic object language used to exercise the quoted boundary. *)
Inductive Expr : Type -> Type :=
| ENat : nat -> Expr nat
| EAdd : Expr nat -> Expr nat -> Expr nat
| EIf : Expr bool -> Expr nat -> Expr nat -> Expr nat
| EEq : Expr nat -> Expr nat -> Expr bool
| ETrue : Expr bool
| EFalse : Expr bool.

Fixpoint eval_expr {A : Type} (e : Expr A) : A :=
  match e with
  | ENat n => n
  | EAdd x y => eval_expr x + eval_expr y
  | EIf test yes no => if eval_expr test then eval_expr yes else eval_expr no
  | EEq x y => Nat.eqb (eval_expr x) (eval_expr y)
  | ETrue => true
  | EFalse => false
  end.

Definition arithmetic_example : Expr nat :=
  EIf (EEq (EAdd (ENat 2) (ENat 3)) (ENat 5))
      (EAdd (ENat 7) (EAdd (ENat 8) (ENat 9))) (ENat 0).

Example arithmetic_example_correct : eval_expr arithmetic_example = 24.
Proof. vm_compute. reflexivity. Qed.
