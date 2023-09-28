*[1] Dummy variable encoding;

/* Create new variable by adding a 1 to get dummy variable array to work */

%let anal_var = recent_star_status2;
data data610.s_pm1_donor_hw_v3; set data610.s_pm1_donor_hw_v3;
recent_star_status2 = recent_star_status + 1; run;

proc freq data=data610.s_pm1_donor_hw_v3 noprint; tables recent_star_status2/ out=df_freq; run;
	proc sort data=df_freq; by descending COUNT; run;  /* this yields a ranking of neighborhoods by frequency */
		proc print data=df_freq; run;


	data df_freq; set df_freq; recent_star_NUM = _n_; drop percent COUNT; run;
			proc print data=df_freq; run;

	proc sort data=data610.s_pm1_donor_hw_v3; by recent_star_status2; run;
	proc sort data=df_freq; by recent_star_status2; run;

		data df2; merge data610.s_pm1_donor_hw_v3 (in=a) df_freq (in=b); by recent_star_status2; if a; run;
		
			proc freq data=df2; tables recent_star_NUM; run;

%let threshold = 30;

/* First, find frequency for each category and append to dataset */

proc freq data=df2; table &anal_var / out=freq; run;

	proc print data=freq; run;
	
	proc sort data=freq; by &anal_var; run;
	proc sort data=df2; by &anal_var; run;

data df3; merge df2 (in=a) freq (in=b); by &anal_var; if a; run;

data df4; set df3;

	array red(23) DUM_recent_star_1-DUM_recent_star_23;	
		do i = 1 to 23;
			if recent_star_NUM = i and COUNT ge &threshold then red(i) = 1; else red(i) = 0;
		end;
	if sum(of DUM_recent_star_1-DUM_recent_star_23) = 0 then DUM_recent_star_other = 1; 
		else DUM_recent_star_OTHER = 0;
run;

proc means data=df4 min mean max sum std; var DUM_recent_star_1-DUM_recent_star_23 DUM_recent_star_OTHER ; run;	






data dummy; set data610.s_pm1_donor_hw_v3;
if recent_star_status in("R1") then dum_r1 = 1; else dum_r1 = 0;
if recent_star_status in("R2") then dum_r2 = 1; else dum_r2 = 0;
if recent_star_status in("R3") then dum_r3 = 1; else dum_r3 = 0;
run;



data dummy1; set data610.s_pm1_donor_hw_v3;
dum_r0 = (star="R0");
dum_r1 = (star="R1");
dum_r2 = (star="R2");
dum_r3 = (star="R3");
dum_r4 = (star="R4");
dum_r5 = (star="R5");
dum_r6 = (star="R6");
dum_r7 = (star="R7");
dum_r8 = (star="R8");
dum_r9 = (star="R9");
dum_r10 = (star="R10");
dum_r11 = (star="R11");
dum_r12 = (star="R12");
dum_r13 = (star="R13");
dum_r14 = (star="R14");
dum_r15 = (star="R15");
dum_r16 = (star="R16");
dum_r17 = (star="R17");
dum_r18 = (star="R18");
dum_r19 = (star="R19");
dum_r20 = (star="R20");
dum_r21 = (star="R21");
dum_r22 = (star="R22");
run;

/* Then we can check the counts for each dummy variable
by finding the SUM for each */

%let star_dums = dum_r0 dum_r1 dum_r2 dum_r3 dum_r4
dum_r5 dum_r6 dum_r7 dum_r8 dum_r9
dum_r10 dum_r11 dum_r12 dum_r13 dum_r14 dum_r15
dum_r16 dum_r17 dum_r18 dum_r19 dum_r20 dum_r21 dum_r22;

proc means data=dummy1 min mean max sum; var
&star_dums; run;


*/TASK #3 target variable*/;

%let anal_var 		= recent_star_status;
%let target_var  	= target_b;

/* [Step 1]: Create dataset showing proportion of target var */

proc means data=data610.s_pmL_donor_hw_v3 noprint nway;
class &anal_var;
var &target_var;
output out=level mean = prop; run;

proc sort data=level; by descending prop;run;

proc print data=level; format prop percent10.2; run;

*====> simple FREQ;

proc freq data=data610.s_pmL_donor_hw_v3;
table &anal_var; run;

proc freq data=data610.s_pmL_donor_hw_v3;
table &anal_var;
where &target_var = 1; run;

*[Step 2]: Cluster the levels based on the proportions (using
Ward's method);

ods output clusterhistory=cluster;

proc cluster data=level method=ward outtree=fortree;
freq _freq_;
var prop;
id &anal_var;run;

*[Step 3]: Statistically find optimal number of clusters;

proc freq data=data610.s_pmL_donor_hw_v3 noprint;
table &anal_var*&target_var / chisq;
output out=chi(keep=_pchi_) chisq; run;

/* Use a one-to-many merge to put the Chi^2 statistic onto the
clustering results. Calculate a (log) p-value for each level of
clustering. */

data cutoff;
if _n_=1 then set chi;
set cluster;
chisquare=_pchi_*rsquared;
degfree=numberofclusters-1;
logpvalue=logsdf('CHISQ',chisquare,degfree); run;

title1 "Plot of the Log of the P-value by Number of Clusters";
proc sgplot data=cutoff;
series x=numberofclusters y=logpvalue;
xaxis values= (0 to 22 by 1);
run;

*/ Create a macro variable (&ncl) that contains the number of clusters associated
with the minimum log p-value. */;

proc sql;
select NumberOfClusters into :ncl
from cutoff
having logpvalue=min(logpvalue);
quit;

*[Step 4]: Create a dataset “clus” with the cluster solution;

proc tree data=fortree noprint nclusters=&ncl out=clus ;
id &anal_var; run;

proc sort data=clus;
by clusname; run;

title1 "Levels of Categorical Variable by Cluster";
proc print data=clus;
by clusname;
id clusname;
run;

*[Step 5]: Merge cluster assignment onto master file and create dummies;

proc sort data=clus; by &anal_var; run;
proc sort data=data610.s_pmL_donor_hw_v3; by &anal_var; run;

data dummy; merge data610.s_pmL_donor_hw_v3 clus; by &anal_var;
rdum_clus1=(cluster=1); rdum_clus2=(cluster=2);
rdum_clus3=(cluster=3); run;

proc means data=dummy sum; var rdum_clus1-rdum_clus3; run;

/* check frequencies at the target-level */

proc sort data=dummy; by &target_var; run;
proc means data=dummy sum; var rdum_clus1-rdum_clus3;
output out=tmp_sum (drop = _TYPE_ _FREQ_)
sum = rdum_clus1-rdum_clus3;
by &target_var;
where not missing(&target_var); run;

proc transpose data=tmp_sum out=tmp_sum_t; id &target_var; run;

proc print data=tmp_sum_t; run;

*/ Task #4 supervised ratio*/;

*[8.4.3 Target encoding];

%let anal_var 		= recent_star_status;
%let target_var  	= target_b;
%let dsn			= data610.s_pmL_donor_hw_v3;

/* find average target for each category */

proc means data=&dsn mean; var &target_var;	class &anal_var;
	output out=target_mean(drop=_type_ _freq_) mean=sup_ratio_&anal_var.;
run;

proc sort data=&dsn; by &anal_var; run;
proc sort data=target_mean; by &anal_var; run;

	data df_te; merge &dsn(in=a) target_mean(in=b); by &anal_var; if a; run;
	
	proc means data=df_te mean; var sup_ratio_&anal_var.; class &anal_var; run;
	
	proc corr data=df_te; var &target_var sup_ratio_&anal_var.; run;






