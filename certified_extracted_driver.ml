(* Runtime smoke test for the implementation extracted from Coq. *)

open Certified_core_extracted

let two = S (S O)
let three = S (S (S O))

let () =
  match compile (SAdd (SConst two, SConst three)) with
  | TConst (S (S (S (S (S O))))) -> print_endline "PASS extracted compile"
  | _ -> failwith "extracted compiler returned an unexpected residual"

