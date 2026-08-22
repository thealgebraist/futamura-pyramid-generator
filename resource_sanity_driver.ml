open Core_specializer
open Resource_sanity

let rec sum_tree count start =
  if count = 1 then EInt start
  else
    let left = count / 2 in
    EAdd (sum_tree left start, sum_tree (count - left) (start + left))

let check number leaves =
  let expression = ELet ("work", sum_tree leaves 1, EAdd (EVar "work", EInt 1)) in
  let e = estimate expression in
  Printf.printf "case %02d: ops=%d nodes=%d depth=%d bytes=%d\n"
    number e.operations e.ast_nodes e.maximum_depth e.estimated_bytes;
  List.iter (fun warning -> Printf.printf "  WARNING: %s\n" warning)
    (warnings e)

let () =
  check 1 1024;
  check 2 2048;
  check 3 4096;
  check 4 8192;
  check 5 16384;
  check 6 32768;
  check 7 65536;
  check 8 131072
