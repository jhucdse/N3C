/**********Kayte accessing CROWN data 
June 23, 2020
Objective: Table 2 (Unadjusted clinical outocmes by HCQ use */

libname covid "S:\KAndersen_CCDA_COVID\Immunosuppression";

Title "Table 2";
proc sort data=covid.cohort_immuno; by immuno_meds; run;

*Leaving these as separate tables (not employing the * format) so that we get a p-value for each;
proc freq data=covid.cohort_immuno;
table discharged*immuno_meds / nopercent norow chisq;
run;

proc freq data=covid.cohort_immuno;
table hospitalized*immuno_meds / nopercent norow chisq;
run;
/*To get the date of "remains hospitalized through ..."*/
proc freq data=covid.cohort_immuno; table final_hosp_disch_time; run;

Title "Time to ventilation";
/*Need to exclude DNR/DNI*/
proc freq data=covid.cohort_immuno;
	table ventilator*immuno_meds / nopercent norow chisq;
run;
data a;
set covid.cohort_immuno;
if 0 <= daystovent <2;
run;
proc freq data=a; table immuno_meds; run;
data b; 
set covid.cohort_immuno;
if 2<= daystovent <=7; 
run;
proc freq data=b; table immuno_meds; run;
data c;
set covid.cohort_immuno;
if daystovent > 7; 
run;
proc freq data=c; table immuno_meds; run;

Title "Median time to ventilation";
proc univariate data=covid.cohort_immuno; 
var daystovent; 
by immuno_meds; 
run;
proc npar1way data=covid.cohort_immuno wilcoxon; 
class immuno_meds; 
var daystovent;
run;

/*
Title "Rate of ventilation per patient-days";
proc sql;
	create table persontime as
	select immuno_meds, sum(daystovent) as sum
	from covid.cohort_immuno
	group by immuno_meds;
quit; 
/**************************change the ventilation count where applicable
data persontime_vent;
set persontime;
if immuno_meds=0 then vent=283;
if immuno_meds=1 then vent=13;
rateper100 = (vent*100)/sum;
run;
proc genmod data=persontime_vent;
model rateper100 = immuno_meds; 
run;
*/

proc freq data=covid.cohort_immuno;
table deceased*immuno_meds / nopercent norow chisq;
run;
Title "Time to in-hospital death";
data a;
set covid.cohort_immuno;
if daystodeath <2;
where deceased=1;
run;
proc freq data=a; table immuno_meds; run;
data b; 
set covid.cohort_immuno;
if 2<= daystodeath <=7; 
run;
proc freq data=b; table immuno_meds; run;
data c;
set covid.cohort_immuno;
if daystodeath > 7; 
run;
proc freq data=c; table immuno_meds; run;

Title "Median time to death";
proc univariate data=covid.cohort_immuno; 
var daystodeath; 
by immuno_meds; 
run;
proc npar1way data=covid.cohort_immuno wilcoxon; 
class immuno_meds; 
var daystodeath;
run;

/*
Title "Rate of death per patient-days";
proc sql;
	create table persontime as
	select immuno_meds, sum(daystodeath) as sum
	from covid.cohort_immuno
	group by immuno_meds;
quit; 
/**************************change the death count where applicable
data persontime_death;
set persontime;
if immuno_meds=0 then deaths=184;
if immuno_meds=1 then deaths=11;
rateper100 = (deaths*100)/sum;
run;
proc genmod data=persontime_death;
model rateper100 = immuno_meds; 
run;
*/

Title "Length of stay";
data total_los;
set covid.cohort_immuno;
if lengthofstay ne . then total_los = lengthofstay;
if deceased=1 then total_los=daystodeath;
keep immuno_meds total_los lengthofstay daystodeath;
run;
proc univariate data=total_los; var total_los; run;
/*Wilcoxon rank sum for the p-value for difference in medians*/
proc sort data=total_los; by immuno_meds;
proc univariate data=total_los; 
var total_los; 
by immuno_meds; 
run;
proc npar1way data=total_los wilcoxon; 
class immuno_meds; 
var total_los;
run;

proc univariate data=covid.cohort_immuno;
var lengthofstay;
by immuno_meds;
where discharged=1;
run;
proc npar1way data=covid.cohort_immuno wilcoxon;
class immuno_meds; 
var lengthofstay;
where discharged=1;
run;

proc univariate data=covid.cohort_immuno;
var lengthofstay;
by immuno_meds;
where hospitalized=1;
run;
proc npar1way data=covid.cohort_immuno wilcoxon;
class immuno_meds; 
var lengthofstay;
where hospitalized=1;
run;
/*This is true, even if weird
data check; set covid.cohort_immuno; where immuno_meds=1 and hospitalized=1; run;
proc freq data=check; table pat_status; run; */

proc univariate data=covid.cohort_immuno;
var daystodeath;
by immuno_meds;
where deceased=1;
run;
proc npar1way data=covid.cohort_immuno wilcoxon;
class immuno_meds; 
var daystodeath;
where deceased=1;
run;
