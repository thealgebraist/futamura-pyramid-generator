(** A small formally specified fragment of the pyramid query DSL. *)

From Stdlib Require Import List.
Import ListNotations.

Record pyramid : Type := {
  pyramid_id : nat;
  country_id : nat;
  built_year : nat;
  height_cm : nat
}.

Record query : Type := {
  limit : nat;
  required_id : option nat;
  required_country : option nat;
  required_year : option nat;
  minimum_height_cm : option nat
}.

Definition matches (q : query) (p : pyramid) : bool :=
  let year_ok :=
    match required_year q with
    | None => true
    | Some year => Nat.eqb year (built_year p)
    end in
  let country_ok :=
    match required_country q with
    | None => true
    | Some country => Nat.eqb country (country_id p)
    end in
  let id_ok :=
    match required_id q with
    | None => true
    | Some identifier => Nat.eqb identifier (pyramid_id p)
    end in
  let height_ok :=
    match minimum_height_cm q with
    | None => true
    | Some minimum => Nat.leb minimum (height_cm p)
    end in
  andb (andb (andb id_ok country_ok) year_ok) height_ok.

Fixpoint take (n : nat) (xs : list pyramid) : list pyramid :=
  match n, xs with
  | O, _ => []
  | S n', [] => []
  | S n', x :: xs' => x :: take n' xs'
  end.

Fixpoint select (q : query) (xs : list pyramid) : list pyramid :=
  match xs with
  | [] => []
  | x :: xs' =>
      if matches q x
      then match limit q with
           | O => []
           | S n => x :: select
                         {| limit := n; required_id := required_id q;
                            required_country := required_country q;
                            required_year := required_year q;
                            minimum_height_cm := minimum_height_cm q |}
                         xs'
           end
      else select q xs'
  end.

(** The compiler residualizes a fixed year predicate, leaving only records
    and the bounded traversal dynamic. *)
Definition residual_query (year : nat) (n : nat) : query :=
  {| limit := n; required_id := None; required_country := None;
     required_year := Some year;
     minimum_height_cm := None |}.

Theorem fixed_year_query_correct : forall year n rows,
  select (residual_query year n) rows =
  select {| limit := n; required_id := None; required_country := None;
           required_year := Some year;
            minimum_height_cm := None |} rows.
Proof.
  reflexivity.
Qed.

Theorem select_respects_limit : forall q rows,
  length (select q rows) <= limit q.
Proof.
  intros q rows; revert q.
  induction rows as [|p rows IH]; intros q; simpl.
  - apply le_0_n.
  - destruct (matches q p) eqn:hm.
    + destruct (limit q) as [|n] eqn:hl; simpl.
      * apply le_n.
      * simpl. apply le_n_S. apply IH.
    + apply IH.
Qed.

Lemma select_rows_match : forall q rows,
  Forall (fun p => matches q p = true) (select q rows).
Proof.
  intros q rows; revert q.
  induction rows as [|p rows IH]; intros q; simpl.
  - constructor.
  - destruct (matches q p) eqn:hm.
    + destruct (limit q) as [|n] eqn:hl; simpl.
      * constructor.
      * constructor; [exact hm|].
        change (Forall
          (fun p => matches
             {| limit := n; required_id := required_id q;
                required_country := required_country q;
                required_year := required_year q;
                minimum_height_cm := minimum_height_cm q |} p = true)
          (select {| limit := n; required_id := required_id q;
                    required_country := required_country q;
                    required_year := required_year q;
                    minimum_height_cm := minimum_height_cm q |} rows)).
        apply IH.
    + apply IH.
Qed.

Lemma select_rows_from_input : forall q rows p,
  In p (select q rows) -> In p rows.
Proof.
  intros q rows; revert q.
  induction rows as [|x rows IH]; intros q p hp; simpl in *.
  - contradiction.
  - destruct (matches q x) eqn:hm.
    + destruct (limit q) as [|n] eqn:hl; simpl in hp.
      * contradiction.
      * destruct hp as [same|tail].
        -- left; exact same.
        -- right; apply IH with
             (q := {| limit := n; required_id := required_id q;
                      required_country := required_country q;
                      required_year := required_year q;
                      minimum_height_cm := minimum_height_cm q |});
             exact tail.
    + right; apply IH with (q := q); exact hp.
Qed.

Lemma select_zero : forall q rows,
  limit q = 0 -> select q rows = [].
Proof.
  intros q rows; revert q.
  induction rows as [|p rows IH]; intros q hlimit; simpl.
  - reflexivity.
  - destruct (matches q p); simpl.
    + rewrite hlimit; reflexivity.
    + apply IH; exact hlimit.
Qed.
