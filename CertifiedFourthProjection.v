(**
   The fourth-level type boundary.

   In this representation-independent account, stage 3 is a
   [CompilerGenerator]: a value which maps an interpreter to a compiler.
   Stage 4 must therefore consume a *representation of such generators* and
   return a residual generator.  It is not another [Interpreter -> Compiler]
   value unless a representation/evaluator for compiler-generators has been
   supplied explicitly.
*)

Set Universe Polymorphism.
Require Import CertifiedProjection.

Section Fourth.
  Context {Program Data Result : Type}.

  Definition Interpreter := Program -> Data -> Result.
  Definition Compiler := Program -> Data -> Result.
  Definition CompilerGenerator := Interpreter -> Compiler.

  (** The level-4 artifact type: a compiler-generator transformer. *)
  Definition CompilerGeneratorTransformer :=
    CompilerGenerator -> CompilerGenerator.

  Definition projection4 (transformer : CompilerGeneratorTransformer) :
      CompilerGeneratorTransformer := transformer.

  Theorem projection4_correct :
    forall (transformer : CompilerGeneratorTransformer)
           (generator : CompilerGenerator)
           (i : Interpreter) (p : Program) (d : Data),
      projection4 transformer generator i p d =
      transformer generator i p d.
  Proof. reflexivity. Qed.

  (** A concrete total level-4 transformer.  It preserves the generator's
      behavior while making the extra representation level explicit. *)
  Definition identity_transformer : CompilerGeneratorTransformer :=
    fun generator => generator.

  Example identity_level4 :
    forall (generator : CompilerGenerator) (i : Interpreter)
           (p : Program) (d : Data),
      projection4 identity_transformer generator i p d = generator i p d.
  Proof. reflexivity. Qed.

  (** If a compiler-generator is encoded as data, self-application is a
      separate, typed operation; it is not silently assumed by projection 4. *)
  Definition represented_generator := nat -> CompilerGenerator.

  Definition self_apply_level4
      (encoded : represented_generator) : CompilerGenerator := encoded 0.

  Theorem self_apply_level4_correct :
    forall (encoded : represented_generator) (i : Interpreter)
           (p : Program) (d : Data),
      self_apply_level4 encoded i p d = encoded 0 i p d.
  Proof. reflexivity. Qed.
End Fourth.
