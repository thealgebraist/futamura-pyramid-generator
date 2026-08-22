(* Pure, non-executing resource analysis for the core expression ADT. *)

open Core_specializer

type estimate = {
  operations: int;
  ast_nodes: int;
  maximum_depth: int;
  dynamic_leaves: int;
  estimated_bytes: int;
  log2_nodes: float;
}

let add a b = a + b

let rec inspect depth expression =
  match expression with
  | EInt _ | EBool _ | EVar _ ->
      (1, 1, depth, if match expression with EVar _ -> true | _ -> false then 1 else 0)
  | EAdd (left, right) | EEq (left, right) ->
      let a = inspect (depth + 1) left in
      let b = inspect (depth + 1) right in
      (1 + add (let (x, _, _, _) = a in x) (let (x, _, _, _) = b in x),
       1 + add (let (_, x, _, _) = a in x) (let (_, x, _, _) = b in x),
       max (let (_, _, x, _) = a in x) (let (_, _, x, _) = b in x),
       add (let (_, _, _, x) = a in x) (let (_, _, _, x) = b in x))
  | EIf (test, yes_branch, no_branch) ->
      let a = inspect (depth + 1) test in
      let b = inspect (depth + 1) yes_branch in
      let c = inspect (depth + 1) no_branch in
      (1 + add (let (x, _, _, _) = a in x)
             (add (let (x, _, _, _) = b in x) (let (x, _, _, _) = c in x)),
       1 + add (let (_, x, _, _) = a in x)
             (add (let (_, x, _, _) = b in x) (let (_, x, _, _) = c in x)),
       max (let (_, _, x, _) = a in x)
         (max (let (_, _, x, _) = b in x) (let (_, _, x, _) = c in x)),
       add (let (_, _, _, x) = a in x)
         (add (let (_, _, _, x) = b in x) (let (_, _, _, x) = c in x)))
  | ELet (_, definition, body) ->
      let a = inspect (depth + 1) definition in
      let b = inspect (depth + 1) body in
      (1 + add (let (x, _, _, _) = a in x) (let (x, _, _, _) = b in x),
       1 + add (let (_, x, _, _) = a in x) (let (_, x, _, _) = b in x),
       max (let (_, _, x, _) = a in x) (let (_, _, x, _) = b in x),
       add (let (_, _, _, x) = a in x) (let (_, _, _, x) = b in x))

let estimate expression =
  let operations, ast_nodes, maximum_depth, dynamic_leaves = inspect 1 expression in
  {
    operations;
    ast_nodes;
    maximum_depth;
    dynamic_leaves;
    estimated_bytes = ast_nodes * 64;
    log2_nodes = log (float_of_int ast_nodes) /. log 2.0;
  }

let warnings ?(operation_budget = 1_000_000) ?(memory_budget = 64 * 1024 * 1024) e =
  let operation_warning =
    if e.operations > operation_budget then
      ["operation estimate exceeds budget: " ^ string_of_int e.operations]
    else []
  in
  let memory_warning =
    if e.estimated_bytes > memory_budget then
      ["estimated AST memory exceeds budget: " ^ string_of_int e.estimated_bytes]
    else []
  in
  let branching_warning =
    if e.maximum_depth >= 16 && e.log2_nodes /. float_of_int e.maximum_depth > 0.85 then
      ["branching shape is exponential-like: log2(nodes)/depth = " ^
       string_of_float (e.log2_nodes /. float_of_int e.maximum_depth)]
    else []
  in
  operation_warning @ memory_warning @ branching_warning
