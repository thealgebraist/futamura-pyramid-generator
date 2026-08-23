open Certified_pyramid_end_to_end

let rows =
  Cons ({ pyramid_id = O; country_id = O; built_year = S O; height_cm = S O },
    Cons ({ pyramid_id = S O; country_id = O; built_year = S O; height_cm = S (S O) }, Nil))

let () =
  let valid = Cons (TokTop (S O),
    Cons (TokId O, Cons (TokCountry O,
      Cons (TokYear (S O), Cons (TokHeightAtLeast O, Nil))))) in
  let invalid = Cons (TokTop (S O), Cons (TokYear O, Cons (TokYear (S O), Nil))) in
  match run_tokens valid rows, run_tokens invalid rows with
  | Some (Cons (_, Nil)), None -> print_endline "PASS extracted end-to-end API"
  | _ -> failwith "unexpected extracted end-to-end result"
