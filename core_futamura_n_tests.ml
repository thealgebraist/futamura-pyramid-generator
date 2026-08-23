open Core_specializer
open Core_futamura_n

let require_ok label value =
  match value with
  | Ok result -> result
  | Error message -> failwith (label ^ ": " ^ message)

let () =
  let program = EAdd (EInt 2, EInt 3) in
  let complex_program =
    ELet
      ( "x",
        EInt 20,
        EIf
          ( EEq (EVar "x", EInt 20),
            EAdd (EVar "x", EInt 22),
            EInt 0 ) )
  in
  let stage1 = require_ok "stage 1" (core_stage1 program []) in
  begin match stage1 with
  | VInt 5 -> ()
  | _ -> failwith "stage 1 produced the wrong value"
  end;
  let typed1 = projection1_typed core_interpreter program in
  begin match typed1.typed_artifact [] with
  | Ok (VInt 5) -> ()
  | _ -> failwith "typed stage 1 produced the wrong value"
  end;
  let typed2 = projection2_typed core_interpreter in
  begin match typed2.typed_artifact program [] with
  | Ok (VInt 5) -> ()
  | _ -> failwith "typed stage 2 produced the wrong value"
  end;
  let typed3 = projection3_typed core_generator in
  begin match typed3.typed_artifact core_interpreter program [] with
  | Ok (VInt 5) -> ()
  | _ -> failwith "typed stage 3 produced the wrong value"
  end;
  let stage2 = core_stage2.artifact program [] |> require_ok "stage 2" in
  begin match stage2 with
  | VInt 5 -> ()
  | _ -> failwith "stage 2 produced the wrong value"
  end;
  let stage3 = core_stage3.artifact core_interpreter program [] |> require_ok "stage 3" in
  begin match stage3 with
  | VInt 5 -> ()
  | _ -> failwith "stage 3 produced the wrong value"
  end;
  let check_complex label result =
    match require_ok label result with
    | VInt 42 -> ()
    | _ -> failwith (label ^ " produced the wrong value")
  in
  check_complex "complex stage 1" (core_stage1 complex_program []);
  check_complex "complex stage 2" (core_stage2.artifact complex_program []);
  check_complex "complex stage 3"
    (core_stage3.artifact core_interpreter complex_program []);
  (* Eight independent end-to-end programs.  Each is sent through both
     projection 2 (fixed interpreter) and projection 3 (interpreter
     generator), including successful and total-error paths. *)
  let same_value left right =
    match left, right with
    | VInt a, VInt b -> a = b
    | VBool a, VBool b -> a = b
    | _ -> false
  in
  let cases =
    [ (ELet ("a", EInt 6, ELet ("b", EInt 7, EAdd (EVar "a", EVar "b"))), [], Ok (VInt 13));
      (EIf (EEq (EBool false, EBool false), EInt 9, EInt 1), [], Ok (VInt 9));
      (EAdd (EVar "x", EVar "y"), ["x", VInt 10; "y", VInt 3], Ok (VInt 13));
      (ELet ("x", EInt 5, EIf (EEq (EVar "x", EInt 6), EInt 99, EAdd (EVar "x", EInt 10))), [], Ok (VInt 15));
      (EEq (EBool true, EBool true), [], Ok (VBool true));
      (EAdd (EVar "missing", EInt 1), [], Error "unbound variable: missing");
      (EEq (EInt 1, EBool true), [], Error "equality type mismatch");
      (ELet ("base", EAdd (EInt 2, EInt 3), EIf (EEq (EVar "base", EInt 5), EAdd (EVar "base", EInt 8), EInt 0)), [], Ok (VInt 13)) ]
  in
  List.iteri
    (fun index (expression, environment, expected) ->
      let label = Printf.sprintf "projection case %d" (index + 1) in
      let check actual =
        match expected, actual with
        | Ok wanted, Ok obtained when same_value wanted obtained -> ()
        | Error wanted, Error obtained when wanted = obtained -> ()
        | _ -> failwith (label ^ " mismatch")
      in
      check (core_stage2.artifact expression environment);
      check (core_stage3.artifact core_interpreter expression environment))
    cases;
  let malformed = EIf (EInt 1, EInt 2, EInt 3) in
  begin match core_stage1 malformed [] with
  | Error _ -> ()
  | Ok _ -> failwith "ill-typed DSL program was accepted"
  end;
  let alternate_interpreter _program environment = Ok (VInt (List.length environment)) in
  begin match core_stage3.artifact alternate_interpreter program ["x", VInt 0] with
  | Ok (VInt 1) -> ()
  | _ -> failwith "stage 3 ignored its interpreter argument"
  end;
  begin match contract Stage3 Stage3 Stage3 with
  | Ok Stage3 -> ()
  | _ -> failwith "valid stage contract rejected"
  end;
  begin match contract Stage3 Stage2 Stage1 with
  | Error _ -> ()
  | Ok _ -> failwith "invalid stage order accepted"
  end;
  let increment x = Ok (x + 1) in
  begin match stage_n_checked 0 increment 4 with
  | Ok 4 -> ()
  | _ -> failwith "stage n zero case failed"
  end;
  begin match stage_n_checked 3 increment 4 with
  | Ok 7 -> ()
  | _ -> failwith "stage n recursive case failed"
  end;
  begin match stage_n_checked 10 increment 0 with
  | Ok 10 -> ()
  | _ -> failwith "deep stage n case failed"
  end;
  let fail_after_two x = if x >= 2 then Error "stage failure" else Ok (x + 1) in
  begin match stage_n_checked 5 fail_after_two 0 with
  | Error "stage failure" -> ()
  | Ok _ | Error _ -> failwith "stage error was not propagated"
  end;
  begin match stage_n_checked (-1) increment 4 with
  | Error _ -> ()
  | Ok _ -> failwith "negative stage count accepted"
  end;
  let three_steps = S (S (S Z)) in
  begin match stage_n_typed three_steps increment 4 with
  | Ok 7 -> ()
  | _ -> failwith "typed n-stage witness failed"
  end;
  print_endline "PASS total Futamura stages 1-3"
