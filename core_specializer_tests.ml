open Core_specializer

let expect_value label expected expression environment =
  match eval environment expression, expected with
  | Ok (VInt actual), Ok (VInt wanted) when actual = wanted -> print_endline ("PASS " ^ label)
  | Ok (VBool actual), Ok (VBool wanted) when actual = wanted -> print_endline ("PASS " ^ label)
  | Error actual, Error wanted when actual = wanted -> print_endline ("PASS " ^ label)
  | _ -> failwith ("FAIL " ^ label)

let expect_residual label expression expected =
  let actual = specialize_closed expression in
  if actual = expected then print_endline ("PASS " ^ label)
  else failwith ("FAIL " ^ label ^ ": got " ^ actual)

let () =
  expect_value "01 constant addition" (Ok (VInt 7)) (EAdd (EInt 3, EInt 4)) [];
  expect_residual "02 constant specialization" (EAdd (EInt 3, EInt 4)) "7";
  expect_value "03 nested addition" (Ok (VInt 15))
    (EAdd (EAdd (EInt 1, EInt 2), EAdd (EInt 4, EInt 8))) [];
  expect_residual "04 dynamic addition" (EAdd (EVar "x", EInt 1)) "(x + 1)";
  expect_value "05 constant let" (Ok (VInt 9))
    (ELet ("x", EInt 4, EAdd (EVar "x", EInt 5))) [];
  expect_residual "06 dynamic let" (ELet ("x", EVar "input", EAdd (EVar "x", EInt 1)))
    "(let x = input in (input + 1))";
  expect_value "07 shadowing" (Ok (VInt 3))
    (ELet ("x", EInt 1, ELet ("x", EInt 2, EAdd (EVar "x", EInt 1)))) [];
  expect_residual "08 static true branch" (EIf (EBool true, EInt 10, EInt 20)) "10";
  expect_residual "09 static false branch" (EIf (EBool false, EInt 10, EInt 20)) "20";
  expect_value "10 dynamic branch true" (Ok (VInt 10))
    (EIf (EVar "flag", EInt 10, EInt 20)) [("flag", VBool true)];
  expect_value "11 dynamic branch false" (Ok (VInt 20))
    (EIf (EVar "flag", EInt 10, EInt 20)) [("flag", VBool false)];
  expect_value "12 integer equality" (Ok (VBool true)) (EEq (EInt 8, EInt 8)) [];
  expect_value "13 boolean equality" (Ok (VBool false)) (EEq (EBool true, EBool false)) [];
  expect_value "14 unbound variable" (Error "unbound variable: missing")
    (EVar "missing") [];
  expect_value "15 bad addition" (Error "expected integer")
    (EAdd (EBool true, EInt 1)) [];
  expect_value "16 bad conditional" (Error "if requires boolean")
    (EIf (EInt 1, EInt 2, EInt 3)) []
