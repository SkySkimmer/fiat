Require Import
        Coq.omega.Omega
        Coq.Strings.String
        Coq.Vectors.Vector.

Require Import
        Fiat.Computation
        Fiat.Narcissus.Common.Specs.

Section UnionFormat.

  Context {S : Type}. (* Source Type *)
  Context {T : Type}. (* Target Type *)
  Context {cache : Cache}. (* State Type *)

  Context {S' : Type}. (* Transformed Type *)
  Variable f : S -> S' -> Prop. (* Transformation Relation *)

  Definition FMap_Format
             (format_a : FormatM S T)
    : FormatM S' T :=
    fun a' env benv' =>
      exists a, computes_to (format_a a env) benv' /\ f a a'.

  Variable g : S -> S'. (* Transformation Function *)

  Definition FMap_Decode
             (decode : DecodeM S T)
    : DecodeM S' T  :=
    fun b env => `(a, env') <- decode b env; Some (g a, env').

  Lemma CorrectDecoder_FMap
        (format : FormatM S T)
        (decode : DecodeM S T)
        (format_decode_corect : CorrectDecoder_simpl format decode)
        (g_inverts_f : forall a a' env benv,
            format a env benv -> f a a' -> g a = a')
        (g_OK : forall a, f a (g a))
    : CorrectDecoder_simpl (FMap_Format format) (FMap_Decode decode).
  Proof.
    unfold CorrectDecoder_simpl, FMap_Decode, FMap_Format in *; split; intros.
    { repeat (apply_in_hyp @unfold_computes; destruct_ex; intuition).
      pose proof (g_inverts_f  _ _ _ _ H3 H4).
      rewrite <- unfold_computes in H3.
      eapply H1 in H3; destruct_ex; intuition eauto.
      eexists; rewrite H5; simpl; intuition eauto.
      subst; eauto.
    }
    { apply_in_hyp DecodeBindOpt_inv; destruct_ex; intuition.
      eapply H2 in H3; eauto; injections.
      destruct_ex; eexists; intuition eauto.
      apply unfold_computes.
      eexists; intuition eauto.
    }
  Qed.

End UnionFormat.

Definition Restrict_Format
           {S T : Type}
           {cache : Cache}
           (P : S -> Prop)
           (format : FormatM S T)
  := FMap_Format (fun s s' => s = s' /\ P s) format.

Definition Projection_Format
           {S S' T : Type}
           {cache : Cache}
           (f : S -> S')
           (format : FormatM S' T)
  : FormatM S T :=
  FMap_Format (fun s' s => f s = s') format.

Notation "f <$> format" := (FMap_Format f format) (at level 99) : format_scope.
