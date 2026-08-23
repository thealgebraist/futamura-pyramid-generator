
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

type token =
| TokTop of nat
| TokId of nat
| TokCountry of nat
| TokYear of nat
| TokHeightAtLeast of nat

(** val parse : token list -> query option **)

let parse = function
| Nil -> None
| Cons (t, l) ->
  (match t with
   | TokTop n ->
     (match l with
      | Nil ->
        Some { limit = n; required_id = None; required_country = None;
          required_year = None; minimum_height_cm = None }
      | Cons (t0, l0) ->
        (match t0 with
         | TokTop _ -> None
         | TokId i ->
           (match l0 with
            | Nil ->
              Some { limit = n; required_id = (Some i); required_country =
                None; required_year = None; minimum_height_cm = None }
            | Cons (t1, l1) ->
              (match t1 with
               | TokCountry c ->
                 (match l1 with
                  | Nil -> None
                  | Cons (t2, l2) ->
                    (match t2 with
                     | TokYear y ->
                       (match l2 with
                        | Nil -> None
                        | Cons (t3, l3) ->
                          (match t3 with
                           | TokHeightAtLeast h ->
                             (match l3 with
                              | Nil ->
                                Some { limit = n; required_id = (Some i);
                                  required_country = (Some c);
                                  required_year = (Some y);
                                  minimum_height_cm = (Some h) }
                              | Cons (_, _) -> None)
                           | _ -> None))
                     | _ -> None))
               | _ -> None))
         | TokCountry c ->
           (match l0 with
            | Nil ->
              Some { limit = n; required_id = None; required_country = (Some
                c); required_year = None; minimum_height_cm = None }
            | Cons (_, _) -> None)
         | TokYear y ->
           (match l0 with
            | Nil ->
              Some { limit = n; required_id = None; required_country = None;
                required_year = (Some y); minimum_height_cm = None }
            | Cons (_, _) -> None)
         | TokHeightAtLeast h ->
           (match l0 with
            | Nil ->
              Some { limit = n; required_id = None; required_country = None;
                required_year = None; minimum_height_cm = (Some h) }
            | Cons (_, _) -> None)))
   | _ -> None)

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

(** val parse_and_compile : token list -> compiled_query option **)

let parse_and_compile tokens =
  match parse tokens with
  | Some q -> Some (compile_query q)
  | None -> None

(** val run_tokens : token list -> pyramid list -> pyramid list option **)

let run_tokens tokens rows =
  match parse_and_compile tokens with
  | Some compiled -> Some (run_compiled compiled rows)
  | None -> None
