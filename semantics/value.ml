(* Set of values *)
(* noinitialized and non causal values *)

type 'a extended =
  | Vnil : 'a extended
  | Vbot : 'a extended
  | Value : 'a -> 'a extended
  
type pvalue =
  | Vint : int -> pvalue
  | Vbool : bool -> pvalue
  | Vfloat : float -> pvalue
  | Vchar : char -> pvalue
  | Vstring : string -> pvalue
  | Vvoid : pvalue
  | Vconstr0 : Lident.t -> pvalue
  | Vconstr1 : Lident.t * value list -> pvalue
  | Vtuple : value list -> pvalue
  | Vstate0 : Ident.t -> pvalue
  | Vstate1 : Ident.t * value list -> pvalue

and value = pvalue extended
          
type state =
  | Sempty : state
  | Stuple : state list -> state
  | Sval : value -> state
  | Sopt : value option -> state
                 
type ('a, 's) costream =
  | CoF : { init : 's;
            step : 's -> ('a * 's) option } -> ('a, 's) costream

type ('a, 'b, 's) node =
  | CoFun  : ('a -> 'b option) -> ('a, 'b, 's) node
  | CoNode : { init : 's;
               step : 's -> 'a -> ('b * 's) option } -> ('a, 'b, 's) node

type gvalue =
  | Gvalue : value -> gvalue
  | Gfun : (value list, value list, state) node -> gvalue
