(* Compare the independently extracted Coq result with the OCaml DSL. *)
let rec nat_to_int = function
  | Independent_typed_core_result.O -> 0
  | Independent_typed_core_result.S n -> 1 + nat_to_int n

let () =
  let coq_value =
    nat_to_int Independent_typed_core_result.independent_result_nat
  in
  let ocaml_value = Typed_core.eval Typed_core.example in
  if coq_value <> ocaml_value then
    failwith
      (Printf.sprintf "independent mismatch: Coq=%d OCaml=%d" coq_value
         ocaml_value);
  Printf.printf "PASS extracted Coq/OCaml result: %d\n" coq_value
