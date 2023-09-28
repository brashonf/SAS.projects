proc univariate data=data610.s_pml_donor_hw_v3 noprint;
var lifetime_gift_amount; output out=skew_stats skew=original_skew;
run;

data transformed_data; set data610.s_pml_donor_hw_v3;
log_lifetime_gift_amount = log(lifetime_gift_amount);
run;

proc univariate data=transformed_data noprint;
var log_lifetime_gift_amount; output out=skew_stats skew=transformed_skewness;
run;

proc sgpanel data=data610.s_pml_donor_hw_v3;
panelby target_b;
histogram lifetime_gift_amount; colaxis grid;run;

proc sgpanel data=transformed_data;
panelby target_b;
histogram log_lifetime_gift_amount;
colaxis grid;run;

proc print data= skew_stats label noobs;
var original_skewness transformed_skewness;run;

