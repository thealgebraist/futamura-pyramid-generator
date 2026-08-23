open Certified_pyramid_extracted

let () =
  let rows =
    Cons ({ pyramid_id = O; built_year = S (S O); height_cm = S O },
      Cons ({ pyramid_id = S O; built_year = S (S O); height_cm = S (S O) },
        Cons ({ pyramid_id = S (S O); built_year = S O; height_cm = S O }, Nil)))
  in
  let q = { limit = S O; required_year = Some (S (S O));
            minimum_height_cm = Some (S O) } in
  match select q rows with
  | Cons (_, Nil) -> print_endline "PASS extracted pyramid query"
  | _ -> failwith "extracted pyramid query returned an unexpected result"
