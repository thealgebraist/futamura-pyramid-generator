
type nat =
| O
| S of nat

(** val add : nat -> nat -> nat **)

let rec add n m =
  match n with
  | O -> m
  | S p -> S (add p m)

type code =
| CConst of nat * nat
| CInput of nat
| CAdd of nat * code * code
| CQuote of nat * code

(** val run : nat -> nat -> code -> nat **)

let rec run _ input = function
| CConst (_, n) -> n
| CInput _ -> input
| CAdd (level0, a, b) -> add (run level0 input a) (run level0 input b)
| CQuote (level0, inner) -> run level0 input inner

type source =
| SConst of nat
| SInput
| SAdd of source * source

(** val residualize : nat -> source -> code **)

let rec residualize level = function
| SConst n -> CConst (level, n)
| SInput -> CInput level
| SAdd (a, b) -> CAdd (level, (residualize level a), (residualize level b))
