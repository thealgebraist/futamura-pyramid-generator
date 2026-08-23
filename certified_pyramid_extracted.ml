
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

type pyramid = { pyramid_id : nat; built_year : nat; height_cm : nat }

type query = { limit : nat; required_year : nat option }

(** val matches : query -> pyramid -> bool **)

let matches q p =
  match q.required_year with
  | Some year -> eqb year p.built_year
  | None -> True

(** val select : query -> pyramid list -> pyramid list **)

let rec select q = function
| Nil -> Nil
| Cons (x, xs') ->
  (match matches q x with
   | True ->
     (match q.limit with
      | O -> Nil
      | S n ->
        Cons (x, (select { limit = n; required_year = q.required_year } xs')))
   | False -> select q xs')
