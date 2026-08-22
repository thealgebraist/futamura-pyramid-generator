(* A tiny pure OCaml core for Futamura-style specialization.

   The language, interpreter, residual-code ADT, evaluator, and specializer
   are all written in the same pure algebraic core.  There are no refs,
   arrays, exceptions, objects, modules, or I/O here.
*)

type expr =
  | EInt of int
  | EBool of bool
  | EVar of string
  | EAdd of expr * expr
  | EEq of expr * expr
  | EIf of expr * expr * expr
  | ELet of string * expr * expr

type value =
  | VInt of int
  | VBool of bool

type env = (string * value) list

let rec lookup name environment =
  match environment with
  | [] -> Error ("unbound variable: " ^ name)
  | (key, value) :: rest ->
      if key = name then Ok value else lookup name rest

let bind name value environment = (name, value) :: environment

let int_of_value value =
  match value with
  | VInt number -> Ok number
  | VBool _ -> Error "expected integer"

let bool_of_value value =
  match value with
  | VBool flag -> Ok flag
  | VInt _ -> Error "expected boolean"

let rec eval environment expression =
  match expression with
  | EInt number -> Ok (VInt number)
  | EBool flag -> Ok (VBool flag)
  | EVar name -> lookup name environment
  | EAdd (left, right) ->
      begin match eval environment left, eval environment right with
      | Ok left_value, Ok right_value ->
          begin match int_of_value left_value, int_of_value right_value with
          | Ok left_number, Ok right_number -> Ok (VInt (left_number + right_number))
          | Error message, _ | _, Error message -> Error message
          end
      | Error message, _ | _, Error message -> Error message
      end
  | EEq (left, right) ->
      begin match eval environment left, eval environment right with
      | Ok (VInt left_number), Ok (VInt right_number) ->
          Ok (VBool (left_number = right_number))
      | Ok (VBool left_flag), Ok (VBool right_flag) ->
          Ok (VBool (left_flag = right_flag))
      | Ok _, Ok _ -> Error "equality type mismatch"
      | Error message, _ | _, Error message -> Error message
      end
  | EIf (test, yes_branch, no_branch) ->
      begin match eval environment test with
      | Ok (VBool true) -> eval environment yes_branch
      | Ok (VBool false) -> eval environment no_branch
      | Ok (VInt _) -> Error "if requires boolean"
      | Error message -> Error message
      end
  | ELet (name, definition, body) ->
      begin match eval environment definition with
      | Ok value -> eval (bind name value environment) body
      | Error message -> Error message
      end

(* Residual OCaml is itself an ADT.  Variables are the only dynamic leaves. *)
type code =
  | CInt of int
  | CBool of bool
  | CVar of string
  | CAdd of code * code
  | CEq of code * code
  | CIf of code * code * code
  | CLet of string * code * code

type static =
  | Static of value
  | Dynamic of code

type static_env = (string * static) list

let rec static_lookup name environment =
  match environment with
  | [] -> None
  | (key, value) :: rest ->
      if key = name then Some value else static_lookup name rest

let static_bind name value environment = (name, value) :: environment

let code_of_value value =
  match value with
  | VInt number -> CInt number
  | VBool flag -> CBool flag

(* First Futamura projection: specialize the evaluator with respect to the
   static environment. Constant subexpressions are evaluated now; dynamic
   structure is preserved as residual code. *)
let rec specialize environment expression =
  match expression with
  | EInt number -> Static (VInt number)
  | EBool flag -> Static (VBool flag)
  | EVar name ->
      begin match static_lookup name environment with
      | Some value -> value
      | None -> Dynamic (CVar name)
      end
  | EAdd (left, right) ->
      specialize_add (specialize environment left) (specialize environment right)
  | EEq (left, right) ->
      specialize_eq (specialize environment left) (specialize environment right)
  | EIf (test, yes_branch, no_branch) ->
      begin match specialize environment test with
      | Static (VBool true) -> specialize environment yes_branch
      | Static (VBool false) -> specialize environment no_branch
      | Static (VInt _) -> Dynamic (CIf (CInt 0, render (specialize environment yes_branch), render (specialize environment no_branch)))
      | Dynamic test_code ->
          Dynamic (CIf (test_code,
                        render (specialize environment yes_branch),
                        render (specialize environment no_branch)))
      end
  | ELet (name, definition, body) ->
      begin match specialize environment definition with
      | Static value -> specialize (static_bind name (Static value) environment) body
      | Dynamic definition_code ->
          let body_code = specialize (static_bind name (Dynamic definition_code) environment) body in
          Dynamic (CLet (name, definition_code, render body_code))
      end

and specialize_add left right =
  match left, right with
  | Static (VInt a), Static (VInt b) -> Static (VInt (a + b))
  | Static a, Static b -> Dynamic (CAdd (code_of_value a, code_of_value b))
  | Dynamic a, Static (VInt 0) -> Dynamic a
  | Static (VInt 0), Dynamic b -> Dynamic b
  | Static a, Dynamic b -> Dynamic (CAdd (code_of_value a, b))
  | Dynamic a, Static b -> Dynamic (CAdd (a, code_of_value b))
  | Dynamic a, Dynamic b -> Dynamic (CAdd (a, b))

and specialize_eq left right =
  match left, right with
  | Static (VInt a), Static (VInt b) -> Static (VBool (a = b))
  | Static (VBool a), Static (VBool b) -> Static (VBool (a = b))
  | Static a, Dynamic b -> Dynamic (CEq (code_of_value a, b))
  | Dynamic a, Static b -> Dynamic (CEq (a, code_of_value b))
  | Dynamic a, Dynamic b -> Dynamic (CEq (a, b))
  | Static _, Static _ -> Dynamic (CEq (CInt 0, CInt 0))

and render result =
  match result with
  | Static value -> code_of_value value
  | Dynamic code -> code

let rec to_ocaml code =
  match code with
  | CInt number -> string_of_int number
  | CBool true -> "true"
  | CBool false -> "false"
  | CVar name -> name
  | CAdd (left, right) -> "(" ^ to_ocaml left ^ " + " ^ to_ocaml right ^ ")"
  | CEq (left, right) -> "(" ^ to_ocaml left ^ " = " ^ to_ocaml right ^ ")"
  | CIf (test, yes_branch, no_branch) ->
      "(if " ^ to_ocaml test ^ " then " ^ to_ocaml yes_branch ^
      " else " ^ to_ocaml no_branch ^ ")"
  | CLet (name, definition, body) ->
      "(let " ^ name ^ " = " ^ to_ocaml definition ^
      " in " ^ to_ocaml body ^ ")"

let specialize_closed expression =
  match specialize [] expression with
  | Static value -> to_ocaml (code_of_value value)
  | Dynamic code -> to_ocaml code

(* Pure examples used by the separate driver and tests. *)
let example_constant =
  specialize_closed (ELet ("x", EAdd (EInt 2, EInt 3), EAdd (EVar "x", EInt 4)))

let example_dynamic =
  specialize_closed (ELet ("x", EAdd (EVar "input", EInt 1),
                           EIf (EEq (EVar "x", EInt 4), EInt 10, EInt 20)))
