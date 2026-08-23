
type nat =
| O
| S of nat

val add : nat -> nat -> nat

type source =
| SConst of nat
| SAdd of source * source

type target =
| TConst of nat
| TAdd of target * target

val fold_add : target -> target -> target

val compile : source -> target
