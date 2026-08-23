(** Structural resource accounting for the staged residualizer. *)

Require Import CertifiedStagedPass.

Fixpoint source_size (e : source) : nat :=
  match e with
  | SConst _ => 1
  | SInput => 1
  | SAdd a b => 1 + source_size a + source_size b
  end.

Fixpoint code_size {level} (c : code level) : nat :=
  match c with
  | CConst _ _ => 1
  | CInput _ => 1
  | CAdd _ a b => 1 + code_size a + code_size b
  | CQuote _ inner => 1 + code_size inner
  end.

Lemma residual_size_exact : forall level e,
  code_size (residualize (level := level) e) = source_size e.
Proof.
  intros level e; induction e as [n| |a IHa b IHb]; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite IHa, IHb; reflexivity.
Qed.

Theorem residual_size_linear : forall level e,
  code_size (residualize (level := level) e) <= source_size e.
Proof.
  intros; rewrite residual_size_exact; apply le_n.
Qed.
