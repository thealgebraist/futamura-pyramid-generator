open Certified_pyramid_compiler_extracted

let () =
  let rows =
    Cons ({ pyramid_id = O; country_id = O; built_year = S O; height_cm = S O },
      Cons ({ pyramid_id = S O; country_id = O; built_year = S O; height_cm = S O }, Nil))
  in
  let q =
    { limit = S O; required_id = None; required_country = Some O;
      required_year = Some (S O); minimum_height_cm = None }
  in
  let compiled = compile_query q in
  match run_compiled compiled rows with
  | Cons (_, Nil) -> print_endline "PASS extracted pyramid compiler"
  | _ -> failwith "compiled pyramid query returned an unexpected result"

