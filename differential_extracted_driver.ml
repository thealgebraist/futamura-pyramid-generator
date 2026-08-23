let () =
  let result =
    Differential_extracted.DifferentialDSL.integrate
      Differential_extracted.DifferentialDSL.example 5 3
  in
  if result <> 56 then failwith "extracted calculus result mismatch";
  print_endline "PASS extracted specialization calculus"
