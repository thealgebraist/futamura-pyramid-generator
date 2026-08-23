(**
   A small Coq account of the typed equations behind the Futamura
   projections.  We model the partial evaluator extensionally: the
   implementation details of parsing and residual construction are outside
   this semantic lemma.

   The important boundary is explicit.  The first three equations follow
   from [mix_correct].  A fourth or n-th projection needs another typed
   representation level; it cannot be obtained by blindly iterating an
   untyped function.
*)

Set Universe Polymorphism.

Section Futamura.

  Context {Program Data Result : Type}.

  Definition Interpreter := Program -> Data -> Result.
  Definition Residual := Data -> Result.
  Definition Compiler := Program -> Residual.

  Variable mix : Interpreter -> Program -> Residual.

  Hypothesis mix_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      mix i p d = i p d.

  (** First projection: interpreter + fixed program = executable residual. *)
  Definition projection1 (i : Interpreter) (p : Program) : Residual :=
    mix i p.

  Theorem projection1_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      projection1 i p d = i p d.
  Proof.
    intros i p d.
    unfold projection1.
    apply mix_correct.
  Qed.

  (** Second projection: interpreter fixed, program remains dynamic. *)
  Definition projection2 (i : Interpreter) : Compiler :=
    fun p => projection1 i p.

  Theorem projection2_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      projection2 i p d = i p d.
  Proof.
    intros i p d.
    unfold projection2.
    apply projection1_correct.
  Qed.

  (**
     A compiler-generator is a program which accepts an interpreter and
     returns its compiler.  Its semantic contract is stated independently
     of how the generator is represented.
  *)
  Definition CompilerGenerator := Interpreter -> Compiler.

  Variable cogen : CompilerGenerator.
  Hypothesis cogen_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      cogen i p d = i p d.

  (** Third projection contract. *)
  Definition projection3 : CompilerGenerator := cogen.

  Theorem projection3_correct :
    forall (i : Interpreter) (p : Program) (d : Data),
      projection3 i p d = i p d.
  Proof.
    intros i p d.
    unfold projection3.
    apply cogen_correct.
  Qed.

End Futamura.

(**
   Why there is no untyped projection_n here:

   [projection1] consumes an interpreter and a program;
   [projection2] consumes an interpreter and returns a compiler;
   [projection3] consumes an interpreter and returns a compiler-generator.

   The result types are different.  To continue, one must introduce a
   representation tower (for example Exp A and Exp (Exp A)) and a typed
   self-applicable specializer.  The needed additional theorem is not a
   consequence of [mix_correct] alone.  This is the proof boundary rather
   than an omitted implementation detail.
*)

Theorem projection3_is_not_projection2 :
  forall (Program Data Result : Type),
    (Program -> Data -> Result) -> Type.
Proof.
  intros Program0 Data0 Result0 _.
  exact (Program0 -> (Data0 -> Result0))%type.
Qed.
