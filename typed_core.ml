(* Intrinsically typed, total core DSL.  Ill-typed terms cannot be built. *)

type _ ty =
  | TInt : int ty
  | TBool : bool ty

type _ expr =
  | TIntLit : int -> int expr
  | TBoolLit : bool -> bool expr
  | TAdd : int expr * int expr -> int expr
  | TEq : 'a expr * 'a expr -> bool expr
  | TIf : bool expr * 'a expr * 'a expr -> 'a expr

let rec eval : type a. a expr -> a = function
  | TIntLit n -> n
  | TBoolLit b -> b
  | TAdd (left, right) -> eval left + eval right
  | TEq (left, right) -> eval left = eval right
  | TIf (test, yes_branch, no_branch) ->
      if eval test then eval yes_branch else eval no_branch

type packed = Pack : 'a expr -> packed

let eval_packed (Pack expression) =
  match expression with
  | TIntLit n -> string_of_int n
  | TBoolLit b -> string_of_bool b
  | TAdd _ | TEq _ | TIf _ ->
      (* Evaluation is still total; this renderer is only a smoke boundary. *)
      "<typed-expression>"

let example : int expr =
  TIf
    ( TEq (TAdd (TIntLit 2, TIntLit 3), TIntLit 5),
      TAdd (TIntLit 7, TAdd (TIntLit 8, TIntLit 9)),
      TIntLit 0 )

(* Exercises the false branch, boolean literals, nested conditionals, and
   equality over booleans while remaining intrinsically well typed. *)
let complex_false : int expr =
  TIf
    ( TEq (TBoolLit true, TBoolLit false),
      TAdd (TIntLit 100, TIntLit 1),
      TIf (TBoolLit false, TIntLit 7, TAdd (TIntLit 20, TIntLit 22)) )

let complex_true : bool expr =
  TIf
    ( TEq (TBoolLit true, TBoolLit true),
      TIf (TBoolLit false, TBoolLit false, TBoolLit true),
      TBoolLit false )
