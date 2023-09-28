*/First, perform a quick data integrity check on LIFETIME_GIFT_AMOUNT*/;

proc means data=data610.s_pmL_donor_hw_v3 n nmiss mean median mode min max;
var lifetime_gift_amount;run;

proc univariate data=data610.s_pmL_donor_hw_v3; var lifetime_gift_amount;
histogram/normal; run;

proc sgplot data=data610.s_pmL_donor_hw_v3;
hbox lifetime_gift_amount; run;

*[0] First Step - Simple cardinality check;

proc contents data=data610.s_pml_donor_hw_v3 noprint out=lifetime_gift_amount; run;

	proc sql noprint; select name into :dfvars separated by " " from lifetime_gift_amount; quit;
		%put &dfvars;
		
	proc sql noprint; select type into :type separated by " " from lifetime_gift_amount; quit;
		%put &type;



*/summarize your findings from the first 4 extreme value checking*/;

/* use PROC UNIVARIATE to find cut off values - say top and bottom 1% */

%let anal_var = lifetime_gift_amount;

proc univariate data=data610.s_pmL_donor_hw_v3;
var &anal_var; 
output out = tmp pctlpts=1 99 pctlpre=percent;
run;

proc print data=tmp;run;

data hi_low;
set data610.s_pml_donor_hw_v3;
if _n_ = 1 then set tmp;
if &anal_var lt percent1 then range = "low ";
else if &anal_var gt percent99 then range = "high";
else range = "ok";
run;
proc freq data=hi_low; table range;
where not missing(lifetime_gift_amount); run;
proc means data=hi_low; var lifetime_gift_amount;
where range = "high" and
not missing(lifetime_gift_amount); run;


data work.hi_low;
set data610.s_pmL_donor_hw_v3;
if _n_ = 1 then set work.tmp;
if &anal_var lt percent1 and not missing(lifetime_gift_amount) then do;
range = "low ";
output;
end;
else if &anal_var gt percent99 and not missing(lifetime_gift_amount) then do;
range = "high";
output;
end;
run;
proc freq data=work.hi_low; table range; run;

*[6] Outliers based on interquartile range (IQR);

%let anal_var = lifetime_gift_amount;

proc sgplot data=data610.s_pmL_donor_hw_v3;
hbox &anal_var;
where not missing(lifetime_gift_amount);run;

/* use PROC MEANS to find interquartile range */
proc means data=data610.s_pmL_donor_hw_v3 noprint; var &anal_var;
output out=tmp q3 = upper q1 = lower qrange = IQR;
where not missing(lifetime_gift_amount); run; 
proc print data=tmp;run;

/* merge stats values with master file and generate calculations */

%let iqr_mult = 3.0;
data iqr_test; set data610.s_pmL_donor_hw_v3; if _n_ = 1 then set tmp;
if &anal_var lt lower - &iqr_mult*IQR then range = "low ";
else if &anal_var gt upper + &iqr_mult*IQR then range = "high";
else range = "ok";
run;

proc freq data=iqr_test; table range;
where not missing(lifetime_gift_amount);
run;

proc means data=iqr_test; var lifetime_gift_amount;
where range = "high" and not missing(lifetime_gift_amount);
run;

*[7] Extremes based on clustering;

*====> invoke FASTCLUS to group obs into 50 clusters;

proc fastclus data=data610.s_pmL_donor_hw_v3 maxc=50 maxiter=100 cluster=_clusterindex_ out=temp_clus noprint;
var lifetime_gift_amount;
run;

*====> analyze resulting clusters;

proc freq data=temp_clus noprint;
tables _clusterindex_ / out=temp_freq; run;

proc sort data=temp_freq; by descending percent;

Title 'Clusters and Member %'; 
proc print data=work.temp_freq; run;
proc sgplot data=temp_freq; vbar _clusterindex_ / response=count categoryorder=respasc; run;

*====> isolate clusters with a size less than pmin of the dataset size;

data work.temp_low; set work.temp_freq;
	if percent < .006 and _clusterindex_ notin(.); _extreme_ = 1;
	keep _clusterindex_ _extreme_;
run; 

*====> merge these isolated clusters back onto the master dataset;

proc sort data=work.temp_clus; by _clusterindex_; run;
proc sort data=work.temp_low; by _clusterindex_; run;

data gift_out; merge work.temp_clus work.temp_low; by _clusterindex_;
	if _extreme_ = . then _extreme_ = 0;
run;

*====> print the extreme values;

proc sort data=gift_out; by lifetime_gift_amount; run;
Title 'Extremes (single member clusters)';
proc print data=gift_out; var lifetime_gift_amount  _extreme_; where _extreme_ = 1; run;






*[6.3.2 Distribution examination...importance of PROC EYEBALL];

/* Descriptive stats */

proc means data=data610.s_pm1_donor_hw_v3 n nmiss min mean median max std skew; var lifetime_gift_amount; run;

/* Distribution */

proc sgplot data=data610.s_pm1_donor_hw_v3; histogram lifetime_gift_amount  / binwidth=1000; run;

/* Top/bottom 10 => quickly identifies EVs in quantiles and extreme obs tables */

proc univariate data=data610.s_pm1_donor_hw_v3 nextrobs=10; var lifetime_gift_amount; run;

/* Count above/below cutoff values */

proc sql; select count(lifetime_gift_amount) as n_obs from data610.s_pm1_donor_hw_v3 where lifetime_gift_amount > 1000; quit;
proc sql; select count(lifetime_gift_amount) as n_obs from data610.s_pm1_donor_hw_v3 where lifetime_gift_amount < 4000; quit;

/* Distribution after applied cutoff */

proc sgplot data=data610.s_pm1_donor_hw_v3; histogram lifetime_gift_amount / binwidth=1000; 
	where lifetime_gift_amount <= 20000;
run;

proc means data=data610.s_pm1_donor_hw_v3 n nmiss min mean median max std skew; var lifetime_gift_amount; 
	where lifetime_gift_amount <= 20000;
run;

%let anal_var = lifetime_gift_amount;

proc univariate data=data610.s_pm1_donor_hw_v3;
var &anal_var; 
output out = giftmp pctlpts=1 99 pctlpre=percent;
run;

proc print data=giftmp;run;

*/ Grubbs Test p-value=0.05*/;

/* find ds size */

proc sql noprint; select count(*) into: obs from data610.s_pmL_donor_hw_v3; quit; 

/* find var stats */

proc means data=data610.s_pml_donor_hw_v3 noprint; var lifetime_gift_amount; output out=df_stats(drop= _type_ _freq_) max=max min=min mean=mean std=std; run;

/* find Grubbs critical value and apply test */

data df_t; set data610.s_pml_donor_hw_v3; if _n_ = 1 then set df_stats; 
	t2 = tinv(0.05/(2*lifetime_gift_amount), lifetime_gift_amount-2);
	gcrit2 = ((lifetime_gift_amount-1)/sqrt(lifetime_gift_amount))*sqrt(t2*t2/(lifetime_gift_amount-2+t2*t2));
	g = abs(lifetime_gift_amount - mean)/std;
	if g <= gcrit2 then test_result = "Not Extreme Value"; else test_result = "Extreme Value";
run;

/* report findings */

proc print data=df_t; var lifetime_gift_amount test_result; where lifetime_gift_amount = max; 
	Title "Grubbs Test for One Outlier: High End"; run;
proc print data=df_t; var lifetime_gift_amount test_result; where lifetime_gift_amount = min; 
	Title "Grubbs Test for One Outlier: Low End"; run;


%macro GrubbsTest(dsin,var,alpha);
%let dsin = data610.s_pmL_donor_hw_v3;
%let anal_var = lifetime_gift_amount;
%let alpha = 0.05;

data data610.s_pmL_donor_hw_v3; set data610.s_pml_donor_hw_v3; where &anal_var < 4000;run;



