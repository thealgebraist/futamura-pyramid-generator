open Core_futamura_n

let increment x = Ok (x + 1)

let () =
  match stage_n_checked 10 increment 0,
        stage_n_checked 3 increment 4 with
  | Ok 10, Ok 7 -> print_endline "PASS independent Coq/OCaml stage results: 10,7"
  | _ -> failwith "OCaml stage results disagree with Coq derivation"

