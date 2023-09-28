*[Data Integrity Check-Wealth Rating];
proc contents data=data610.s_pml_donor_hw_v3;run;

ods select WEALTH_RATING;				/* "Variables" = SAS name for the output table */
proc contents data=data610.s_pml_donor_hw_v3; run;
ods select default;					/* resets ODS for other procedures */

proc freq data=data610.s_pml_donor_hw_v3; tables WEALTH_RATING / plots=freqplot; run; /* character variables */

proc univariate data=data610.s_pml_donor_hw_v3 noprint; var WEALTH_RATING; histogram WEALTH_RATING / normal; run;

proc freq data=data610.s_pml_donor_hw_v3; tables WEALTH_RATING; run;

proc means data=data610.s_pml_donor_hw_v3 n nmiss std mean median min max; var Wealth_Rating ; run;


*[5.5 Imputing categorical variables];
proc contents data=data610.s_pml_donor_hw_v3; run;
proc print data= data610.a_pm1_donor_hw_v3 (firstobs=1 obs=10); run;
proc means data=data610.s_pml_donor_hw_v3 n nmiss min mean max; run;

/* Create imputation variable and MV flag */

data data610.s_pm1_donor_hw_v3; set data610.s_pml_donor_hw_v3;
	wealth_rating_mi 		= wealth_rating;
	wealth_rating_mi_flag 	= (wealth_rating_mi in(.) );
	wealth_rating_cat_mi 		= wealth_rating_cat;
	wealth_rating_mi_flag 	= (wealth_rating_cat_mi in(.) );
	run;

/* Find observed value statistics */

proc means data=data610.s_pm1_donor_hw_v3 n nmiss min mean max std mode median; var wealth_rating wealth_rating_cat;  run;

/* Find observed value correlations */

proc corr data=data610.s_pm1_donor_hw_v3; with wealth_rating wealth_rating_cat; run;

/* Find observed value frequencies */

proc freq data=data610.s_pm1_donor_hw_v3; tables wealth_rating wealth_rating_cat; run;

/* Find observed value plots */

proc sgplot data=data610.s_pm1_donor_hw_v3;
	hbar wealth_rating;
run;

proc sgplot data=data610.s_pm1_donor_hw_v3;
	hbar wealth_rating_cat;
run;

proc sgplot data=data610.s_pm1_donor_hw_v3; hbox wealth_rating; run;

*[5.5.1 Mode imputation];

*====> Binary categorical variable;

/* Find mode and put into a macrovariable */

proc means data=data610.s_pm1_donor_hw_v3 noprint; var wealth_rating_mi; output out=wealth_mode mode=mode; run;
proc sql; select mode into : mode separated by ' ' from wealth_mode; quit;

/* Create df to impute */

proc stdize data=data610.s_pm1_donor_hw_v3 
	    missing=&mode 
	    reponly 
	    out=one_mode_imp; 
	    var wealth_rating_mi; 
	run; 
	
/* Find observed vs imputed value statistics */

proc means data=one_mode_imp n nmiss min mean mode max std; var wealth_rating wealth_rating_mi; run;

/* Find observed vs imputed value correlations */

proc corr data=one_mode_imp; with wealth_rating wealth_rating_mi; run;

/* Plot overlaid histograms */

proc sgplot data=one_mode_imp;
	histogram wealth_rating / binwidth=1 transparency=.5 scale=count;
	histogram wealth_rating_mi / binwidth = 1 transparency=.5 scale=count;
run;

proc sgplot data=one_mode_imp;
	histogram wealth_rating / binwidth=1 transparency=.5 scale=percent;
	histogram wealth_rating_mi / binwidth = 1 transparency=.5 scale=percent;
run;
	
*[5.5.3 Multicategory categorical variable conditional imputation];

*===> PMM;

proc mi data=data610.s_pm1_donor_hw_v3 nimpute=1 seed=12345 out=wealth_pmm_imp; 
	fcs regpmm(wealth_rating_cat_mi= wealth_rating MEDIAN_HOME_VALUE PEP_STAR  PER_CAPITA_INCOME);
	var wealth_rating MEDIAN_HOME_VALUe PEP_STAR PER_CAPITA_INCOME; run;

/* Find observed vs imputed value statistics */

proc means data= wealth_pmm_imp n nmiss min mean mode max std; var wealth_rating_cat wealth_rating_cat_mi; run;

/* Find observed vs imputed value correlations */

proc corr data=wealth_pmm_imp; with wealth_rating_cat wealth_rating_cat_mi; run;

/* Plot overlaid histograms */

proc sgplot data=df_pmm_imp;
	histogram median_age_cat / binwidth=1 transparency=.5 scale=count;
	histogram median_age_cat_mi / binwidth = 1 transparency=.5 scale=count;
run;

proc sgplot data=df_pmm_imp;
	histogram median_age_cat / binwidth=1 transparency=.5 scale=percent;
	histogram median_age_cat_mi / binwidth = 1 transparency=.5 scale=percent;
run;

/* Find RMSE */

proc reg data=df_pmm_imp;
	model median_house_value = median_age_cat_mi total_rooms total_bedrooms
              median_income population households;
run;	
