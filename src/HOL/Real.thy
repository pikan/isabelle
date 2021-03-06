(*  Title:      HOL/Real.thy
    Author:     Jacques D. Fleuriot, University of Edinburgh, 1998
    Author:     Larry Paulson, University of Cambridge
    Author:     Jeremy Avigad, Carnegie Mellon University
    Author:     Florian Zuleger, Johannes Hoelzl, and Simon Funke, TU Muenchen
    Conversion to Isar and new proofs by Lawrence C Paulson, 2003/4
    Construction of Cauchy Reals by Brian Huffman, 2010
*)

section \<open>Development of the Reals using Cauchy Sequences\<close>

theory Real
imports Rat Conditionally_Complete_Lattices
begin

text \<open>
  This theory contains a formalization of the real numbers as
  equivalence classes of Cauchy sequences of rationals.  See
  @{file "~~/src/HOL/ex/Dedekind_Real.thy"} for an alternative
  construction using Dedekind cuts.
\<close>

subsection \<open>Preliminary lemmas\<close>

lemma inj_add_left [simp]:
  fixes x :: "'a::cancel_semigroup_add" shows "inj (op+ x)"
by (meson add_left_imp_eq injI)

lemma inj_mult_left [simp]: "inj (op* x) \<longleftrightarrow> x \<noteq> (0::'a::idom)"
  by (metis injI mult_cancel_left the_inv_f_f zero_neq_one)

lemma add_diff_add:
  fixes a b c d :: "'a::ab_group_add"
  shows "(a + c) - (b + d) = (a - b) + (c - d)"
  by simp

lemma minus_diff_minus:
  fixes a b :: "'a::ab_group_add"
  shows "- a - - b = - (a - b)"
  by simp

lemma mult_diff_mult:
  fixes x y a b :: "'a::ring"
  shows "(x * y - a * b) = x * (y - b) + (x - a) * b"
  by (simp add: algebra_simps)

lemma inverse_diff_inverse:
  fixes a b :: "'a::division_ring"
  assumes "a \<noteq> 0" and "b \<noteq> 0"
  shows "inverse a - inverse b = - (inverse a * (a - b) * inverse b)"
  using assms by (simp add: algebra_simps)

lemma obtain_pos_sum:
  fixes r :: rat assumes r: "0 < r"
  obtains s t where "0 < s" and "0 < t" and "r = s + t"
proof
    from r show "0 < r/2" by simp
    from r show "0 < r/2" by simp
    show "r = r/2 + r/2" by simp
qed

subsection \<open>Sequences that converge to zero\<close>

definition
  vanishes :: "(nat \<Rightarrow> rat) \<Rightarrow> bool"
where
  "vanishes X = (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r)"

lemma vanishesI: "(\<And>r. 0 < r \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r) \<Longrightarrow> vanishes X"
  unfolding vanishes_def by simp

lemma vanishesD: "\<lbrakk>vanishes X; 0 < r\<rbrakk> \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. \<bar>X n\<bar> < r"
  unfolding vanishes_def by simp

lemma vanishes_const [simp]: "vanishes (\<lambda>n. c) \<longleftrightarrow> c = 0"
  unfolding vanishes_def
  apply (cases "c = 0", auto)
  apply (rule exI [where x="\<bar>c\<bar>"], auto)
  done

lemma vanishes_minus: "vanishes X \<Longrightarrow> vanishes (\<lambda>n. - X n)"
  unfolding vanishes_def by simp

lemma vanishes_add:
  assumes X: "vanishes X" and Y: "vanishes Y"
  shows "vanishes (\<lambda>n. X n + Y n)"
proof (rule vanishesI)
  fix r :: rat assume "0 < r"
  then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
    by (rule obtain_pos_sum)
  obtain i where i: "\<forall>n\<ge>i. \<bar>X n\<bar> < s"
    using vanishesD [OF X s] ..
  obtain j where j: "\<forall>n\<ge>j. \<bar>Y n\<bar> < t"
    using vanishesD [OF Y t] ..
  have "\<forall>n\<ge>max i j. \<bar>X n + Y n\<bar> < r"
  proof (clarsimp)
    fix n assume n: "i \<le> n" "j \<le> n"
    have "\<bar>X n + Y n\<bar> \<le> \<bar>X n\<bar> + \<bar>Y n\<bar>" by (rule abs_triangle_ineq)
    also have "\<dots> < s + t" by (simp add: add_strict_mono i j n)
    finally show "\<bar>X n + Y n\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>X n + Y n\<bar> < r" ..
qed

lemma vanishes_diff:
  assumes X: "vanishes X" and Y: "vanishes Y"
  shows "vanishes (\<lambda>n. X n - Y n)"
  unfolding diff_conv_add_uminus by (intro vanishes_add vanishes_minus X Y)

lemma vanishes_mult_bounded:
  assumes X: "\<exists>a>0. \<forall>n. \<bar>X n\<bar> < a"
  assumes Y: "vanishes (\<lambda>n. Y n)"
  shows "vanishes (\<lambda>n. X n * Y n)"
proof (rule vanishesI)
  fix r :: rat assume r: "0 < r"
  obtain a where a: "0 < a" "\<forall>n. \<bar>X n\<bar> < a"
    using X by blast
  obtain b where b: "0 < b" "r = a * b"
  proof
    show "0 < r / a" using r a by simp
    show "r = a * (r / a)" using a by simp
  qed
  obtain k where k: "\<forall>n\<ge>k. \<bar>Y n\<bar> < b"
    using vanishesD [OF Y b(1)] ..
  have "\<forall>n\<ge>k. \<bar>X n * Y n\<bar> < r"
    by (simp add: b(2) abs_mult mult_strict_mono' a k)
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>X n * Y n\<bar> < r" ..
qed

subsection \<open>Cauchy sequences\<close>

definition
  cauchy :: "(nat \<Rightarrow> rat) \<Rightarrow> bool"
where
  "cauchy X \<longleftrightarrow> (\<forall>r>0. \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r)"

lemma cauchyI:
  "(\<And>r. 0 < r \<Longrightarrow> \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r) \<Longrightarrow> cauchy X"
  unfolding cauchy_def by simp

lemma cauchyD:
  "\<lbrakk>cauchy X; 0 < r\<rbrakk> \<Longrightarrow> \<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < r"
  unfolding cauchy_def by simp

lemma cauchy_const [simp]: "cauchy (\<lambda>n. x)"
  unfolding cauchy_def by simp

lemma cauchy_add [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n + Y n)"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
    by (rule obtain_pos_sum)
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>Y m - Y n\<bar> < t"
    using cauchyD [OF Y t] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>(X m + Y m) - (X n + Y n)\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>(X m + Y m) - (X n + Y n)\<bar> \<le> \<bar>X m - X n\<bar> + \<bar>Y m - Y n\<bar>"
      unfolding add_diff_add by (rule abs_triangle_ineq)
    also have "\<dots> < s + t"
      by (rule add_strict_mono, simp_all add: i j *)
    finally show "\<bar>(X m + Y m) - (X n + Y n)\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>(X m + Y m) - (X n + Y n)\<bar> < r" ..
qed

lemma cauchy_minus [simp]:
  assumes X: "cauchy X"
  shows "cauchy (\<lambda>n. - X n)"
using assms unfolding cauchy_def
unfolding minus_diff_minus abs_minus_cancel .

lemma cauchy_diff [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n - Y n)"
  using assms unfolding diff_conv_add_uminus by (simp del: add_uminus_conv_diff)

lemma cauchy_imp_bounded:
  assumes "cauchy X" shows "\<exists>b>0. \<forall>n. \<bar>X n\<bar> < b"
proof -
  obtain k where k: "\<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m - X n\<bar> < 1"
    using cauchyD [OF assms zero_less_one] ..
  show "\<exists>b>0. \<forall>n. \<bar>X n\<bar> < b"
  proof (intro exI conjI allI)
    have "0 \<le> \<bar>X 0\<bar>" by simp
    also have "\<bar>X 0\<bar> \<le> Max (abs ` X ` {..k})" by simp
    finally have "0 \<le> Max (abs ` X ` {..k})" .
    thus "0 < Max (abs ` X ` {..k}) + 1" by simp
  next
    fix n :: nat
    show "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1"
    proof (rule linorder_le_cases)
      assume "n \<le> k"
      hence "\<bar>X n\<bar> \<le> Max (abs ` X ` {..k})" by simp
      thus "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1" by simp
    next
      assume "k \<le> n"
      have "\<bar>X n\<bar> = \<bar>X k + (X n - X k)\<bar>" by simp
      also have "\<bar>X k + (X n - X k)\<bar> \<le> \<bar>X k\<bar> + \<bar>X n - X k\<bar>"
        by (rule abs_triangle_ineq)
      also have "\<dots> < Max (abs ` X ` {..k}) + 1"
        by (rule add_le_less_mono, simp, simp add: k \<open>k \<le> n\<close>)
      finally show "\<bar>X n\<bar> < Max (abs ` X ` {..k}) + 1" .
    qed
  qed
qed

lemma cauchy_mult [simp]:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "cauchy (\<lambda>n. X n * Y n)"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  then obtain u v where u: "0 < u" and v: "0 < v" and "r = u + v"
    by (rule obtain_pos_sum)
  obtain a where a: "0 < a" "\<forall>n. \<bar>X n\<bar> < a"
    using cauchy_imp_bounded [OF X] by blast
  obtain b where b: "0 < b" "\<forall>n. \<bar>Y n\<bar> < b"
    using cauchy_imp_bounded [OF Y] by blast
  obtain s t where s: "0 < s" and t: "0 < t" and r: "r = a * t + s * b"
  proof
    show "0 < v/b" using v b(1) by simp
    show "0 < u/a" using u a(1) by simp
    show "r = a * (u/a) + (v/b) * b"
      using a(1) b(1) \<open>r = u + v\<close> by simp
  qed
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>Y m - Y n\<bar> < t"
    using cauchyD [OF Y t] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>X m * Y m - X n * Y n\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>X m * Y m - X n * Y n\<bar> = \<bar>X m * (Y m - Y n) + (X m - X n) * Y n\<bar>"
      unfolding mult_diff_mult ..
    also have "\<dots> \<le> \<bar>X m * (Y m - Y n)\<bar> + \<bar>(X m - X n) * Y n\<bar>"
      by (rule abs_triangle_ineq)
    also have "\<dots> = \<bar>X m\<bar> * \<bar>Y m - Y n\<bar> + \<bar>X m - X n\<bar> * \<bar>Y n\<bar>"
      unfolding abs_mult ..
    also have "\<dots> < a * t + s * b"
      by (simp_all add: add_strict_mono mult_strict_mono' a b i j *)
    finally show "\<bar>X m * Y m - X n * Y n\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>X m * Y m - X n * Y n\<bar> < r" ..
qed

lemma cauchy_not_vanishes_cases:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "\<exists>b>0. \<exists>k. (\<forall>n\<ge>k. b < - X n) \<or> (\<forall>n\<ge>k. b < X n)"
proof -
  obtain r where "0 < r" and r: "\<forall>k. \<exists>n\<ge>k. r \<le> \<bar>X n\<bar>"
    using nz unfolding vanishes_def by (auto simp add: not_less)
  obtain s t where s: "0 < s" and t: "0 < t" and "r = s + t"
    using \<open>0 < r\<close> by (rule obtain_pos_sum)
  obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  obtain k where "i \<le> k" and "r \<le> \<bar>X k\<bar>"
    using r by blast
  have k: "\<forall>n\<ge>k. \<bar>X n - X k\<bar> < s"
    using i \<open>i \<le> k\<close> by auto
  have "X k \<le> - r \<or> r \<le> X k"
    using \<open>r \<le> \<bar>X k\<bar>\<close> by auto
  hence "(\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)"
    unfolding \<open>r = s + t\<close> using k by auto
  hence "\<exists>k. (\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)" ..
  thus "\<exists>t>0. \<exists>k. (\<forall>n\<ge>k. t < - X n) \<or> (\<forall>n\<ge>k. t < X n)"
    using t by auto
qed

lemma cauchy_not_vanishes:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "\<exists>b>0. \<exists>k. \<forall>n\<ge>k. b < \<bar>X n\<bar>"
using cauchy_not_vanishes_cases [OF assms]
by clarify (rule exI, erule conjI, rule_tac x=k in exI, auto)

lemma cauchy_inverse [simp]:
  assumes X: "cauchy X"
  assumes nz: "\<not> vanishes X"
  shows "cauchy (\<lambda>n. inverse (X n))"
proof (rule cauchyI)
  fix r :: rat assume "0 < r"
  obtain b i where b: "0 < b" and i: "\<forall>n\<ge>i. b < \<bar>X n\<bar>"
    using cauchy_not_vanishes [OF X nz] by blast
  from b i have nz: "\<forall>n\<ge>i. X n \<noteq> 0" by auto
  obtain s where s: "0 < s" and r: "r = inverse b * s * inverse b"
  proof
    show "0 < b * r * b" by (simp add: \<open>0 < r\<close> b)
    show "r = inverse b * (b * r * b) * inverse b"
      using b by simp
  qed
  obtain j where j: "\<forall>m\<ge>j. \<forall>n\<ge>j. \<bar>X m - X n\<bar> < s"
    using cauchyD [OF X s] ..
  have "\<forall>m\<ge>max i j. \<forall>n\<ge>max i j. \<bar>inverse (X m) - inverse (X n)\<bar> < r"
  proof (clarsimp)
    fix m n assume *: "i \<le> m" "j \<le> m" "i \<le> n" "j \<le> n"
    have "\<bar>inverse (X m) - inverse (X n)\<bar> =
          inverse \<bar>X m\<bar> * \<bar>X m - X n\<bar> * inverse \<bar>X n\<bar>"
      by (simp add: inverse_diff_inverse nz * abs_mult)
    also have "\<dots> < inverse b * s * inverse b"
      by (simp add: mult_strict_mono less_imp_inverse_less
                    i j b * s)
    finally show "\<bar>inverse (X m) - inverse (X n)\<bar> < r" unfolding r .
  qed
  thus "\<exists>k. \<forall>m\<ge>k. \<forall>n\<ge>k. \<bar>inverse (X m) - inverse (X n)\<bar> < r" ..
qed

lemma vanishes_diff_inverse:
  assumes X: "cauchy X" "\<not> vanishes X"
  assumes Y: "cauchy Y" "\<not> vanishes Y"
  assumes XY: "vanishes (\<lambda>n. X n - Y n)"
  shows "vanishes (\<lambda>n. inverse (X n) - inverse (Y n))"
proof (rule vanishesI)
  fix r :: rat assume r: "0 < r"
  obtain a i where a: "0 < a" and i: "\<forall>n\<ge>i. a < \<bar>X n\<bar>"
    using cauchy_not_vanishes [OF X] by blast
  obtain b j where b: "0 < b" and j: "\<forall>n\<ge>j. b < \<bar>Y n\<bar>"
    using cauchy_not_vanishes [OF Y] by blast
  obtain s where s: "0 < s" and "inverse a * s * inverse b = r"
  proof
    show "0 < a * r * b"
      using a r b by simp
    show "inverse a * (a * r * b) * inverse b = r"
      using a r b by simp
  qed
  obtain k where k: "\<forall>n\<ge>k. \<bar>X n - Y n\<bar> < s"
    using vanishesD [OF XY s] ..
  have "\<forall>n\<ge>max (max i j) k. \<bar>inverse (X n) - inverse (Y n)\<bar> < r"
  proof (clarsimp)
    fix n assume n: "i \<le> n" "j \<le> n" "k \<le> n"
    have "X n \<noteq> 0" and "Y n \<noteq> 0"
      using i j a b n by auto
    hence "\<bar>inverse (X n) - inverse (Y n)\<bar> =
        inverse \<bar>X n\<bar> * \<bar>X n - Y n\<bar> * inverse \<bar>Y n\<bar>"
      by (simp add: inverse_diff_inverse abs_mult)
    also have "\<dots> < inverse a * s * inverse b"
      apply (intro mult_strict_mono' less_imp_inverse_less)
      apply (simp_all add: a b i j k n)
      done
    also note \<open>inverse a * s * inverse b = r\<close>
    finally show "\<bar>inverse (X n) - inverse (Y n)\<bar> < r" .
  qed
  thus "\<exists>k. \<forall>n\<ge>k. \<bar>inverse (X n) - inverse (Y n)\<bar> < r" ..
qed

subsection \<open>Equivalence relation on Cauchy sequences\<close>

definition realrel :: "(nat \<Rightarrow> rat) \<Rightarrow> (nat \<Rightarrow> rat) \<Rightarrow> bool"
  where "realrel = (\<lambda>X Y. cauchy X \<and> cauchy Y \<and> vanishes (\<lambda>n. X n - Y n))"

lemma realrelI [intro?]:
  assumes "cauchy X" and "cauchy Y" and "vanishes (\<lambda>n. X n - Y n)"
  shows "realrel X Y"
  using assms unfolding realrel_def by simp

lemma realrel_refl: "cauchy X \<Longrightarrow> realrel X X"
  unfolding realrel_def by simp

lemma symp_realrel: "symp realrel"
  unfolding realrel_def
  by (rule sympI, clarify, drule vanishes_minus, simp)

lemma transp_realrel: "transp realrel"
  unfolding realrel_def
  apply (rule transpI, clarify)
  apply (drule (1) vanishes_add)
  apply (simp add: algebra_simps)
  done

lemma part_equivp_realrel: "part_equivp realrel"
  by (blast intro: part_equivpI symp_realrel transp_realrel
    realrel_refl cauchy_const)

subsection \<open>The field of real numbers\<close>

quotient_type real = "nat \<Rightarrow> rat" / partial: realrel
  morphisms rep_real Real
  by (rule part_equivp_realrel)

lemma cr_real_eq: "pcr_real = (\<lambda>x y. cauchy x \<and> Real x = y)"
  unfolding real.pcr_cr_eq cr_real_def realrel_def by auto

lemma Real_induct [induct type: real]: (* TODO: generate automatically *)
  assumes "\<And>X. cauchy X \<Longrightarrow> P (Real X)" shows "P x"
proof (induct x)
  case (1 X)
  hence "cauchy X" by (simp add: realrel_def)
  thus "P (Real X)" by (rule assms)
qed

lemma eq_Real:
  "cauchy X \<Longrightarrow> cauchy Y \<Longrightarrow> Real X = Real Y \<longleftrightarrow> vanishes (\<lambda>n. X n - Y n)"
  using real.rel_eq_transfer
  unfolding real.pcr_cr_eq cr_real_def rel_fun_def realrel_def by simp

lemma Domainp_pcr_real [transfer_domain_rule]: "Domainp pcr_real = cauchy"
by (simp add: real.domain_eq realrel_def)

instantiation real :: field
begin

lift_definition zero_real :: "real" is "\<lambda>n. 0"
  by (simp add: realrel_refl)

lift_definition one_real :: "real" is "\<lambda>n. 1"
  by (simp add: realrel_refl)

lift_definition plus_real :: "real \<Rightarrow> real \<Rightarrow> real" is "\<lambda>X Y n. X n + Y n"
  unfolding realrel_def add_diff_add
  by (simp only: cauchy_add vanishes_add simp_thms)

lift_definition uminus_real :: "real \<Rightarrow> real" is "\<lambda>X n. - X n"
  unfolding realrel_def minus_diff_minus
  by (simp only: cauchy_minus vanishes_minus simp_thms)

lift_definition times_real :: "real \<Rightarrow> real \<Rightarrow> real" is "\<lambda>X Y n. X n * Y n"
  unfolding realrel_def mult_diff_mult
  by (subst (4) mult.commute, simp only: cauchy_mult vanishes_add
    vanishes_mult_bounded cauchy_imp_bounded simp_thms)

lift_definition inverse_real :: "real \<Rightarrow> real"
  is "\<lambda>X. if vanishes X then (\<lambda>n. 0) else (\<lambda>n. inverse (X n))"
proof -
  fix X Y assume "realrel X Y"
  hence X: "cauchy X" and Y: "cauchy Y" and XY: "vanishes (\<lambda>n. X n - Y n)"
    unfolding realrel_def by simp_all
  have "vanishes X \<longleftrightarrow> vanishes Y"
  proof
    assume "vanishes X"
    from vanishes_diff [OF this XY] show "vanishes Y" by simp
  next
    assume "vanishes Y"
    from vanishes_add [OF this XY] show "vanishes X" by simp
  qed
  thus "?thesis X Y"
    unfolding realrel_def
    by (simp add: vanishes_diff_inverse X Y XY)
qed

definition
  "x - y = (x::real) + - y"

definition
  "x div y = (x::real) * inverse y"

lemma add_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X + Real Y = Real (\<lambda>n. X n + Y n)"
  using assms plus_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma minus_Real:
  assumes X: "cauchy X"
  shows "- Real X = Real (\<lambda>n. - X n)"
  using assms uminus_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma diff_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X - Real Y = Real (\<lambda>n. X n - Y n)"
  unfolding minus_real_def
  by (simp add: minus_Real add_Real X Y)

lemma mult_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X * Real Y = Real (\<lambda>n. X n * Y n)"
  using assms times_real.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma inverse_Real:
  assumes X: "cauchy X"
  shows "inverse (Real X) =
    (if vanishes X then 0 else Real (\<lambda>n. inverse (X n)))"
  using assms inverse_real.transfer zero_real.transfer
  unfolding cr_real_eq rel_fun_def by (simp split: if_split_asm, metis)

instance proof
  fix a b c :: real
  show "a + b = b + a"
    by transfer (simp add: ac_simps realrel_def)
  show "(a + b) + c = a + (b + c)"
    by transfer (simp add: ac_simps realrel_def)
  show "0 + a = a"
    by transfer (simp add: realrel_def)
  show "- a + a = 0"
    by transfer (simp add: realrel_def)
  show "a - b = a + - b"
    by (rule minus_real_def)
  show "(a * b) * c = a * (b * c)"
    by transfer (simp add: ac_simps realrel_def)
  show "a * b = b * a"
    by transfer (simp add: ac_simps realrel_def)
  show "1 * a = a"
    by transfer (simp add: ac_simps realrel_def)
  show "(a + b) * c = a * c + b * c"
    by transfer (simp add: distrib_right realrel_def)
  show "(0::real) \<noteq> (1::real)"
    by transfer (simp add: realrel_def)
  show "a \<noteq> 0 \<Longrightarrow> inverse a * a = 1"
    apply transfer
    apply (simp add: realrel_def)
    apply (rule vanishesI)
    apply (frule (1) cauchy_not_vanishes, clarify)
    apply (rule_tac x=k in exI, clarify)
    apply (drule_tac x=n in spec, simp)
    done
  show "a div b = a * inverse b"
    by (rule divide_real_def)
  show "inverse (0::real) = 0"
    by transfer (simp add: realrel_def)
qed

end

subsection \<open>Positive reals\<close>

lift_definition positive :: "real \<Rightarrow> bool"
  is "\<lambda>X. \<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n"
proof -
  { fix X Y
    assume "realrel X Y"
    hence XY: "vanishes (\<lambda>n. X n - Y n)"
      unfolding realrel_def by simp_all
    assume "\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n"
    then obtain r i where "0 < r" and i: "\<forall>n\<ge>i. r < X n"
      by blast
    obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
      using \<open>0 < r\<close> by (rule obtain_pos_sum)
    obtain j where j: "\<forall>n\<ge>j. \<bar>X n - Y n\<bar> < s"
      using vanishesD [OF XY s] ..
    have "\<forall>n\<ge>max i j. t < Y n"
    proof (clarsimp)
      fix n assume n: "i \<le> n" "j \<le> n"
      have "\<bar>X n - Y n\<bar> < s" and "r < X n"
        using i j n by simp_all
      thus "t < Y n" unfolding r by simp
    qed
    hence "\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < Y n" using t by blast
  } note 1 = this
  fix X Y assume "realrel X Y"
  hence "realrel X Y" and "realrel Y X"
    using symp_realrel unfolding symp_def by auto
  thus "?thesis X Y"
    by (safe elim!: 1)
qed

lemma positive_Real:
  assumes X: "cauchy X"
  shows "positive (Real X) \<longleftrightarrow> (\<exists>r>0. \<exists>k. \<forall>n\<ge>k. r < X n)"
  using assms positive.transfer
  unfolding cr_real_eq rel_fun_def by simp

lemma positive_zero: "\<not> positive 0"
  by transfer auto

lemma positive_add:
  "positive x \<Longrightarrow> positive y \<Longrightarrow> positive (x + y)"
apply transfer
apply (clarify, rename_tac a b i j)
apply (rule_tac x="a + b" in exI, simp)
apply (rule_tac x="max i j" in exI, clarsimp)
apply (simp add: add_strict_mono)
done

lemma positive_mult:
  "positive x \<Longrightarrow> positive y \<Longrightarrow> positive (x * y)"
apply transfer
apply (clarify, rename_tac a b i j)
apply (rule_tac x="a * b" in exI, simp)
apply (rule_tac x="max i j" in exI, clarsimp)
apply (rule mult_strict_mono, auto)
done

lemma positive_minus:
  "\<not> positive x \<Longrightarrow> x \<noteq> 0 \<Longrightarrow> positive (- x)"
apply transfer
apply (simp add: realrel_def)
apply (drule (1) cauchy_not_vanishes_cases, safe)
apply blast+
done

instantiation real :: linordered_field
begin

definition
  "x < y \<longleftrightarrow> positive (y - x)"

definition
  "x \<le> (y::real) \<longleftrightarrow> x < y \<or> x = y"

definition
  "\<bar>a::real\<bar> = (if a < 0 then - a else a)"

definition
  "sgn (a::real) = (if a = 0 then 0 else if 0 < a then 1 else - 1)"

instance proof
  fix a b c :: real
  show "\<bar>a\<bar> = (if a < 0 then - a else a)"
    by (rule abs_real_def)
  show "a < b \<longleftrightarrow> a \<le> b \<and> \<not> b \<le> a"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp_all add: positive_zero)
  show "a \<le> a"
    unfolding less_eq_real_def by simp
  show "a \<le> b \<Longrightarrow> b \<le> c \<Longrightarrow> a \<le> c"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp add: algebra_simps)
  show "a \<le> b \<Longrightarrow> b \<le> a \<Longrightarrow> a = b"
    unfolding less_eq_real_def less_real_def
    by (auto, drule (1) positive_add, simp add: positive_zero)
  show "a \<le> b \<Longrightarrow> c + a \<le> c + b"
    unfolding less_eq_real_def less_real_def by auto
    (* FIXME: Procedure int_combine_numerals: c + b - (c + a) \<equiv> b + - a *)
    (* Should produce c + b - (c + a) \<equiv> b - a *)
  show "sgn a = (if a = 0 then 0 else if 0 < a then 1 else - 1)"
    by (rule sgn_real_def)
  show "a \<le> b \<or> b \<le> a"
    unfolding less_eq_real_def less_real_def
    by (auto dest!: positive_minus)
  show "a < b \<Longrightarrow> 0 < c \<Longrightarrow> c * a < c * b"
    unfolding less_real_def
    by (drule (1) positive_mult, simp add: algebra_simps)
qed

end

instantiation real :: distrib_lattice
begin

definition
  "(inf :: real \<Rightarrow> real \<Rightarrow> real) = min"

definition
  "(sup :: real \<Rightarrow> real \<Rightarrow> real) = max"

instance proof
qed (auto simp add: inf_real_def sup_real_def max_min_distrib2)

end

lemma of_nat_Real: "of_nat x = Real (\<lambda>n. of_nat x)"
apply (induct x)
apply (simp add: zero_real_def)
apply (simp add: one_real_def add_Real)
done

lemma of_int_Real: "of_int x = Real (\<lambda>n. of_int x)"
apply (cases x rule: int_diff_cases)
apply (simp add: of_nat_Real diff_Real)
done

lemma of_rat_Real: "of_rat x = Real (\<lambda>n. x)"
apply (induct x)
apply (simp add: Fract_of_int_quotient of_rat_divide)
apply (simp add: of_int_Real divide_inverse)
apply (simp add: inverse_Real mult_Real)
done

instance real :: archimedean_field
proof
  fix x :: real
  show "\<exists>z. x \<le> of_int z"
    apply (induct x)
    apply (frule cauchy_imp_bounded, clarify)
    apply (rule_tac x="\<lceil>b\<rceil> + 1" in exI)
    apply (rule less_imp_le)
    apply (simp add: of_int_Real less_real_def diff_Real positive_Real)
    apply (rule_tac x=1 in exI, simp add: algebra_simps)
    apply (rule_tac x=0 in exI, clarsimp)
    apply (rule le_less_trans [OF abs_ge_self])
    apply (rule less_le_trans [OF _ le_of_int_ceiling])
    apply simp
    done
qed

instantiation real :: floor_ceiling
begin

definition [code del]:
  "\<lfloor>x::real\<rfloor> = (THE z. of_int z \<le> x \<and> x < of_int (z + 1))"

instance
proof
  fix x :: real
  show "of_int \<lfloor>x\<rfloor> \<le> x \<and> x < of_int (\<lfloor>x\<rfloor> + 1)"
    unfolding floor_real_def using floor_exists1 by (rule theI')
qed

end

subsection \<open>Completeness\<close>

lemma not_positive_Real:
  assumes X: "cauchy X"
  shows "\<not> positive (Real X) \<longleftrightarrow> (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. X n \<le> r)"
unfolding positive_Real [OF X]
apply (auto, unfold not_less)
apply (erule obtain_pos_sum)
apply (drule_tac x=s in spec, simp)
apply (drule_tac r=t in cauchyD [OF X], clarify)
apply (drule_tac x=k in spec, clarsimp)
apply (rule_tac x=n in exI, clarify, rename_tac m)
apply (drule_tac x=m in spec, simp)
apply (drule_tac x=n in spec, simp)
apply (drule spec, drule (1) mp, clarify, rename_tac i)
apply (rule_tac x="max i k" in exI, simp)
done

lemma le_Real:
  assumes X: "cauchy X" and Y: "cauchy Y"
  shows "Real X \<le> Real Y = (\<forall>r>0. \<exists>k. \<forall>n\<ge>k. X n \<le> Y n + r)"
unfolding not_less [symmetric, where 'a=real] less_real_def
apply (simp add: diff_Real not_positive_Real X Y)
apply (simp add: diff_le_eq ac_simps)
done

lemma le_RealI:
  assumes Y: "cauchy Y"
  shows "\<forall>n. x \<le> of_rat (Y n) \<Longrightarrow> x \<le> Real Y"
proof (induct x)
  fix X assume X: "cauchy X" and "\<forall>n. Real X \<le> of_rat (Y n)"
  hence le: "\<And>m r. 0 < r \<Longrightarrow> \<exists>k. \<forall>n\<ge>k. X n \<le> Y m + r"
    by (simp add: of_rat_Real le_Real)
  {
    fix r :: rat assume "0 < r"
    then obtain s t where s: "0 < s" and t: "0 < t" and r: "r = s + t"
      by (rule obtain_pos_sum)
    obtain i where i: "\<forall>m\<ge>i. \<forall>n\<ge>i. \<bar>Y m - Y n\<bar> < s"
      using cauchyD [OF Y s] ..
    obtain j where j: "\<forall>n\<ge>j. X n \<le> Y i + t"
      using le [OF t] ..
    have "\<forall>n\<ge>max i j. X n \<le> Y n + r"
    proof (clarsimp)
      fix n assume n: "i \<le> n" "j \<le> n"
      have "X n \<le> Y i + t" using n j by simp
      moreover have "\<bar>Y i - Y n\<bar> < s" using n i by simp
      ultimately show "X n \<le> Y n + r" unfolding r by simp
    qed
    hence "\<exists>k. \<forall>n\<ge>k. X n \<le> Y n + r" ..
  }
  thus "Real X \<le> Real Y"
    by (simp add: of_rat_Real le_Real X Y)
qed

lemma Real_leI:
  assumes X: "cauchy X"
  assumes le: "\<forall>n. of_rat (X n) \<le> y"
  shows "Real X \<le> y"
proof -
  have "- y \<le> - Real X"
    by (simp add: minus_Real X le_RealI of_rat_minus le)
  thus ?thesis by simp
qed

lemma less_RealD:
  assumes Y: "cauchy Y"
  shows "x < Real Y \<Longrightarrow> \<exists>n. x < of_rat (Y n)"
by (erule contrapos_pp, simp add: not_less, erule Real_leI [OF Y])

lemma of_nat_less_two_power [simp]:
  "of_nat n < (2::'a::linordered_idom) ^ n"
apply (induct n, simp)
by (metis add_le_less_mono mult_2 of_nat_Suc one_le_numeral one_le_power power_Suc)

lemma complete_real:
  fixes S :: "real set"
  assumes "\<exists>x. x \<in> S" and "\<exists>z. \<forall>x\<in>S. x \<le> z"
  shows "\<exists>y. (\<forall>x\<in>S. x \<le> y) \<and> (\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> y \<le> z)"
proof -
  obtain x where x: "x \<in> S" using assms(1) ..
  obtain z where z: "\<forall>x\<in>S. x \<le> z" using assms(2) ..

  def P \<equiv> "\<lambda>x. \<forall>y\<in>S. y \<le> of_rat x"
  obtain a where a: "\<not> P a"
  proof
    have "of_int \<lfloor>x - 1\<rfloor> \<le> x - 1" by (rule of_int_floor_le)
    also have "x - 1 < x" by simp
    finally have "of_int \<lfloor>x - 1\<rfloor> < x" .
    hence "\<not> x \<le> of_int \<lfloor>x - 1\<rfloor>" by (simp only: not_le)
    then show "\<not> P (of_int \<lfloor>x - 1\<rfloor>)"
      unfolding P_def of_rat_of_int_eq using x by blast
  qed
  obtain b where b: "P b"
  proof
    show "P (of_int \<lceil>z\<rceil>)"
    unfolding P_def of_rat_of_int_eq
    proof
      fix y assume "y \<in> S"
      hence "y \<le> z" using z by simp
      also have "z \<le> of_int \<lceil>z\<rceil>" by (rule le_of_int_ceiling)
      finally show "y \<le> of_int \<lceil>z\<rceil>" .
    qed
  qed

  def avg \<equiv> "\<lambda>x y :: rat. x/2 + y/2"
  def bisect \<equiv> "\<lambda>(x, y). if P (avg x y) then (x, avg x y) else (avg x y, y)"
  def A \<equiv> "\<lambda>n. fst ((bisect ^^ n) (a, b))"
  def B \<equiv> "\<lambda>n. snd ((bisect ^^ n) (a, b))"
  def C \<equiv> "\<lambda>n. avg (A n) (B n)"
  have A_0 [simp]: "A 0 = a" unfolding A_def by simp
  have B_0 [simp]: "B 0 = b" unfolding B_def by simp
  have A_Suc [simp]: "\<And>n. A (Suc n) = (if P (C n) then A n else C n)"
    unfolding A_def B_def C_def bisect_def split_def by simp
  have B_Suc [simp]: "\<And>n. B (Suc n) = (if P (C n) then C n else B n)"
    unfolding A_def B_def C_def bisect_def split_def by simp

  have width: "\<And>n. B n - A n = (b - a) / 2^n"
    apply (simp add: eq_divide_eq)
    apply (induct_tac n, simp)
    apply (simp add: C_def avg_def algebra_simps)
    done

  have twos: "\<And>y r :: rat. 0 < r \<Longrightarrow> \<exists>n. y / 2 ^ n < r"
    apply (simp add: divide_less_eq)
    apply (subst mult.commute)
    apply (frule_tac y=y in ex_less_of_nat_mult)
    apply clarify
    apply (rule_tac x=n in exI)
    apply (erule less_trans)
    apply (rule mult_strict_right_mono)
    apply (rule le_less_trans [OF _ of_nat_less_two_power])
    apply simp
    apply assumption
    done

  have PA: "\<And>n. \<not> P (A n)"
    by (induct_tac n, simp_all add: a)
  have PB: "\<And>n. P (B n)"
    by (induct_tac n, simp_all add: b)
  have ab: "a < b"
    using a b unfolding P_def
    apply (clarsimp simp add: not_le)
    apply (drule (1) bspec)
    apply (drule (1) less_le_trans)
    apply (simp add: of_rat_less)
    done
  have AB: "\<And>n. A n < B n"
    by (induct_tac n, simp add: ab, simp add: C_def avg_def)
  have A_mono: "\<And>i j. i \<le> j \<Longrightarrow> A i \<le> A j"
    apply (auto simp add: le_less [where 'a=nat])
    apply (erule less_Suc_induct)
    apply (clarsimp simp add: C_def avg_def)
    apply (simp add: add_divide_distrib [symmetric])
    apply (rule AB [THEN less_imp_le])
    apply simp
    done
  have B_mono: "\<And>i j. i \<le> j \<Longrightarrow> B j \<le> B i"
    apply (auto simp add: le_less [where 'a=nat])
    apply (erule less_Suc_induct)
    apply (clarsimp simp add: C_def avg_def)
    apply (simp add: add_divide_distrib [symmetric])
    apply (rule AB [THEN less_imp_le])
    apply simp
    done
  have cauchy_lemma:
    "\<And>X. \<forall>n. \<forall>i\<ge>n. A n \<le> X i \<and> X i \<le> B n \<Longrightarrow> cauchy X"
    apply (rule cauchyI)
    apply (drule twos [where y="b - a"])
    apply (erule exE)
    apply (rule_tac x=n in exI, clarify, rename_tac i j)
    apply (rule_tac y="B n - A n" in le_less_trans) defer
    apply (simp add: width)
    apply (drule_tac x=n in spec)
    apply (frule_tac x=i in spec, drule (1) mp)
    apply (frule_tac x=j in spec, drule (1) mp)
    apply (frule A_mono, drule B_mono)
    apply (frule A_mono, drule B_mono)
    apply arith
    done
  have "cauchy A"
    apply (rule cauchy_lemma [rule_format])
    apply (simp add: A_mono)
    apply (erule order_trans [OF less_imp_le [OF AB] B_mono])
    done
  have "cauchy B"
    apply (rule cauchy_lemma [rule_format])
    apply (simp add: B_mono)
    apply (erule order_trans [OF A_mono less_imp_le [OF AB]])
    done
  have 1: "\<forall>x\<in>S. x \<le> Real B"
  proof
    fix x assume "x \<in> S"
    then show "x \<le> Real B"
      using PB [unfolded P_def] \<open>cauchy B\<close>
      by (simp add: le_RealI)
  qed
  have 2: "\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> Real A \<le> z"
    apply clarify
    apply (erule contrapos_pp)
    apply (simp add: not_le)
    apply (drule less_RealD [OF \<open>cauchy A\<close>], clarify)
    apply (subgoal_tac "\<not> P (A n)")
    apply (simp add: P_def not_le, clarify)
    apply (erule rev_bexI)
    apply (erule (1) less_trans)
    apply (simp add: PA)
    done
  have "vanishes (\<lambda>n. (b - a) / 2 ^ n)"
  proof (rule vanishesI)
    fix r :: rat assume "0 < r"
    then obtain k where k: "\<bar>b - a\<bar> / 2 ^ k < r"
      using twos by blast
    have "\<forall>n\<ge>k. \<bar>(b - a) / 2 ^ n\<bar> < r"
    proof (clarify)
      fix n assume n: "k \<le> n"
      have "\<bar>(b - a) / 2 ^ n\<bar> = \<bar>b - a\<bar> / 2 ^ n"
        by simp
      also have "\<dots> \<le> \<bar>b - a\<bar> / 2 ^ k"
        using n by (simp add: divide_left_mono)
      also note k
      finally show "\<bar>(b - a) / 2 ^ n\<bar> < r" .
    qed
    thus "\<exists>k. \<forall>n\<ge>k. \<bar>(b - a) / 2 ^ n\<bar> < r" ..
  qed
  hence 3: "Real B = Real A"
    by (simp add: eq_Real \<open>cauchy A\<close> \<open>cauchy B\<close> width)
  show "\<exists>y. (\<forall>x\<in>S. x \<le> y) \<and> (\<forall>z. (\<forall>x\<in>S. x \<le> z) \<longrightarrow> y \<le> z)"
    using 1 2 3 by (rule_tac x="Real B" in exI, simp)
qed

instantiation real :: linear_continuum
begin

subsection\<open>Supremum of a set of reals\<close>

definition "Sup X = (LEAST z::real. \<forall>x\<in>X. x \<le> z)"
definition "Inf (X::real set) = - Sup (uminus ` X)"

instance
proof
  { fix x :: real and X :: "real set"
    assume x: "x \<in> X" "bdd_above X"
    then obtain s where s: "\<forall>y\<in>X. y \<le> s" "\<And>z. \<forall>y\<in>X. y \<le> z \<Longrightarrow> s \<le> z"
      using complete_real[of X] unfolding bdd_above_def by blast
    then show "x \<le> Sup X"
      unfolding Sup_real_def by (rule LeastI2_order) (auto simp: x) }
  note Sup_upper = this

  { fix z :: real and X :: "real set"
    assume x: "X \<noteq> {}" and z: "\<And>x. x \<in> X \<Longrightarrow> x \<le> z"
    then obtain s where s: "\<forall>y\<in>X. y \<le> s" "\<And>z. \<forall>y\<in>X. y \<le> z \<Longrightarrow> s \<le> z"
      using complete_real[of X] by blast
    then have "Sup X = s"
      unfolding Sup_real_def by (best intro: Least_equality)
    also from s z have "... \<le> z"
      by blast
    finally show "Sup X \<le> z" . }
  note Sup_least = this

  { fix x :: real and X :: "real set" assume x: "x \<in> X" "bdd_below X" then show "Inf X \<le> x"
      using Sup_upper[of "-x" "uminus ` X"] by (auto simp: Inf_real_def) }
  { fix z :: real and X :: "real set" assume "X \<noteq> {}" "\<And>x. x \<in> X \<Longrightarrow> z \<le> x" then show "z \<le> Inf X"
      using Sup_least[of "uminus ` X" "- z"] by (force simp: Inf_real_def) }
  show "\<exists>a b::real. a \<noteq> b"
    using zero_neq_one by blast
qed
end


subsection \<open>Hiding implementation details\<close>

hide_const (open) vanishes cauchy positive Real

declare Real_induct [induct del]
declare Abs_real_induct [induct del]
declare Abs_real_cases [cases del]

lifting_update real.lifting
lifting_forget real.lifting

subsection\<open>More Lemmas\<close>

text \<open>BH: These lemmas should not be necessary; they should be
covered by existing simp rules and simplification procedures.\<close>

lemma real_mult_less_iff1 [simp]: "(0::real) < z ==> (x*z < y*z) = (x < y)"
by simp (* solved by linordered_ring_less_cancel_factor simproc *)

lemma real_mult_le_cancel_iff1 [simp]: "(0::real) < z ==> (x*z \<le> y*z) = (x\<le>y)"
by simp (* solved by linordered_ring_le_cancel_factor simproc *)

lemma real_mult_le_cancel_iff2 [simp]: "(0::real) < z ==> (z*x \<le> z*y) = (x\<le>y)"
by simp (* solved by linordered_ring_le_cancel_factor simproc *)


subsection \<open>Embedding numbers into the Reals\<close>

abbreviation
  real_of_nat :: "nat \<Rightarrow> real"
where
  "real_of_nat \<equiv> of_nat"

abbreviation
  real :: "nat \<Rightarrow> real"
where
  "real \<equiv> of_nat"

abbreviation
  real_of_int :: "int \<Rightarrow> real"
where
  "real_of_int \<equiv> of_int"

abbreviation
  real_of_rat :: "rat \<Rightarrow> real"
where
  "real_of_rat \<equiv> of_rat"

declare [[coercion_enabled]]

declare [[coercion "of_nat :: nat \<Rightarrow> int"]]
declare [[coercion "of_nat :: nat \<Rightarrow> real"]]
declare [[coercion "of_int :: int \<Rightarrow> real"]]

(* We do not add rat to the coerced types, this has often unpleasant side effects when writing
inverse (Suc n) which sometimes gets two coercions: of_rat (inverse (of_nat (Suc n))) *)

declare [[coercion_map map]]
declare [[coercion_map "\<lambda>f g h x. g (h (f x))"]]
declare [[coercion_map "\<lambda>f g (x,y). (f x, g y)"]]

declare of_int_eq_0_iff [algebra, presburger]
declare of_int_eq_1_iff [algebra, presburger]
declare of_int_eq_iff [algebra, presburger]
declare of_int_less_0_iff [algebra, presburger]
declare of_int_less_1_iff [algebra, presburger]
declare of_int_less_iff [algebra, presburger]
declare of_int_le_0_iff [algebra, presburger]
declare of_int_le_1_iff [algebra, presburger]
declare of_int_le_iff [algebra, presburger]
declare of_int_0_less_iff [algebra, presburger]
declare of_int_0_le_iff [algebra, presburger]
declare of_int_1_less_iff [algebra, presburger]
declare of_int_1_le_iff [algebra, presburger]

lemma int_less_real_le: "(n < m) = (real_of_int n + 1 <= real_of_int m)"
proof -
  have "(0::real) \<le> 1"
    by (metis less_eq_real_def zero_less_one)
  thus ?thesis
    by (metis floor_of_int less_floor_iff)
qed

lemma int_le_real_less: "(n \<le> m) = (real_of_int n < real_of_int m + 1)"
  by (meson int_less_real_le not_le)


lemma real_of_int_div_aux: "(real_of_int x) / (real_of_int d) =
    real_of_int (x div d) + (real_of_int (x mod d)) / (real_of_int d)"
proof -
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real_of_int x = real_of_int (x div d) * real_of_int d + real_of_int(x mod d)"
    by (metis of_int_add of_int_mult)
  then have "real_of_int x / real_of_int d = ... / real_of_int d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib algebra_simps)
qed

lemma real_of_int_div:
  fixes d n :: int
  shows "d dvd n \<Longrightarrow> real_of_int (n div d) = real_of_int n / real_of_int d"
  by (simp add: real_of_int_div_aux)

lemma real_of_int_div2:
  "0 <= real_of_int n / real_of_int x - real_of_int (n div x)"
  apply (case_tac "x = 0", simp)
  apply (case_tac "0 < x")
   apply (metis add.left_neutral floor_correct floor_divide_of_int_eq le_diff_eq)
  apply (metis add.left_neutral floor_correct floor_divide_of_int_eq le_diff_eq)
  done

lemma real_of_int_div3:
  "real_of_int (n::int) / real_of_int (x) - real_of_int (n div x) <= 1"
  apply (simp add: algebra_simps)
  apply (subst real_of_int_div_aux)
  apply (auto simp add: divide_le_eq intro: order_less_imp_le)
done

lemma real_of_int_div4: "real_of_int (n div x) <= real_of_int (n::int) / real_of_int x"
by (insert real_of_int_div2 [of n x], simp)


subsection\<open>Embedding the Naturals into the Reals\<close>

lemma real_of_card: "real (card A) = setsum (\<lambda>x.1) A"
  by simp

lemma nat_less_real_le: "(n < m) = (real n + 1 \<le> real m)"
  by (metis discrete of_nat_1 of_nat_add of_nat_le_iff)

lemma nat_le_real_less: "((n::nat) <= m) = (real n < real m + 1)"
  by (meson nat_less_real_le not_le)

lemma real_of_nat_div_aux: "(real x) / (real d) =
    real (x div d) + (real (x mod d)) / (real d)"
proof -
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real x = real (x div d) * real d + real(x mod d)"
    by (metis of_nat_add of_nat_mult)
  then have "real x / real d = \<dots> / real d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib algebra_simps)
qed

lemma real_of_nat_div: "d dvd n \<Longrightarrow> real(n div d) = real n / real d"
  by (subst real_of_nat_div_aux)
    (auto simp add: dvd_eq_mod_eq_0 [symmetric])

lemma real_of_nat_div2:
  "0 <= real (n::nat) / real (x) - real (n div x)"
apply (simp add: algebra_simps)
apply (subst real_of_nat_div_aux)
apply simp
done

lemma real_of_nat_div3:
  "real (n::nat) / real (x) - real (n div x) <= 1"
apply(case_tac "x = 0")
apply (simp)
apply (simp add: algebra_simps)
apply (subst real_of_nat_div_aux)
apply simp
done

lemma real_of_nat_div4: "real (n div x) <= real (n::nat) / real x"
by (insert real_of_nat_div2 [of n x], simp)

subsection \<open>The Archimedean Property of the Reals\<close>

lemmas reals_Archimedean = ex_inverse_of_nat_Suc_less  (*FIXME*)
lemmas reals_Archimedean2 = ex_less_of_nat

lemma reals_Archimedean3:
  assumes x_greater_zero: "0 < x"
  shows "\<forall>y. \<exists>n. y < real n * x"
  using \<open>0 < x\<close> by (auto intro: ex_less_of_nat_mult)

lemma real_archimedian_rdiv_eq_0:
  assumes x0: "x \<ge> 0"
      and c: "c \<ge> 0"
      and xc: "\<And>m::nat. m > 0 \<Longrightarrow> real m * x \<le> c"
    shows "x = 0"
by (metis reals_Archimedean3 dual_order.order_iff_strict le0 le_less_trans not_le x0 xc)


subsection\<open>Rationals\<close>

lemma Rats_eq_int_div_int:
  "\<rat> = { real_of_int i / real_of_int j |i j. j \<noteq> 0}" (is "_ = ?S")
proof
  show "\<rat> \<subseteq> ?S"
  proof
    fix x::real assume "x : \<rat>"
    then obtain r where "x = of_rat r" unfolding Rats_def ..
    have "of_rat r : ?S"
      by (cases r) (auto simp add:of_rat_rat)
    thus "x : ?S" using \<open>x = of_rat r\<close> by simp
  qed
next
  show "?S \<subseteq> \<rat>"
  proof(auto simp:Rats_def)
    fix i j :: int assume "j \<noteq> 0"
    hence "real_of_int i / real_of_int j = of_rat(Fract i j)"
      by (simp add: of_rat_rat)
    thus "real_of_int i / real_of_int j \<in> range of_rat" by blast
  qed
qed

lemma Rats_eq_int_div_nat:
  "\<rat> = { real_of_int i / real n |i n. n \<noteq> 0}"
proof(auto simp:Rats_eq_int_div_int)
  fix i j::int assume "j \<noteq> 0"
  show "EX (i'::int) (n::nat). real_of_int i / real_of_int j = real_of_int i'/real n \<and> 0<n"
  proof cases
    assume "j>0"
    hence "real_of_int i / real_of_int j = real_of_int i/real(nat j) \<and> 0<nat j"
      by (simp add: of_nat_nat)
    thus ?thesis by blast
  next
    assume "~ j>0"
    hence "real_of_int i / real_of_int j = real_of_int(-i) / real(nat(-j)) \<and> 0<nat(-j)" using \<open>j\<noteq>0\<close>
      by (simp add: of_nat_nat)
    thus ?thesis by blast
  qed
next
  fix i::int and n::nat assume "0 < n"
  hence "real_of_int i / real n = real_of_int i / real_of_int(int n) \<and> int n \<noteq> 0" by simp
  thus "\<exists>i' j. real_of_int i / real n = real_of_int i' / real_of_int j \<and> j \<noteq> 0" by blast
qed

lemma Rats_abs_nat_div_natE:
  assumes "x \<in> \<rat>"
  obtains m n :: nat
  where "n \<noteq> 0" and "\<bar>x\<bar> = real m / real n" and "gcd m n = 1"
proof -
  from \<open>x \<in> \<rat>\<close> obtain i::int and n::nat where "n \<noteq> 0" and "x = real_of_int i / real n"
    by(auto simp add: Rats_eq_int_div_nat)
  hence "\<bar>x\<bar> = real (nat \<bar>i\<bar>) / real n" by (simp add: of_nat_nat)
  then obtain m :: nat where x_rat: "\<bar>x\<bar> = real m / real n" by blast
  let ?gcd = "gcd m n"
  from \<open>n\<noteq>0\<close> have gcd: "?gcd \<noteq> 0" by simp
  let ?k = "m div ?gcd"
  let ?l = "n div ?gcd"
  let ?gcd' = "gcd ?k ?l"
  have "?gcd dvd m" .. then have gcd_k: "?gcd * ?k = m"
    by (rule dvd_mult_div_cancel)
  have "?gcd dvd n" .. then have gcd_l: "?gcd * ?l = n"
    by (rule dvd_mult_div_cancel)
  from \<open>n \<noteq> 0\<close> and gcd_l
  have "?gcd * ?l \<noteq> 0" by simp
  then have "?l \<noteq> 0" by (blast dest!: mult_not_zero)
  moreover
  have "\<bar>x\<bar> = real ?k / real ?l"
  proof -
    from gcd have "real ?k / real ?l = real (?gcd * ?k) / real (?gcd * ?l)"
      by (simp add: real_of_nat_div)
    also from gcd_k and gcd_l have "\<dots> = real m / real n" by simp
    also from x_rat have "\<dots> = \<bar>x\<bar>" ..
    finally show ?thesis ..
  qed
  moreover
  have "?gcd' = 1"
  proof -
    have "?gcd * ?gcd' = gcd (?gcd * ?k) (?gcd * ?l)"
      by (rule gcd_mult_distrib_nat)
    with gcd_k gcd_l have "?gcd * ?gcd' = ?gcd" by simp
    with gcd show ?thesis by auto
  qed
  ultimately show ?thesis ..
qed

subsection\<open>Density of the Rational Reals in the Reals\<close>

text\<open>This density proof is due to Stefan Richter and was ported by TN.  The
original source is \emph{Real Analysis} by H.L. Royden.
It employs the Archimedean property of the reals.\<close>

lemma Rats_dense_in_real:
  fixes x :: real
  assumes "x < y" shows "\<exists>r\<in>\<rat>. x < r \<and> r < y"
proof -
  from \<open>x<y\<close> have "0 < y-x" by simp
  with reals_Archimedean obtain q::nat
    where q: "inverse (real q) < y-x" and "0 < q" by blast
  def p \<equiv> "\<lceil>y * real q\<rceil> - 1"
  def r \<equiv> "of_int p / real q"
  from q have "x < y - inverse (real q)" by simp
  also have "y - inverse (real q) \<le> r"
    unfolding r_def p_def
    by (simp add: le_divide_eq left_diff_distrib le_of_int_ceiling \<open>0 < q\<close>)
  finally have "x < r" .
  moreover have "r < y"
    unfolding r_def p_def
    by (simp add: divide_less_eq diff_less_eq \<open>0 < q\<close>
      less_ceiling_iff [symmetric])
  moreover from r_def have "r \<in> \<rat>" by simp
  ultimately show ?thesis by blast
qed

lemma of_rat_dense:
  fixes x y :: real
  assumes "x < y"
  shows "\<exists>q :: rat. x < of_rat q \<and> of_rat q < y"
using Rats_dense_in_real [OF \<open>x < y\<close>]
by (auto elim: Rats_cases)


subsection\<open>Numerals and Arithmetic\<close>

lemma [code_abbrev]:   (*FIXME*)
  "real_of_int (numeral k) = numeral k"
  "real_of_int (- numeral k) = - numeral k"
  by simp_all

declaration \<open>
  K (Lin_Arith.add_inj_thms [@{thm of_nat_le_iff} RS iffD2, @{thm of_nat_eq_iff} RS iffD2]
    (* not needed because x < (y::nat) can be rewritten as Suc x <= y: of_nat_less_iff RS iffD2 *)
  #> Lin_Arith.add_inj_thms [@{thm of_int_le_iff} RS iffD2, @{thm of_nat_eq_iff} RS iffD2]
    (* not needed because x < (y::int) can be rewritten as x + 1 <= y: of_int_less_iff RS iffD2 *)
  #> Lin_Arith.add_simps [@{thm of_nat_0}, @{thm of_nat_Suc}, @{thm of_nat_add},
      @{thm of_nat_mult}, @{thm of_int_0}, @{thm of_int_1},
      @{thm of_int_add}, @{thm of_int_minus}, @{thm of_int_diff},
      @{thm of_int_mult}, @{thm of_int_of_nat_eq},
      @{thm of_nat_numeral}, @{thm of_nat_numeral}, @{thm of_int_neg_numeral}]
  #> Lin_Arith.add_inj_const (@{const_name of_nat}, @{typ "nat \<Rightarrow> real"})
  #> Lin_Arith.add_inj_const (@{const_name of_int}, @{typ "int \<Rightarrow> real"}))
\<close>

subsection\<open>Simprules combining x+y and 0: ARE THEY NEEDED?\<close>

lemma real_add_minus_iff [simp]: "(x + - a = (0::real)) = (x=a)"
by arith

lemma real_add_less_0_iff: "(x+y < (0::real)) = (y < -x)"
by auto

lemma real_0_less_add_iff: "((0::real) < x+y) = (-x < y)"
by auto

lemma real_add_le_0_iff: "(x+y \<le> (0::real)) = (y \<le> -x)"
by auto

lemma real_0_le_add_iff: "((0::real) \<le> x+y) = (-x \<le> y)"
by auto

subsection \<open>Lemmas about powers\<close>

lemma two_realpow_ge_one: "(1::real) \<le> 2 ^ n"
  by simp

text \<open>FIXME: declare this [simp] for all types, or not at all\<close>
declare sum_squares_eq_zero_iff [simp] sum_power2_eq_zero_iff [simp]

lemma real_minus_mult_self_le [simp]: "-(u * u) \<le> (x * (x::real))"
by (rule_tac y = 0 in order_trans, auto)

lemma realpow_square_minus_le [simp]: "- u\<^sup>2 \<le> (x::real)\<^sup>2"
  by (auto simp add: power2_eq_square)

lemma numeral_power_eq_real_of_int_cancel_iff[simp]:
     "numeral x ^ n = real_of_int (y::int) \<longleftrightarrow> numeral x ^ n = y"
  by (metis of_int_eq_iff of_int_numeral of_int_power)

lemma real_of_int_eq_numeral_power_cancel_iff[simp]:
     "real_of_int (y::int) = numeral x ^ n \<longleftrightarrow> y = numeral x ^ n"
  using numeral_power_eq_real_of_int_cancel_iff[of x n y]
  by metis

lemma numeral_power_eq_real_of_nat_cancel_iff[simp]:
     "numeral x ^ n = real (y::nat) \<longleftrightarrow> numeral x ^ n = y"
  using of_nat_eq_iff by fastforce

lemma real_of_nat_eq_numeral_power_cancel_iff[simp]:
  "real (y::nat) = numeral x ^ n \<longleftrightarrow> y = numeral x ^ n"
  using numeral_power_eq_real_of_nat_cancel_iff[of x n y]
  by metis

lemma numeral_power_le_real_of_nat_cancel_iff[simp]:
  "(numeral x::real) ^ n \<le> real a \<longleftrightarrow> (numeral x::nat) ^ n \<le> a"
by (metis of_nat_le_iff of_nat_numeral of_nat_power)

lemma real_of_nat_le_numeral_power_cancel_iff[simp]:
  "real a \<le> (numeral x::real) ^ n \<longleftrightarrow> a \<le> (numeral x::nat) ^ n"
by (metis of_nat_le_iff of_nat_numeral of_nat_power)

lemma numeral_power_le_real_of_int_cancel_iff[simp]:
    "(numeral x::real) ^ n \<le> real_of_int a \<longleftrightarrow> (numeral x::int) ^ n \<le> a"
  by (metis ceiling_le_iff ceiling_of_int of_int_numeral of_int_power)

lemma real_of_int_le_numeral_power_cancel_iff[simp]:
    "real_of_int a \<le> (numeral x::real) ^ n \<longleftrightarrow> a \<le> (numeral x::int) ^ n"
  by (metis floor_of_int le_floor_iff of_int_numeral of_int_power)

lemma numeral_power_less_real_of_nat_cancel_iff[simp]:
    "(numeral x::real) ^ n < real a \<longleftrightarrow> (numeral x::nat) ^ n < a"
  by (metis of_nat_less_iff of_nat_numeral of_nat_power)

lemma real_of_nat_less_numeral_power_cancel_iff[simp]:
  "real a < (numeral x::real) ^ n \<longleftrightarrow> a < (numeral x::nat) ^ n"
by (metis of_nat_less_iff of_nat_numeral of_nat_power)

lemma numeral_power_less_real_of_int_cancel_iff[simp]:
    "(numeral x::real) ^ n < real_of_int a \<longleftrightarrow> (numeral x::int) ^ n < a"
  by (meson not_less real_of_int_le_numeral_power_cancel_iff)

lemma real_of_int_less_numeral_power_cancel_iff[simp]:
     "real_of_int a < (numeral x::real) ^ n \<longleftrightarrow> a < (numeral x::int) ^ n"
  by (meson not_less numeral_power_le_real_of_int_cancel_iff)

lemma neg_numeral_power_le_real_of_int_cancel_iff[simp]:
    "(- numeral x::real) ^ n \<le> real_of_int a \<longleftrightarrow> (- numeral x::int) ^ n \<le> a"
  by (metis of_int_le_iff of_int_neg_numeral of_int_power)

lemma real_of_int_le_neg_numeral_power_cancel_iff[simp]:
     "real_of_int a \<le> (- numeral x::real) ^ n \<longleftrightarrow> a \<le> (- numeral x::int) ^ n"
  by (metis of_int_le_iff of_int_neg_numeral of_int_power)


subsection\<open>Density of the Reals\<close>

lemma real_lbound_gt_zero:
     "[| (0::real) < d1; 0 < d2 |] ==> \<exists>e. 0 < e & e < d1 & e < d2"
apply (rule_tac x = " (min d1 d2) /2" in exI)
apply (simp add: min_def)
done


text\<open>Similar results are proved in \<open>Fields\<close>\<close>
lemma real_less_half_sum: "x < y ==> x < (x+y) / (2::real)"
  by auto

lemma real_gt_half_sum: "x < y ==> (x+y)/(2::real) < y"
  by auto

lemma real_sum_of_halves: "x/2 + x/2 = (x::real)"
  by simp

subsection\<open>Absolute Value Function for the Reals\<close>

lemma abs_minus_add_cancel: "\<bar>x + (- y)\<bar> = \<bar>y + (- (x::real))\<bar>"
  by (simp add: abs_if)

lemma abs_add_one_gt_zero: "(0::real) < 1 + \<bar>x\<bar>"
  by (simp add: abs_if)

lemma abs_add_one_not_less_self: "~ \<bar>x\<bar> + (1::real) < x"
  by simp

lemma abs_sum_triangle_ineq: "\<bar>(x::real) + y + (-l + -m)\<bar> \<le> \<bar>x + -l\<bar> + \<bar>y + -m\<bar>"
  by simp


subsection\<open>Floor and Ceiling Functions from the Reals to the Integers\<close>

(* FIXME: theorems for negative numerals. Many duplicates, e.g. from Archimedean_Field.thy. *)

lemma real_of_nat_less_numeral_iff [simp]:
     "real (n::nat) < numeral w \<longleftrightarrow> n < numeral w"
  by (metis of_nat_less_iff of_nat_numeral)

lemma numeral_less_real_of_nat_iff [simp]:
     "numeral w < real (n::nat) \<longleftrightarrow> numeral w < n"
  by (metis of_nat_less_iff of_nat_numeral)

lemma numeral_le_real_of_nat_iff[simp]:
  "(numeral n \<le> real(m::nat)) = (numeral n \<le> m)"
by (metis not_le real_of_nat_less_numeral_iff)

declare of_int_floor_le [simp] (* FIXME*)

lemma of_int_floor_cancel [simp]:
    "(of_int \<lfloor>x\<rfloor> = x) = (\<exists>n::int. x = of_int n)"
  by (metis floor_of_int)

lemma floor_eq: "[| real_of_int n < x; x < real_of_int n + 1 |] ==> \<lfloor>x\<rfloor> = n"
  by linarith

lemma floor_eq2: "[| real_of_int n \<le> x; x < real_of_int n + 1 |] ==> \<lfloor>x\<rfloor> = n"
  by linarith

lemma floor_eq3: "[| real n < x; x < real (Suc n) |] ==> nat \<lfloor>x\<rfloor> = n"
  by linarith

lemma floor_eq4: "[| real n \<le> x; x < real (Suc n) |] ==> nat \<lfloor>x\<rfloor> = n"
  by linarith

lemma real_of_int_floor_ge_diff_one [simp]: "r - 1 \<le> real_of_int \<lfloor>r\<rfloor>"
  by linarith

lemma real_of_int_floor_gt_diff_one [simp]: "r - 1 < real_of_int \<lfloor>r\<rfloor>"
  by linarith

lemma real_of_int_floor_add_one_ge [simp]: "r \<le> real_of_int \<lfloor>r\<rfloor> + 1"
  by linarith

lemma real_of_int_floor_add_one_gt [simp]: "r < real_of_int \<lfloor>r\<rfloor> + 1"
  by linarith

lemma floor_eq_iff: "\<lfloor>x\<rfloor> = b \<longleftrightarrow> of_int b \<le> x \<and> x < of_int (b + 1)"
  by (simp add: floor_unique_iff)

lemma floor_add2[simp]: "\<lfloor>of_int a + x\<rfloor> = a + \<lfloor>x\<rfloor>"
  by (simp add: add.commute)

lemma floor_divide_real_eq_div: "0 \<le> b \<Longrightarrow> \<lfloor>a / real_of_int b\<rfloor> = \<lfloor>a\<rfloor> div b"
proof cases
  assume "0 < b"
  { fix i j :: int assume "real_of_int i \<le> a" "a < 1 + real_of_int i"
      "real_of_int j * real_of_int b \<le> a" "a < real_of_int b + real_of_int j * real_of_int b"
    then have "i < b + j * b"
      by (metis linorder_not_less of_int_add of_int_le_iff of_int_mult order_trans_rules(21))
    moreover have "j * b < 1 + i"
    proof -
      have "real_of_int (j * b) < real_of_int i + 1"
        using \<open>a < 1 + real_of_int i\<close> \<open>real_of_int j * real_of_int b \<le> a\<close> by force
      thus "j * b < 1 + i"
        by linarith
    qed
    ultimately have "(j - i div b) * b \<le> i mod b" "i mod b < ((j - i div b) + 1) * b"
      by (auto simp: field_simps)
    then have "(j - i div b) * b < 1 * b" "0 * b < ((j - i div b) + 1) * b"
      using pos_mod_bound[OF \<open>0<b\<close>, of i] pos_mod_sign[OF \<open>0<b\<close>, of i] by linarith+
    then have "j = i div b"
      using \<open>0 < b\<close> unfolding mult_less_cancel_right by auto
  }
  with \<open>0 < b\<close> show ?thesis
    by (auto split: floor_split simp: field_simps)
qed auto

lemma floor_divide_eq_div_numeral[simp]: "\<lfloor>numeral a / numeral b::real\<rfloor> = numeral a div numeral b"
  by (metis floor_divide_of_int_eq of_int_numeral)

lemma floor_minus_divide_eq_div_numeral[simp]: "\<lfloor>- (numeral a / numeral b)::real\<rfloor> = - numeral a div numeral b"
  by (metis divide_minus_left floor_divide_of_int_eq of_int_neg_numeral of_int_numeral)

lemma of_int_ceiling_cancel [simp]: "(of_int \<lceil>x\<rceil> = x) = (\<exists>n::int. x = of_int n)"
  using ceiling_of_int by metis

lemma ceiling_eq: "[| of_int n < x; x \<le> of_int n + 1 |] ==> \<lceil>x\<rceil> = n + 1"
  by (simp add: ceiling_unique)

lemma of_int_ceiling_diff_one_le [simp]: "of_int \<lceil>r\<rceil> - 1 \<le> r"
  by linarith

lemma of_int_ceiling_le_add_one [simp]: "of_int \<lceil>r\<rceil> \<le> r + 1"
  by linarith

lemma ceiling_le: "x <= of_int a ==> \<lceil>x\<rceil> <= a"
  by (simp add: ceiling_le_iff)

lemma ceiling_divide_eq_div: "\<lceil>of_int a / of_int b\<rceil> = - (- a div b)"
  by (metis ceiling_def floor_divide_of_int_eq minus_divide_left of_int_minus)

lemma ceiling_divide_eq_div_numeral [simp]:
  "\<lceil>numeral a / numeral b :: real\<rceil> = - (- numeral a div numeral b)"
  using ceiling_divide_eq_div[of "numeral a" "numeral b"] by simp

lemma ceiling_minus_divide_eq_div_numeral [simp]:
  "\<lceil>- (numeral a / numeral b :: real)\<rceil> = - (numeral a div numeral b)"
  using ceiling_divide_eq_div[of "- numeral a" "numeral b"] by simp

text\<open>The following lemmas are remnants of the erstwhile functions natfloor
and natceiling.\<close>

lemma nat_floor_neg: "(x::real) <= 0 ==> nat \<lfloor>x\<rfloor> = 0"
  by linarith

lemma le_nat_floor: "real x <= a ==> x <= nat \<lfloor>a\<rfloor>"
  by linarith

lemma le_mult_nat_floor: "nat \<lfloor>a\<rfloor> * nat \<lfloor>b\<rfloor> \<le> nat \<lfloor>a * b\<rfloor>"
  by (cases "0 <= a & 0 <= b")
     (auto simp add: nat_mult_distrib[symmetric] nat_mono le_mult_floor)

lemma nat_ceiling_le_eq [simp]: "(nat \<lceil>x\<rceil> <= a) = (x <= real a)"
  by linarith

lemma real_nat_ceiling_ge: "x <= real (nat \<lceil>x\<rceil>)"
  by linarith

lemma Rats_no_top_le: "\<exists> q \<in> \<rat>. (x :: real) \<le> q"
  by (auto intro!: bexI[of _ "of_nat (nat \<lceil>x\<rceil>)"]) linarith

lemma Rats_no_bot_less: "\<exists> q \<in> \<rat>. q < (x :: real)"
  apply (auto intro!: bexI[of _ "of_int (\<lfloor>x\<rfloor> - 1)"])
  apply (rule less_le_trans[OF _ of_int_floor_le])
  apply simp
  done

subsection \<open>Exponentiation with floor\<close>

lemma floor_power:
  assumes "x = of_int \<lfloor>x\<rfloor>"
  shows "\<lfloor>x ^ n\<rfloor> = \<lfloor>x\<rfloor> ^ n"
proof -
  have "x ^ n = of_int (\<lfloor>x\<rfloor> ^ n)"
    using assms by (induct n arbitrary: x) simp_all
  then show ?thesis by (metis floor_of_int) 
qed

lemma floor_numeral_power[simp]:
  "\<lfloor>numeral x ^ n\<rfloor> = numeral x ^ n"
  by (metis floor_of_int of_int_numeral of_int_power)

lemma ceiling_numeral_power[simp]:
  "\<lceil>numeral x ^ n\<rceil> = numeral x ^ n"
  by (metis ceiling_of_int of_int_numeral of_int_power)

subsection \<open>Implementation of rational real numbers\<close>

text \<open>Formal constructor\<close>

definition Ratreal :: "rat \<Rightarrow> real" where
  [code_abbrev, simp]: "Ratreal = of_rat"

code_datatype Ratreal


text \<open>Numerals\<close>

lemma [code_abbrev]:
  "(of_rat (of_int a) :: real) = of_int a"
  by simp

lemma [code_abbrev]:
  "(of_rat 0 :: real) = 0"
  by simp

lemma [code_abbrev]:
  "(of_rat 1 :: real) = 1"
  by simp

lemma [code_abbrev]:
  "(of_rat (- 1) :: real) = - 1"
  by simp

lemma [code_abbrev]:
  "(of_rat (numeral k) :: real) = numeral k"
  by simp

lemma [code_abbrev]:
  "(of_rat (- numeral k) :: real) = - numeral k"
  by simp

lemma [code_post]:
  "(of_rat (1 / numeral k) :: real) = 1 / numeral k"
  "(of_rat (numeral k / numeral l) :: real) = numeral k / numeral l"
  "(of_rat (- (1 / numeral k)) :: real) = - (1 / numeral k)"
  "(of_rat (- (numeral k / numeral l)) :: real) = - (numeral k / numeral l)"
  by (simp_all add: of_rat_divide of_rat_minus)


text \<open>Operations\<close>

lemma zero_real_code [code]:
  "0 = Ratreal 0"
by simp

lemma one_real_code [code]:
  "1 = Ratreal 1"
by simp

instantiation real :: equal
begin

definition "HOL.equal (x::real) y \<longleftrightarrow> x - y = 0"

instance proof
qed (simp add: equal_real_def)

lemma real_equal_code [code]:
  "HOL.equal (Ratreal x) (Ratreal y) \<longleftrightarrow> HOL.equal x y"
  by (simp add: equal_real_def equal)

lemma [code nbe]:
  "HOL.equal (x::real) x \<longleftrightarrow> True"
  by (rule equal_refl)

end

lemma real_less_eq_code [code]: "Ratreal x \<le> Ratreal y \<longleftrightarrow> x \<le> y"
  by (simp add: of_rat_less_eq)

lemma real_less_code [code]: "Ratreal x < Ratreal y \<longleftrightarrow> x < y"
  by (simp add: of_rat_less)

lemma real_plus_code [code]: "Ratreal x + Ratreal y = Ratreal (x + y)"
  by (simp add: of_rat_add)

lemma real_times_code [code]: "Ratreal x * Ratreal y = Ratreal (x * y)"
  by (simp add: of_rat_mult)

lemma real_uminus_code [code]: "- Ratreal x = Ratreal (- x)"
  by (simp add: of_rat_minus)

lemma real_minus_code [code]: "Ratreal x - Ratreal y = Ratreal (x - y)"
  by (simp add: of_rat_diff)

lemma real_inverse_code [code]: "inverse (Ratreal x) = Ratreal (inverse x)"
  by (simp add: of_rat_inverse)

lemma real_divide_code [code]: "Ratreal x / Ratreal y = Ratreal (x / y)"
  by (simp add: of_rat_divide)

lemma real_floor_code [code]: "\<lfloor>Ratreal x\<rfloor> = \<lfloor>x\<rfloor>"
  by (metis Ratreal_def floor_le_iff floor_unique le_floor_iff of_int_floor_le of_rat_of_int_eq real_less_eq_code)


text \<open>Quickcheck\<close>

definition (in term_syntax)
  valterm_ratreal :: "rat \<times> (unit \<Rightarrow> Code_Evaluation.term) \<Rightarrow> real \<times> (unit \<Rightarrow> Code_Evaluation.term)" where
  [code_unfold]: "valterm_ratreal k = Code_Evaluation.valtermify Ratreal {\<cdot>} k"

notation fcomp (infixl "\<circ>>" 60)
notation scomp (infixl "\<circ>\<rightarrow>" 60)

instantiation real :: random
begin

definition
  "Quickcheck_Random.random i = Quickcheck_Random.random i \<circ>\<rightarrow> (\<lambda>r. Pair (valterm_ratreal r))"

instance ..

end

no_notation fcomp (infixl "\<circ>>" 60)
no_notation scomp (infixl "\<circ>\<rightarrow>" 60)

instantiation real :: exhaustive
begin

definition
  "exhaustive_real f d = Quickcheck_Exhaustive.exhaustive (%r. f (Ratreal r)) d"

instance ..

end

instantiation real :: full_exhaustive
begin

definition
  "full_exhaustive_real f d = Quickcheck_Exhaustive.full_exhaustive (%r. f (valterm_ratreal r)) d"

instance ..

end

instantiation real :: narrowing
begin

definition
  "narrowing = Quickcheck_Narrowing.apply (Quickcheck_Narrowing.cons Ratreal) narrowing"

instance ..

end


subsection \<open>Setup for Nitpick\<close>

declaration \<open>
  Nitpick_HOL.register_frac_type @{type_name real}
    [(@{const_name zero_real_inst.zero_real}, @{const_name Nitpick.zero_frac}),
     (@{const_name one_real_inst.one_real}, @{const_name Nitpick.one_frac}),
     (@{const_name plus_real_inst.plus_real}, @{const_name Nitpick.plus_frac}),
     (@{const_name times_real_inst.times_real}, @{const_name Nitpick.times_frac}),
     (@{const_name uminus_real_inst.uminus_real}, @{const_name Nitpick.uminus_frac}),
     (@{const_name inverse_real_inst.inverse_real}, @{const_name Nitpick.inverse_frac}),
     (@{const_name ord_real_inst.less_real}, @{const_name Nitpick.less_frac}),
     (@{const_name ord_real_inst.less_eq_real}, @{const_name Nitpick.less_eq_frac})]
\<close>

lemmas [nitpick_unfold] = inverse_real_inst.inverse_real one_real_inst.one_real
    ord_real_inst.less_real ord_real_inst.less_eq_real plus_real_inst.plus_real
    times_real_inst.times_real uminus_real_inst.uminus_real
    zero_real_inst.zero_real


subsection \<open>Setup for SMT\<close>

ML_file "Tools/SMT/smt_real.ML"
ML_file "Tools/SMT/z3_real.ML"

lemma [z3_rule]:
  "0 + (x::real) = x"
  "x + 0 = x"
  "0 * x = 0"
  "1 * x = x"
  "x + y = y + x"
  by auto

end
