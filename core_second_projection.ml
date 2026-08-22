(* Second Futamura projection for the pure OCaml core.

   The first projection specializes an interpreter with respect to one
   expression.  Here a generic interpreter is specialized with respect to a
   language specification, producing a compiler for that language.
*)

open Core_specializer

type language = {
  add: bool;
  equality: bool;
  conditionals: bool;
  bindings: bool;
}

let core_language = {
  add = true;
  equality = true;
  conditionals = true;
  bindings = true;
}

type compiler = expr -> code

(* This is the interpreter parameterized by a language description. *)
let interpreter language expression =
  let rec compile environment expression =
    match expression with
    | EInt number -> CInt number
    | EBool flag -> CBool flag
    | EVar name ->
        begin match List.assoc_opt name environment with
        | Some code -> code
        | None -> CVar name
        end
    | EAdd (left, right) when language.add ->
        CAdd (compile environment left, compile environment right)
    | EEq (left, right) when language.equality ->
        CEq (compile environment left, compile environment right)
    | EIf (test, yes_branch, no_branch) when language.conditionals ->
        CIf (compile environment test,
             compile environment yes_branch,
             compile environment no_branch)
    | ELet (name, definition, body) when language.bindings ->
        CLet (name, compile environment definition,
              compile ((name, compile environment definition) :: environment) body)
    | _ -> CVar "unsupported_language_construct"
  in
  compile [] expression

(* Projection 2: interpreter + fixed language -> compiler. *)
let compiler_for language : compiler =
  fun expression -> interpreter language expression

let core_compiler : compiler = compiler_for core_language

let compile_to_ocaml expression = to_ocaml (core_compiler expression)
