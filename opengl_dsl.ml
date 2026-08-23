(* A small, total OpenGL-shaped FFI DSL.  Raw void pointers never occur in
   the DSL: a buffer carries its element type, count, and byte size, and the
   constructor rejects inconsistent metadata before stage 3 runs. *)

type scalar = F32 | U32

type buffer = {
  name : string;
  element : scalar;
  elements : int;
  bytes : int;
}

type command =
  | BufferData of buffer
  | DrawArrays of { first : int; count : int }

type program = command list

let scalar_size = function F32 | U32 -> 4

let make_buffer name element elements bytes =
  if name = "" then Error "empty buffer name"
  else if elements < 0 || bytes < 0 then Error "negative buffer dimension"
  else if bytes <> elements * scalar_size element then
    Error "buffer byte size does not match element count and type"
  else Ok { name; element; elements; bytes }

let validate_command = function
  | BufferData b when b.bytes = b.elements * scalar_size b.element -> Ok ()
  | BufferData _ -> Error "invalid buffer metadata"
  | DrawArrays { first; count } when first >= 0 && count >= 0 -> Ok ()
  | DrawArrays _ -> Error "negative draw range"

let validate_program commands =
  List.fold_left
    (fun result command ->
      match result, validate_command command with
      | Error _ as error, _ -> error
      | Ok (), Ok () -> Ok ()
      | Ok (), Error message -> Error message)
    (Ok ()) commands

let c_scalar = function F32 -> "float" | U32 -> "unsigned"

let c_command = function
  | BufferData b ->
      Printf.sprintf
        "static const %s %s[%d] = {0};\n_Static_assert(sizeof(%s) == %d, \"buffer size\");\nglBufferData(0x8892u, %d, %s, 0x88E4u);\n"
        (c_scalar b.element) b.name b.elements b.name b.bytes b.bytes b.name
  | DrawArrays { first; count } ->
      Printf.sprintf "glDrawArrays(0x0004u, %d, %d);\n" first count

let interpreter (commands : program) () =
  match validate_program commands with
  | Error message -> Error message
  | Ok () ->
      Ok
        ("typedef unsigned int GLenum;\n"
        ^ "typedef int GLsizei;\n"
        ^ "extern void glBufferData(GLenum, GLsizei, const void *, GLenum);\n"
        ^ "extern void glDrawArrays(GLenum, int, GLsizei);\n"
        ^ "void generated_gl_program(void) {\n"
        ^ String.concat "" (List.map c_command commands)
        ^ "}\n")

let stage3_compile commands =
  let generator =
    Core_futamura_n.projection3
      (fun specialized_interpreter program ->
        fun data -> specialized_interpreter program data)
  in
  generator.artifact interpreter commands ()
