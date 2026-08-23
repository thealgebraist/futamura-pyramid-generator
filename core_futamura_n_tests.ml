open Core_specializer
open Core_futamura_n

let require_ok label value =
  match value with
  | Ok result -> result
  | Error message -> failwith (label ^ ": " ^ message)

let () =
  let program = EAdd (EInt 2, EInt 3) in
  let stage1 = require_ok "stage 1" (core_stage1 program []) in
  begin match stage1 with
  | VInt 5 -> ()
  | _ -> failwith "stage 1 produced the wrong value"
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
  print_endline "PASS total Futamura stages 1-3"
