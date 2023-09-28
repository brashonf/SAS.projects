*/ Task #1---Date Fields*/;

data data610.s_pmL_donor_hw_v3; set data610.s_pmL_donor_hw_v3;
entry_date = intnx('month', '01AUG1998'd, -months_since_origin, 'same');
format entry_date mmddyy10.;run;

data data610.s_pmL_donor_hw_v3; set data610.s_pmL_donor_hw_v3;
first_gift_date = intnx('month', '01AUG1998'd, -months_since_first_gift, 'same');
format first_gift_date mmddyy10.;run;


data data610.s_pmL_donor_hw_v3; set data610.s_pmL_donor_hw_v3;
last_gift_date = intnx('month', '01AUG1998'd, -months_since_last_gift, 'same');
format last_gift_date mmddyy10.;run;

data data610.s_pmL_donor_hw_v3; set data610.s_pmL_donor_hw_v3;
Time_Between = intck('Month', first_gift_date, last_gift_date);
run;

proc means  data=data610.s_pmL_donor_hw_v3 nmiss median; var time_between;run;

proc univariate data=data610.s_pml_donor_hw_v3; histogram entry_date first_gift_date;run;

data data610.s_pm1_donor_hw_v3;
    set data610.s_pm1_donor_hw_v3;

    /* Create new fields with the year from date variables */
    ENTRY_DATE_YEAR = year(ENTRY_DATE);
    FIRST_GIFT_DATE_YEAR = year(FIRST_GIFT_DATE);
    LAST_GIFT_DATE_YEAR = year(LAST_GIFT_DATE);

run;


proc sql;
select count(*) as count_added_in_1998 from data610.s_pmL_donor_hw_v3 where entry_date_year=1998;
RUN;

proc means data=data610.s_pm1_donor_hw_v3; var last_gift_date_year;run;
proc means data=data610.s_pm1_donor_hw_v3; var last_gift_amt;run;

proc summary data=data610.s_pm1_donor_hw_v3 nway;
class last_gift_date_year; var last_gift_amt;
output out=mean_last_gift_amt mean=mean_last_gift_amt;run;
PROC PRINT data=mean_last_gift_amt;run;

data lowest_mean_year; set mean_last_gift_amt; if _type_=0;run;

proc means data=data610.s_pm1_donor_hw_v3 noprint;
where CLUSTER_CODE = 9 and last_gift_date_year=1997; var last_gift_amt;
output out=mean_last_gift_amt;run;

proc print data=mean_last_gift_amt;run;





*[1] Check SAS log when reading in/creating
datasets;
data one;
set data610.s_pml_donor_hw_v3; run;
*[2] Print some of your data;
proc print data= one
(firstobs = 1 obs = 25); run;

*[3] Machine numeric variables;
proc means data = one n nmiss; run;


*[4] Machine character variables;
proc format;
value $Count_Missing ' ' = 'Missing' other = 'Nonmissing';
run;
proc freq data=one;
tables _character_ / nocum missing;
format _character_ $Count_Missing.;
run;

*[5.3.1 The datafile];

/* Data check */

ods select Variables;
	proc contents data=one; run;

proc print data=one (firstobs=1 obs=10); run;

proc means data=one n nmiss min mean max std; run;


* single mean unconditional imputation;

* Step 1: Create missing value indicator; 

data one; set data610.s_pmL_donor_hw_v3;
donor_age_mi = donor_age;
donor_age_mi_flag = (donor_age in(.));
run;

proc reg data = one;
model donor_age_mi_flag = donor_age months_since_origin in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift;
run;

/* Check how many MV there are */

proc means data=one nmiss n min max std mean;
var donor_age_mi donor_age ;run;

proc corr data=one; with donor_age; run;

proc reg data=one;
model months_since_origin = donor_age donor_age_mi in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift;
run;
/* So, our starting benchmarks:
					   Observed
N				        14577	
Mean					58.919
STD						16.66
min						  0
max					  87.00
corr donor_age		  
corr months_since_origin 0.236
RMSE				6.286

*/







* Step 2: Impute missing values using mean and
output imputed data;

proc stdize data=one
method=mean
reponly
out=one_mean_imp;
var donor_age_mi;
run;

* Step 3: Conduct comparative analysis;

proc means data=one_mean_imp nmiss n min max std mean median;
var donor_age_mi donor_age; run;

proc univariate data=one_mean_imp;
var donor_age_mi donor_age;
histogram donor_age_mi donor_age;run;

/* Find observed vs imputed value correlations */

proc corr data=one_mean_imp; var donor_age_mi donor_age; run;


proc sgplot data=one_mean_imp;
histogram donor_age / binwidth=5 transparency=.5;
histogram donor_age_mi / binwidth=5 transparency=.5;
run;

proc sgplot data=one_mean_imp;
hbox donor_age / boxwidth=1 transparency=.5;
hbox donor_age_mi / boxwidth=1 transparency=.5;
run;

/* Calculate RMSE using imputed values */

proc reg data=one_mean_imp;
	model months_since_origin = donor_age donor_age_mi in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift;
run;

/* So, compared to our starting benchmarks:*/
Max 87
Mean 58.91
STD donor_age_mi--14.45 donor_age--16.69
min 0
max 87
corr donor_age .0001
RMSE 6.28



*[5.3.4 Single Stochastic Regression (conditional) Imputation];	

*[STEP 2: Impute];

proc mi data=one nimpute=1 seed=12345
 	out=donor_sreg_imp; 
/* reg method; NBITER => 1 set of imputed data */
	fcs nbiter=1;
/* reg of MMBAL on seg var */   
	var donor_age_mi months_since_origin donor_age in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift ; 
run;

*[STEP 3: Comparative Analysis];
 
/* Find observed vs imputed value statistics */

proc means data=donor_sreg_imp n nmiss min max mean median std; var donor_age donor_age_mi;run;

/* Find observed vs imputed value correlations */

proc corr data=donor_sreg_imp; with donor_age donor_age_mi; run;

/* Plot overlaid histograms  */

proc sgplot data=donor_sreg_imp;
	histogram donor_age /  binwidth=5 transparency=.5;
	histogram donor_age_mi /  binwidth=5 transparency=.5;
run;

proc sgplot data=donor_sreg_imp;
hbox donor_age / boxwidth=1 transparency=.5;
hbox donor_age_mi / boxwidth=1 transparency=.5; run;

/* Calculate RMSE using imputed values */

proc reg data=donor_sreg_imp;
	model months_since_origin = donor_age donor_age_mi in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift;
run;
*/RMSE--6.334--;	

*[5.3.7 Single Hot-deck(conditional) Imputation];

*[STEP 2: Impute];

proc surveyimpute data=one seed=12345 method=hotdeck(selection=srswr);
    var donor_age_mi months_since_origin donor_age in_house pep_star lifetime_card_prom lifetime_prom months_since_first_gift; 
    output out=donor_hot_imp;
run;

*[STEP 3: Comparative Analysis];

/* Find observed vs imputed value statistics */

proc means data=donor_hot_imp n nmiss min mean max median std; var donor_age donor_age_mi; run;

/* Find observed vs imputed value correlations */

proc corr data=donor_hot_imp; with donor_age donor_age_mi; run;

/* Plot overlaid histograms  */

proc sgplot data=donor_hot_imp;
	histogram donor_age /  binwidth=5 transparency=.5;
	histogram donor_age_mi /  binwidth=5 transparency=.5;
run;

proc sgplot data=donor_hot_imp;
hbox donor_age / boxwidth= 1 transparency=.5;
hbox donor_age_mi / boxwidth=1 transparency=.5;
run;

/* Calculate RMSE using imputed values */

proc reg data=donor_hot_imp;
	model months_since_origin = donor_age in_house donor_age_mi pep_star lifetime_card_prom lifetime_prom months_since_last_gift; 
run;           
--rmse: 16.706--;

*[5.3.9 Single Predictive Mean Matching (conditional) Imputation];	

*[STEP 2: Impute];

proc mi data=one nimpute=1 seed=12345 out=donor_pmm_imp; 
	fcs regpmm(donor_age_mi= months_since_origin donor_age in_house pep_star lifetime_card_prom lifetime_prom months_since_last_gift);
	var donor_age_mi months_since_origin donor_age in_house pep_star lifetime_card_prom lifetime_prom months_since_last_gift ; 
run; 

*[STEP 3: Comparative Analysis];
 
/* Find observed vs imputed value statistics */

proc means data=donor_pmm_imp n nmiss min mean max std median; var donor_age donor_age_mi; run;

/* Find observed vs imputed value correlations */

proc corr data=donor_pmm_imp; with donor_age donor_age_mi; run;

/* Plot overlaid histograms  */

proc sgplot data=donor_pmm_imp;
	histogram donor_age /  binwidth=5 transparency=.5;
	histogram donor_age_mi /  binwidth=5 transparency=.5;
run;

proc sgplot data=donor_pmm_imp;
hbox donor_age_mi / boxwidth=1 transparency=.5;
hbox donor_age / boxwidth=1 transparency=.5;
run;


/* Calculate RMSE using imputed values */

proc reg data=donor_pmm_imp;
	model months_since_origin = donor_age in_house pep_star donor_age_mi lifetime_card_prom lifetime_prom months_since_last_gift;
 run;	
rsme--16.707







