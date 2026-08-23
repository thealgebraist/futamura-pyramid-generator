type ('program, 'data, 'result) interpreter =
  'program -> 'data -> ('result, string) result
type ('data, 'result) residual =
  'data -> ('result, string) result
type ('program, 'data, 'result) compiler =
  'program -> ('data, 'result) residual
type ('program, 'data, 'result) generator =
  ('program, 'data, 'result) interpreter ->
  ('program, 'data, 'result) compiler
type ('program, 'data, 'result) compiler_generator_transformer =
  ('program, 'data, 'result) generator ->
  ('program, 'data, 'result) generator

type stage = Stage1 | Stage2 | Stage3 | Stage4
type stage_1
type stage_2
type stage_3
type stage_4
type zero
type 'n successor = Successor_marker of 'n
type _ nat_witness = Z : zero nat_witness | S : 'n nat_witness -> 'n successor nat_witness

type 'a staged = { stage : stage; artifact : 'a }
type ('a, 'b) total_step = 'a -> ('b, string) result
type ('level, 'artifact) typed_staged = {
  typed_stage : stage;
  typed_artifact : 'artifact;
}

val stage_n : int -> ('a, 'a) total_step -> 'a -> ('a, string) result
val stage_n_checked : int -> ('a, 'a) total_step -> 'a -> ('a, string) result
val stage_n_typed : 'n nat_witness -> ('a, 'a) total_step -> 'a -> ('a, string) result
val mix : ('program, 'data, 'result) interpreter -> 'program -> ('data, 'result) residual
val projection1_typed : ('a, 'data, 'result) interpreter -> 'a -> (stage_1, ('data, 'result) residual) typed_staged
val projection2_typed : ('program, 'data, 'result) interpreter -> (stage_2, ('program, 'data, 'result) compiler) typed_staged
val projection3_typed : ('program, 'data, 'result) generator -> (stage_3, ('program, 'data, 'result) generator) typed_staged
val projection4_typed : ('program, 'data, 'result) compiler_generator_transformer -> (stage_4, ('program, 'data, 'result) compiler_generator_transformer) typed_staged
val projection1 : ('a, 'b, 'c) interpreter -> 'a -> ('b, 'c) residual staged
val projection2 : ('program, 'data, 'result) interpreter -> ('program, 'data, 'result) compiler staged
val projection3 : ('program, 'data, 'result) generator -> ('program, 'data, 'result) generator staged
val projection4 : ('program, 'data, 'result) compiler_generator_transformer -> ('program, 'data, 'result) compiler_generator_transformer staged
val check_stage : stage -> stage -> (unit, string) result
val contract : 'a -> stage -> stage -> ('a, string) result

val core_interpreter :
  (Core_specializer.expr, (string * Core_specializer.value) list,
   Core_specializer.value) interpreter
val core_stage1 : Core_specializer.expr -> (string * Core_specializer.value) list -> (Core_specializer.value, string) result
val core_compiler :
  (Core_specializer.expr, (string * Core_specializer.value) list,
   Core_specializer.value) compiler
val core_generator :
  (Core_specializer.expr, (string * Core_specializer.value) list,
   Core_specializer.value) generator
val core_stage2 :
  (Core_specializer.expr, (string * Core_specializer.value) list,
   Core_specializer.value) compiler staged
val core_stage3 :
  (Core_specializer.expr, (string * Core_specializer.value) list,
   Core_specializer.value) generator staged
