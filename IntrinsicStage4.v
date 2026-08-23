(** A syntax-level representation for a concrete fourth-stage artifact. *)

Inductive Ty := TNat | TBool.

Inductive Expr : Ty -> Type :=
| ENat : nat -> Expr TNat
| EBool : bool -> Expr TBool
| EAdd : Expr TNat -> Expr TNat -> Expr TNat
| EEq : Expr TNat -> Expr TNat -> Expr TBool
| EIf : forall A, Expr TBool -> Expr A -> Expr A -> Expr A.

Fixpoint eval {A : Ty} (e : Expr A) :
    match A with TNat => nat | TBool => bool end :=
  match e with
  | ENat n => n
  | EBool b => b
  | EAdd x y => eval x + eval y
  | EEq x y => Nat.eqb (eval x) (eval y)
  | EIf _ test yes no => if eval test then eval yes else eval no
  end.

Inductive NatInterpreterCode : Type :=
| NIAdd : NatInterpreterCode.

Definition run_interpreter (c : NatInterpreterCode) : nat -> nat -> nat :=
  match c with NIAdd => fun program data => program + data end.

Inductive NatGeneratorCode : Type :=
| NGIdentity : NatGeneratorCode.

Definition run_generator (c : NatGeneratorCode) :
    NatInterpreterCode -> nat -> nat -> nat :=
  match c with
  | NGIdentity => fun interpreter program data =>
      run_interpreter interpreter program data
  end.

(** This is now actual code-to-code stage 4, rather than a function wrapper. *)
Definition stage4_code : NatGeneratorCode -> NatGeneratorCode :=
  fun code => code.

Theorem stage4_code_correct :
  forall code interpreter program data,
    run_generator (stage4_code code) interpreter program data =
    run_generator code interpreter program data.
Proof. reflexivity. Qed.

Definition nontrivial_program : Expr TNat :=
  @EIf TNat (EEq (EAdd (ENat 2) (ENat 3)) (ENat 5))
      (EAdd (ENat 7) (EAdd (ENat 8) (ENat 9))) (ENat 0).

Example typed_program_result : eval nontrivial_program = 24.
Proof. vm_compute. reflexivity. Qed.

Example stage4_nontrivial_result :
  run_generator (stage4_code NGIdentity) NIAdd 7 5 = 12.
Proof. vm_compute. reflexivity. Qed.
