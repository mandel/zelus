(**************************************************************************)
(*                                                                        *)
(*  The Zelus Hybrid Synchronous Language                                 *)
(*  Copyright (C) 2012-2017                                               *)
(*                                                                        *)
(*  Timothy Bourke                                                        *)
(*  Marc Pouzet                                                           *)
(*                                                                        *)
(*  Universite Pierre et Marie Curie - Ecole normale superieure - INRIA   *)
(*                                                                        *)
(*   This file is distributed under the terms of the CeCILL-C licence     *)
(*                                                                        *)
(**************************************************************************)

(* copie continuous state vectors back and forth into the internal state *)
(* A machine of the form *)
(* machine m =                         *)
(*    memories (k_i m_k: t_i)_{i in I} *)
(*    instance (j_i: f_i)_{i in J}     *)
(*    method (meth_l p_l = e_l)_{l in L} *)
(* is modified by adding functions calls to read and write *)
(* the continous state and zero-crossing vectors *)

(* we suppose known the following globals *)
(*  val cindex : int ref
 *- val zindex : int ref
 *  val cmax : int ref
 *- val zmax : int ref
 *- val cin : cont -> int -> unit
 *- val cout : cont -> int -> unit
 *- val zin : zero -> int -> unit
 *- val zout : zero -> int -> unit
 *- val dzero : int -> int -> unit
 *- val discrete : bool ref
 *- val horizon : float ref *)


(*- let cvec = ref (Zls.cmake 0)
 *- let dvec = ref (Zls.zmake 0)
 *- let zinvec = ref (Zls.cmake 0)
 *- let zoutvec = ref (Zls.zmake 0)
 *- let cindex = ref 0
 *- let cmax = ref 0
 *- let zindex = ref 0
 *- let zmax = ref 0
 *- let discrete = ref true
 *- let horizon = ref infinity
		   
 *- let cindex () = !cindex
 *- let zindex () = !zindex
 *- let cmax i = cmax := !cmax + i
 *- let zmax i = zmax := !zmax + i
 *- let cincr i = cindex := !cindex + i
 *- let zincr i = zindex := !zindex + i
 *- let cin x i = x.pos <- Zls.get !cvec i
 *- let zin x i = x.zin <- Zls.get_zin !zinvec i
 *- let cout x i = Zls.set !cvec i x.pos
 *- let dout x i = Zls.set !dvec i x.der
 *- let zout x i = Zls.set !zout i x.zout
 *- let dzero c s = for i = c to s - 1 do Zls.set !dvec i 0.0 done
 *- let horizon h = horizon := !horizon +. h
 *- let hzero () = horizon := 0.0 *)

(* Only the method "step" is changed and initialization code is added to
 *- set [cmax] and [zmax].
 *- suppose that [csize] is the length of the state vector of the current block;
 *- x1,..., xn are the continuous state variables;
 *- m1,..., mk are the zero-crossing variables;
 *- method step(x1,...,xn) = ...body... is the step method.
 *- rewrite it into:
 *- method step(x1,...,xn) =
 *-    let ci = cindex() in (* current position of the cvector *)
 *-    let zi = zindex() in (* current position of the zvector *)
 *-    if d then dzero s ci (* set all speeds to 0.0 *)
 *-    else (zin m1 zi;...; zout mk (zi+k);
 *-          (* sets de value of continuous zero-crossing with what has been *)
 *-          (* computed by the zero-crossing detection *)
 *-          cin x1 ci;...; cin xn (ci+n));
 *-          (* sets the xi with the value of the input state vector *)
 *-    let result = ...body... in
 *-    if d then (cout x1 ci;...; cout xn (ci+n));
 *-        (* sets the output state vector with the xi *)
 *-    else (zout m1 zi;...; mout mk (zi+k));
 *-      (* store the argument of zero-crossing into the vector of zero-cross *)
 *-    result
 *-
 *- Add to the initialization code: 
 *-    cmax csize; 
 *-    zmax zsize
 *- which increments the size of the continuous state and zero-crossing vectors *)

open Misc
open Ident
open Lident
open Deftypes
open Obc
open Format

let oletin p e1 i2 = Olet(p, e1, i2)
let int_const v = Oconst(Oint(v))
let float_const v = Oconst(Ofloat(v))
let operator op = Oglobal(Modname (Initial.pervasives_name op))
let oplus e1 e2 = Oapp(operator "(+)", [e1; e2])
let ominus e1 e2 = Oapp(operator "(-)", [e1; e2])
let local x = Olocal(x)
let modname x = Lident.Modname { Lident.qual = "Zls"; Lident.id = x }
let global x = Oglobal(x)                      
let varpat x ty = Ovarpat(x, Translate.type_expression_of_typ ty)
let void = Oconst(Ovoid)
let ifthenelse c i1 i2 = Oif(c, i1, Some(i2))
let sequence i1 i2 = Osequence [i1; i2]
let i = Ident.fresh "i"
		    
(* input/output functions *)
let bang mname = Oapp(operator "!", [global (modname mname)])
let cindex = bang "cindex"
let zindex = bang "zindex"
let discrete = bang "discrete"

let inout f args = Oapp(global(modname f), args)
let get e i = inout "get" [e; i]
let get_zin e i = inout "get_zin" [e; i]
let set e i arg = inout "set" [e; i; arg]
                        
let incr x i =
  Oassign_state(Oleft_state_global(modname x),
                oplus (bang x) (int_const i))
               
let cmax i = incr "cmax" i
let zmax i = incr "zmax" i
let cincr i = incr "cindex" i
let zincr i = incr "zindex" i
                  
let cin x i =
  Oassign_state(Oleft_state_primitive_access(Oleft_state_name(x), Ocont),
                get (bang "cvec") i)
let zin x i =
  Oassign_state(Oleft_state_primitive_access(Oleft_state_name(x), Ozero_in),
                get_zin (bang "zinvec") i)
let cout x i =
  set (bang "cvec") i (Ostate(Oleft_state_primitive_access(Oleft_state_name(x),
                                                           Ocont)))
let dout x i =
  set (bang "dvec") i (Ostate(Oleft_state_primitive_access(Oleft_state_name(x),
                                                           Oder)))
let zout x i =
  set (bang "zoutvec") i
      (Ostate(Oleft_state_primitive_access(Oleft_state_name(x), Ozero_out)))

let dzero c s =
  Ofor(true, i, local c, ominus s (int_const 1),
       Oexp(set (bang "dvec") (local i) (float_const 0.0)))

(** Compute the index associated to a state variable [x] in the current block *)
(* [build_index m_list = (ctable, csize), (ztable, zsize), m_list] *)
let build_index m_list =
  (* build two tables. The table [ctable] associates an integer index to *)
  (* every continuous state variable; [ztable] do the same for zero-crossings *)
  (* also return the size of every table *)
  let build ((ctable, csize), (ztable, zsize))
	    { m_name = n; m_kind = m; m_value = e_opt } = 
    match m with
    | None -> (ctable, csize), (ztable, zsize)
    | Some(k) ->
       match k with
       | Horizon | Period | Encore -> (ctable, csize), (ztable, zsize)
       | Zero -> (ctable, csize), (Env.add n zsize ztable, zsize + 1)
       | Cont -> (Env.add n csize ctable, csize + 1), (ztable, zsize) in
  let (ctable, csize), (ztable, zsize) =
    List.fold_left build ((Env.empty, 0), (Env.empty, 0)) m_list in
  (ctable, csize), (ztable, zsize)


(** Add a method to copy back and forth the internal representation *)
(** of the continuous state vector to the external flat representation *)
(* This function is generic: [table, size] contains the association table *)
(* [name, index] with size [size]. [assign n index] does the copy for *)
(* local memories. *)
let cinout (table, size) call start =
  (* For every input (x, index) from [table] *)
  (* [call (local x) (start + index)] *)
  let add x index acc =
    call x (oplus (local start) (int_const index)) :: acc in
  let c_list = Env.fold add table [] in
  Osequence(c_list)

let cin (table, size) start =
  let call x i = cin x i in
  cinout (table, size) call start

let cout (table, size) start =
  let assign x i = Oexp(cout x i) in
  cinout (table, size) assign start

let dout (table, size) start =
  let assign x i = Oexp(dout x i) in
  cinout (table, size) assign start

let zin (table, size) start =
  let assign x i = zin x i in
  cinout (table, size) assign start

let zout (table, size) start =
  let assign x i = Oexp(zout x i) in
  cinout (table, size) assign start
	
(* Add a method dzero cstart which fill the vector of derivatives *)
(* with zeros *)
let dzero (ctable, csize) cstart = dzero cstart (int_const csize)

(* increments the maximum size of the continuous state vector and that of *)
(* the zero-crossing vector *)
let max call size i_opt =
  if size = 0 then i_opt
  else let i = call size in
       match i_opt with
       | None -> Some(i) | Some(i_old) -> Some(sequence i i_old)
    
(** Translate a continuous-time machine *)
let machine f ({ ma_initialize = i_opt;
		 ma_memories = m_list; ma_methods = method_list } as mach) =
  (* auxiliary function. Find the method "step" in the list of methods *)
  let rec get method_list =
    match method_list with
    | [] -> raise Not_found
    | { me_name = m } as mdesc :: method_list ->
       if m = Ostep then mdesc, method_list
       else let step, method_list = get method_list in
	    step, mdesc :: method_list in
  try
    let { me_body = body; me_typ = ty } as mdesc, method_list =
      get method_list in
    (* associate an integer index to every continuous state *)
    (* variable and zero-crossing *)
    let (ctable, csize), (ztable, zsize) = build_index m_list in

    (* add initialization code to [e_opt] *)
    let i_opt = max cmax csize (max zmax zsize i_opt) in
          
    (* compute the current position of the cvector *)
    let ci = Ident.fresh "ci" in
    let zi = Ident.fresh "zi" in
    let result = Ident.fresh "result" in
    let body =
      oletin
        (varpat ci Initial.typ_int) cindex
        (* compute the current position of the zvector *)
        (oletin
           (varpat zi Initial.typ_int) zindex
           (sequence
	      (ifthenelse discrete (dzero (ctable, csize) ci)
		          (sequence
                             (zin (ztable, zsize) zi) (cin (ctable, csize) ci)))
	      (oletin
                 (varpat result ty) (Oinst(body))
                 (sequence
	            (ifthenelse discrete (cout (ctable, csize) ci)
			        (sequence (zout (ztable, zsize) zi)
			                  (dout (ctable, csize) ci)))
                    (Oexp (local result)))))) in
    { mach with ma_initialize = i_opt;
		ma_methods = { mdesc with me_body = body } :: method_list }
  with
    (* no get method is present *)
    Not_found -> mach
		   
(** The main entry. Add new methods to copy the continuous state vector *)
(** back and forth into the internal state *)
let implementation impl =
  match impl with
  | Oletmachine(f, ({ ma_kind = Deftypes.Tcont } as mach)) -> 
     (* only continuous machines are concerned *)
     Oletmachine(f, machine f mach)
  | Oletmachine _ | Oletvalue _ | Oletfun _ | Oopen _ | Otypedecl _ -> impl
									 
let implementation_list impl_list = Misc.iter implementation impl_list
