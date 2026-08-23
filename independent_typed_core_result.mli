
type bool =
| True
| False

type nat =
| O
| S of nat

val add : nat -> nat -> nat

val eqb : nat -> nat -> bool

type 'x expr =
| ENat of nat
| EBool of bool
| EAdd of nat expr * nat expr
| EEqNat of nat expr * nat expr
| EIf of bool expr * 'x expr * 'x expr

val eval : 'a1 expr -> 'a1

val nontrivial_example : nat expr

val independent_result_nat : nat
