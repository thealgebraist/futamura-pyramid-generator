let require_ok label = function
  | Ok value -> value
  | Error message -> failwith (label ^ ": " ^ message)

let () =
  let vertex = require_ok "vertex buffer" (Opengl_dsl.make_buffer "vertices" Opengl_dsl.F32 9 36) in
  let indices = require_ok "index buffer" (Opengl_dsl.make_buffer "indices" Opengl_dsl.U32 3 12) in
  let program =
    [ Opengl_dsl.BufferData vertex;
      Opengl_dsl.BufferData indices;
      Opengl_dsl.DrawArrays { first = 0; count = 3 } ]
  in
  let source = require_ok "stage 3" (Opengl_dsl.stage3_compile program) in
  if not (String.contains source '_') || not (String.contains source '*') then
    failwith "generated OpenGL ABI source is incomplete";
  if not (String.contains source 'v') || not (String.contains source 'i') then
    failwith "generated buffer declarations are incomplete";
  begin match Opengl_dsl.make_buffer "bad" Opengl_dsl.F32 3 8 with
  | Error _ -> () | Ok _ -> failwith "inconsistent void-pointer size accepted"
  end;
  print_endline "PASS OpenGL-shaped typed void-pointer DSL and stage 3";
