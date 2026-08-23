
type nat =
| O
| S of nat

(** val add : nat -> nat -> nat **)

let rec add n m =
  match n with
  | O -> m
  | S p -> S (add p m)

(** val mul : nat -> nat -> nat **)

let rec mul n m =
  match n with
  | O -> O
  | S p -> add m (mul p m)

module DifferentialDSL =
 struct
  type coq_Expr =
  | Const of nat
  | Static
  | Var
  | Add of coq_Expr * coq_Expr
  | Mul of coq_Expr * coq_Expr

  (** val eval : nat -> nat -> coq_Expr -> nat **)

  let rec eval static dynamic = function
  | Const n -> n
  | Static -> static
  | Var -> dynamic
  | Add (x, y) -> add (eval static dynamic x) (eval static dynamic y)
  | Mul (x, y) -> mul (eval static dynamic x) (eval static dynamic y)

  (** val sum : (nat -> nat) -> nat -> nat **)

  let rec sum f = function
  | O -> O
  | S n' -> add (f n') (sum f n')

  (** val integrate : coq_Expr -> nat -> nat -> nat **)

  let integrate e static count =
    sum (fun dynamic -> eval static dynamic e) count

  (** val example : coq_Expr **)

  let example =
    Mul ((Add (Static, Var)), (Add (Var, (Const (S (S O))))))
 end
