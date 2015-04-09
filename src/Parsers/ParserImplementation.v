(** * Implementation of simply-typed interface of the parser *)
Require Export ADTSynthesis.Parsers.ParserInterface.
Require Import ADTSynthesis.Parsers.ContextFreeGrammar.
Require Import ADTSynthesis.Parsers.ContextFreeGrammarProperties.
Require Import ADTSynthesis.Parsers.BooleanRecognizer ADTSynthesis.Parsers.BooleanRecognizerCorrect.
Require Import ADTSynthesis.Parsers.Splitters.RDPList.
Require Import ADTSynthesis.Parsers.BaseTypes ADTSynthesis.Parsers.BooleanBaseTypes.
Require Import ADTSynthesis.Parsers.StringLike.Core.
Require Import ADTSynthesis.Parsers.MinimalParseOfParse.
Require Import ADTSynthesis.Common.

Set Implicit Arguments.

Local Open Scope list_scope.

Section implementation.
  Context {Char} {G : grammar Char}.
  Context (splitter : Splitter G).

  Local Instance parser_data : @boolean_parser_dataT Char _ :=
    { predata := rdp_list_predata (G := G);
      split_string_for_production it its str
      := splits_for splitter str it its }.

  Local Instance parser_completeness_data : @boolean_parser_completeness_dataT' Char _ G parser_data
    := { split_string_for_production_complete str0 valid str pf nt Hvalid := _ }.
  Proof.
    unfold is_valid_nonterminal in Hvalid; simpl in Hvalid.
    unfold rdp_list_is_valid_nonterminal in Hvalid; simpl in Hvalid.
    hnf in Hvalid.
    edestruct List.in_dec as [Hvalid' | ]; [ clear Hvalid | congruence ].
    generalize (fun it its n pf pit pits prefix H' => @splits_for_complete Char G splitter str it its n pf pit pits (ex_intro _ nt (ex_intro _ prefix (conj Hvalid' H')))).
    clear Hvalid'.
    induction (G nt) as [ | x xs IHxs ].
    { intros; constructor. }
    { intro H'.
      Opaque split_string_for_production.
      simpl.
      Transparent split_string_for_production.
      split;
        [ clear IHxs
        | apply IHxs;
          intros; eapply H'; try eassumption; [ right; eassumption ] ].
      specialize (fun prefix it its H n pf pit pits => H' it its n pf pit pits prefix (or_introl H)).
      clear -H'.
      induction x as [ | it its IHx ].
      { simpl; constructor. }
      { Opaque split_string_for_production.
        simpl.
        Transparent split_string_for_production.
        split;
          [ clear IHx
          | apply IHx;
            intros; subst; eapply (H' (_::_)); try eassumption; reflexivity ].
        specialize (H' nil it its eq_refl).
        hnf.
        intros [ n [ pit pits ] ]; simpl in * |- .
        destruct (Compare_dec.le_ge_dec n (length str)).
        { exists n; repeat split; eauto.
          apply H'; eauto.
          { exact (parse_of_item__of__minimal_parse_of_item pit). }
          { exact (parse_of_production__of__minimal_parse_of_production pits). } }
        { exists (length str).
          specialize (H' (length str) (reflexivity _)).
          pose proof (fun H => expand_minimal_parse_of_item (str' := take (length str) str) (reflexivity _) (reflexivity _) (or_introl (reflexivity _)) H pit) as pit'; clear pit.
          pose proof (fun H => expand_minimal_parse_of_production (str' := drop (length str) str) (reflexivity _) (reflexivity _) (or_introl (reflexivity _)) H pits) as pits'; clear pits.
          refine ((fun ret => let pit'' := pit' (fst (snd ret)) in
                              let pits'' := pits' (snd (snd ret)) in
                              ((H' (fst (fst ret) pit'') (snd (fst ret) pits''), pit''), pits'')) _); repeat split.
          { apply (@parse_of_item__of__minimal_parse_of_item Char splitter G _). }
          { apply (@parse_of_production__of__minimal_parse_of_production Char splitter G _). }
          { rewrite !take_long; (assumption || reflexivity). }
          { apply bool_eq_empty; rewrite drop_length; omega. } } } }
  Qed.

  Program Definition parser : Parser G splitter
    := {| has_parse str := parse_nonterminal (G := G) (data := parser_data) str (Start_symbol G);
          has_parse_sound str Hparse := parse_nonterminal_sound G _ _ Hparse;
          has_parse_complete str p Hp := _ |}.
  Next Obligation.
  Proof.
    dependent destruction p.
    pose proof (@parse_nonterminal_complete Char splitter _ G _ _ rdp_list_rdata' str (Start_symbol G) p) as H'.
    apply H'.
    rewrite <- (parse_of_item_respectful_refl (pf := reflexivity _)).
    rewrite <- (parse_of_item_respectful_refl (pf := reflexivity _)) in Hp.
    eapply expand_forall_parse_of_item; [ | reflexivity.. | eassumption ].
    simpl.
    unfold rdp_list_is_valid_nonterminal; simpl.
    intros ? ? ? ? ? H0.
    edestruct List.in_dec as [ | nH ]; trivial; [].
    destruct (nH H0).
  Qed.
End implementation.
