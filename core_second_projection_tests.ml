open Core_specializer
open Core_second_projection

let check label expression expected =
  let actual = compile_to_ocaml expression in
  if actual = expected then print_endline ("PASS " ^ label)
  else failwith (label ^ ": got " ^ actual ^ ", expected " ^ expected)

let () =
  check "constant" (EAdd (EInt 2, EInt 3)) "(2 + 3)";
  check "dynamic" (EAdd (EVar "x", EInt 3)) "(x + 3)";
  check "conditional"
    (EIf (EEq (EVar "x", EInt 0), EInt 1, EInt 2))
    "(if (x = 0) then 1 else 2)";
  check "binding"
    (ELet ("x", EInt 4, EAdd (EVar "x", EInt 5)))
    "(let x = 4 in (4 + 5))"
