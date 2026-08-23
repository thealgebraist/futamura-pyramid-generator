open Typed_core

let nontrivial_example : int expr =
  TIf (TEq (TAdd (TIntLit 2, TIntLit 3), TIntLit 5),
       TAdd (TIntLit 7, TAdd (TIntLit 8, TIntLit 9)),
       TIntLit 0)

let () =
  let ocaml_result = eval nontrivial_example in
  if ocaml_result <> 24 then failwith "OCaml result disagrees with Coq certificate";
  print_endline "PASS independent Coq/OCaml result: 24"

