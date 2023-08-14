/*Initial data management for CROWN analyses
Kayte Andersen, June 2020*/

libname test odbc noprompt = "Driver={ODBC Driver 17 for SQL Server};Server=https://urldefense.com/v3/__http://ESMPMDBPR4.WIN.AD.JHU.EDU__;!!H9nueQsQ!9rZht_dZrAPm65bwHke-3RRDqFKxL2WcCEGtpooZC4un1mEM9FAQFtxJyniUkMJ9S1vv22xm5yTs2PrnryuX2i5AetqD7Nk$ ,1433; Trusted_Connection=yes;Database=CROWNAlexander_Projection;UID=&id;PWD=&pass" 
schema=dbo;
/*Michael Cook refreshes the "non-curated" tables, Bonnie Woods does the curated tables*/

libname covid "S:\KAndersen_CCDA_COVID\Immunosuppression";      **SAFE desktop folder – permanent library;

data covid.covid_allpersons;
set test.curated_IPevents;
run;
*These are the unique individuals;

Title "Excluding persons who were on a ventilator at admission";
data vent_at_admit;
set test.curated_IPevents;
minutes_to_vent = intck('minute',admit_time,vent_start); 
keep osler_id minutes_to_vent;
run;

Title "Excluding persons with DNR/DNI";
data dnr;
set test.curated_IPEvents;
*Note can't just add 1440 to admission time, it's stored in seconds not minutes --> thanks Natasha for identifying!;
minutes_to_dnr = intck('minute',admit_time,init_dnr_dni);
if minutes_to_dnr =. then delete;
if minutes_to_dnr => 1440 then delete;
dnr=1;
keep osler_id dnr;
run;

Title "Excluding persons who appear dead before admission";
data dead_at_admit;
set test.curated_IPevents;
minutes_to_death = intck('minute',admit_time,death_time); 
keep osler_id minutes_to_death;
run;
proc sort data=dead_at_admit; by minutes_to_death; run;

Title "Medications present at admission";
data admitdate;
set covid.covid_allpersons;
keep osler_id admit_time;
run;
proc sort data=test.derived_med_orders out=all_meds; by osler_id;
proc sort data=admitdate; by osler_id; run;
data covid.meds_at_admission;
merge all_meds admitdate; 
by osler_id; 
if admit_time=. then delete; /*these are people in the hospital but not with COVID*/
if discon_time ne . and discon_time < admit_time then delete; /*discontinued before COVID hospitalization*/
if ordering_dttm >= (admit_time + 21600) then delete; /*ordered within 6 hours (60 seconds per minute * 60 minutes per hour * 6 hours) of admission*/
run;

Title "EXPOSURE DEFINITION: immunocompromised persons on admission to hospital";
/*NOTE this definition is more comprehensive than selective immunosuppressants and corticosteroids used in the HCQ analyses*/
/*On September 2, noticed the "Current_med_yn" filter changed so we have to instead consider stop date and admission date for present at admission*/
data immuno_meds;
set covid.meds_at_admission;
if med_name in:( 
		/*ATC CODE L04AA - SELECTIVE IMMUNOSUPPRESSANTS*/ 'MUROMONAB-CD3', 'ANTILYMPHOCYTE IMMUNOGLOBULIN (HORSE)', 'ANTITHMYOCYTE IMMUNOGLOBULIN (RABBIT)', 'MYCOPHENOLIC ACID'
			'MYCOPHENOLATE SODIUM', 'MYCOPHENOLATE MOFETIL', 'SIROLIMUS', 'LEFLUNOMIDE', 'ALEFACEPT', 'EVEROLIMUS', 'GUSPERIMUS', 'EFALIZUMAB', 'ABETIMUS', 
			'NATALIZUMAB', 'ABATACEPT', 'ECULIZUMAB', 'BELIMUMAB', 'FINGOLIMOD', 'BELATACEPT', 'TOFACITINIB', 'TERIFLUNOMIDE', 'APREMILAST', 'VEDOLIZUMAB', 
			'ALEMTUZUMAB', 'BEGELOMAB', 'OCRELIZUMAB', 'BARICITINIB', 'OZANIMOD', 'EMAPALUMAB', 'CLADRIBINE', 'IMLIFIDASE', 'SIPONIMOD', 'RAVULIZUMAB', 'UPADACITINIB' 
		/*ATC CODE L04AB - TNF ALPHA INHIBITORS*/ 'ETANERCEPT', 'INFLIXIMAB', 'AFELIMOMAB', 'ADALIMUMAB', 'CERTOLIZUMAB PEGOL', 'GOLIMUMAB', 'OPINERCEPT' 
		/*ATC CODE L04AC - INTERLEUKIN INHIBITORS*/ 'DACILUZUMAB', 'BASILIXIMAB', 'ANAKINRA', 'RILONACEPT', 'USTEKINUMAB', 'TOCILIZUMAB', 'CANAKINUMAB', 'BRIAKINUMAB', 
			'SECUKINUMAB', 'SILTUXIMAB', 'BRODALUMAB', 'IXEKIZUMAB', 'SARILUMAB', 'SIRUKUMAB', 'GUSELKUMAB', 'TILDRAKIZUMAB', 'RISANKIZUMAB'
		/*ATC CODE L04AD - CALCINEURIN INHIBITORS*/ 'CICLOSPORIN', 'CYCLOSPORIN', 'TACROLIMUS', 'VOCLOSPORIN', 
		/*ATC CODE L04AX - OTHER IMMUNOSUPPRESSANTS*/ 'AZATHIOPRINE', 'THALIDOMIDE', 'METHOTREXATE', 'LENALIDOMIDE', 'PIRFENIDONE', 'POMALIDOMIDE', 'DIMETHYL FUMARATE', 'DARVADSTROCEL'
		/*CORTICOSTEROIDS*/ 'PREDNISONE', 'METHYLPREDNISOLONE'
		/*L01AA NITROGEN MUSTARD ANALOGUES*/ 'CYCLOPHOSPHAMIDE', 'CHLORAMBUCIL', 'MELPHALAN', 'CHLORMETHINE', 'IFOSFAMIDE', 'TROFOSFAMIDE', 'PREDNIMUSTINE', 'BENDAMUSTINE', 
		/*L01AB ALKYL SULFONATES*/ 'BUSULFAN', 'TREOSULFAN', 'MANNOSULFAN', 
		/*L01AC ETHYLENE IMINES*/ 'THIOTEPA', 'TRIAZIQUONE', 'CARBOQUONE', 
		/*L01AD NITROSOUREAS*/ 'CARMUSTINE', 'LOMUSTINE', 'SEMUSTINE', 'STREPTOZOCIN', 'FOTEMUSTINE', 'NIMUSTINE', 'RANIMUSTINE', 'URAMUSTINE', 
		/*L01AG EPOXIDES*/ 'ETOGLUCID', 
		/*L01AX OTHER ALKYLATING AGENTS*/ 'MITOBRONITOL', 'PIPOBROMAN', 'TEMOZOLOMIDE', 'DACARBAZINE', 
		/*L01BA FOLIC ACID ANALOGUES*/ 'METHOTREXATE', 'RALTITREXED', 'PEMETREXED', 'PRALATREXATE', 
		/*L01BB PURINE ANALOGUES*/ 'MERCAPTOPURINE', 'TIOGUANINE', 'CLADRIBINE', 'FLUDARABINE', 'CLOFARABINE', 'NELARABINE', 'RABACFOSADINE', 
		/*L01BC PYRIMIDINE ANALOGUES*/ 'CYTARABINE', 'FLUOROURACIL', 'TEGAFUR', 'CARMOFUR', 'GEMCITABINE', 'CAPECITABINE', 'AZACITIDINE', 'DECITABINE', 'FLOXURIDINE', 'FLUOROURACIL',
						'TEGAFUR', 'TRIFLURIDINE', 
		/*L01CA VINCA ALKALOIDS AND ANALOGUES*/ 'VINBLASTINE', 'VINCRISTINE', 'VINDESINE', 'VINORELBINE', 'VINFLUNINE', 'VINTAFOLIDE', 
		/*L01CB PODOPHYLLOTOXIN DERIVATIVES*/ 'ETOPOSIDE', 'TENIPOSIDE', 
		/*L01CC COLCHICINE DERIVATIVES*/ 'DEMECOLCINE', 
		/*L01CD TAXANES*/ 'PACLITAXEL', 'DOCETAXEL', 'PACLITAXEL POLIGLUMEX', 'CABAZITAXEL', 
		/*L01CX OTHER PLANT ALKALOIDS AND NATURAL PRODUCTS*/ 'TRABECTEDIN', 
		/*L01DA ACTINOMYCINES*/ 'DACTINOMYCIN', 
		/*L01DB ANTHRACYCLINES AND RELATED SUBSTANCES*/ 'DOXORUBICIN', 'DAUNORUBICIN', 'EPIRUBICIN', 'ACLARUBICIN', 'ZORUBICIN', 'IDARUBICIN', 'MITOXANTRONE', 'PIRARUBICIN', 
						'VALRUBICIN', 'AMRUBICIN', 'PIXANTRONE', 
		/*L01DC OTHER CYTOTOXIC ANTIBIOTICS*/ 'BLEOMYCIN', 'PLICAMYCIN', 'MITOMYCIN', 'IXABEPILONE', 
		/*L01XA PLATINUM COMPOUNDS*/ 'CISPLATIN', 'CARBOPLATIN', 'OXALIPLATIN', 'SATRAPLATIN', 'POLYPLATILLEN', 
		/*L01XB METHYLHYDRAZINES*/ 'PROCARBAZINE', 
		/*L01XC MONOCLONAL ANTIBODIES*/ 'EDRECOLOMAB', 'RITUXIMAB', 'TRASTUZUMAB', 'GEMTUZUMAB OZOGAMICIN', 'CETUXIMAB', 'BEVACIZUMAB', 'PANITUMUMAB', 'CATUMAXOMAB', 'OFATUMUMAB', 
						'IPILIMUMAB', 'BRENTUXIMAB VEDOTIN', 'PERTUZUMAB', 'TRASTUZUMAB EMTANSINE', 'OBINUTUZUMAB', 'DINUTUXIMAB BETA', 'NIVOLUMAB', 'PEMBROLIZUMAB', 'BLINATUMOMAB', 
						'RAMUCIRUMAB', 'NECITUMUMAB', 'ELOTUZUMAB', 'DARATUMUMAB', 'MOGAMULIZUMAB', 'INOTUZUMAB OZOGAMICIN', 'OLARATUMAB', 'DURVALUMAB', 'BERMEKIMAB', 'AVELUMAB', 
						'ATEZOLIZUMAB', 'CEMIPLIMAB', 
		/*L01XD SENSITIZERS USED IN PHOTODYNAMIC/RADIATION THERAPY*/ 'PORFIMER SODIUM', 'METHYL AMINOLEVULINATE', 'AMINOLEVULINIC ACID', 'TEMOPORFIN', 'EFAPROXIRAL', 'PADELIPORFIN', 
		/*L01XE PROTEIN KINASE INHIBITORS*/ 'IMATINIB', 'GEFITINIB', 'ERLOTINIB', 'SUNITINIB', 'SORAFENIB', 'DASATINIB', 'LAPATINIB', 'NILOTINIB', 'TEMSIROLIMUS', 'EVEROLIMUS', 
						'PAZOPANIB', 'VANDETANIB', 'AFATINIB', 'BOSUTINIB', 'VEMURAFENIB', 'CRIZOTINIB', 'AXITINIB', 'RUXOLITINIB', 'RIDAFOROLIMUS', 'REGORAFENIB', 'MASITINIB', 
						'DABRAFENIB', 'PONATINIB', 'TRAMETINIB', 'CABOZANTINIB', 'IBRUTINIB', 'CERITINIB', 'LENVATINIB', 'NINTEDANIB', 'CEDIRANIB', 'PALBOCICLIB', 'TIVOZANIB', 
						'OSIMERTINIB', 'ALECTINIB', 'ROCILETINIB', 'COBIMETINIB', 'MIDOSTAURIN', 'OLMUTINIB', 'BINIMETINIB', 'RIBOCICLIB', 'BRIGATINIB', 'LORLATINIB', 'NERATINIB', 
						'ENCORAFENIB', 'DACOMITINIB', 'ICOTINIB', 'ABEMACICLIB', 'ACALABRUTINIB', 'QUIZARTINIB', 'LAROTRECTINIB', 'GILTERITINIB', 'ENTRECTINIB', 'FEDRATINIB', 
						'TOCERANIB', 
		/*L01XX OTHER ANTINEOPLASTIC AGENTS*/ 'AMSACRINE', 'ASPARAGINASE', 'ALTRETAMINE', 'HYDROXYCARBAMIDE', 'LONIDAMINE', 'PENTOSTATIN', 'MASOPROCOL', 'ESTRAMUSTINE', /*'TRETINOIN',*/ 
						'MITOGUAZONE', 'TOPOTECAN', 'TIAZOFURINE', 'IRINOTECAN', 'ALITRETINOIN', 'MITOTANE', 'PEGASPARGASE', 'BEXAROTENE', 'ARSENIC TRIOXIDE', 'DENILEUKIN DIFTITOX', 
						'BORTEZOMIB', 'ANAGRELIDE', 'OBLIMERSEN', 'SITIMAGENE CERADENOVEC', 'VORINOSTAT', 'ROMIDEPSIN', 'OMACETAXINE MEPESUCCINATE', 'ERIBULIN', 'PANOBINOSTAT', 
						'VISMODEGIB', 'AFLIBERCEPT', 'CARFILZOMIB', 'OLAPARIB', 'IDELALISIB', 'SONIDEGIB', 'BELINOSTAT', 'IXAZOMIB', 'TALIMOGENE LAHERPAREPVEC', 'VENETOCLAX', 
						'VOSAROXIN', 'NIRAPARIB', 'RUCAPARIB', 'ETIRINOTECAN PEGOL', 'PLITIDEPSIN', 'EPACADOSTAT', 'ENASIDENIB', 'TALAZOPARIB', 'COPANLISIB', 'IVOSIDENIB', 
						'GLASDEGIB', 'ENTINOSTAT', 'ALPELISIB', 'SELINEXOR', 'TAGRAXOFUSP', 'BELOTECAN', 'TIGILANOL TIGLATE', 
		/*L01XY COMBINATIONS OF ANTINEOPLASTIC AGENTS*/ 'CYTARABINE'
 ) ;
immuno_med_name=med_name;
immuno_dose=dose; /*There's a lot of missing for the dose (aka how many pills) with pred 2.5mg or 5mg*/
immuno_frequency=frequency;
immuno_meds=1;
if med_name="BEVACIZUMAB 1.25 MG/0.05 ML INTRAVITREAL INJECTION" then delete;
if med_name="CYCLOSPORINE 0.05 % EYE DROPS IN A DROPPERETTE" then delete;
if med_name="METHYLPREDNISOLONE 4 MG TABLET" then delete;
if med_name="METHYLPREDNISOLONE 4 MG TABLETS IN A DOSE PACK" then delete;
if med_name="METHYLPREDNISOLONE SOD SUCC (PF) 40 MG/ML SOLUTION FOR INJECTION" then delete;
if med_name="METHYLPREDNISOLONE SOD SUCC (PF) 125 MG/2 ML SOLUTION FOR INJECTION" then delete;
if med_name="METHYLPREDNISOLONE IVPB (JHH, BMC)" then delete;
if med_name="MITOMYCIN 0.2 MG/ML OPHTHALMIC SOLUTION (GLAUCOMA SURGERY)" then delete;
if med_name="PREDNISONE 1 MG TABLET" then delete;
if med_name="PREDNISONE 2 MG TABLET,DELAYED RELEASE" then delete;
if med_name="PREDNISONE 2.5 MG TABLET" then delete;
if med_name="PREDNISONE 5 MG TABLET" then delete;
if med_name="PREDNISONE 5 MG/5 ML ORAL SOLUTION (DISP CODE)" then delete;
if med_name="PREDNISONE 5 MG/5 ML ORAL SOLUTION" then delete;
if med_name="RITUXIMAB 1 MG/0.1 ML INTRAVITREAL INJ" then delete;
if med_name="TRIFLURIDINE 1 % EYE DROPS" then delete;
if med_name="TACROLIMUS 0.1 % TOPICAL OINTMENT" then delete; /*indication = eczema*/
if med_name="TOCILIZUMAB IVPB IN 100 ML NS" then delete; /*This is experimental inpatient protocol*/
keep osler_id immuno_med_name immuno_dose immuno_frequency immuno_meds ordering_dttm discon_time auth_prov;
run; 
proc sort data=immuno_meds nodupkey out=covid.immuno_meds_withduplicates; by osler_id immuno_med_name; run;
proc freq data=covid.immuno_meds_withduplicates; table immuno_med_name; run;
proc sort data=covid.immuno_meds_withduplicates nodupkey out=immuno_med_unique2; by osler_id; run;
*See separate file for checking that previously identified persons are still picked up as immunosuppressed, given change in coding algorithm;

/*There are 4 different comorbidity tables, and they all differ from each other
For the sake of completeness, will pull each one
These definitions are from the AHRQ QI Prevention Quality Indicators APPENDIX C*/
data one;
set test.derived_problem_list;
if icd10_code in:( /*page 1*/ 'B20', 'B59', 'C80.2', 'C88.8', 'C94.40', 'C94.41', 'C94.42', 'C94.6', 'D46.22', 'D47.1', 'D47.9', 'D47.Z1', 'I13.11', 'I13.2', 'K91.2',
		'M35.9', 'N18.5', 'N18.6', 'T86.00', 'T86.01', 'T86.02', 'T86.03', 'T86.09', 'T86.10', /*page 2*/ 'D47.Z9', 'D61.09', 'D61.810', 'D61.811', 'D61.818', 'D70.0', 
		'D70.1', 'D70.2', 'D70.4', 'D70.8', 'D70.9', 'D71', 'D72.0', 'D72.810', 'T86.11', 'T86.12', 'T86.13', 'T86.19', 'T86.20', 'T86.21', 'T86.22', 'T86.23', 'T86.290', 
		'T86.298', 'T86.30', 'T86.31', 'T86.32', 'T86.33', /*page 3*/ 'D72.818', 'D72.819', 'D73.81', 'D75.81', 'D76.1', 'D76.2', 'D76.3', 'D80.0', 'D80.1', 'D80.2', 
		'D80.3', 'D80.4', 'D80.5', 'D80.6', 'T86.39', 'T86.40', 'T86.41', 'T86.42', 'T86.43', 'T86.49', 'T86.5', 'T86.810', 'T86.811', 'T86.812', 'T86.818', 'T86.819', 
		'T86.830', 'T86.831', /*page 4*/ 'D80.7', 'D80.8', 'D80.9', 'D81.0', 'D81.1', 'D81.2', 'D81.4', 'D81.6', 'D81.7', 'D81.89', 'D81.9', 'D82.0', 'D82.1', 'D82.2', 
		'T86.832', 'T86.838', 'T86.839', 'T86.850', 'T86.851', 'T86.852', 'T86.858', 'T86.859', 'T86.890', 'T86.891', 'T86.892', 'T86.898', 'T86.899', 'T86.90', 
		/*page 5*/ 'D82.3', 'D82.4', 'D82.8', 'D82.9', 'D83.0', 'D83.1', 'D83.2', 'D83.8', 'D83.9', 'D84.0', 'D84.1', 'D84.8', 'D84.9', 'D89.3', 'T86.91', 'T86.92', 
		'T86.93', 'T86.99', 'Z48.21', 'Z48.22', 'Z48.23', 'Z48.24', 'Z48.280', 'Z48.290', 'Z48.298', 'Z49.01', 'Z49.02', 'Z49.31', /*page 6*/ 'D89.810', 'D89.811', 
		'D89.812', 'D89.813', 'D89.82', 'D89.89', 'D89.9', 'E40', 'E41', 'E42', 'E43', 'I12.0', 'Z94.0', 'Z94.1', 'Z94.2', 'Z94.3', 'Z94.4', 'Z94.81', 'Z94.82', 
		'Z94.83', 'Z94.84', 'Z94.89', 'Z99.2' /*the rest of the document is procedure codes not diagnosis codes*/
 ) ;
run;
proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;

data two;
set test.derived_medical_hx_summary;
if icd10_code in:( /*page 1*/ 'B20', 'B59', 'C80.2', 'C88.8', 'C94.40', 'C94.41', 'C94.42', 'C94.6', 'D46.22', 'D47.1', 'D47.9', 'D47.Z1', 'I13.11', 'I13.2', 'K91.2',
		'M35.9', 'N18.5', 'N18.6', 'T86.00', 'T86.01', 'T86.02', 'T86.03', 'T86.09', 'T86.10', /*page 2*/ 'D47.Z9', 'D61.09', 'D61.810', 'D61.811', 'D61.818', 'D70.0', 
		'D70.1', 'D70.2', 'D70.4', 'D70.8', 'D70.9', 'D71', 'D72.0', 'D72.810', 'T86.11', 'T86.12', 'T86.13', 'T86.19', 'T86.20', 'T86.21', 'T86.22', 'T86.23', 'T86.290', 
		'T86.298', 'T86.30', 'T86.31', 'T86.32', 'T86.33', /*page 3*/ 'D72.818', 'D72.819', 'D73.81', 'D75.81', 'D76.1', 'D76.2', 'D76.3', 'D80.0', 'D80.1', 'D80.2', 
		'D80.3', 'D80.4', 'D80.5', 'D80.6', 'T86.39', 'T86.40', 'T86.41', 'T86.42', 'T86.43', 'T86.49', 'T86.5', 'T86.810', 'T86.811', 'T86.812', 'T86.818', 'T86.819', 
		'T86.830', 'T86.831', /*page 4*/ 'D80.7', 'D80.8', 'D80.9', 'D81.0', 'D81.1', 'D81.2', 'D81.4', 'D81.6', 'D81.7', 'D81.89', 'D81.9', 'D82.0', 'D82.1', 'D82.2', 
		'T86.832', 'T86.838', 'T86.839', 'T86.850', 'T86.851', 'T86.852', 'T86.858', 'T86.859', 'T86.890', 'T86.891', 'T86.892', 'T86.898', 'T86.899', 'T86.90', 
		/*page 5*/ 'D82.3', 'D82.4', 'D82.8', 'D82.9', 'D83.0', 'D83.1', 'D83.2', 'D83.8', 'D83.9', 'D84.0', 'D84.1', 'D84.8', 'D84.9', 'D89.3', 'T86.91', 'T86.92', 
		'T86.93', 'T86.99', 'Z48.21', 'Z48.22', 'Z48.23', 'Z48.24', 'Z48.280', 'Z48.290', 'Z48.298', 'Z49.01', 'Z49.02', 'Z49.31', /*page 6*/ 'D89.810', 'D89.811', 
		'D89.812', 'D89.813', 'D89.82', 'D89.89', 'D89.9', 'E40', 'E41', 'E42', 'E43', 'I12.0', 'Z94.0', 'Z94.1', 'Z94.2', 'Z94.3', 'Z94.4', 'Z94.81', 'Z94.82', 
		'Z94.83', 'Z94.84', 'Z94.89', 'Z99.2' /*the rest of the document is procedure codes not diagnosis codes*/
 ) ;
run;
proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;

data three;
set test.derived_encounter_dx;
if icd10_code in:( /*page 1*/ 'B20', 'B59', 'C80.2', 'C88.8', 'C94.40', 'C94.41', 'C94.42', 'C94.6', 'D46.22', 'D47.1', 'D47.9', 'D47.Z1', 'I13.11', 'I13.2', 'K91.2',
		'M35.9', 'N18.5', 'N18.6', 'T86.00', 'T86.01', 'T86.02', 'T86.03', 'T86.09', 'T86.10', /*page 2*/ 'D47.Z9', 'D61.09', 'D61.810', 'D61.811', 'D61.818', 'D70.0', 
		'D70.1', 'D70.2', 'D70.4', 'D70.8', 'D70.9', 'D71', 'D72.0', 'D72.810', 'T86.11', 'T86.12', 'T86.13', 'T86.19', 'T86.20', 'T86.21', 'T86.22', 'T86.23', 'T86.290', 
		'T86.298', 'T86.30', 'T86.31', 'T86.32', 'T86.33', /*page 3*/ 'D72.818', 'D72.819', 'D73.81', 'D75.81', 'D76.1', 'D76.2', 'D76.3', 'D80.0', 'D80.1', 'D80.2', 
		'D80.3', 'D80.4', 'D80.5', 'D80.6', 'T86.39', 'T86.40', 'T86.41', 'T86.42', 'T86.43', 'T86.49', 'T86.5', 'T86.810', 'T86.811', 'T86.812', 'T86.818', 'T86.819', 
		'T86.830', 'T86.831', /*page 4*/ 'D80.7', 'D80.8', 'D80.9', 'D81.0', 'D81.1', 'D81.2', 'D81.4', 'D81.6', 'D81.7', 'D81.89', 'D81.9', 'D82.0', 'D82.1', 'D82.2', 
		'T86.832', 'T86.838', 'T86.839', 'T86.850', 'T86.851', 'T86.852', 'T86.858', 'T86.859', 'T86.890', 'T86.891', 'T86.892', 'T86.898', 'T86.899', 'T86.90', 
		/*page 5*/ 'D82.3', 'D82.4', 'D82.8', 'D82.9', 'D83.0', 'D83.1', 'D83.2', 'D83.8', 'D83.9', 'D84.0', 'D84.1', 'D84.8', 'D84.9', 'D89.3', 'T86.91', 'T86.92', 
		'T86.93', 'T86.99', 'Z48.21', 'Z48.22', 'Z48.23', 'Z48.24', 'Z48.280', 'Z48.290', 'Z48.298', 'Z49.01', 'Z49.02', 'Z49.31', /*page 6*/ 'D89.810', 'D89.811', 
		'D89.812', 'D89.813', 'D89.82', 'D89.89', 'D89.9', 'E40', 'E41', 'E42', 'E43', 'I12.0', 'Z94.0', 'Z94.1', 'Z94.2', 'Z94.3', 'Z94.4', 'Z94.81', 'Z94.82', 
		'Z94.83', 'Z94.84', 'Z94.89', 'Z99.2' /*the rest of the document is procedure codes not diagnosis codes*/
 ) ;
run;
proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;

/*The format for icd10list is not conducive to a search --> returned 0 observations
data four;
set test.derived_emr_diagnosis_info;
if icd10list in:( 'B20', 'B59', 'C802', 'C888', 'C944', 'C946', 'D4622', 'D47', 'D61', 'D70', 'D71', 'D72', 'D7381', 'D7581', 'D76', 'D80', 'D81', 'D82', 'D83', 'D84', 'D89', 
		'E40', 'E41', 'E42', 'E43', 'I120', 'I1311', 'I132', 'K912', 'M349', 'N185', 'N186', 'T86', 'Z48.2', 'Z49', 'Z94', 'Z992' 
 ) ;
run;
*/
data immuno;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=immuno; by osler_id; run;
proc sort data=a; by osler_id; run;
data immuno_diagnoses;
merge immuno a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
immuno_diagnosis=1;
run;
proc sort data=immuno_diagnoses nodupkey; by osler_id icd10_code; run;
proc freq data=immuno_diagnoses order=freq; table dx_name; run;
proc sort data=immuno_diagnoses out=counting nodupkey; by osler_id; run;
data covid.all_immuno;
merge immuno_med_unique2 counting; 
by osler_id; 
immunocomp=1; /*so 1 will be the exposure of interest of immunocompromised*/
immuno_icd10_code = icd10_code;
run;
proc sort data=covid.all_immuno nodupkey out=exposure_def(keep=osler_id immuno_meds immuno_med_name immuno_diagnosis immuno_icd10_code immunocomp) ; by osler_id; run;

Title "Alcohol and smoking";
data alcohol_smoke;
set test.derived_social_history_changes;
keep osler_id tobacco_user alcohol_use;
run;
/*Notice that we have people with repeated rows, and they have discrepancies: 245e7... is recorded as never and former smoker, and as yes and no to alcohol
To be conservative, any instance of YES should be prioritized
A clever way around this will be reverse alphabetical sorting */
proc sort data=alcohol_smoke; by osler_id descending tobacco_user descending alcohol_use; run;
proc sort data=alcohol_smoke out=alcohol_smoke_2 nodupkey; by osler_id; run;

Title "Setting up the vitals within 24h of admission";
/*From Jacob Fiksel: they took the average of measurements over the first 24h from admission, 
except for temperature which they took the max within 24 hours*/

*Need the admission time for sorting the curated vitals within 24 hours of admission;
/*Some people had multiple admissions, we want the first one*/
proc sort data=test.derived_inpatient_encounters out=admit_info; by osler_id adt_arrival_time; run;
proc sort data=admit_info nodupkey; by osler_id; run;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;

proc sort data=a; by osler_id; run;
proc sort data=test.curated_IPVitals out=vitals_all; by osler_id; run;
data covid.vitals_24h;
merge a vitals_all;
by osler_id;
vital_timesinceadmit = intck('minute',admit_time,recorded_time); /*This is time in minutes since admission*/
if vital_timesinceadmit > 1440 then delete; *24 hours is 24*60 = 1440 minutes;
if resp_rate >22 then respgt22=1; else if resp_rate<=22 then respgt22=0;
run; /*checked it by manually calculating for the first row, works well*/

Title "Resp rate";
proc summary data=covid.vitals_24h; 
var respgt22; 
by osler_id;
output out=b;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data resp;
set b;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Mean pulse";
proc means data=covid.vitals_24h noprint;
var pulse;
by osler_id; 
output out=pulse; 
run;
data pulse_2;
set pulse;
drop _TYPE_ _FREQ_;
if _STAT_ = "N" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ ="MAX" then delete;
run;
proc transpose data=pulse_2 out=pulse_3; by osler_id; run;
data pulse_4;
set pulse_3;
pulse_mean=col1; 
drop _NAME_ _LABEL_ col1 col2;
run;

Title "Mean temperature";
proc means data=covid.vitals_24h noprint;
var temp_c;
by osler_id; 
output out=temp; 
run;
data temp_2;
set temp;
drop _TYPE_ _FREQ_;
if _STAT_ = "N" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ ="MAX" then delete;
run;
proc transpose data=temp_2 out=temp_3; by osler_id; run;
data temp_4;
set temp_3;
temp_mean=col1; 
drop _NAME_ _LABEL_ col1 col2;
run;

Title "Lab results";
/*From Jacob Fiksel: they used +/- 2 days of admission, which is 24*60*2 = 2880 minutes*/
proc sort data=a; by osler_id; run; *This is the admission date;
data covid.labs_2days;
merge a (in=in1) test.derived_lab_results; 
by osler_id; 
if in1;
lab_timesinceadmit = intck('minute',admit_time,specimen_taken_time); /*This is time in minutes since admission*/
if lab_timesinceadmit > 2880 then delete;
if lab_timesinceadmit < -2880 then delete;
run;
*to check;
proc univariate data=covid.labs_2days; var lab_timesinceadmit; run; /*good, we truly have only +/- 2 days*/
proc freq data=covid.labs_2days order=freq; table loinc_desc; run;

Title "SA02/FIO2 within 24h of admission";
*Kayte "translated" Jacob's code (in create_data_for_models.R) into SAS code;
*I was getting ratios around 1, but it seems like there needs to be data management to get the 200-500 range;
data fio2;
set covid.vitals_24h;
*data quality;
if flow_lmin > 100 then flow_lmin=.;
if O2_device="None-RoomAir" then flow_lmin=0;
if fio2_pct< 20 then fio2_pct=.;
if fio2_pct>100 then fio2_pct=.;
*FIO2;
if flow_lmin <= 6 then fio2=(20+(4*flow_lmin))/100;
else if 6 < flow_lmin <=10 then fio2=(44+((80-44)/4)*(flow_lmin - 6))/100;
else if 10 < flow_lmin <=15 then fio2=(80+((90-80)/5)*(flow_lmin - 10))/100;
if fio2_pct ne . then fio2=(fio2_pct/100);
*Ultimately, we are doing pulse_ox_sat / FIO2;
sao2_fio2_ratio=pulse_ox_sat / fio2;
keep osler_id pulse_ox_sat fio2_pct flow_lmin o2_device fio2 sao2_fio2_ratio; 
run;
proc sort data=fio2; by flow_lmin; run; /*looks good, hand checked flow_lmin = 3, 7 and 12*/
proc univariate data=fio2; var sao2_fio2_ratio; run; /*good, ranging in the 200's to 500 like we had needed it to be, from the Zeger preprint*/

proc sort data=fio2; by osler_id; run;
*Mean in the 24 hours;
proc summary data=fio2; 
var sao2_fio2_ratio;
by osler_id;
output out=fio2_mean;
run;
data fio2_mean_3;
set fio2_mean;
if _STAT_ = "N" then delete;
if _STAT_ ="MAX" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Creatinine";
data creatinine;
set covid.labs_2days;
where COMPONENT_NAME contains "CREATININE";
if result_flag="High" then elevated_creatinine=1; else elevated_creatinine=0;
run;
proc summary data=creatinine; 
var elevated_creatinine; 
by osler_id;
output out=creatinine_2;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data creatinine_3;
set creatinine_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "AST";
data ast;
set covid.labs_2days;
where COMPONENT_NAME contains "ASPARTATE";
if result_flag="High" then elevated_ast=1; else elevated_ast=0;
run;
proc summary data=ast; 
var elevated_ast; 
by osler_id;
output out=ast_2;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data ast_3;
set ast_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "D-Dimer";
data ddimer;
set covid.labs_2days;
where COMPONENT_NAME contains "DIMER";
if result_flag="High" or result_flag="High Panic" then elevated_ddimer=1; 
else elevated_ddimer=0;
run;
proc summary data=ddimer; 
var elevated_ddimer; 
by osler_id;
output out=ddimer_2;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data ddimer_3;
set ddimer_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Troponin";
data troponin;
set covid.labs_2days;
where COMPONENT_NAME contains "TROPONIN";
if result_flag="High" or result_flag="High Panic" then elevated_troponin=1; 
else elevated_troponin=0;
run;
proc summary data=troponin; 
var elevated_troponin; 
by osler_id;
output out=troponin_2;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data troponin_3;
set troponin_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Low albumin";
data albumin;
set covid.labs_2days;
where COMPONENT_NAME contains "ALBUMIN";
if result_flag="Low" or result_flag="Low Panic" then low_albumin=1; else low_albumin=0;
keep osler_id low_albumin;
run;
proc summary data=albumin; 
var low_albumin; 
by osler_id;
output out=albumin_2;
run; /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data albumin_3;
set albumin_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Elevated CRP";
data crp;
set covid.labs_2days;
where COMPONENT_NAME contains "C-REACTIVE PROTEIN";
if result_flag="High" then elevated_crp=1; else elevated_crp=0;
keep osler_id elevated_crp;
run;
proc summary data=crp;
var elevated_crp;
by osler_id; 
output out=crp_2;
run;  /*These are count variables, so we want the max (aka whether a 1 occured or not)*/
data crp_3;
set crp_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "Lymphocyte";
data lymphocyte;
set covid.labs_2days;
where COMPONENT_NAME contains "WHITE BLOOD CELL COUNT"; *The WBC without the word count is for urinalysis;
if result_flag="Low" or result_flag="Low Panic" then low_wbc=1; else low_wbc=0;
if result_flag="High" or result_flag="High Panic" then high_wbc=1; else high_wbc=0;
run;
proc summary data=lymphocyte;
var low_wbc high_wbc; 
by osler_id;
output out=lymphocyte_2;
run;
data lymphocyte_3;
set lymphocyte_2;
if _STAT_ = "N" then delete;
if _STAT_ ="MEAN" then delete;
if _STAT_ ="MIN" then delete;
if _STAT_ = "STD" then delete;
drop _TYPE_ _FREQ_ _STAT_;
run;

Title "RxRISK score";
data rxrisk_1;
set covid.meds_at_admission;
/*ALCOHOL DEPENDENCY*/
IF MED_NAME IN:('DISULFIRAM', 'CALCIUM CARBIMIDE', 'ACAMPROSATE', 'NALTREXONE', 'NALMEFENE') THEN RXRISK=6;
/*ALLERGIES*/
IF MED_NAME IN:('CROMOGLICIC ACID', 'LEVOCABASTINE', 'AZELASTINE', 'ANTAZOLINE', 'SPAGLUMIC ACID', 'THONZYLAMINE', 'NEDOCROMIL', 'OLOPATADINE', 'BECLOMETASONE', 
	'PREDNISOLONE', 'DEXAMETHASONE', 'FLUNISOLIDE', 'BUDESONIDE', 'BETAMETHASONE', 'TIXOCORTOL', 'FLUTICASONE', 'MOMETASONE', 'TRIAMCINOLONE', 'FLUTICASONE FUROATE', 'CICLESONIDE', 
	'ALIMEMAZINE', 'PROMETHAZINE', 'PROMETHAZINE', 'THIETHYLPERAZINE', 'METHDILAZINE', 'HYDROXYETHYLPROMETHAZINE', 'THIAZINAM', 'MEQUITAZINE', 'OXOMEMAZINE', 'ISOTHIPENDYL', 
	'BUCLIZINE', 'CHLORCYCLIZINE', 'MECLOZINE', 'OXATOMIDE', 'CETIRIZINE', 'LEVOCETIRIZINE', 'BAMIPINE', 'CYPROHEPTADINE', 'THENALIDINE', 'PHENINDAMINE', 'ANTAZOLINE', 
	'TRIPROLIDINE', 'PYRROBUTAMINE', 'AZATADINE', 'ASTEMIZOLE', 'TERFENADINE', 'LORATADINE', 'MEBHYDROLIN', 'DEPTROPINE', 'KETOTIFEN', 'ACRIVASTINE', 'AZELASTINE', 'TRITOQUALINE', 
	'EBASTINE', 'PIMETHIXENE', 'EPINASTINE', 'MIZOLASTINE', 'FEXOFENADINE', 'DESLORATADINE') THEN RXRISK=-1;
/*ANTICOAGULANTS*/
IF MED_NAME IN:('HEPARIN', 'ANTITHROMBIN', 'DALTEPARIN', 'ENOXAPARIN', 'NADROPARIN', 'DABIGATRAN', 'RIVAROXABAN', 'APIXABAN', 'FONDAPARINUX') THEN RXRISK=1;
/*ANTIPLATELETS*/
IF MED_NAME IN:('CLOPIDOGREL', 'TICLOPIDINE', 'ACETYLSALICYLIC ACID', 'DIPYRIDAMOLE', 'CARBASALATE CALCIUM', 'EPOPROSTENOL', 'INDOBUFEN', 'ILOPROST', 'ABCIXIMAB', 'ALOXIPRIN', 
	'EPTIFIBATIDE', 'TIROFIBAN', 'TRIFLUSAL', 'BERAPROST', 'TREPROSTINIL', 'PRASUGREL', 'CILOSTAZOL', 'TICAGRELOR', 'CANGRELOR', 'VORAPAXAR', 'SELEXIPAG') THEN RXRISK=2;
/*ANXIETY*/
IF MED_NAME IN:('DIAZEPAM', 'CHLORDIAZEPOXIDE', 'MEDAZEPAM', 'OXAZEPAM', 'POTASSIUM CLORAZEPATE', 'LORAZEPAM', 'ADINAZOLAM', 'BROMAZEPAM', 'CLOBAZAM', 'KETAZOLAM', 'PRAZEPAM', 
	'ALPRAZOLAM', 'BUSPIRONE') THEN RXRISK=1;
/*ARRHYTHMIA*/
IF MED_NAME IN:('QUINIDINE', 'PROCAINAMIDE', 'DISOPYRAMIDE', 'SPARTEINE', 'AJMALINE', 'PRAJMALINE', 'LORAJMINE', 'HYDROQUINIDINE', 'LIDOCAINE', 'MEXILETINE', 'TOCAINIDE', 
	'APRINDINE', 'PROPAFENONE', 'FLECAINIDE','LORCAINIDE', 'ENCAINIDE', 'ETHACIZINE', 'AMIODARONE', 'SOTALOL') THEN RXRISK=2;
/*BIPOLAR DISORDER*/
IF MED_NAME IN:('LITHIUM') THEN RXRISK=-1;
/*CHRONIC AIRWAYS DISEASE*/
IF MED_NAME IN:('SALBUTAMOL', 'TERBUTALINE', 'FENOTEROL', 'RIMITEROL', 'HEXOPRENALINE', 'ISOETARINE', 'PIRBUTEROL', 'TRETOQUINOL', 'CARBUTEROL', 'TULOBUTEROL', 'SALMETEROL', 
	'FORMOTEROL', 'CLENBUTEROL', 'REPROTEROL', 'PROCATEROL', 'BITOLTEROL', 'INDACATEROL', 'OLODATEROL', 'BECLOMETASONE', 'BUDESONIDE', 'FLUNISOLIDE', 'BETAMETHASONE', 'FLUTICASONE', 
	'TRIAMCINOLONE', 'MOMETASONE', 'CICLESONIDE', 'FLUTICASONE FUROATE', 'IPRATROPIUM BROMIDE', 'OXITROPIUM BROMIDE', 'STRAMONI', 'TIOTROPIUM BROMIDE', 'ACLIDINIUM BROMIDE', 
	'GLYCOPYRRONIUM BROMIDE', 'UMECLIDINIUM BROMIDE', 'REVEFENACIN', 'CROMOGLICIC ACID', 'NEDOCROMIL', 'FENSPIRIDE', 'ISOPRENALINE', 'METHOXYPHENAMINE', 'ORCIPRENALINE', 
	'SALBUTAMOL', 'TERBUTALINE', 'FENOTEROL', 'HEXOPRENALINE', 'ISOETARINE', 'PIRBUTEROL', 'PROCATEROL', 'TRETOQUINOL', 'CARBUTEROL', 'TULOBUTEROL', 'BAMBUTEROL', 'CLENBUTEROL', 
	'REPROTEROL', 'DIPROPHYLLINE', 'CHOLINE THEOPHYLLINATE', 'PROXYPHYLLINE', 'THEOPHYLLINE', 'AMINOPHYLLINE', 'ETAMIPHYLLINE', 'THEOBROMINE', 'BAMIFYLLINE', 'ACEFYLLINE PIPERAZINE', 
	'BUFYLLINE', 'DOXOFYLLINE', 'MEPYRAMINE THEOPHYLLINACETATE', 'ZAFIRLUKAST', 'PRANLUKAST', 'MONTELUKAST') THEN RXRISK=2; 
/*CONGESTIVE HEART FAILURE*/
	IF MED_NAME IN:('POTASSIUM CANRENOATE', 'CANRENONE', 'EPLERENONE', 'METOPROLOL') THEN RXRISK=2; 
/*DEMENTIA*/
	IF MED_NAME IN:('DONEPEZIL', 'GALANTAMINE', 'RIVASTIGMINE', 'MEMANTINE') THEN RXRISK=2; 
/*DEPRESSION*/
	IF MED_NAME IN:('ZIMELDINE', 'FLUOXETINE', 'CITALOPRAM', 'PAROXETINE', 'SERTRALINE', 'ALAPROCLATE', 'FLUVOXAMINE', 'ETOPERIDONE', 'ESCITALOPRAM', 'ISOCARBOXAZID', 'NIALAMIDE', 
	'PHENELZINE', 'TRANYLCYPROMINE', 'IPRONIAZIDE', 'IPROCLOZIDE', 'MOCLOBEMIDE', 'MIANSERIN', 'NOMIFENSINE', 'TRAZODONE', 'NEFAZODONE', 'MINAPRINE', 'BIFEMELANE', 'VILOXAZINE', 
	'OXAFLOZANE', 'MIRTAZAPINE', 'MEDIFOXAMINE', 'TIANEPTINE', 'PIVAGABINE', 'VENLAFAXINE', 'MILNACIPRAN', 'REBOXETINE', 'DULOXETINE', 'AGOMELATINE', 'DESVENLAFAXINE', 'VILAZODONE', 
	'HYPERICI HERBA', 'VORTIOXETINE') THEN RXRISK=2; 
/*DIABETES*/
	IF MED_NAME IN:('INSULIN', 'PHENFORMIN', 'METFORMIN', 'BUFORMIN', 'GLIBENCLAMIDE', 'CHLORPROPAMIDE', 'TOLBUTAMIDE', 'GLIBORNURIDE', 'TOLAZAMIDE', 'CARBUTAMIDE', 'GLIPIZIDE', 
	'GLIQUIDONE', 'GLICLAZIDE', 'METAHEXAMIDE', 'GLISOXEPIDE', 'GLIMEPIRIDE', 'ACETOHEXAMIDE', 'GLYMIDINE', 'ACARBOSE', 'MIGLITOL', 'VOGLIBOSE', 'TROGLITAZONE', 'ROSIGLITAZONE', 
	'PIOGLITAZONE', 'SITAGLIPTIN', 'VILDAGLIPTIN', 'SAXAGLIPTIN', 'ALOGLIPTIN', 'LINAGLIPTIN', 'GEMIGLIPTIN', 'EVOGLIPTIN', 'EXENATIDE', 'LIRAGLUTIDE', 'LIXISENATIDE', 'ALBIGLUTIDE', 
	'DULAGLUTIDE', 'SEMAGLUTIDE', 'DAPAGLIFLOZIN', 'CANAGLIFLOZIN', 'EMPAGLIFLOZIN', 'ERTUGLIFLOZIN', 'IPRAGLIFLOZIN', 'SOTAGLIFLOZIN', 'GUAR GUM', 'REPAGLINIDE', 'NATEGLINIDE', 
	'PRAMLINTIDE', 'BENFLUOREX', 'MITIGLINIDE') THEN RXRISK=2;
/*GOUT*/
	IF MED_NAME IN:('ALCURONIUM', 'TUBOCURARINE', 'DIMETHYLTUBOCURARINE', 'PROBENECID', 'SULFINPYRAZONE', 'BENZBROMARONE', 'ISOBROMINDIONE', 'LESINURAD', 'COLCHICINE') THEN RXRISK=1;
/*HYPERKALEMIA*/
	IF MED_NAME IN:('POLYSTYRENE SULFONATE') THEN RXRISK=4; 
/*HYPERLIPIDEMIA*/
	IF MED_NAME IN:('CLOFIBRATE', 'BEZAFIBRATE', 'ALUMINIUM CLOFIBRATE', 'GEMFIBROZIL', 'FENOFIBRATE', 'SIMFIBRATE', 'RONIFIBRATE', 'CIPROFIBRATE', 'ETOFIBRATE', 'CLOFIBRIDE', 
	'CHOLINE FENOFIBRATE', 'COLESTYRAMINE', 'COLESTIPOL', 'COLEXTRAN', 'COLESEVELAM', 'NICERITROL', 'NICOTINIC ACID', 'NICOFURANOSE', 'ALUMINIUM NICOTINATE', 
	'NICOTINYL ALCOHOL (PYRIDYLCARBINOL)', 'ACIPIMOX', 'DEXTROTHYROXINE', 'PROBUCOL', 'TIADENOL', 'MEGLUTOL', 'MAGNESIUM PYRIDOXAL 5-PHOSPHATE GLUTAMATE', 'POLICOSANOL', 'EZETIMIBE', 
	'ALIPOGENE TIPARVOVEC', 'MIPOMERSEN', 'LOMITAPIDE', 'EVOLOCUMAB', 'ALIROCUMAB',	'BEMPEDOIC ACID', 'SIMVASTATIN', 'LOVASTATIN', 'PRAVASTATIN', 'FLUVASTATIN', 'ATORVASTATIN', 
	'CERIVASTATIN', 'ROSUVASTATIN', 'PITAVASTATIN') THEN RXRISK=-1;
/*HYPERTENSION*/
	IF MED_NAME IN:('BENDROFLUMETHIAZIDE', 'HYDROFLUMETHIAZIDE', 'HYDROCHLOROTHIAZIDE', 'CHLOROTHIAZIDE', 'POLYTHIAZIDE', 'TRICHLORMETHIAZIDE', 'CYCLOPENTHIAZIDE', 
	'METHYCLOTHIAZIDE', 'CYCLOTHIAZIDE', 'MEBUTIZIDE', 'QUINETHAZONE', 'CLOPAMIDE', 'CHLORTALIDONE', 'MEFRUSIDE', 'CLOFENAMIDE', 'METOLAZONE', 'METICRANE', 'XIPAMIDE', 
	'INDAPAMIDE', 'AMILORIDE', 'ENALAPRIL', 'LISINOPRIL', 'PERINDOPRIL', 'RAMIPRIL', 'QUINAPRIL', 'BENAZEPRIL', 'CILAZAPRIL', 'FOSINOPRIL', 'EPROSARTAN', 'VALSARTAN', 
	'IRBESARTAN', 'TASOSARTAN', 'CANDESARTAN', 'TELMISARTAN', 'OLMESARTAN MEDOXOMIL', 'METHYLDOPA', 'CLONIDINE', 'GUANFACINE', 'TOLONIDINE', 'MOXONIDINE', 'HYDRALAZINE', 
	'ENDRALAZINE', 'CADRALAZINE') THEN RXRISK=-1;
/*HYPERTHYROIDISM*/
	IF MED_NAME IN:('PROPYLTHIOURACIL', 'CARBIMAZOLE') THEN RXRISK=2; 
/*ISCHAEMIC HEART DISEASE: ANGINA*/
	IF MED_NAME IN:('GLYCERYL TRINITRATE', 'METHYLPROPYLPROPANEDIOL DINITRATE', 'PENTAERITHRITYL TETRANITRATE', 'PROPATYLNITRATE', 'ISOSORBIDE DINITRATE', 
	'TROLNITRATE', 'ERITRITYL TETRANITRATE', 'ISOSORBIDE MONONITRATE', 'NICORANDIL', 'PERHEXILINE') THEN RXRISK=2; 
/*ISCHAEMIC HEART DISEASE: HYPERTENSION*/
	IF MED_NAME IN:('ALPRENOLOL', 'OXPRENOLOL', 'PINDOLOL', 'PROPRANOLOL', 'TIMOLOL', 'NADOLOL', 'MEPINDOLOL', 'CARTEOLOL', 'TERTATOLOL', 'BOPINDOLOL', 'BUPRANOLOL', 'PENBUTOLOL', 
	'CLORANOLOL', 'PRACTOLOL', 'LABETALOL', 'AMLODIPINE', 'FELODIPINE', 'ISRADIPINE', 'NICARDIPINE', 'NIFEDIPINE', 'NIMODIPINE', 'NISOLDIPINE', 'NITRENDIPINE', 'LACIDIPINE', 
	'NILVADIPINE', 'MANIDIPINE', 'BARNIDIPINE', 'LERCANIDIPINE', 'CILNIDIPINE', 'BENIDIPINE', 'CLEVIDIPINE', 'MIBEFRADIL', 'VERAPAMIL', 'GALLOPAMIL', 'DILTIAZEM', 'ATENOLOL') THEN RXRISK=-1;
/*INFLAMMATION OR PAIN*/
	IF MED_NAME IN:('INDOMETACIN', 'SULINDAC', 'TOLMETIN', 'ZOMEPIRAC', 'DICLOFENAC', 'ALCLOFENAC', 'BUMADIZONE', 'ETODOLAC', 'LONAZOLAC', 'FENTIAZAC', 'ACEMETACIN', 
	'DIFENPIRAMIDE', 'OXAMETACIN', 'PROGLUMETACIN', 'KETOROLAC', 'ACECLOFENAC', 'BUFEXAMAC', 'PIROXICAM', 'TENOXICAM', 'DROXICAM', 'LORNOXICAM', 'MELOXICAM', 'IBUPROFEN', 'NAPROXEN', 
	'KETOPROFEN', 'FENOPROFEN', 'FENBUFEN', 'BENOXAPROFEN', 'SUPROFEN', 'PIRPROFEN', 'FLURBIPROFEN', 'INDOPROFEN', 'TIAPROFENIC ACID', 'OXAPROZIN', 'IBUPROXAM', 'DEXIBUPROFEN', 
	'FLUNOXAPROFEN', 'ALMINOPROFEN', 'DEXKETOPROFEN', 'NAPROXCINOD', 'MEFENAMIC ACID', 'TOLFENAMIC ACID', 'FLUFENAMIC ACID', 'MECLOFENAMIC ACID', 'CELECOXIB', 'ROFECOXIB', 'VALDECOXIB', 
	'PARECOXIB', 'ETORICOXIB', 'LUMIRACOXIB') THEN RXRISK=-1; 
/*LIVER FAILURE*/
	IF MED_NAME IN:('LACTULOSE', 'RIFAXIMIN') THEN RXRISK=3;
/*MALIGNANCIES*/
	IF MED_NAME IN:('CYCLOPHOSPHAMIDE', 'CHLORAMBUCIL', 'MELPHALAN', 'CHLORMETHINE', 'IFOSFAMID', 'TROFOSFAMIDE', 'PREDNIMUSTINE', 'BENDAMUSTINE', 'BUSULFAN', 'TREOSULFAN', 
	'MANNOSULFAN', 'THIOTEPA', 'TRIAZIQUONE', 'CARBOQUONE', 'CARMUSTINE', 'LOMUSTINE', 'SEMUSTINE', 'STREPTOZOCIN', 'FOTEMUSTINE', 'NIMUSTINE', 'RANIMUSTINE', 'URAMUSTINE', 
	'ETOGLUCID', 'MITOBRONITOL', 'PIPOBROMAN', 'TEMOZOLOMIDE', 'DACARBAZINE', 'METHOTREXATE', 'RALTITREXED', 'PEMETREXED', 'PRALATREXATE', 'MERCAPTOPURINE', 'TIOGUANINE', 
	'CLADRIBINE', 'FLUDARABINE', 'CLOFARABINE', 'NELARABINE', 'CYTARABINE', 'FLUOROURACIL', 'TEGAFUR', 'CARMOFUR', 'GEMCITABINE', 'CAPECITABINE', 'AZACITIDINE', 'DECITABINE', 
	'FLOXURIDINE', 'VINBLASTINE', 'VINCRISTINE', 'VINDESINE', 'VINORELBINE', 'VINFLUNINE', 'VINTAFOLIDE', 'ETOPOSIDE', 'TENIPOSIDE', 'DEMECOLCINE', 'PACLITAXEL', 'DOCETAXEL', 
	'PACLITAXEL POLIGLUMEX', 'CABAZITAXEL', 'TRABECTEDIN', 'DACTINOMYCIN', 'DOXORUBICIN', 'DAUNORUBICIN', 'EPIRUBICIN', 'ACLARUBICIN', 'ZORUBICIN', 'IDARUBICIN', 'MITOXANTRONE', 
	'PIRARUBICIN', 'VALRUBICIN', 'AMRUBICIN', 'PIXANTRONE', 'BLEOMYCIN', 'PLICAMYCIN', 'MITOMYCIN', 'IXABEPILONE', 'CISPLATIN', 'CARBOPLATIN', 'OXALIPLATIN', 'SATRAPLATIN', 
	'POLYPLATILLEN', 'PROCARBAZINE', 'EDRECOLOMAB', 'RITUXIMAB', 'TRASTUZUMAB', 'GEMTUZUMAB OZOGAMICIN', 'CETUXIMAB', 'BEVACIZUMAB', 'PANITUMUMAB', 'CATUMAXOMAB', 'OFATUMUMAB', 
	'IPILIMUMAB', 'BRENTUXIMAB VEDOTIN', 'PERTUZUMAB', 'TRASTUZUMAB EMTANSINE', 'OBINUTUZUMAB', 'DINUTUXIMAB BETA', 'NIVOLUMAB', 'PEMBROLIZUMAB', 'BLINATUMOMAB', 'RAMUCIRUMAB', 
	'NECITUMUMAB', 'ELOTUZUMAB', 'DARATUMUMAB', 'MOGAMULIZUMAB', 'INOTUZUMAB OZOGAMICIN', 'OLARATUMAB', 'DURVALUMAB', 'BERMEKIMAB', 'AVELUMAB', 'ATEZOLIZUMAB', 'CEMIPLIMAB', 
	'PORFIMER SODIUM', 'METHYL AMINOLEVULINATE', 'AMINOLEVULINIC ACID', 'TEMOPORFIN', 'EFAPROXIRAL', 'PADELIPORFIN', 'IMATINIB', 'GEFITINIB', 'ERLOTINIB', 'SUNITINIB', 'SORAFENIB', 
	'DASATINIB', 'LAPATINIB', 'NILOTINIB', 'TEMSIROLIMUS', 'EVEROLIMUS', 'PAZOPANIB', 'VANDETANIB', 'AFATINIB', 'BOSUTINIB', 'VEMURAFENIB', 'CRIZOTINIB', 'AXITINIB', 'RUXOLITINIB', 
	'RIDAFOROLIMUS', 'REGORAFENIB', 'MASITINIB', 'DABRAFENIB', 'PONATINIB', 'TRAMETINIB', 'CABOZANTINIB', 'IBRUTINIB', 'CERITINIB', 'LENVATINIB', 'NINTEDANIB', 'CEDIRANIB', 
	'PALBOCICLIB', 'TIVOZANIB', 'OSIMERTINIB', 'ALECTINIB', 'ROCILETINIB', 'COBIMETINIB', 'MIDOSTAURIN', 'OLMUTINIB', 'BINIMETINIB', 'RIBOCICLIB', 'BRIGATINIB', 'LORLATINIB', 
	'NERATINIB', 'ENCORAFENIB', 'DACOMITINIB', 'ICOTINIB', 'ABEMACICLIB', 'ACALABRUTINIB', 'QUIZARTINIB', 'LAROTRECTINIB', 'GILTERITINIB', 'ENTRECTINIB', 'FEDRATINIB', 'AMSACRINE', 
	'ASPARAGINASE', 'ALTRETAMINE', 'HYDROXYCARBAMIDE', 'LONIDAMINE', 'PENTOSTATIN', 'MASOPROCOL', 'ESTRAMUSTINE', 'TRETINOIN', 'MITOGUAZONE', 'TOPOTECAN', 'TIAZOFURINE', 'IRINOTECAN', 
	'ALITRETINOIN', 'MITOTANE', 'PEGASPARGASE', 'BEXAROTENE', 'ARSENIC TRIOXIDE', 'DENILEUKIN DIFTITOX', 'BORTEZOMIB', 'CELECOXIB', 'ANAGRELIDE', 'OBLIMERSEN', 'SITIMAGENE CERADENOVEC', 
	'VORINOSTAT', 'ROMIDEPSIN', 'OMACETAXINE MEPESUCCINATE', 'ERIBULIN') THEN RXRISK=2;
/*MIGRAINES*/
	IF MED_NAME IN:('DIHYDROERGOTAMINE', 'ERGOTAMINE', 'METHYSERGIDE', 'LISURIDE', 'FLUMEDROXONE', 'SUMATRIPTAN', 'NARATRIPTAN', 'ZOLMITRIPTAN', 'RIZATRIPTAN', 'ALMOTRIPTAN', 
	'ELETRIPTAN', 'ERENUMAB', 'GALCANEZUMAB', 'FREMANEZUMAB', 'PIZOTIFEN') THEN RXRISK=-1;
/*OSTEOPOROSIS OR PAGET'S */
	IF MED_NAME IN:('ETIDRONIC ACID', 'CLODRONIC ACID', 'PAMIDRONIC ACID', 'ALENDRONIC ACID', 'TILUDRONIC ACID', 
	'STRONTIUM RANELATE', 'DENOSUMAB', 'RALOXIFENE', 'TERIPARATIDE') THEN RXRISK=-1;
/*PAIN*/
	IF MED_NAME IN:('MORPHINE', 'OPIUM', 'HYDROMORPHONE', 'NICOMORPHINE', 'OXYCODONE', 'DIHYDROCODEINE', 'PAPAVERETUM', 'KETOBEMIDONE', 'PETHIDINE', 'FENTANYL', 'DEXTROMORAMIDE', 
	'PIRITRAMIDE', 'DEXTROPROPOXYPHENE', 'BEZITRAMIDE', 'PHENAZOCINE', 'BUPRENORPHINE', 'BUTORPHANOL', 'NALBUPHINE', 'TILIDINE', 'TRAMADOL', 'TAPENTADOL') THEN RXRISK=3;
/*PARKINSON'S DISEASE*/
	IF MED_NAME IN:('TRIHEXYPHENIDYL', 'BIPERIDEN', 'METIXENE', 'PROCYCLIDINE', 'PROFENAMINE', 'DEXETIMIDE', 'PHENGLUTARIMIDE', 'MAZATICOL', 'BORNAPRINE', 'TROPATEPINE', 'ETANAUTINE', 
	'ORPHENADRINE', 'BENZATROPINE', 'ETYBENZATROPINE', 'LEVODOPA', 'MELEVODOPA', 'AMANTADINE', 'BROMOCRIPTINE', 'PERGOLIDE', 'DIHYDROERGOCRYPTINE MESYLATE', 'ROPINIROLE', 'PRAMIPEXOLE', 
	'CABERGOLINE', 'APOMORPHINE', 'PIRIBEDIL', 'ROTIGOTINE', 'SELEGILINE', 'RASAGILINE', 'SAFINAMIDE', 'TOLCAPONE', 'ENTACAPONE') THEN RXRISK=3;
/*PSYCHOTIC ILLNESS*/
	IF MED_NAME IN:('CHLORPROMAZINE', 'LEVOMEPROMAZINE', 'PROMAZINE', 'ACEPROMAZINE', 'TRIFLUPROMAZINE', 'CYAMEMAZINE', 'CHLORPROETHAZINE', 'DIXYRAZINE', 'FLUPHENAZINE', 'TRIFLUOPERAZINE', 
	'ACETOPHENAZINE', 'PROTHIPENDYL', 'RISPERIDONE', 'MOSAPRAMINE', 'ZOTEPINE', 'ARIPIPRAZOLE', 'PALIPERIDONE') THEN RXRISK=6;
/*PULMONARY HYPERTENSION*/
	IF MED_NAME IN:('BOSENTAN', 'AMBRISENTAN', 'SITAXENTAN', 'MACITENTAN', 'RIOCIGUAT') THEN RXRISK=6;
/*RENAL DISEASE*/
	IF MED_NAME IN:('ERYTHROPOIETIN', 'DARBEPOETIN ALFA', 'METHOXY POLYETHYLENE GLYCOL-EPOETIN BETA', 'ERGOCALCIFEROL', 'DIHYDROTACHYSTEROL', 'ALFACALCIDOL', 'CALCITRIOL', 'SEVELAMER', 
	'LANTHANUM CARBONATE', 'SUCROFERRIC OXYHYDROXIDE') THEN RXRISK=6; 
/*SMOKING CESSATION*/
	IF MED_NAME IN:('NICOTINE', 'VARENICLINE', 'BUPROPION') THEN RXRISK=6;
/*STEROID-RESPONSIVE DISEASE*/
	IF MED_NAME IN:('BETAMETHASONE', 'DEXAMETHASONE', 'FLUOCORTOLONE', 'METHYLPREDNISOLONE', 'PARAMETHASONE', 'PREDNISOLONE', 'PREDNISONE', 'TRIAMCINOLONE', 'HYDROCORTISONE', 'CORTISONE')
	THEN RXRISK=2;
ELSE IF RXRISK=. THEN RXRISK=0;
run;
proc freq data=rxrisk_1; table rxrisk; run;

proc sql;
	create table covid.rxrisk as
	select osler_id, 
	sum(rxrisk) as rxrisk_sum 
	from rxrisk_1
	group by osler_id;
quit;

/*The reviewer at CID wanted us to have COPD, Autoimmune (which we are operationalizing at rheumatic diseases), renal, cancer and HIV 
	IN ADDITION TO ELIXHAUSER*/
Title "COPD";
data one;
set test.derived_problem_list;
where icd10_code contains "J44";
run; 
	proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;
data two;
set test.derived_medical_hx_summary;
where icd10_code contains "J44";
run;
	proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;
data three;
set test.derived_encounter_dx;
where icd10_code contains "J44";
run;
	proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;
data copd;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=copd; by osler_id; run;
proc sort data=a; by osler_id; run;
data copd_2;
merge copd a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
copd=1;
keep osler_id copd;
run;
proc sort data=copd_2 nodupkey; by osler_id; run;

Title "Rheumatic diseaes";
data one;
set test.derived_problem_list;
if icd10_code IN: ('M05','M32','M33','M34','M06','M315','M351','M353','M360');
run; 
	proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;
data two;
set test.derived_medical_hx_summary;
if icd10_code IN: ('M05','M32','M33','M34','M06','M315','M351','M353','M360');
run;
	proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;
data three;
set test.derived_encounter_dx;
if icd10_code IN: ('M05','M32','M33','M34','M06','M315','M351','M353','M360');
run;
	proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;
data rheum;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=rheum; by osler_id; run;
proc sort data=a; by osler_id; run;
data rheum_2;
merge rheum a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
rheum=1;
keep osler_id rheum;
run;
proc sort data=rheum_2 nodupkey; by osler_id; run;

Title "Renal";
data one;
set test.derived_problem_list;
if icd10_code IN: ('N18','N19','N052','N053','N054','N055','N056','N057','N250','I120','I131','N032','N033','N034','N035','N036','N037','Z490','Z491','Z492','Z940','Z992');
run; 
	proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;
data two;
set test.derived_medical_hx_summary;
if icd10_code IN: ('N18','N19','N052','N053','N054','N055','N056','N057','N250','I120','I131','N032','N033','N034','N035','N036','N037','Z490','Z491','Z492','Z940','Z992');
run;
	proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;
data three;
set test.derived_encounter_dx;
if icd10_code IN: ('N18','N19','N052','N053','N054','N055','N056','N057','N250','I120','I131','N032','N033','N034','N035','N036','N037','Z490','Z491','Z492','Z940','Z992');
run;
	proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;
data renal;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=renal; by osler_id; run;
proc sort data=a; by osler_id; run;
data renal_2;
merge renal a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
renal=1;
keep osler_id renal;
run;
proc sort data=renal_2 nodupkey; by osler_id; run;

Title "Cancer";
data one;
set test.derived_problem_list;
if icd10_code IN: ('C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11',
                         'C12','C13','C14','C15','C16','C17','C18','C19','C20','C21','C22','C23',
                         'C24','C25','C26','C30','C31','C32','C33','C34','C37','C38','C39','C40',
                         'C41','C43','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54',
                         'C55','C56','C57','C58','C60','C61','C62','C63','C64','C65','C66','C67',
                         'C68','C69','C70','C71','C72','C73','C74','C75','C76','C81','C82','C83',
                         'C84','C85','C88','C90','C91','C92','C93','C94','C95','C96','C97');
run; 
	proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;
data two;
set test.derived_medical_hx_summary;
if icd10_code IN: ('C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11',
                         'C12','C13','C14','C15','C16','C17','C18','C19','C20','C21','C22','C23',
                         'C24','C25','C26','C30','C31','C32','C33','C34','C37','C38','C39','C40',
                         'C41','C43','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54',
                         'C55','C56','C57','C58','C60','C61','C62','C63','C64','C65','C66','C67',
                         'C68','C69','C70','C71','C72','C73','C74','C75','C76','C81','C82','C83',
                         'C84','C85','C88','C90','C91','C92','C93','C94','C95','C96','C97');
run;
	proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;
data three;
set test.derived_encounter_dx;
if icd10_code IN: ('C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11',
                         'C12','C13','C14','C15','C16','C17','C18','C19','C20','C21','C22','C23',
                         'C24','C25','C26','C30','C31','C32','C33','C34','C37','C38','C39','C40',
                         'C41','C43','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54',
                         'C55','C56','C57','C58','C60','C61','C62','C63','C64','C65','C66','C67',
                         'C68','C69','C70','C71','C72','C73','C74','C75','C76','C81','C82','C83',
                         'C84','C85','C88','C90','C91','C92','C93','C94','C95','C96','C97');
run;
	proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;
data cancer;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=cancer; by osler_id; run;
proc sort data=a; by osler_id; run;
data cancer_2;
merge cancer a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
cancer=1;
keep osler_id cancer;
run;
proc sort data=cancer_2 nodupkey; by osler_id; run;

Title "HIV";
data one;
set test.derived_problem_list;
where icd10_code contains "B20";
run; 
	proc sort data=one out=counting nodupkey; by osler_id icd10_code; run;
data two;
set test.derived_medical_hx_summary;
where icd10_code contains "B20";
run;
	proc sort data=two out=counting nodupkey; by osler_id icd10_code; run;
data three;
set test.derived_encounter_dx;
where icd10_code contains "B20";
run;
	proc sort data=three out=counting nodupkey; by osler_id icd10_code; run;
data hiv;
set one two three;
run;
*Making sure they are pre-admission diagnoses;
data a;
set covid.covid_allpersons;
keep osler_id admit_time; 
run;
proc sort data=hiv; by osler_id; run;
proc sort data=a; by osler_id; run;
data hiv_2;
merge hiv a (in=in1); /*Not everyone in these one two three tables is a COVID+ person*/
by osler_id;
if in1;
if enc_contact_date > admit_time then delete;
if icd10_code=" " then delete;
hiv=1;
keep osler_id hiv; 
run;
proc sort data=hiv_2 nodupkey; by osler_id; run;

Title "Merging into single analytic file";
proc sort data=covid.covid_allpersons; by osler_id; run;
proc sort data=vent_at_admit; by osler_id; run;
proc sort data=dnr; by osler_id; run;
proc sort data=dead_at_admit; by osler_id; run;
proc sort data=test.covid_pmcoe_covid_positive out=pmcoe; by osler_id; run;
proc sort data=test.derived_epic_patient out=epic; by osler_id; run;
proc sort data=test.covid_pmcoe_covid_positive out=confirmed_suspected; by osler_id; run;
proc sort data=exposure_def; by osler_id; run;
proc sort data=alcohol_smoke_2; by osler_id; run;
proc sort data=test.curated_bmi out=bmi; by osler_id; run;
proc sort data=test.curated_comorbidities out=comorb; by osler_id; run;
proc sort data=admit_info; by osler_id; run;
proc sort data=resp; by osler_id; run;
proc sort data=pulse_4; by osler_id; run;
proc sort data=temp_4; by osler_id; run;
proc sort data=fio2_mean_3; by osler_id; run;
proc sort data=creatinine_3; by osler_id; run;
proc sort data=ast_3; by osler_id; run;
proc sort data=ddimer_3; by osler_id; run;
proc sort data=troponin_3; by osler_id; run;
proc sort data=albumin_3; by osler_id; run;
proc sort data=crp_3; by osler_id; run;
proc sort data=lymphocyte_3; by osler_id; run;
proc sort data=covid.rxrisk; by osler_id; run;
proc sort data=copd_2; by osler_id; run;
proc sort data=rheum_2; by osler_id; run;
proc sort data=renal_2; by osler_id; run;
proc sort data=cancer_2; by osler_id; run;
proc sort data=hiv_2; by osler_id; run;

data merging;
merge exposure_def confirmed_suspected vent_at_admit dnr dead_at_admit pmcoe epic
	alcohol_smoke_2 bmi comorb admit_info 
	resp pulse_4 temp_4 fio2_mean_3 
	creatinine_3 ast_3 ddimer_3 troponin_3 albumin_3 crp_3 lymphocyte_3 covid.rxrisk
	copd_2 rheum_2 renal_2 cancer_2 hiv_2; 
by osler_id; 
if immuno_meds=. then immuno_meds=0;
if immuno_diagnosis=. then immuno_diagnosis=0;
if immunocomp=. then immunocomp=0;
if el_drug=. then el_drug=0;
if respgt22=. then respgt22=0;
if rxrisk_sum=. then rxrisk_sum=0;
if copd=. then copd=0;
if rheum=. then rheum=0;
if renal=. then renal=0;
if cancer=. then cancer=0;
if hiv=. then hiv=0;
/*June 25: decision to treat labs that were not ordered as indicator variables*/
if elevated_crp=. then crp_notordered=1;
	if elevated_crp ne . then crp_notordered=0;
if elevated_creatinine=. then creatinine_notordered=1;
	if elevated_creatinine ne . then creatinine_notordered=0;
if elevated_ddimer=. then ddimer_notordered=1;
	if elevated_ddimer ne . then ddimer_notordered=0;
if elevated_ast=. then ast_notordered=1;
	if elevated_ast ne . then ast_notordered=0;
if elevated_troponin=. then troponin_notordered=1;
	if elevated_troponin ne . then troponin_notordered=0;
if high_wbc=. then wbc_notordered=1;
	if high_wbc ne . then wbc_notordered=0;
if low_albumin=. then albumin_notordered=1;
	if low_albumin ne . then albumin_notordered=0;
if low_wbc=. then wbc_notordered=1;
	if low_wbc ne . then wbc_notordered=0;
DROP ADMIT_SOURCE_C;
run;

data mergingin;
set merging;
merge covid.covid_allpersons (in=in1) merging;
if in1;
by osler_id; 
*Needs to be a separate step, otherwise was overriding and corrupting above;
	if elevated_crp=. then elevated_crp=0;
	if elevated_creatinine=. then elevated_creatinine=0;
	if elevated_ddimer=. then elevated_ddimer=0;
	if elevated_ast=. then elevated_ast=0;
	if elevated_troponin=. then elevated_troponin=0;
	if high_wbc=. then high_wbc=0;
	if low_albumin=. then low_albumin=0;
	if low_wbc=. then low_wbc=0;
run;

data one;
set mergingin;
*There are people with sex, age, race etc all missing - identifying them by a missing value in age because it is a numeric field;
if age=. then delete; 
run;

data two;
set one;
*There are people left who were ventilated before admission, need to exclude;
if -1000000000<minutes_to_vent<0 then delete;
run;

data three;
set two;
*There is a person with apparent negative death time, but they have already been excluded at another step;
if -1000000000<minutes_to_death < 0 then delete;
run; 

data four;
set three;
if dnr=1 then delete;
run;

data covid.cohort_immuno;
set covid.cohort_immuno;
*Reworking the categorical variables into dummy variables;
if gender = "Male" then male = 1; else male = 0;

if first_race = "White" then white = 1; else white = 0;
if first_race = "Black" then black = 1; else black = 0;
if first_race in ("Am Indian", "Asian", "Declined", "Other", "Other Pacifi", "Pac Islander", "Unknown") then other_race = 1; else other_race = 0;

if ethnic_group = "Hispanic" then hispanic = 1; 		else hispanic = 0;
if ethnic_group = "Not Hispanic" then no_hispanic = 1; 	else no_hispanic = 0;
if ethnic_group in ("Pt Refused", "Unknown", " ") then unknown_ethnicity = 1; else unknown_ethnicity = 0;

if alcohol_use = "Yes" then alcohol_yes = 1; 							else alcohol_yes = 0;
if alcohol_use in ("Never","No","Not Currently") then alcohol_no = 1;	else alcohol_no = 0;
if alcohol_use in ("Not Asked "," ") then alcohol_miss = 1;				else alcohol_miss = 0;

if tobacco_user in ("Yes", "Passive") then smoker_yes = 1; 				else smoker_yes = 0;
if tobacco_user in ("Quit") then smoker_former = 1; 					else smoker_former = 0;
if tobacco_user in ("Never") then smoker_no = 1; 						else smoker_no = 0;
if tobacco_user in ("Not Asked "," ") then smoker_miss = 1;				else smoker_miss = 0;

if bmi_cat ="1. not overweight or obese" then bmi_normal = 1; 	else bmi_normal = 0; 
if bmi_cat ="2. overweight" then bmi_overwt = 1; 				else bmi_overwt = 0; 
if bmi_cat ="3. class 1 obese" or bmi_cat ="4. class 2 obese" or bmi_cat ="5. class 3 obese" then bmi_obese = 1; else bmi_obese = 0; 
if bmi_cat =" " then bmi_miss = 1; 								else bmi_miss = 0; 

if admit_source = "Skilled Nursing Facility, Intermediate Care Facility or Assisted Living Facility" then admit_nh = 1; else admit_nh = 0;

elix_summary_score = 
	3*el_chrnlung + 
	13*el_mets +
	9*el_chf +
	0*el_aids +
	0*el_anemdef +
	5*el_liver +
	8*el_tumor +
	9*el_lytes +
	(-1)*el_htn +
	8*el_wghtloss +
	(-2)*el_alcohol +
	(-8)*el_drug +
	0*el_ulcer +
	(-4)*el_obese +
	(-2)*el_bldloss +
	0*el_dmcx +
	3*el_para +
	5*el_pulmcirc +
	(-4)*el_depress +
	6*el_renlfail +
	(-4)*el_psych +
	9*el_coag +
	0*el_hypothy +
	0*el_arth +
	el_htncx +
	4*el_neuro +
	0*el_valve +
	6*el_lymph +
	4*el_perivasc;

if elix_summary_score = . then elix_summary_score_v01 = 0;
else elix_summary_score_v01 = elix_summary_score;
*Some zip codes have 5 digits, some have 9 (21224-XXXX for example) - would be best to keep to 5 for consistency;
format zipcode $5.;
*Need calendar week to adjust for time trends;
date_only=datepart(admit_time);
week = week(date_only, 'v'); 
*Days from positive test to admission;
days_test_to_admit = intck('minute',positive_test_time,admit_time)/1440; 
*Patient status as of end of follow-up;
if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then discharged=1; 
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then hospitalized=0;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then deceased=0;  
if pat_status="Deceased" then deceased=1;
	if pat_status="Deceased" then discharged=0;
	if pat_status="Deceased" then hospitalized=0;
if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then hospitalized=1;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then discharged=0;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then deceased=0;
daystodeath = (minutes_to_death/1440);
daystovent = (minutes_to_vent/1440);
if discharged=1 then lengthofstay = intck('minute',admit_time,FINAL_HOSP_DISCH_TIME)/1440; 
	if hospitalized=1 then lengthofstay = intck('minute',admit_time,1914364740)/1440;  /*This is August 29, 2020 at 23:59*/
	if deceased=1 then lengthofstay =.; 
if daystovent=. then ventilator=0;
if daystovent ne . then ventilator=1;
***From Hemal's code: Censor variable and time for death;
if deceased=1 then censor_death=1; 
	else censor_death=0;
if censor_death=1 then survtime_death=daystodeath; *event (dead);
if censor_death=0 then survtime_death=lengthofstay; *censor (i.e. not dead);
***From Hemal's code: censor variable and time for ventilation with a competing risk of death;
if ventilator=1 then censor_vent=1; *event (ventilated);
	else if deceased=1 then censor_vent=2; *competing event (death);
	else censor_vent=0; *censor (i.e. not ventilated);
if censor_vent=1 then survtime_vent=daystovent;
if censor_vent=2 then survtime_vent=daystodeath;
if censor_vent=0 then survtime_vent=lengthofstay;
***From Hemal's code: censor variable and time for ventilation with a competing risk of death;
if discharged=1 then censor_los=1; *event (ventilated);
	else if deceased=1 then censor_los=2; *competing event (death);
	else censor_los=0; *censor (i.e. not discharged and not dead, remains hospitalized);
if censor_los=1 then survtime_los=lengthofstay;
if censor_los=2 then survtime_los=daystodeath;
if censor_los=0 then survtime_los=lengthofstay;
*Need dummy variable for the hospital location;
if init_hosp_loc_abbr="SMSMH" then sibley=1; else sibley=0;
if init_hosp_loc_abbr="JHJHH" then downtown=1; else downtown=0;
if init_hosp_loc_abbr="HCGH" then hoco=1; else hoco=0;
if init_hosp_loc_abbr="BVBMC" then bayview=1; else bayview=0;
if init_hosp_loc_abbr="SBSBH" then suburban=1; else suburban=0;
run;
proc freq data=covid.cohort_immuno; table immuno_meds; run;

proc freq data=covid.cohort_immuno; table admit_time; run;


/*****************************************************************************************************
August 2, 2020: updating the events for the 70 persons who remain hospitalized as of last check (June 26)
****************************************************************************************************
data finding;
set covid.cohort_immuno;
if hospitalized=1;
keep osler_id;
run;
proc sort data=finding; by osler_id; 
proc sort data=test.curated_IPevents out=events; by osler_id;
data update_august2;
merge events finding (in=in1);
if in1;
by osler_id; 
keep osler_id nippv_rx hiflow_rx vent_start final_hosp_disch_time death_time;
run;
proc sort data=update_august2; by osler_id;
proc sort data=covid.cohort_immuno; by osler_id;
proc sort data=test.covid_pmcoe_covid_positive out=status; by osler_id;
data a;
merge covid.cohort_immuno (in=in1) status update_august2; 
by osler_id; 
if in1;
*Patient status as of end of follow-up;
if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then discharged=1; 
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then hospitalized=0;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME ne . then deceased=0;  
if pat_status="Deceased" then deceased=1;
	if pat_status="Deceased" then discharged=0;
	if pat_status="Deceased" then hospitalized=0;
if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then hospitalized=1;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then discharged=0;
	if pat_status="Alive" and FINAL_HOSP_DISCH_TIME=. then deceased=0;
daystodeath = (minutes_to_death/1440);
daystovent = (minutes_to_vent/1440);
if discharged=1 then lengthofstay = intck('minute',admit_time,FINAL_HOSP_DISCH_TIME)/1440; 
	if hospitalized=1 then lengthofstay = intck('minute',admit_time,1911161760)/1440; *This is July 23, 2020 at 22:16;
	if deceased=1 then lengthofstay =.; 
if daystovent=. then ventilator=0;
if daystovent ne . then ventilator=1;
***From Hemal's code: Censor variable and time for death;
if deceased=1 then censor_death=1; 
	else censor_death=0;
if censor_death=1 then survtime_death=daystodeath; *event (dead);
if censor_death=0 then survtime_death=lengthofstay; *censor (i.e. not dead);
***From Hemal's code: censor variable and time for ventilation with a competing risk of death;
if ventilator=1 then censor_vent=1; *event (ventilated);
	else if deceased=1 then censor_vent=2; *competing event (death);
	else censor_vent=0; *censor (i.e. not ventilated);
if censor_vent=1 then survtime_vent=daystovent;
if censor_vent=2 then survtime_vent=daystodeath;
if censor_vent=0 then survtime_vent=lengthofstay;
***From Hemal's code: censor variable and time for ventilation with a competing risk of death;
if discharged=1 then censor_los=1; *event (ventilated);
	else if deceased=1 then censor_los=2; *competing event (death);
	else censor_los=0; *censor (i.e. not discharged and not dead, remains hospitalized);
if censor_los=1 then survtime_los=lengthofstay;
if censor_los=2 then survtime_los=daystodeath;
if censor_los=0 then survtime_los=lengthofstay;
run;
data covid.cohort_immuno;
set a; 
run;
*/
