header "Arithmetic and Boolean Expressions"

theory AExp imports Main begin

subsection "Arithmetic Expressions"

type_synonym name = string
type_synonym val = int
type_synonym state = "name \<Rightarrow> val"

datatype aexp = N int | V name | Plus aexp aexp

fun aval :: "aexp \<Rightarrow> state \<Rightarrow> val" where
"aval (N n) _ = n" |
"aval (V x) s = s x" |
"aval (Plus a1 a2) s = aval a1 s + aval a2 s"


value "aval (Plus (V ''x'') (N 5)) (%x. if x = ''x'' then 7 else 0)"

text {* The same state more concisely: *}
value "aval (Plus (V ''x'') (N 5)) ((%x. 0) (''x'':= 7))"

text {* A little syntax magic to write larger states compactly: *}

nonterminal funlets and funlet

syntax
  "_funlet"  :: "['a, 'a] => funlet"             ("_ /->/ _")
   ""         :: "funlet => funlets"             ("_")
  "_Funlets" :: "[funlet, funlets] => funlets"   ("_,/ _")
  "_Fun"     :: "funlets => 'a => 'b"            ("(1[_])")
  "_FunUpd"  :: "['a => 'b, funlets] => 'a => 'b" ("_/'(_')" [900,0]900)

syntax (xsymbols)
  "_funlet"  :: "['a, 'a] => funlet"             ("_ /\<rightarrow>/ _")

translations
  "_FunUpd m (_Funlets xy ms)"  == "_FunUpd (_FunUpd m xy) ms"
  "_FunUpd m (_funlet  x y)"    == "m(x := y)"
  "_Fun ms"                     == "_FunUpd (%_. 0) ms"
  "_Fun (_Funlets ms1 ms2)"     <= "_FunUpd (_Fun ms1) ms2"
  "_Funlets ms1 (_Funlets ms2 ms3)" <= "_Funlets (_Funlets ms1 ms2) ms3"

text {* 
  We can now write a series of updates to the function @{text "\<lambda>x. 0"} compactly:
*}
lemma "[a \<rightarrow> Suc 0, b \<rightarrow> 2] = ((%_. 0) (a := Suc 0)) (b := 2)"
  by (rule refl)

value "aval (Plus (V ''x'') (N 5)) [''x'' \<rightarrow> 7]"

text {* Variables that are not mentioned in the state are 0 by default in 
  the @{term "[a \<rightarrow> b::int]"} syntax: 
*}   
value "aval (Plus (V ''x'') (N 5)) [''y'' \<rightarrow> 7]"


subsection "Optimization"

text{* Evaluate constant subsexpressions: *}

fun asimp_const :: "aexp \<Rightarrow> aexp" where
"asimp_const (N n) = N n" |
"asimp_const (V x) = V x" |
"asimp_const (Plus a1 a2) =
  (case (asimp_const a1, asimp_const a2) of
    (N n1, N n2) \<Rightarrow> N(n1+n2) |
    (a1',a2') \<Rightarrow> Plus a1' a2')"

theorem aval_asimp_const[simp]:
  "aval (asimp_const a) s = aval a s"
apply(induct a)
apply (auto split: aexp.split)
done

text{* Now we also eliminate all occurrences 0 in additions. The standard
method: optimized versions of the constructors: *}

fun plus :: "aexp \<Rightarrow> aexp \<Rightarrow> aexp" where
"plus (N i1) (N i2) = N(i1+i2)" |
"plus (N i) a = (if i=0 then a else Plus (N i) a)" |
"plus a (N i) = (if i=0 then a else Plus a (N i))" |
"plus a1 a2 = Plus a1 a2"

code_thms plus
code_thms plus

(* FIXME: dropping subsumed code eqns?? *)
lemma aval_plus[simp]:
  "aval (plus a1 a2) s = aval a1 s + aval a2 s"
apply(induct a1 a2 rule: plus.induct)
apply simp_all (* just for a change from auto *)
done
code_thms plus

fun asimp :: "aexp \<Rightarrow> aexp" where
"asimp (N n) = N n" |
"asimp (V x) = V x" |
"asimp (Plus a1 a2) = plus (asimp a1) (asimp a2)"

text{* Note that in @{const asimp_const} the optimized constructor was
inlined. Making it a separate function @{const plus} improves modularity of
the code and the proofs. *}

value "asimp (Plus (Plus (N 0) (N 0)) (Plus (V ''x'') (N 0)))"

theorem aval_asimp[simp]:
  "aval (asimp a) s = aval a s"
apply(induct a)
apply simp_all
done

end
