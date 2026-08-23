open Typed_core

let () =
  if eval example <> 24 then failwith "typed evaluator returned the wrong value";
  if eval complex_false <> 42 then
    failwith "typed false-branch example returned the wrong value";
  if not (eval complex_true) then
    failwith "typed true-branch example returned the wrong value";
  let bool_example : bool expr = TIf (TBoolLit true, TBoolLit false, TBoolLit true) in
  if eval bool_example then failwith "typed boolean conditional returned the wrong value";
  if eval_packed (Pack example) <> "<typed-expression>" then
    failwith "packed typed expression boundary failed";
  print_endline "PASS intrinsically typed total DSL"
