open Core_specializer
open Resource_sanity

let state = ref 0x13579B

let next () =
  state := (!state * 1103515245 + 12345) land 0x3fffffff;
  !state

let choose n = next () mod n

let rec expression depth =
  if depth = 0 then
    match choose 3 with
    | 0 -> EInt (choose 101 - 50)
    | 1 -> EBool (choose 2 = 0)
    | _ -> EVar (if choose 2 = 0 then "x" else "flag")
  else
    match choose 7 with
    | 0 -> EAdd (expression (depth - 1), expression (depth - 1))
    | 1 -> EEq (expression (depth - 1), expression (depth - 1))
    | 2 -> EIf (expression (depth - 1), expression (depth - 1), expression (depth - 1))
    | 3 -> ELet ("x", expression (depth - 1), expression (depth - 1))
    | 4 -> ELet ("flag", expression (depth - 1), expression (depth - 1))
    | 5 -> EInt (choose 1001 - 500)
    | _ -> EVar "x"

let () =
  for case = 1 to 10000 do
    let program = expression 6 in
    let estimate = estimate program in
    if estimate.operations <= 0 || estimate.ast_nodes <= 0 then
      failwith ("non-positive resource estimate at case " ^ string_of_int case);
    ignore (eval ["x", VInt 3; "flag", VBool true] program);
    let residual = specialize_closed program in
    if String.length residual = 0 then
      failwith ("empty residual at case " ^ string_of_int case)
  done;
  print_endline "PASS fuzz: 10000 deterministic expressions"
