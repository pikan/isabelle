(*  Title:      TFL/thry
    ID:         $Id$
    Author:     Konrad Slind, Cambridge University Computer Laboratory
    Copyright   1997  University of Cambridge
*)

structure Thry : Thry_sig (* LThry_sig *) = 
struct

structure USyntax  = USyntax;

open Mask;
structure S = USyntax;


fun THRY_ERR{func,mesg} = Utils.ERR{module = "Thry",func=func,mesg=mesg};

(*---------------------------------------------------------------------------
 *    Matching 
 *---------------------------------------------------------------------------*)

local open Utils
      infix 3 |->
      fun tybind (x,y) = TVar (x,["term"])  |-> y
      fun tmbind (x,y) = Var  (x,type_of y) |-> y
in
 fun match_term thry pat ob = 
    let val tsig = #tsig(Sign.rep_sg(sign_of thry))
        val (ty_theta,tm_theta) = Pattern.match tsig (pat,ob)
    in (map tmbind tm_theta, map tybind ty_theta)
    end

 fun match_type thry pat ob = 
    map tybind(Type.typ_match (#tsig(Sign.rep_sg(sign_of thry))) ([],(pat,ob)))
end;


(*---------------------------------------------------------------------------
 * Typing 
 *---------------------------------------------------------------------------*)

fun typecheck thry = cterm_of (sign_of thry);



(*----------------------------------------------------------------------------
 * Making a definition. The argument "tm" looks like "f = WFREC R M". This 
 * entrypoint is specialized for interactive use, since it closes the theory
 * after making the definition. This allows later interactive definitions to
 * refer to previous ones. The name for the new theory is automatically 
 * generated from the name of the argument theory.
 *---------------------------------------------------------------------------*)


(*---------------------------------------------------------------------------
 * TFL attempts to make definitions where the lhs is a variable. Isabelle
 * wants it to be a constant, so here we map it to a constant. Moreover, the
 * theory should already have the constant, so we refrain from adding the
 * constant to the theory. We just add the axiom and return the theory.
 *---------------------------------------------------------------------------*)
local val (imp $ tprop $ (eeq $ _ $ _ )) = #prop(rep_thm(eq_reflection))
      val Const(eeq_name, ty) = eeq
      val prop = #2 (S.strip_type ty)
in
fun make_definition parent s tm = 
   let val {lhs,rhs} = S.dest_eq tm
       val (Name,Ty) = dest_Free lhs
       val lhs1 = S.mk_const{Name = Name, Ty = Ty}
       val eeq1 = S.mk_const{Name = eeq_name, Ty = Ty --> Ty --> prop}
       val dtm = list_comb(eeq1,[lhs1,rhs])      (* Rename "=" to "==" *)
       val (_, tm', _) = Sign.infer_types (sign_of parent)
                     (K None) (K None) [] true ([dtm],propT)
       val new_thy = add_defs_i [(s,tm')] parent
   in 
   (freezeT((get_axiom new_thy s) RS meta_eq_to_obj_eq), new_thy)
   end;
end;

(*---------------------------------------------------------------------------
 * Utility routine. Insert into list ordered by the key (a string). If two 
 * keys are equal, the new element replaces the old. A more efficient option 
 * for the future is needed. In fact, having the list of datatype facts be 
 * ordered is useless, since the lookup should never fail!
 *---------------------------------------------------------------------------*)
fun insert (el as (x:string, _)) = 
 let fun canfind[] = [el] 
       | canfind(alist as ((y as (k,_))::rst)) = 
           if (x<k) then el::alist
           else if (x=k) then el::rst
           else y::canfind rst 
 in canfind
 end;


(*---------------------------------------------------------------------------
 *     A collection of facts about datatypes
 *---------------------------------------------------------------------------*)
val nat_record = Dtype.build_record (Nat.thy, ("nat",["0","Suc"]), nat_ind_tac)
val prod_record =
    let val prod_case_thms = Dtype.case_thms (sign_of Prod.thy) [split] 
                                 (fn s => res_inst_tac [("p",s)] PairE_lemma)
         fun const s = Const(s, the(Sign.const_type (sign_of Prod.thy) s))
     in ("*", 
         {constructors = [const "Pair"],
            case_const = const "split",
         case_rewrites = [split RS eq_reflection],
             case_cong = #case_cong prod_case_thms,
              nchotomy = #nchotomy prod_case_thms}) 
     end;

(*---------------------------------------------------------------------------
 * Hacks to make interactive mode work. Referring to "datatypes" directly
 * is temporary, I hope!
 *---------------------------------------------------------------------------*)
val match_info = fn thy =>
    fn "*" => Some({case_const = #case_const (#2 prod_record),
                     constructors = #constructors (#2 prod_record)})
     | "nat" => Some({case_const = #case_const (#2 nat_record),
                       constructors = #constructors (#2 nat_record)})
     | ty => case assoc(!datatypes,ty)
               of None => None
                | Some{case_const,constructors, ...} =>
                   Some{case_const=case_const, constructors=constructors}

val induct_info = fn thy =>
    fn "*" => Some({nchotomy = #nchotomy (#2 prod_record),
                     constructors = #constructors (#2 prod_record)})
     | "nat" => Some({nchotomy = #nchotomy (#2 nat_record),
                       constructors = #constructors (#2 nat_record)})
     | ty => case assoc(!datatypes,ty)
               of None => None
                | Some{nchotomy,constructors, ...} =>
                  Some{nchotomy=nchotomy, constructors=constructors}

val extract_info = fn thy => 
 let val case_congs = map (#case_cong o #2) (!datatypes)
         val case_rewrites = flat(map (#case_rewrites o #2) (!datatypes))
 in {case_congs = #case_cong (#2 prod_record)::
                  #case_cong (#2 nat_record)::case_congs,
     case_rewrites = #case_rewrites(#2 prod_record)@
                     #case_rewrites(#2 nat_record)@case_rewrites}
 end;

end; (* Thry *)
