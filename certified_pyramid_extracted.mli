
type bool =
| True
| False

type nat =
| O
| S of nat

type 'a option =
| Some of 'a
| None

type 'a list =
| Nil
| Cons of 'a * 'a list

val eqb : nat -> nat -> bool

val leb : nat -> nat -> bool

type pyramid = { pyramid_id : nat; country_id : nat; built_year : nat;
                 height_cm : nat }

type query = { limit : nat; required_id : nat option;
               required_country : nat option; required_year : nat option;
               minimum_height_cm : nat option }

val matches : query -> pyramid -> bool

val select : query -> pyramid list -> pyramid list
