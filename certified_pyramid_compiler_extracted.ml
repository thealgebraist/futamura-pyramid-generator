
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

(** val eqb : nat -> nat -> bool **)

let rec eqb n m =
  match n with
  | O -> (match m with
          | O -> True
          | S _ -> False)
  | S n' -> (match m with
             | O -> False
             | S m' -> eqb n' m')

(** val leb : nat -> nat -> bool **)

let rec leb n m =
  match n with
  | O -> True
  | S n' -> (match m with
             | O -> False
             | S m' -> leb n' m')

type pyramid = { pyramid_id : nat; country_id : nat; built_year : nat;
                 height_cm : nat }

type query = { limit : nat; required_id : nat option;
               required_country : nat option; required_year : nat option;
               minimum_height_cm : nat option }

(** val matches : query -> pyramid -> bool **)

let matches q p =
  let year_ok =
    match q.required_year with
    | Some year -> eqb year p.built_year
    | None -> True
  in
  let country_ok =
    match q.required_country with
    | Some country -> eqb country p.country_id
    | None -> True
  in
  let id_ok =
    match q.required_id with
    | Some identifier -> eqb identifier p.pyramid_id
    | None -> True
  in
  let height_ok =
    match q.minimum_height_cm with
    | Some minimum -> leb minimum p.height_cm
    | None -> True
  in
  (match match match id_ok with
               | True -> country_ok
               | False -> False with
         | True -> year_ok
         | False -> False with
   | True -> height_ok
   | False -> False)

type compiled_query = { compiled_limit : nat;
                        compiled_predicate : (pyramid -> bool) }

(** val compile_query : query -> compiled_query **)

let compile_query q =
  { compiled_limit = q.limit; compiled_predicate = (fun p -> matches q p) }

(** val run_compiled : compiled_query -> pyramid list -> pyramid list **)

let rec run_compiled c = function
| Nil -> Nil
| Cons (p, rest) ->
  (match c.compiled_predicate p with
   | True ->
     (match c.compiled_limit with
      | O -> Nil
      | S n ->
        Cons (p,
          (run_compiled { compiled_limit = n; compiled_predicate =
            c.compiled_predicate } rest)))
   | False -> run_compiled c rest)
