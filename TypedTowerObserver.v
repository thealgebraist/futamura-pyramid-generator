(** A proof-erased meta-type gate for staged specializers.

    The observer is deliberately separate from object-language values.  It
    checks that a declared tower is explicit, recursively meaningful, and
    ordered.  All evidence lives in [Prop], so extraction removes it. *)

Set Universe Polymorphism.
Require Import List Lia.
Import ListNotations.

Inductive tower_ty : Type :=
| TInteger
| TBoolean
| TArrow : tower_ty -> tower_ty -> tower_ty
| TExpr : tower_ty -> tower_ty
| TCode : nat -> tower_ty -> tower_ty.

Fixpoint meaningful_ty (t : tower_ty) : Prop :=
  match t with
  | TInteger => True
  | TBoolean => True
  | TArrow a b => meaningful_ty a /\ meaningful_ty b
  | TExpr a => meaningful_ty a
  | TCode level a => level > 0 /\ meaningful_ty a
  end.

Inductive declaration : Type :=
| TypeDecl : nat -> tower_ty -> declaration
| StageDecl : nat -> nat -> declaration
| Depends : nat -> nat -> declaration.

Inductive earlier : nat -> nat -> Prop :=
| earlier_step : forall n, earlier n (S n)
| earlier_trans : forall a b c,
    earlier a b -> earlier b c -> earlier a c.

Lemma earlier_lt : forall a b, earlier a b -> a < b.
Proof.
  intros a b h; induction h.
  - lia.
  - lia.
Qed.

Inductive Explicit : list declaration -> Prop :=
| explicit_nil : Explicit []
| explicit_type : forall id t rest,
    Explicit rest -> Explicit (TypeDecl id t :: rest)
| explicit_stage : forall id level rest,
    Explicit rest -> Explicit (StageDecl id level :: rest)
| explicit_dep : forall source target rest,
    Explicit rest -> Explicit (Depends source target :: rest).

Inductive Meaningful : list declaration -> Prop :=
| meaningful_nil : Meaningful []
| meaningful_type : forall id t rest,
    meaningful_ty t -> Meaningful rest ->
    Meaningful (TypeDecl id t :: rest)
| meaningful_stage : forall id level rest,
    Meaningful rest -> Meaningful (StageDecl id level :: rest)
| meaningful_dep : forall source target rest,
    Meaningful rest -> Meaningful (Depends source target :: rest).

Inductive Ordered : list declaration -> Prop :=
| ordered_nil : Ordered []
| ordered_type : forall id t rest,
    Ordered rest -> Ordered (TypeDecl id t :: rest)
| ordered_stage : forall id level rest,
    Ordered rest -> Ordered (StageDecl id level :: rest)
| ordered_dep : forall source target rest,
    earlier source target -> Ordered rest ->
    Ordered (Depends source target :: rest).

Record well_formed_tower (d : list declaration) : Prop := {
  explicit_ok : Explicit d;
  meaningful_ok : Meaningful d;
  ordered_ok : Ordered d
}.

(** The proof argument is computationally irrelevant and is erased. *)
Definition accept (d : list declaration)
  (proof : well_formed_tower d) : list declaration := d.

Definition pyramid_tower : list declaration :=
  [ TypeDecl 0 (TExpr TInteger);
    StageDecl 0 0;
    TypeDecl 1 (TCode 1 (TExpr TInteger));
    Depends 0 1 ].

Lemma pyramid_tower_well_formed : well_formed_tower pyramid_tower.
Proof.
  constructor.
  - repeat constructor.
  - repeat constructor; simpl; auto with arith.
  - repeat constructor.
Qed.

Definition accepted_pyramid_tower : list declaration :=
  accept pyramid_tower pyramid_tower_well_formed.

(** A backward dependency has no [Ordered] proof. *)
Definition backward_tower : list declaration :=
  [ Depends 1 0 ].

Lemma backward_tower_not_ordered :
  ~ Ordered backward_tower.
Proof.
  intro h.
  inversion h as [| | | source target rest hbefore hrest].
  pose proof (earlier_lt _ _ hbefore) as impossible.
  lia.
Qed.

(** A meaningless zero-level code type has no meaningfulness proof. *)
Definition meaningless_tower : list declaration :=
  [ TypeDecl 0 (TCode 0 TInteger) ].

Lemma meaningless_tower_not_meaningful :
  ~ Meaningful meaningless_tower.
Proof.
  intro h.
  inversion h as [| id t rest hm hr | |].
  simpl in hm.
  lia.
Qed.
