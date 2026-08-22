open Core_specializer

(* Balanced trees keep construction and evaluation logarithmically deep while
   still forcing thousands of interpreter/specializer visits. *)
let rec sum_tree count start =
  if count = 1 then EInt start
  else
    let left = count / 2 in
    EAdd (sum_tree left start, sum_tree (count - left) (start + left))

let expected_sum count start = (2 * start + count - 1) * count / 2

let run_case number leaves start offset =
  let program =
    ELet ("static_work", sum_tree leaves start,
          EAdd (EVar "static_work", EInt offset))
  in
  let expected = expected_sum leaves start + offset in
  let residual = specialize_closed program in
  if residual = string_of_int expected then
    Printf.printf "PASS long %02d: %d static leaves -> %s\n"
      number leaves residual
  else
    failwith (Printf.sprintf "FAIL long %02d: got %s expected %d"
                number residual expected)

let () =
  run_case 1 1024 1 7;
  run_case 2 2048 3 11;
  run_case 3 4096 5 13;
  run_case 4 8192 7 17;
  run_case 5 16384 11 19;
  run_case 6 32768 13 23;
  run_case 7 65536 17 29;
  run_case 8 131072 19 31
