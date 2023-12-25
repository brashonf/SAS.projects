libname transprt xport '/home/u63556350/my_courses/ANA625/CDBRFS10.XPT' ; 
 
libname ANAdata '/home/u63556350/my_courses/ANA625'
inencoding= 'latin1' ;

proc copy in=transprt out=ANAdata; run;

libname ANADATA '/home/u63556350/my_courses/ANA625';

*/recoding*/;

data ANAdata.cdbrfs10;
    set ANAdata.cdbrfs10(rename=(_BMI4CAT=BMI));
run;
proc contents data=anadata.cdbrfs10; run;

data ANAdata.cdbrfs10; set ANAdata.cdbrfs10; 
where (18<=age<=99) and sex in(1,2) and diabete2 in(1,3) and exerany2 in(1,2) and 1<= educa <=6 and BMI in(1,2,3) and genhlth in(1,2,3,4,5); 

if 18<=age<=34 then agecat = 1; 
if 35<=age<=54 then agecat = 2; 
if 55<=age then agecat = 3; 

/* have you ever been told by a doctor that you have diabetes? 1 = yes, 3 = no */ 
if diabete2=1 then diabetes = 1; 
if diabete2=3 then diabetes = 0;
 
/* did you participate in any physical activity during the past month? 1 = yes, 2 = no */ 
if exerany2=1 then exercise = 1; 
if exerany2=2 then exercise = 0; 

/* inline recoding of variable SEX */ 
array red sex; 
do over red; 
if red = 2 then red = 1; 
else if red = 1 then red = 0; 
end; 
run;


data ANADATA.cdbrfs10;
    set ANADATA.cdbrfs10; 
    where 18 <= AGE <= 99 and
          SEX in (1, 2) and
          DIABETE2 in (1, 3) and
          EXERANY2 in (1, 2) and
          EDUCA in (1, 2, 3, 4, 5, 6) and
          BMI in (1, 2, 3) and
          GENHLTH in (1, 2, 3, 4, 5);
run;

data ANAdata.cdbrfs10;
    set ANAdata.cdbrfs10;

    if SEX = 0 then
        SEX_LABEL = 'Male';
    else if SEX = 1 then
        SEX_LABEL = 'Female';
run;

proc freq data=ANADATA.cdbrfs10 order=data;
tables SEX*EXERCISE/ norow nopercent nocol chisq
plots=mosaicplot;
run;

proc freq data=ANAdata.cdbrfs10; tables SEX*BMI EXERCISE / chisq;
run;

proc freq data=anadata.cdbrfs10; tables EXERCISE*BMI/chisq;
run;


data ANADATA.cdbrfs10;
    set ANADATA.cdbrfs10;

    OBESITY = ifn(BMI = 1, 0, 1); 

run;


*/ Table 2 diabetes & obesity*/;

proc freq data=anadata.cdbrfs10;
tables diabetes*obesity / nocol nocum nopercent;
run;

proc freq data=anadata.cdbrfs10;
tables diabetes*obesity sex/nocol nocum nopercent;
run;

proc sort data=ANADATA.CDBRFS10;
    by SEX_LABEL;
run;

proc freq data=ANADATA.CDBRFS10;
    tables DIABETES*OBESITY / nopercent nocum nocol chisq;
    by SEX_LABEL;
run;

proc freq data=anadata.cdbrfs10 order=data;
tables DIABETES*OBESITY / nopercent nocum nocol chisq
plots=mosaicplot relrisk cmh;
run;

proc sort data=anadata.cdbrfs10;
    by SEX OBESITY DIABETES;
run;

proc freq data=anadata.cdbrfs10;
    tables DIABETES*OBESITY / nocol nopercent nocum nocol chisq plots= mosaicplot cmh;
    by SEX;
run;







