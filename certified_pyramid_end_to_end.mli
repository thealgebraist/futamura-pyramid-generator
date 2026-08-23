
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

type token =
| TokTop of nat
| TokId of nat
| TokCountry of nat
| TokYear of nat
| TokHeightAtLeast of nat

val parse : token list -> query option

type compiled_query = { compiled_limit : nat;
                        compiled_predicate : (pyramid -> bool) }

val compile_query : query -> compiled_query

val run_compiled : compiled_query -> pyramid list -> pyramid list

val parse_and_compile : token list -> compiled_query option

val run_tokens : token list -> pyramid list -> pyramid list option
