
type nat =
| O
| S of nat

(** val add : nat -> nat -> nat **)

let rec add n m =
  match n with
  | O -> m
  | S p -> S (add p m)

type source =
| SConst of nat
| SAdd of source * source

type target =
| TConst of nat
| TAdd of target * target

(** val fold_add : target -> target -> target **)

let fold_add x y =
  match x with
  | TConst a ->
    (match y with
     | TConst b -> TConst (add a b)
     | TAdd (_, _) -> TAdd (x, y))
  | TAdd (_, _) -> TAdd (x, y)

(** val compile : source -> target **)

let rec compile = function
| SConst n -> TConst n
| SAdd (a, b) -> fold_add (compile a) (compile b)
