/**********Kayte, using code that Hemal wrote 
June 2020*/

libname covid "S:\KAndersen_CCDA_COVID\Immunosuppression";

%let independent= week sibley downtown hoco bayview suburban
					age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio rxrisk_sum 
					male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
					smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_obese bmi_miss
					admit_nh respgt22 elevated_crp elevated_creatinine elevated_troponin high_wbc low_albumin low_wbc
					copd rheum renal cancer hiv elix_summary_score_v01;

/********************************************************************************
     Derive PS and get Std Diff before and after weighting
********************************************************************************/
proc psmatch data=covid.cohort_immuno region=allobs;
		class immuno_meds zipcode;
		psmodel immuno_meds(treated='1')= &independent;
		assess lps var=(&independent)
						/ varinfo nlargestwgt=6 plots=(barchart boxplot(display=(lps )) wgtcloud) weight=atewgt(stabilize=yes);
output out(obs=all)=propensity_score atewgt(stabilize=yes)=_ATEWgt_;
run;
proc univariate data=propensity_score; var _ps_; histogram; run; /*propensity score*/
proc univariate data=propensity_score; var _ATEWgt_; run; /*stabilized weights*/
/*Trimming at 1st and 99th percentile*/
data covid.propensity_score; 
set propensity_score; 
if 0< _ATEWgt_ < 0.2093960 then _ATEWgt_=0.2093960; 
if _ATEWgt_ > 1.8831598 then _ATEWgt_=1.8831598; 
if _ATEWgt_=. then delete; 
run;

/*IPTW without the stabilized weight
proc psmatch data=covid.cohort_immuno region=allobs;
		class immunocomp zipcode;
		psmodel immunocomp(treated='1')= week age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio total_meds elix_summary_score
				male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
				smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_class1 bmi_class2 bmi_class3 bmi_miss
				admit_nh respgt22 elevated_Crp crp_notordered elevated_creatinine creatinine_notordered elevated_ddimer ddimer_notordered
				elevated_ast ast_notordered elevated_troponin troponin_notordered high_wbc low_wbc wbc_notordered low_albumin albumin_notordered
				acearb_preadmission anticoag antidm antihtn antiplatelet azithro_preadmission hcq_preadmission meds_lungdisease statins;
		assess lps var=(week age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio total_meds elix_summary_score
				male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
				smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_class1 bmi_class2 bmi_class3 bmi_miss
				admit_nh respgt22 elevated_Crp crp_notordered elevated_creatinine creatinine_notordered elevated_ddimer ddimer_notordered
				elevated_ast ast_notordered elevated_troponin troponin_notordered high_wbc low_wbc wbc_notordered low_albumin albumin_notordered
				acearb_preadmission anticoag antidm antihtn antiplatelet azithro_preadmission hcq_preadmission meds_lungdisease statins)
						/ varinfo nlargestwgt=6 plots=(barchart boxplot(display=(lps )) wgtcloud) weight=atewgt;
output out(obs=all)=notstable atewgt=_ATEWgt_;
run;
*/

/*For the matching instead of weighting*/
proc psmatch data=covid.cohort_immuno region=allobs;
		class immuno_meds zipcode;
		psmodel immuno_meds(treated='1')= &independent;
		match distance=lps method=greedy(k=1) caliper=0.5; 
		assess lps var=(&independent)
						/ stddev=pooled(allobs=no) stdbinvar=no plots(nodetails)=all weight=none;
output out(obs=match)=covid.ps_match matchid=_matchID;
run;
/*With greedy matching, getting 134 people so all 67 have matches */
proc univariate data=covid.ps_match; var _ps_; run; /*propensity score*/
