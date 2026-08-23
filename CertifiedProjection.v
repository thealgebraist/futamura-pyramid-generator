(** Executable projection contracts for the verified core. *)

Set Universe Polymorphism.

Section Projection.
  Context {Program Data Result : Type}.

  Definition interpreter := Program -> Data -> Result.
  Definition residual := Data -> Result.
  Definition compiler := Program -> residual.

  Definition mix (i : interpreter) (p : Program) : residual := i p.

  Definition compiler_for (i : interpreter) : compiler :=
    fun p => mix i p.

  Definition compiler_generator := interpreter -> compiler.

  Definition cogen : compiler_generator := compiler_for.

  Theorem first_projection : forall i p d,
    mix i p d = i p d.
  Proof. reflexivity. Qed.

  Theorem second_projection : forall i p d,
    compiler_for i p d = i p d.
  Proof. reflexivity. Qed.

  Theorem third_projection : forall i p d,
    cogen i p d = i p d.
  Proof. reflexivity. Qed.

  (** The representation is explicit: self-application is only exposed at a
      level where a program is itself represented as data. *)
  Definition represented (A : Type) := nat -> A.

  Definition self_apply (s : represented (interpreter -> compiler)) :
      interpreter -> compiler :=
    fun i => s 0 i.

End Projection.
