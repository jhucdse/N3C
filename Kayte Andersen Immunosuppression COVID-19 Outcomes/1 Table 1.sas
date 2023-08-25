/**********Kayte accessing CROWN data for Immunosuppression analyses
June 23, 2020
Objective: Table 1 */

libname covid "S:\KAndersen_CCDA_COVID\Immunosuppression";

proc sort data=covid.cohort_immuno; by immuno_meds; run;

proc freq data=covid.immuno_meds_withduplicates /*order=freq*/; table immuno_med_name; run;
proc freq data=covid.cohort_immuno; table immuno_meds*immuno_diagnosis; run;
proc freq data=covid.cohort_immuno order=freq; table immuno_icd10_code; run;

*Confirmed vs suspected;
data confirmed;
set covid.cohort_immuno;
if initial_dx_source="LAB" then confirmed=1;
if initial_dx_source="INF+LAB" then confirmed=1;
if initial_dx_source="INF" then suspected=1;
if confirmed=1 then suspected=0; if suspected=1 then confirmed=0;
run;
proc freq data=confirmed; table confirmed suspected; run;

Title "Table 1";
proc means data=covid.cohort_immuno maxdec=1; 
var age_at_positive; by immuno_meds; run;

proc freq data=covid.cohort_immuno; 
table (male white black other_race hispanic no_hispanic unknown_ethnicity
	el_drug alcohol_yes alcohol_no alcohol_miss
	smoker_yes smoker_former smoker_no smoker_miss)*immuno_meds / missing nopercent norow; 
run;

/*proc means data=covid.cohort_immuno maxdec=1; 
var bmi;
by immuno_meds; 
run;*/

proc freq data=covid.cohort_immuno; 
table (bmi_normal bmi_overwt bmi_obese bmi_miss admit_nh)*immuno_meds / missing nopercent norow; 
run;

/*Days to admission, and Vitals*/
proc means data=covid.cohort_immuno maxdec=1;
var days_test_to_admit temp_mean pulse_mean saO2_fio2_ratio; 
by immuno_meds; 
run;

proc freq data=covid.cohort_immuno; table respgt22*immuno_meds / missing nopercent norow; run;

/*Labs*/
proc freq data=covid.cohort_immuno;
table (
	elevated_Crp crp_notordered 
	elevated_creatinine creatinine_notordered 
	elevated_troponin troponin_notordered
	high_wbc low_wbc wbc_notordered
	low_albumin albumin_notordered)*immuno_meds / missing nopercent norow;
run;

/*Meds*/
proc means data=covid.cohort_immuno maxdec=1; var rxrisk_sum elix_summary_score_v01; by immuno_meds; run;

/*Specific comorbidities*/
proc freq data=covid.cohort_immuno; 
table (copd rheum renal cancer hiv)*immuno_meds / missing nopercent norow; 
run;  *HIV threw me off at first, but the antivirals are not immunosuppressing so it's ok so many of them are not positive;

/*Elixhauser using our own scoring, not the CCDA's. This is the one Hemal created, and has 0's if people were blank*/

/***************** STOP AND RUN THE "9 STDDIFF" PROGRAM ****************

*THEN COME BACK AND RUN THIS MACRO;
%stddiff(inds = covid.cohort_immuno,
			groupvar=immuno_meds,
			numvars = age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio rxrisk_sum elix_summary_score_v01, 
			charvars = male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
						smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_obese bmi_miss
						admit_nh respgt22 elevated_crp elevated_creatinine elevated_troponin high_wbc low_albumin low_wbc
						copd rheum renal cancer hiv,  
			wtvar = ,
			stdfmt = 8.4,
			outds = stddiff_result);
*/

Title "The propensity score half of the table";
proc sort data=covid.propensity_score; by immuno_meds; run;

proc means data=covid.propensity_score maxdec=1; 
var age_at_positive; 
by immuno_meds; 
weight _ATEWgt_; run;

proc freq data=covid.propensity_score; 
table (male white black other_race hispanic no_hispanic unknown_ethnicity
	el_drug alcohol_yes alcohol_no alcohol_miss
	smoker_yes smoker_former smoker_no smoker_miss)*immuno_meds / missing nopercent norow; 
weight _ATEWgt_; run;
/*
proc means data=covid.propensity_score maxdec=1; 
var bmi;
by immuno_meds; 
weight _ATEWgt_; run;
*/
proc freq data=covid.propensity_score; 
table (bmi_normal bmi_overwt bmi_obese bmi_miss admit_nh)*immuno_meds / missing nopercent norow; 
weight _ATEWgt_; run;

/*Days to admission, and Vitals*/
proc means data=covid.propensity_score maxdec=1;
var days_test_to_admit temp_mean pulse_mean saO2_fio2_ratio; 
by immuno_meds; 
weight _ATEWgt_; run;

proc freq data=covid.propensity_score; 
table respgt22*immuno_meds / missing nopercent norow;
weight _ATEWgt_; run;

/*Labs*/
proc freq data=covid.propensity_score;
table (
	elevated_Crp crp_notordered 
	elevated_creatinine creatinine_notordered 
	elevated_troponin troponin_notordered
	high_wbc low_wbc wbc_notordered
	low_albumin albumin_notordered)*immuno_meds  / missing nopercent norow;
weight _ATEWgt_; run;

/*Meds*/
proc means data=covid.propensity_score maxdec=1; 
var rxrisk_sum elix_summary_score_v01;
by immuno_meds; 
weight _ATEWgt_; run;

/*Specific comorbidities*/
proc freq data=covid.propensity_score;
table (copd rheum renal cancer hiv)*immuno_meds / missing nopercent norow;
weight _ATEWgt_; run;

/***************** STOP AND RUN THE "9 STDDIFF" PROGRAM ****************

*THEN COME BACK AND RUN THIS MACRO;
%stddiff(inds = covid.propensity_score,
			groupvar=immuno_meds,
			numvars = age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio rxrisk_sum elix_summary_score_v01, 
			charvars = week sibley downtown hoco bayview suburban
						male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
						smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_obese bmi_miss
						admit_nh respgt22 elevated_crp elevated_creatinine elevated_troponin high_wbc low_albumin low_wbc
						copd rheum renal cancer hiv,  
			wtvar = _ATEWgt_,
			stdfmt = 8.4,
			outds = stddiff_result);
*/

