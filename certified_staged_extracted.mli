
type nat =
| O
| S of nat

val add : nat -> nat -> nat

type code =
| CConst of nat * nat
| CInput of nat
| CAdd of nat * code * code
| CQuote of nat * code

val run : nat -> nat -> code -> nat

type source =
| SConst of nat
| SInput
| SAdd of source * source

val residualize : nat -> source -> code
