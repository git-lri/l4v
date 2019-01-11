(*
 * Copyright 2019, Data61
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(DATA61_BSD)
 *)

(* A folding operation for separation algebra, to facilitate mappings with sharing
 *
 * Ordinarily when we map over a list, we require that the heap initially satisfies some
 * precondition P for every element of the list, and we transform it into a heap which satisfies
 * a post-condition Q for every element, i.e.
 *
 *  \<And>* map P xs \<and>* ((\<And>* map Q xs) \<longrightarrow>* R))
 *
 * However, what if we only have one copy of some resource required by P, and we want to share it
 * between iterations? The above formulation is insufficient, as it would require a copy of the
 * resource for every x \<in> xs. That's where sep_fold comes in.
 *
 * As you can see in the definition below, sep_fold nests each iteration's pre-condition under
 * the post-conditions for previous iterations, which allows a shared resource to be passed down.
 *
 * For a real-world example of sep_fold usage, see the lemmas in SysInit.InitVSpace
 *
 * See also the Sep_Fold_Cancel lemmas and tactics, which automatically detect and cancel sharing
 *)

theory Sep_Fold
imports
  Separation_Algebra
begin

definition
  sep_fold :: "('b \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow>
               ('b \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow>
               ('a \<Rightarrow> bool) \<Rightarrow>
               'b list \<Rightarrow>
               ('a::sep_algebra \<Rightarrow> bool)"
  where
  "sep_fold P Q R xs \<equiv> foldr (\<lambda>x R. (P x \<and>* (Q x \<longrightarrow>* R))) xs R"

notation sep_fold ("\<lparr>{_} \<and>* ({_} \<longrightarrow>* {_})\<rparr> _")

lemma sep_map_sep_foldI: "(\<And>* map P xs \<and>* ((\<And>* map Q xs) \<longrightarrow>* R)) s \<Longrightarrow> sep_fold P Q R xs s"
  apply (clarsimp simp: sep_fold_def)
  apply (induct xs arbitrary: s; clarsimp)
   apply (metis sep_add_zero sep_disj_zero sep_empty_zero sep_impl_def)
  apply (clarsimp simp: sep_conj_ac)
  apply (erule (1) sep_conj_impl)
  apply (erule sep_conj_sep_impl)
  apply (clarsimp simp: sep_conj_ac)
  by (smt abel_semigroup.commute sep.mult.abel_semigroup_axioms sep.mult.left_commute sep_conj_impl
          sep_conj_sep_impl sep_conj_sep_impl2)

lemma sep_factor_foldI:
  "(R' \<and>* (sep_fold P Q R xs)) s \<Longrightarrow>
   sep_fold (\<lambda>x. R' \<and>* P x) (\<lambda>x. R' \<and>* Q x) (R' \<and>* R) xs s"
  apply (induct xs arbitrary: s; clarsimp simp: sep_fold_def)
  apply (clarsimp simp: sep_conj_ac)
  apply (erule (1) sep_conj_impl)
  apply (erule (1) sep_conj_impl)
  apply (erule sep_conj_sep_impl)
  apply (clarsimp simp: sep_conj_ac)
  apply (drule (1) sep_conj_impl)
   apply (subst (asm) sep_conj_commute, erule (1) sep_conj_sep_impl2)
  by blast

end