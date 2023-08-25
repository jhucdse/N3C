/**********Kayte, using code that Hemal wrote 
June 2020*/
Title "Objective: Table 3 Association between use and clinical outcomes";

libname covid "S:\KAndersen_CCDA_COVID\Immunosuppression";

*all covariates;
%let independent= week sibley downtown hoco bayview suburban
					age_at_positive days_test_to_admit temp_mean pulse_mean sao2_fio2_ratio rxrisk_sum elix_summary_score_v01 
					male white black other_race hispanic no_hispanic unknown_ethnicity el_drug alcohol_yes alcohol_no alcohol_miss
					smoker_yes smoker_former smoker_no smoker_miss bmi_normal bmi_overwt bmi_obese bmi_miss
					admit_nh respgt22 elevated_crp elevated_creatinine elevated_troponin high_wbc low_albumin low_wbc;

*unbalanced covariates after IPTW;
%let unbalanced= week days_test_to_admit rxrisk_sum elix_summary_score_v01 
					male other_race el_drug
					smoker_former bmi_obese bmi_miss
					temp_mean sao2_fio2_ratio cancer copd;

/********************************************************************************
     Unadjusted and adjusted Fine and Gray's competing risk model - Ventilation
********************************************************************************/
**1. Unadjusted association of immunosuppression with ventilation;
proc phreg data=covid.propensity_score;
	class / param=ref ref=first; 
	model survtime_vent*censor_vent(0) = immuno_meds / eventcode=1 risklimits;
run;

**2. Trimmed IPTW association of immunosuppression with ventilation;
proc phreg data=covid.propensity_score;
	class / param=ref ref=first;
	model survtime_vent*censor_vent(0) = immuno_meds &unbalanced / eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;

**3. Propensity score matched; 
proc phreg data=covid.ps_match;
	model survtime_vent*censor_vent(0) = immuno_meds / eventcode=1 ties=discrete risklimits;
	strata _matchid; 
run;

**4. Adjusting for the propensity score in association of immunosuppression with ventilation;
proc phreg data=covid.propensity_score;
	class / param=ref ref=first;
	model survtime_vent*censor_vent(0) = immuno_meds _ps_ / eventcode=1 risklimits;
run;

/********************************************************************************
              Unadjusted and adjusted Cox model - Death
********************************************************************************/

**1. Unadjusted association of immunosuppression with death;
proc phreg data=covid.cohort_immuno;
	class / param=ref ref=first;
	model survtime_death*censor_death(0) = immuno_meds / eventcode=1 risklimits;
run;

**2. Trimmed IPTW association of immunosuppression with death;
proc phreg data=covid.propensity_score;
	model survtime_death*censor_death(0) = immuno_meds &unbalanced / eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;

**3. Propensity score matched;
proc phreg data=covid.ps_match;
model survtime_death*censor_death(0) = immuno_meds / eventcode=1 ties=discrete risklimits;
	strata _matchid; 
run;

**4. Adjusting for the propensity score in association of immunosuppression with death;
proc phreg data=covid.propensity_score;
	class / param=ref ref=first;
	model survtime_death*censor_death(0) = immuno_meds _ps_ / eventcode=1 risklimits;
run;

/********************************************************************************
     Unadjusted and adjusted linear regression for length of stay
*******************************************************************************

**1. Unadjusted association of immunosuppression with length of stay; 
proc reg data=covid.cohort_immuno;
	model lengthofstay = immuno_meds;
run;

**2. Trimmed IPTW association of immunosuppression with length of stay;
proc reg data=covid.propensity_score;
	model lengthofstay = immuno_meds &unbalanced ;
	*weight _ATEWgt_;
run;

**3. Propensity score matched;
proc genmod data=covid.ps_match;
class _matchid; 
model lengthofstay = immuno_meds;
repeated subject=_matchid / type=exch; 
run;
quit;

**4. Adjusting for the propensity score in association of immunosuppression with ventilation;
proc reg data=covid.propensity_score;
	model lengthofstay = immuno_meds _ps_;
run;

proc univariate data=covid.propensity_score; var lengthofstay; run;
*/

/********************************************************************************
     Unadjusted and adjusted Cox regression for length of stay
*******************************************************************************/
**1. Unadjusted association of immunosuppression with death;
proc phreg data=covid.cohort_immuno;
	class / param=ref ref=first;
	model survtime_los*censor_los(0) = immuno_meds / eventcode=1 risklimits;
run;

**2. Trimmed IPTW association of immunosuppression with death;
proc phreg data=covid.propensity_score;
	model survtime_los*censor_los(0) = immuno_meds &unbalanced / eventcode=1 risklimits;
	weight _ATEWgt_ / normalize;
run;

**3. Propensity score matched;
proc phreg data=covid.ps_match;
model survtime_los*censor_los(0) = immuno_meds / eventcode=1 ties=discrete risklimits;
	strata _matchid; 
run;

**4. Adjusting for the propensity score in association of immunosuppression with death;
proc phreg data=covid.propensity_score;
	class / param=ref ref=first;
	model survtime_los*censor_los(0) = immuno_meds _ps_ / eventcode=1 risklimits;
run;
