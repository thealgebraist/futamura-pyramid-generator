open Certified_staged_extracted

let () =
  let program = SAdd (SConst (S (S O)), SInput) in
  let residual = residualize O program in
  match run O (S (S (S O))) residual with
  | S (S (S (S (S O)))) -> print_endline "PASS extracted staged residualizer"
  | _ -> failwith "staged residualizer returned an unexpected value"
