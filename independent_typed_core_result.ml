
type bool =
| True
| False

type nat =
| O
| S of nat

(** val add : nat -> nat -> nat **)

let rec add n m =
  match n with
  | O -> m
  | S p -> S (add p m)

(** val eqb : nat -> nat -> bool **)

let rec eqb n m =
  match n with
  | O -> (match m with
          | O -> True
          | S _ -> False)
  | S n' -> (match m with
             | O -> False
             | S m' -> eqb n' m')

type 'x expr =
| ENat of nat
| EBool of bool
| EAdd of nat expr * nat expr
| EEqNat of nat expr * nat expr
| EIf of bool expr * 'x expr * 'x expr

(** val eval : 'a1 expr -> 'a1 **)

let rec eval = function
| ENat n -> Obj.magic n
| EBool b -> Obj.magic b
| EAdd (x, y) -> Obj.magic add (eval (Obj.magic x)) (eval (Obj.magic y))
| EEqNat (x, y) -> Obj.magic eqb (eval (Obj.magic x)) (eval (Obj.magic y))
| EIf (test, yes_branch, no_branch) ->
  (match Obj.magic eval test with
   | True -> eval yes_branch
   | False -> eval no_branch)

(** val nontrivial_example : nat expr **)

let nontrivial_example =
  EIf ((EEqNat ((EAdd ((ENat (S (S O))), (ENat (S (S (S O)))))), (ENat (S (S
    (S (S (S O)))))))), (EAdd ((ENat (S (S (S (S (S (S (S O)))))))), (EAdd
    ((ENat (S (S (S (S (S (S (S (S O))))))))), (ENat (S (S (S (S (S (S (S (S
    (S O)))))))))))))), (ENat O))

(** val independent_result_nat : nat **)

let independent_result_nat =
  eval nontrivial_example
