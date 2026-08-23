let () =
  let rec nat_of_int n =
    if n <= 0 then Differential_extracted.O
    else Differential_extracted.S (nat_of_int (n - 1))
  in
  let result =
    Differential_extracted.DifferentialDSL.integrate
      Differential_extracted.DifferentialDSL.example (nat_of_int 5) (nat_of_int 3)
  in
  let rec int_of_nat = function
    | Differential_extracted.O -> 0
    | Differential_extracted.S n -> 1 + int_of_nat n
  in
  if int_of_nat result <> 56 then failwith "extracted calculus result mismatch";
  print_endline "PASS extracted specialization calculus"
