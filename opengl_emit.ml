let () =
  let open Opengl_dsl in
  let vertex =
    match make_buffer "vertices" F32 9 36 with
    | Ok value -> value | Error message -> failwith message
  in
  let indices =
    match make_buffer "indices" U32 3 12 with
    | Ok value -> value | Error message -> failwith message
  in
  let program =
    [BufferData vertex; BufferData indices; DrawArrays { first = 0; count = 3 }]
  in
  match stage3_compile program with
  | Ok source -> print_string source
  | Error message -> failwith message
