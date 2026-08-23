(** The differentiating transformation as a staged, quoted DSL pass. *)
Require Import TypedQuotedFutamura.
Require Import DifferentialStaged.

Definition quoted_specialize (static : nat)
    (e : Quote DifferentialDSL.Expr) : Quote DifferentialDSL.Expr :=
  quote (DifferentialDSL.specialize static (unquote e)).

Definition quoted_derivative (e : Quote DifferentialDSL.Expr) :
    Quote DifferentialDSL.Expr :=
  quote (DifferentialDSL.derivative (unquote e)).

Theorem quoted_specialize_correct :
  forall static dynamic (e : Quote DifferentialDSL.Expr),
    DifferentialDSL.eval 0 dynamic (unquote (quoted_specialize static e)) =
    DifferentialDSL.eval static dynamic (unquote e).
Proof.
  intros; apply DifferentialDSL.specialize_correct.
Qed.

Theorem quoted_derivative_specialization_commutes :
  forall static (e : Quote DifferentialDSL.Expr),
    unquote (quoted_derivative (quoted_specialize static e)) =
    unquote (quoted_specialize static (quoted_derivative e)).
Proof.
  intros; apply DifferentialDSL.specialize_derivative_commutes.
Qed.

Theorem quoted_integrate_specialization_commutes :
  forall static count (e : Quote DifferentialDSL.Expr),
    DifferentialDSL.integrate (unquote (quoted_specialize static e)) 0 count =
    DifferentialDSL.integrate (unquote e) static count.
Proof.
  intros; apply DifferentialDSL.integrate_specialize_commutes.
Qed.
