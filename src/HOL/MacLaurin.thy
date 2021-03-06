(*  Author      : Jacques D. Fleuriot
    Copyright   : 2001 University of Edinburgh
    Conversion to Isar and new proofs by Lawrence C Paulson, 2004
    Conversion of Mac Laurin to Isar by Lukas Bulwahn and Bernhard Häupler, 2005
*)

section\<open>MacLaurin Series\<close>

theory MacLaurin
imports Transcendental
begin

subsection\<open>Maclaurin's Theorem with Lagrange Form of Remainder\<close>

text\<open>This is a very long, messy proof even now that it's been broken down
into lemmas.\<close>

lemma Maclaurin_lemma:
    "0 < h ==>
     \<exists>B::real. f h = (\<Sum>m<n. (j m / (fact m)) * (h^m)) +
               (B * ((h^n) /(fact n)))"
by (rule exI[where x = "(f h - (\<Sum>m<n. (j m / (fact m)) * h^m)) * (fact n) / (h^n)"]) simp

lemma eq_diff_eq': "(x = y - z) = (y = x + (z::real))"
by arith

lemma fact_diff_Suc:
  "n < Suc m \<Longrightarrow> fact (Suc m - n) = (Suc m - n) * fact (m - n)"
  by (subst fact_reduce, auto)

lemma Maclaurin_lemma2:
  fixes B
  assumes DERIV : "\<forall>m t. m < n \<and> 0\<le>t \<and> t\<le>h \<longrightarrow> DERIV (diff m) t :> diff (Suc m) t"
      and INIT : "n = Suc k"
  defines "difg \<equiv>
      (\<lambda>m t::real. diff m t -
         ((\<Sum>p<n - m. diff (m + p) 0 / (fact p) * t ^ p) + B * (t ^ (n - m) / (fact (n - m)))))"
        (is "difg \<equiv> (\<lambda>m t. diff m t - ?difg m t)")
  shows "\<forall>m t. m < n & 0 \<le> t & t \<le> h --> DERIV (difg m) t :> difg (Suc m) t"
proof (rule allI impI)+
  fix m and t::real
  assume INIT2: "m < n & 0 \<le> t & t \<le> h"
  have "DERIV (difg m) t :> diff (Suc m) t -
    ((\<Sum>x<n - m. real x * t ^ (x - Suc 0) * diff (m + x) 0 / (fact x)) +
     real (n - m) * t ^ (n - Suc m) * B / (fact (n - m)))"
    unfolding difg_def
    by (auto intro!: derivative_eq_intros DERIV[rule_format, OF INIT2])
  moreover
  from INIT2 have intvl: "{..<n - m} = insert 0 (Suc ` {..<n - Suc m})" and "0 < n - m"
    unfolding atLeast0LessThan[symmetric] by auto
  have "(\<Sum>x<n - m. real x * t ^ (x - Suc 0) * diff (m + x) 0 / (fact x)) =
      (\<Sum>x<n - Suc m. real (Suc x) * t ^ x * diff (Suc m + x) 0 / (fact (Suc x)))"
    unfolding intvl atLeast0LessThan by (subst setsum.insert) (auto simp: setsum.reindex)
  moreover
  have fact_neq_0: "\<And>x. (fact x) + real x * (fact x) \<noteq> 0"
    by (metis add_pos_pos fact_gt_zero less_add_same_cancel1 less_add_same_cancel2 less_numeral_extra(3) mult_less_0_iff of_nat_less_0_iff)
  have "\<And>x. (Suc x) * t ^ x * diff (Suc m + x) 0 / (fact (Suc x)) =
            diff (Suc m + x) 0 * t^x / (fact x)"
    by (rule nonzero_divide_eq_eq[THEN iffD2]) auto
  moreover
  have "(n - m) * t ^ (n - Suc m) * B / (fact (n - m)) =
        B * (t ^ (n - Suc m) / (fact (n - Suc m)))"
    using \<open>0 < n - m\<close>
    by (simp add: divide_simps fact_reduce)
  ultimately show "DERIV (difg m) t :> difg (Suc m) t"
    unfolding difg_def  by (simp add: mult.commute)
qed

lemma Maclaurin:
  assumes h: "0 < h"
  assumes n: "0 < n"
  assumes diff_0: "diff 0 = f"
  assumes diff_Suc:
    "\<forall>m t. m < n & 0 \<le> t & t \<le> h --> DERIV (diff m) t :> diff (Suc m) t"
  shows
    "\<exists>t::real. 0 < t & t < h &
              f h =
              setsum (%m. (diff m 0 / (fact m)) * h ^ m) {..<n} +
              (diff n t / (fact n)) * h ^ n"
proof -
  from n obtain m where m: "n = Suc m"
    by (cases n) (simp add: n)

  obtain B where f_h: "f h =
        (\<Sum>m<n. diff m (0::real) / (fact m) * h ^ m) + B * (h ^ n / (fact n))"
    using Maclaurin_lemma [OF h] ..

  def g \<equiv> "(\<lambda>t. f t -
    (setsum (\<lambda>m. (diff m 0 / (fact m)) * t^m) {..<n} + (B * (t^n / (fact n)))))"

  have g2: "g 0 = 0 & g h = 0"
    by (simp add: m f_h g_def lessThan_Suc_eq_insert_0 image_iff diff_0 setsum.reindex)

  def difg \<equiv> "(%m t. diff m t -
    (setsum (%p. (diff (m + p) 0 / (fact p)) * (t ^ p)) {..<n-m}
      + (B * ((t ^ (n - m)) / (fact (n - m))))))"

  have difg_0: "difg 0 = g"
    unfolding difg_def g_def by (simp add: diff_0)

  have difg_Suc: "\<forall>(m::nat) t::real.
        m < n \<and> (0::real) \<le> t \<and> t \<le> h \<longrightarrow> DERIV (difg m) t :> difg (Suc m) t"
    using diff_Suc m unfolding difg_def by (rule Maclaurin_lemma2)

  have difg_eq_0: "\<forall>m<n. difg m 0 = 0"
    by (auto simp: difg_def m Suc_diff_le lessThan_Suc_eq_insert_0 image_iff setsum.reindex)

  have isCont_difg: "\<And>m x. \<lbrakk>m < n; 0 \<le> x; x \<le> h\<rbrakk> \<Longrightarrow> isCont (difg m) x"
    by (rule DERIV_isCont [OF difg_Suc [rule_format]]) simp

  have differentiable_difg:
    "\<And>m x. \<lbrakk>m < n; 0 \<le> x; x \<le> h\<rbrakk> \<Longrightarrow> difg m differentiable (at x)"
    by (rule differentiableI [OF difg_Suc [rule_format]]) simp

  have difg_Suc_eq_0: "\<And>m t. \<lbrakk>m < n; 0 \<le> t; t \<le> h; DERIV (difg m) t :> 0\<rbrakk>
        \<Longrightarrow> difg (Suc m) t = 0"
    by (rule DERIV_unique [OF difg_Suc [rule_format]]) simp

  have "m < n" using m by simp

  have "\<exists>t. 0 < t \<and> t < h \<and> DERIV (difg m) t :> 0"
  using \<open>m < n\<close>
  proof (induct m)
    case 0
    show ?case
    proof (rule Rolle)
      show "0 < h" by fact
      show "difg 0 0 = difg 0 h" by (simp add: difg_0 g2)
      show "\<forall>x. 0 \<le> x \<and> x \<le> h \<longrightarrow> isCont (difg (0::nat)) x"
        by (simp add: isCont_difg n)
      show "\<forall>x. 0 < x \<and> x < h \<longrightarrow> difg (0::nat) differentiable (at x)"
        by (simp add: differentiable_difg n)
    qed
  next
    case (Suc m')
    hence "\<exists>t. 0 < t \<and> t < h \<and> DERIV (difg m') t :> 0" by simp
    then obtain t where t: "0 < t" "t < h" "DERIV (difg m') t :> 0" by fast
    have "\<exists>t'. 0 < t' \<and> t' < t \<and> DERIV (difg (Suc m')) t' :> 0"
    proof (rule Rolle)
      show "0 < t" by fact
      show "difg (Suc m') 0 = difg (Suc m') t"
        using t \<open>Suc m' < n\<close> by (simp add: difg_Suc_eq_0 difg_eq_0)
      show "\<forall>x. 0 \<le> x \<and> x \<le> t \<longrightarrow> isCont (difg (Suc m')) x"
        using \<open>t < h\<close> \<open>Suc m' < n\<close> by (simp add: isCont_difg)
      show "\<forall>x. 0 < x \<and> x < t \<longrightarrow> difg (Suc m') differentiable (at x)"
        using \<open>t < h\<close> \<open>Suc m' < n\<close> by (simp add: differentiable_difg)
    qed
    thus ?case
      using \<open>t < h\<close> by auto
  qed
  then obtain t where "0 < t" "t < h" "DERIV (difg m) t :> 0" by fast

  hence "difg (Suc m) t = 0"
    using \<open>m < n\<close> by (simp add: difg_Suc_eq_0)

  show ?thesis
  proof (intro exI conjI)
    show "0 < t" by fact
    show "t < h" by fact
    show "f h = (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) + diff n t / (fact n) * h ^ n"
      using \<open>difg (Suc m) t = 0\<close>
      by (simp add: m f_h difg_def)
  qed
qed

lemma Maclaurin_objl:
  "0 < h & n>0 & diff 0 = f &
  (\<forall>m t. m < n & 0 \<le> t & t \<le> h --> DERIV (diff m) t :> diff (Suc m) t)
   --> (\<exists>t::real. 0 < t & t < h &
            f h = (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) +
                  diff n t / (fact n) * h ^ n)"
by (blast intro: Maclaurin)


lemma Maclaurin2:
  assumes INIT1: "0 < h " and INIT2: "diff 0 = f"
  and DERIV: "\<forall>m t::real.
  m < n & 0 \<le> t & t \<le> h --> DERIV (diff m) t :> diff (Suc m) t"
  shows "\<exists>t. 0 < t \<and> t \<le> h \<and> f h =
  (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) +
  diff n t / (fact n) * h ^ n"
proof (cases "n")
  case 0 with INIT1 INIT2 show ?thesis by fastforce
next
  case Suc
  hence "n > 0" by simp
  from INIT1 this INIT2 DERIV have "\<exists>t>0. t < h \<and>
    f h =
    (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) + diff n t / (fact n) * h ^ n"
    by (rule Maclaurin)
  thus ?thesis by fastforce
qed

lemma Maclaurin2_objl:
     "0 < h & diff 0 = f &
       (\<forall>m t. m < n & 0 \<le> t & t \<le> h --> DERIV (diff m) t :> diff (Suc m) t)
    --> (\<exists>t::real. 0 < t &
              t \<le> h &
              f h =
              (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) +
              diff n t / (fact n) * h ^ n)"
by (blast intro: Maclaurin2)

lemma Maclaurin_minus:
  fixes h::real
  assumes "h < 0" "0 < n" "diff 0 = f"
  and DERIV: "\<forall>m t. m < n & h \<le> t & t \<le> 0 --> DERIV (diff m) t :> diff (Suc m) t"
  shows "\<exists>t. h < t & t < 0 &
         f h = (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) +
         diff n t / (fact n) * h ^ n"
proof -
  txt "Transform \<open>ABL'\<close> into \<open>derivative_intros\<close> format."
  note DERIV' = DERIV_chain'[OF _ DERIV[rule_format], THEN DERIV_cong]
  from assms
  have "\<exists>t>0. t < - h \<and>
    f (- (- h)) =
    (\<Sum>m<n.
    (- 1) ^ m * diff m (- 0) / (fact m) * (- h) ^ m) +
    (- 1) ^ n * diff n (- t) / (fact n) * (- h) ^ n"
    by (intro Maclaurin) (auto intro!: derivative_eq_intros DERIV')
  then guess t ..
  moreover
  have "(- 1) ^ n * diff n (- t) * (- h) ^ n / (fact n) = diff n (- t) * h ^ n / (fact n)"
    by (auto simp add: power_mult_distrib[symmetric])
  moreover
  have "(\<Sum>m<n. (- 1) ^ m * diff m 0 * (- h) ^ m / (fact m)) = (\<Sum>m<n. diff m 0 * h ^ m / (fact m))"
    by (auto intro: setsum.cong simp add: power_mult_distrib[symmetric])
  ultimately have " h < - t \<and>
    - t < 0 \<and>
    f h =
    (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) + diff n (- t) / (fact n) * h ^ n"
    by auto
  thus ?thesis ..
qed

lemma Maclaurin_minus_objl:
  fixes h::real
  shows
     "(h < 0 & n > 0 & diff 0 = f &
       (\<forall>m t.
          m < n & h \<le> t & t \<le> 0 --> DERIV (diff m) t :> diff (Suc m) t))
    --> (\<exists>t. h < t &
              t < 0 &
              f h =
              (\<Sum>m<n. diff m 0 / (fact m) * h ^ m) +
              diff n t / (fact n) * h ^ n)"
by (blast intro: Maclaurin_minus)


subsection\<open>More Convenient "Bidirectional" Version.\<close>

(* not good for PVS sin_approx, cos_approx *)

lemma Maclaurin_bi_le_lemma:
  "n>0 \<Longrightarrow>
   diff 0 0 =
   (\<Sum>m<n. diff m 0 * 0 ^ m / (fact m)) + diff n 0 * 0 ^ n / (fact n :: real)"
by (induct "n") auto

lemma Maclaurin_bi_le:
   assumes "diff 0 = f"
   and DERIV : "\<forall>m t::real. m < n & \<bar>t\<bar> \<le> \<bar>x\<bar> --> DERIV (diff m) t :> diff (Suc m) t"
   shows "\<exists>t. \<bar>t\<bar> \<le> \<bar>x\<bar> &
              f x =
              (\<Sum>m<n. diff m 0 / (fact m) * x ^ m) +
     diff n t / (fact n) * x ^ n" (is "\<exists>t. _ \<and> f x = ?f x t")
proof cases
  assume "n = 0" with \<open>diff 0 = f\<close> show ?thesis by force
next
  assume "n \<noteq> 0"
  show ?thesis
  proof (cases rule: linorder_cases)
    assume "x = 0" with \<open>n \<noteq> 0\<close> \<open>diff 0 = f\<close> DERIV
    have "\<bar>0\<bar> \<le> \<bar>x\<bar> \<and> f x = ?f x 0" by (auto simp add: Maclaurin_bi_le_lemma)
    thus ?thesis ..
  next
    assume "x < 0"
    with \<open>n \<noteq> 0\<close> DERIV
    have "\<exists>t>x. t < 0 \<and> diff 0 x = ?f x t" by (intro Maclaurin_minus) auto
    then guess t ..
    with \<open>x < 0\<close> \<open>diff 0 = f\<close> have "\<bar>t\<bar> \<le> \<bar>x\<bar> \<and> f x = ?f x t" by simp
    thus ?thesis ..
  next
    assume "x > 0"
    with \<open>n \<noteq> 0\<close> \<open>diff 0 = f\<close> DERIV
    have "\<exists>t>0. t < x \<and> diff 0 x = ?f x t" by (intro Maclaurin) auto
    then guess t ..
    with \<open>x > 0\<close> \<open>diff 0 = f\<close> have "\<bar>t\<bar> \<le> \<bar>x\<bar> \<and> f x = ?f x t" by simp
    thus ?thesis ..
  qed
qed

lemma Maclaurin_all_lt:
  fixes x::real
  assumes INIT1: "diff 0 = f" and INIT2: "0 < n" and INIT3: "x \<noteq> 0"
  and DERIV: "\<forall>m x. DERIV (diff m) x :> diff(Suc m) x"
  shows "\<exists>t. 0 < \<bar>t\<bar> & \<bar>t\<bar> < \<bar>x\<bar> & f x =
    (\<Sum>m<n. (diff m 0 / (fact m)) * x ^ m) +
                (diff n t / (fact n)) * x ^ n" (is "\<exists>t. _ \<and> _ \<and> f x = ?f x t")
proof (cases rule: linorder_cases)
  assume "x = 0" with INIT3 show "?thesis"..
next
  assume "x < 0"
  with assms have "\<exists>t>x. t < 0 \<and> f x = ?f x t" by (intro Maclaurin_minus) auto
  then guess t ..
  with \<open>x < 0\<close> have "0 < \<bar>t\<bar> \<and> \<bar>t\<bar> < \<bar>x\<bar> \<and> f x = ?f x t" by simp
  thus ?thesis ..
next
  assume "x > 0"
  with assms have "\<exists>t>0. t < x \<and> f x = ?f x t " by (intro Maclaurin) auto
  then guess t ..
  with \<open>x > 0\<close> have "0 < \<bar>t\<bar> \<and> \<bar>t\<bar> < \<bar>x\<bar> \<and> f x = ?f x t" by simp
  thus ?thesis ..
qed


lemma Maclaurin_all_lt_objl:
  fixes x::real
  shows
     "diff 0 = f &
      (\<forall>m x. DERIV (diff m) x :> diff(Suc m) x) &
      x ~= 0 & n > 0
      --> (\<exists>t. 0 < \<bar>t\<bar> & \<bar>t\<bar> < \<bar>x\<bar> &
               f x = (\<Sum>m<n. (diff m 0 / (fact m)) * x ^ m) +
                     (diff n t / (fact n)) * x ^ n)"
by (blast intro: Maclaurin_all_lt)

lemma Maclaurin_zero [rule_format]:
     "x = (0::real)
      ==> n \<noteq> 0 -->
          (\<Sum>m<n. (diff m (0::real) / (fact m)) * x ^ m) =
          diff 0 0"
by (induct n, auto)


lemma Maclaurin_all_le:
  assumes INIT: "diff 0 = f"
  and DERIV: "\<forall>m x::real. DERIV (diff m) x :> diff (Suc m) x"
  shows "\<exists>t. \<bar>t\<bar> \<le> \<bar>x\<bar> & f x =
    (\<Sum>m<n. (diff m 0 / (fact m)) * x ^ m) +
    (diff n t / (fact n)) * x ^ n" (is "\<exists>t. _ \<and> f x = ?f x t")
proof cases
  assume "n = 0" with INIT show ?thesis by force
  next
  assume "n \<noteq> 0"
  show ?thesis
  proof cases
    assume "x = 0"
    with \<open>n \<noteq> 0\<close> have "(\<Sum>m<n. diff m 0 / (fact m) * x ^ m) = diff 0 0"
      by (intro Maclaurin_zero) auto
    with INIT \<open>x = 0\<close> \<open>n \<noteq> 0\<close> have " \<bar>0\<bar> \<le> \<bar>x\<bar> \<and> f x = ?f x 0" by force
    thus ?thesis ..
  next
    assume "x \<noteq> 0"
    with INIT \<open>n \<noteq> 0\<close> DERIV have "\<exists>t. 0 < \<bar>t\<bar> \<and> \<bar>t\<bar> < \<bar>x\<bar> \<and> f x = ?f x t"
      by (intro Maclaurin_all_lt) auto
    then guess t ..
    hence "\<bar>t\<bar> \<le> \<bar>x\<bar> \<and> f x = ?f x t" by simp
    thus ?thesis ..
  qed
qed

lemma Maclaurin_all_le_objl:
  "diff 0 = f &
      (\<forall>m x. DERIV (diff m) x :> diff (Suc m) x)
      --> (\<exists>t::real. \<bar>t\<bar> \<le> \<bar>x\<bar> &
              f x = (\<Sum>m<n. (diff m 0 / (fact m)) * x ^ m) +
                    (diff n t / (fact n)) * x ^ n)"
by (blast intro: Maclaurin_all_le)


subsection\<open>Version for Exponential Function\<close>

lemma Maclaurin_exp_lt:
  fixes x::real
  shows
  "[| x ~= 0; n > 0 |]
      ==> (\<exists>t. 0 < \<bar>t\<bar> &
                \<bar>t\<bar> < \<bar>x\<bar> &
                exp x = (\<Sum>m<n. (x ^ m) / (fact m)) +
                        (exp t / (fact n)) * x ^ n)"
by (cut_tac diff = "%n. exp" and f = exp and x = x and n = n in Maclaurin_all_lt_objl, auto)


lemma Maclaurin_exp_le:
     "\<exists>t::real. \<bar>t\<bar> \<le> \<bar>x\<bar> &
            exp x = (\<Sum>m<n. (x ^ m) / (fact m)) +
                       (exp t / (fact n)) * x ^ n"
by (cut_tac diff = "%n. exp" and f = exp and x = x and n = n in Maclaurin_all_le_objl, auto)

lemma exp_lower_taylor_quadratic:
  fixes x::real
  shows "0 \<le> x \<Longrightarrow> 1 + x + x\<^sup>2 / 2 \<le> exp x"
  using Maclaurin_exp_le [of x 3]
  by (auto simp: numeral_3_eq_3 power2_eq_square power_Suc)


subsection\<open>Version for Sine Function\<close>

lemma mod_exhaust_less_4:
  "m mod 4 = 0 | m mod 4 = 1 | m mod 4 = 2 | m mod 4 = (3::nat)"
by auto

lemma Suc_Suc_mult_two_diff_two [rule_format, simp]:
  "n\<noteq>0 --> Suc (Suc (2 * n - 2)) = 2*n"
by (induct "n", auto)

lemma lemma_Suc_Suc_4n_diff_2 [rule_format, simp]:
  "n\<noteq>0 --> Suc (Suc (4*n - 2)) = 4*n"
by (induct "n", auto)

lemma Suc_mult_two_diff_one [rule_format, simp]:
  "n\<noteq>0 --> Suc (2 * n - 1) = 2*n"
by (induct "n", auto)


text\<open>It is unclear why so many variant results are needed.\<close>

lemma sin_expansion_lemma:
     "sin (x + real (Suc m) * pi / 2) =
      cos (x + real (m) * pi / 2)"
by (simp only: cos_add sin_add of_nat_Suc add_divide_distrib distrib_right, auto)

lemma Maclaurin_sin_expansion2:
     "\<exists>t. \<bar>t\<bar> \<le> \<bar>x\<bar> &
       sin x =
       (\<Sum>m<n. sin_coeff m * x ^ m)
      + ((sin(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = sin and n = n and x = x
        and diff = "%n x. sin (x + 1/2*real n * pi)" in Maclaurin_all_lt_objl)
apply safe
    apply (simp)
   apply (simp add: sin_expansion_lemma del: of_nat_Suc)
   apply (force intro!: derivative_eq_intros)
  apply (subst (asm) setsum.neutral, auto)[1]
 apply (rule ccontr, simp)
 apply (drule_tac x = x in spec, simp)
apply (erule ssubst)
apply (rule_tac x = t in exI, simp)
apply (rule setsum.cong[OF refl])
apply (auto simp add: sin_coeff_def sin_zero_iff elim: oddE simp del: of_nat_Suc)
done

lemma Maclaurin_sin_expansion:
     "\<exists>t. sin x =
       (\<Sum>m<n. sin_coeff m * x ^ m)
      + ((sin(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (insert Maclaurin_sin_expansion2 [of x n])
apply (blast intro: elim:)
done

lemma Maclaurin_sin_expansion3:
     "[| n > 0; 0 < x |] ==>
       \<exists>t. 0 < t & t < x &
       sin x =
       (\<Sum>m<n. sin_coeff m * x ^ m)
      + ((sin(t + 1/2 * real(n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = sin and n = n and h = x and diff = "%n x. sin (x + 1/2*real (n) *pi)" in Maclaurin_objl)
apply safe
    apply simp
   apply (simp (no_asm) add: sin_expansion_lemma del: of_nat_Suc)
   apply (force intro!: derivative_eq_intros)
  apply (erule ssubst)
  apply (rule_tac x = t in exI, simp)
 apply (rule setsum.cong[OF refl])
 apply (auto simp add: sin_coeff_def sin_zero_iff elim: oddE simp del: of_nat_Suc)
done

lemma Maclaurin_sin_expansion4:
     "0 < x ==>
       \<exists>t. 0 < t & t \<le> x &
       sin x =
       (\<Sum>m<n. sin_coeff m * x ^ m)
      + ((sin(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = sin and n = n and h = x and diff = "%n x. sin (x + 1/2*real (n) *pi)" in Maclaurin2_objl)
apply safe
    apply simp
   apply (simp (no_asm) add: sin_expansion_lemma del: of_nat_Suc)
   apply (force intro!: derivative_eq_intros)
  apply (erule ssubst)
  apply (rule_tac x = t in exI, simp)
 apply (rule setsum.cong[OF refl])
 apply (auto simp add: sin_coeff_def sin_zero_iff elim: oddE simp del: of_nat_Suc)
done


subsection\<open>Maclaurin Expansion for Cosine Function\<close>

lemma sumr_cos_zero_one [simp]:
  "(\<Sum>m<(Suc n). cos_coeff m * 0 ^ m) = 1"
by (induct "n", auto)

lemma cos_expansion_lemma:
  "cos (x + real(Suc m) * pi / 2) = -sin (x + real m * pi / 2)"
by (simp only: cos_add sin_add of_nat_Suc distrib_right add_divide_distrib, auto)

lemma Maclaurin_cos_expansion:
     "\<exists>t::real. \<bar>t\<bar> \<le> \<bar>x\<bar> &
       cos x =
       (\<Sum>m<n. cos_coeff m * x ^ m)
      + ((cos(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = cos and n = n and x = x and diff = "%n x. cos (x + 1/2*real (n) *pi)" in Maclaurin_all_lt_objl)
apply safe
    apply (simp (no_asm))
   apply (simp (no_asm) add: cos_expansion_lemma del: of_nat_Suc)
  apply (case_tac "n", simp)
  apply (simp del: setsum_lessThan_Suc)
apply (rule ccontr, simp)
apply (drule_tac x = x in spec, simp)
apply (erule ssubst)
apply (rule_tac x = t in exI, simp)
apply (rule setsum.cong[OF refl])
apply (auto simp add: cos_coeff_def cos_zero_iff elim: evenE)
done

lemma Maclaurin_cos_expansion2:
     "[| 0 < x; n > 0 |] ==>
       \<exists>t. 0 < t & t < x &
       cos x =
       (\<Sum>m<n. cos_coeff m * x ^ m)
      + ((cos(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = cos and n = n and h = x and diff = "%n x. cos (x + 1/2*real (n) *pi)" in Maclaurin_objl)
apply safe
  apply simp
  apply (simp (no_asm) add: cos_expansion_lemma del: of_nat_Suc)
 apply (erule ssubst)
 apply (rule_tac x = t in exI, simp)
apply (rule setsum.cong[OF refl])
apply (auto simp add: cos_coeff_def cos_zero_iff elim: evenE)
done

lemma Maclaurin_minus_cos_expansion:
     "[| x < 0; n > 0 |] ==>
       \<exists>t. x < t & t < 0 &
       cos x =
       (\<Sum>m<n. cos_coeff m * x ^ m)
      + ((cos(t + 1/2 * real (n) *pi) / (fact n)) * x ^ n)"
apply (cut_tac f = cos and n = n and h = x and diff = "%n x. cos (x + 1/2*real (n) *pi)" in Maclaurin_minus_objl)
apply safe
  apply simp
 apply (simp (no_asm) add: cos_expansion_lemma del: of_nat_Suc)
apply (erule ssubst)
apply (rule_tac x = t in exI, simp)
apply (rule setsum.cong[OF refl])
apply (auto simp add: cos_coeff_def cos_zero_iff elim: evenE)
done

(* ------------------------------------------------------------------------- *)
(* Version for ln(1 +/- x). Where is it??                                    *)
(* ------------------------------------------------------------------------- *)

lemma sin_bound_lemma:
    "[|x = y; \<bar>u\<bar> \<le> (v::real) |] ==> \<bar>(x + u) - y\<bar> \<le> v"
by auto

lemma Maclaurin_sin_bound:
  "\<bar>sin x - (\<Sum>m<n. sin_coeff m * x ^ m)\<bar> \<le> inverse((fact n)) * \<bar>x\<bar> ^ n"
proof -
  have "!! x (y::real). x \<le> 1 \<Longrightarrow> 0 \<le> y \<Longrightarrow> x * y \<le> 1 * y"
    by (rule_tac mult_right_mono,simp_all)
  note est = this[simplified]
  let ?diff = "\<lambda>(n::nat) x. if n mod 4 = 0 then sin(x) else if n mod 4 = 1 then cos(x) else if n mod 4 = 2 then -sin(x) else -cos(x)"
  have diff_0: "?diff 0 = sin" by simp
  have DERIV_diff: "\<forall>m x. DERIV (?diff m) x :> ?diff (Suc m) x"
    apply (clarify)
    apply (subst (1 2 3) mod_Suc_eq_Suc_mod)
    apply (cut_tac m=m in mod_exhaust_less_4)
    apply (safe, auto intro!: derivative_eq_intros)
    done
  from Maclaurin_all_le [OF diff_0 DERIV_diff]
  obtain t where t1: "\<bar>t\<bar> \<le> \<bar>x\<bar>" and
    t2: "sin x = (\<Sum>m<n. ?diff m 0 / (fact m) * x ^ m) +
      ?diff n t / (fact n) * x ^ n" by fast
  have diff_m_0:
    "\<And>m. ?diff m 0 = (if even m then 0
         else (- 1) ^ ((m - Suc 0) div 2))"
    apply (subst even_even_mod_4_iff)
    apply (cut_tac m=m in mod_exhaust_less_4)
    apply (elim disjE, simp_all)
    apply (safe dest!: mod_eqD, simp_all)
    done
  show ?thesis
    unfolding sin_coeff_def
    apply (subst t2)
    apply (rule sin_bound_lemma)
    apply (rule setsum.cong[OF refl])
    apply (subst diff_m_0, simp)
    apply (auto intro: mult_right_mono [where b=1, simplified] mult_right_mono
                simp add: est ac_simps divide_inverse power_abs [symmetric] abs_mult)
    done
qed

end
