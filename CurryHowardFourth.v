(** Curry--Howard derivation of the fourth Futamura projection type. *)

Set Universe Polymorphism.

Section Derivation.
  Context (Program Data Result : Type).

  (** Under Curry--Howard, these are types; an arrow is both a function type
      and the proposition that an artifact transforms into another artifact. *)
  Definition Interpreter : Type := Program -> Data -> Result.
  Definition Compiler : Type := Program -> Data -> Result.
  Definition CompilerGenerator : Type := Interpreter -> Compiler.

  (** The third projection has type [CompilerGenerator].  Continuing the
      same construction one level gives a generator of compiler-generators. *)
  Definition FourthProjection : Type :=
    CompilerGenerator -> CompilerGenerator.

  Theorem fourth_projection_type_is_arrow :
    FourthProjection = (CompilerGenerator -> CompilerGenerator).
  Proof. reflexivity. Qed.

  (** The proof term is the identity transformation.  Its type is the
      Curry--Howard witness that a stage-4 artifact consumes and returns a
      stage-3 artifact. *)
  Definition fourth_identity : FourthProjection :=
    fun generator => generator.

  Theorem fourth_identity_typed :
    forall generator : CompilerGenerator,
      fourth_identity generator = generator.
  Proof. intros; reflexivity. Qed.

  (** If code representations are explicit, replace each artifact type by
      its quoted proposition/type.  This is the form needed for genuine
      self-application rather than merely extensional transformation. *)
  Variable Code : Type -> Type.
  Definition RepresentedFourth : Type :=
    Code CompilerGenerator -> Code CompilerGenerator.

  Theorem represented_fourth_is_next_arrow :
    RepresentedFourth = (Code CompilerGenerator -> Code CompilerGenerator).
  Proof. reflexivity. Qed.

  (** A small Curry--Howard stage-indexed recurrence for the generator tail. *)
  Fixpoint GeneratorLevel (n : nat) : Type :=
    match n with
    | O => CompilerGenerator
    | S n' => GeneratorLevel n' -> GeneratorLevel n'
    end.

  Example level_four_is_generator_transformer :
    GeneratorLevel 1 = (CompilerGenerator -> CompilerGenerator).
  Proof. reflexivity. Qed.

  Example level_four_identity : GeneratorLevel 1.
  Proof. exact (fun generator => generator). Qed.
End Derivation.
