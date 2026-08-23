(** Independent Coq derivation of the homogeneous n-stage recurrence. *)

Fixpoint iterate (n : nat) (x : nat) : nat :=
  match n with
  | O => x
  | S n' => iterate n' (S x)
  end.

Example stage_ten_result : iterate 10 0 = 10.
Proof. vm_compute. reflexivity. Qed.

Example stage_three_result : iterate 3 4 = 7.
Proof. vm_compute. reflexivity. Qed.

