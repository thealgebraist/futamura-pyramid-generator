(* A total, typed stage-1/2/3 Futamura tower for the pure core language.

   The representation deliberately uses ordinary algebraic records and
   Result-returning functions.  There is no partial function, exception, or
   I/O in this module.  The [stage] index is a value-level witness used by the
   generic tower API; the concrete artifact types remain explicit and easy to
   inspect. *)

open Core_specializer

type ('program, 'data, 'result) interpreter =
  'program -> 'data -> ('result, string) result

type ('data, 'result) residual =
  'data -> ('result, string) result

type ('program, 'data, 'result) compiler =
  'program -> ('data, 'result) residual

type ('program, 'data, 'result) generator =
  ('program, 'data, 'result) interpreter ->
  ('program, 'data, 'result) compiler

type stage =
  | Stage1
  | Stage2
  | Stage3

type stage_1
type stage_2
type stage_3

type zero
type 'n successor = Successor_marker of 'n
type _ nat_witness =
  | Z : zero nat_witness
  | S : 'n nat_witness -> 'n successor nat_witness

type 'a staged = {
  stage: stage;
  artifact: 'a;
}

type ('a, 'b) total_step = 'a -> ('b, string) result

(* General n-stage composition for a homogeneous representation level.  The
   heterogeneous concrete projections above remain the readable API for the
   first three levels; this recursive operator is the extension mechanism for
   arbitrary n. *)
let rec stage_n (count : int) (step : ('a, 'a) total_step) (value : 'a) =
  if count <= 0 then Ok value
  else
    match step value with
    | Error message -> Error message
    | Ok next -> stage_n (count - 1) step next

let stage_n_checked count step value =
  if count < 0 then Error "negative stage count"
  else stage_n count step value

let rec stage_n_typed : type n. n nat_witness ->
  ('a, 'a) total_step -> 'a -> ('a, string) result =
  fun witness step value ->
    match witness with
    | Z -> Ok value
    | S predecessor ->
        begin match step value with
        | Error message -> Error message
        | Ok next -> stage_n_typed predecessor step next
        end

let mix (interpreter : ('program, 'data, 'result) interpreter)
    (program : 'program) : ('data, 'result) residual =
  fun data -> interpreter program data

type ('level, 'artifact) typed_staged = {
  typed_stage: stage;
  typed_artifact: 'artifact;
}

let projection1_typed interpreter program :
    (stage_1, ('data, 'result) residual) typed_staged =
  { typed_stage = Stage1; typed_artifact = mix interpreter program }

let projection2_typed interpreter :
    (stage_2, ('program, 'data, 'result) compiler) typed_staged =
  { typed_stage = Stage2; typed_artifact = fun program -> mix interpreter program }

let projection3_typed generator :
    (stage_3, ('program, 'data, 'result) generator) typed_staged =
  { typed_stage = Stage3; typed_artifact = generator }

(* Stage 1: interpreter + fixed program -> residual program. *)
let projection1 interpreter program =
  { stage = Stage1; artifact = mix interpreter program }

(* Stage 2: fixed interpreter -> compiler. *)
let projection2 interpreter :
    ('program, 'data, 'result) compiler staged =
  { stage = Stage2; artifact = fun program -> mix interpreter program }

(* Stage 3: a compiler generator is a program which accepts an interpreter. *)
let projection3 (generator : ('program, 'data, 'result) generator) :
    ('program, 'data, 'result) generator staged =
  { stage = Stage3; artifact = generator }

let check_stage expected actual =
  match expected, actual with
  | Stage1, Stage1 | Stage2, Stage2 | Stage3, Stage3 -> Ok ()
  | _ -> Error "stage-order mismatch"

(* A total generic stage contract.  Higher stages can be added by extending
   [stage] and supplying another typed projection function. *)
let contract stage expected actual = check_stage expected actual |> Result.map (fun () -> stage)

type language = {
  add: bool;
  equality: bool;
  conditionals: bool;
  bindings: bool;
}

let core_language = { add = true; equality = true; conditionals = true; bindings = true }

let core_interpreter : (expr, (string * value) list, value) interpreter =
  fun program environment -> eval environment program

let core_stage1 program environment =
  projection1 core_interpreter program |> fun staged -> staged.artifact environment

let core_compiler : (expr, (string * value) list, value) compiler =
  fun program environment ->
    match specialize [] program with
    | Static value -> Ok value
    | Dynamic _ -> eval environment program

let core_generator : (expr, (string * value) list, value) generator =
  fun interpreter -> fun program -> mix interpreter program

let core_stage2 = projection2 core_interpreter
let core_stage3 = projection3 core_generator
