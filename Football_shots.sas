proc surveyselect data=assign.shots
    out=assign.Football
    method=srs        
    sampsize=5000   
    seed=123;        
run;
 

proc print data=assign.Football;
run; 

 
Proc contents data=assign.football;
run;

/* Create missing values in assign.football */
data assign.football;
    set assign.football;

    /* For numeric variables */
    if ranuni(123) < 0.1 then X = .;       /* 10% missing for X */
    if ranuni(123) < 0.1 then Y = .;       /* 10% missing for Y */
    if ranuni(123) < 0.05 then xG = .;     /* 5% missing for xG */
    if ranuni(123) < 0.1 then h_goals = .; /* 10% missing for h_goals */

    /* For character variables */
    if ranuni(123) < 0.1 then a_team = '';      /* 10% missing for a_team */
    if ranuni(123) < 0.05 then player = '';     /* 5% missing for player */
    if ranuni(123) < 0.1 then situation = '';   /* 10% missing for situation */
run;



PROC PRINT DATA=assign.football;
run;

PROC CONTENTS DATA=assign.football;
RUN;

PROC FREQ data=assign.football ;
RUN;

PROC means data=assign.football n nmiss;
run;


PROC MEANS DATA=assign.football mean std var;
run;

PROC MEANS DATA=assign.football min max;
RUN;

Proc print data=assign.football;
run;

PROC MEANS DATA=assign.football n nmiss mean std var min max;
VAR minute x y xG h_goals a_goals;
RUN;


**mcmcdmc**;
PROC SGPLOT DATA=assign.football;
    VBOX x / CATEGORY=a_team;
    TITLE "Boxplot of X by Team";
RUN;

PROC SGPLOT DATA=assign.football;
    VBOX y / CATEGORY=a_team;
    TITLE "Boxplot of Y by Team";
RUN;

PROC SGPLOT DATA=assign.football;
    VBOX xG;
    TITLE "Boxplot of Expected Goals (xG)";
RUN;

PROC SGPLOT DATA=assign.football;
    VBOX h_goals;
    TITLE "Boxplot of Home Goals";
RUN;

PROC SGPLOT DATA=assign.football;
    VBOX a_goals;
    TITLE "Boxplot of Away Goals";
RUN;


PROC UNIVARIATE DATA=assign.football;
    VAR x y xG h_goals a_goals;
    HISTOGRAM x y xG h_goals a_goals / NORMAL;
    TITLE "Histogram with Normal Curve";
RUN;

PROC FREQ DATA=assign.football;
TABLES a_team player situation / MISSING;
RUN;

DATA assign.football_clean;
    SET assign.football;
    IF CMISS(player, a_team, h_team, situation, player_assisted, lastaction) = 0; 
RUN;

PROC MEANS DATA=assign.football_clean N NMISS MEAN MEDIAN;
VAR x y xG h_goals a_goals;
RUN;

PROC STDIZE DATA=assign.football_clean OUT=assign.football_imputed METHOD=MEAN REPONLY;
VAR xG;
RUN;

PROC STDIZE DATA=assign.football_imputed OUT=assign.football_imputed_1 METHOD=MEDIAN REPONLY;
VAR x y;
RUN;

PROC MEANS DATA=assign.football_imputed_1 N NMISS MEAN MEDIAN;
VAR x y xG;
RUN;

PROC FREQ DATA=assign.football_imputed_1;
TABLES h_goals a_goals / OUT=mode_out;
RUN;

DATA assign.football_imputed_1;
    SET assign.football_imputed_1;
    IF MISSING(h_goals) THEN h_goals = 1; 
RUN;

PROC MEANS DATA=assign.football_imputed_1 N NMISS MEAN MEDIAN;
VAR x y xG h_goals a_goals;
RUN;

PROC SGPLOT DATA=assign.football_imputed_1;
    VBOX xG;
    TITLE "Boxplot of Expected Goals (xG) After Cleaning";
RUN;

PROC SGPLOT DATA=assign.football_imputed_1;
    VBOX h_goals;
    TITLE "Boxplot of Home Goals After Cleaning";
RUN;

DATA assign.football_transformed;
    SET assign.football_imputed_1;
    log_xG = LOG(xG + 1);  /* Adding 1 to avoid log(0) issues */
RUN;

DATA assign.football_transformed;
    SET assign.football_imputed_1;
    shot_distance = SQRT((X - 100)**2 + (Y - 50)**2); /* Assuming goal is at (100,50) */
RUN;


PROC GLMMOD DATA=assign.football_transformed OUTDESIGN=encoded_situation;
    CLASS situation;
    MODEL xG = situation / NOINT;
RUN;

PROC SORT DATA=assign.football_transformed;
    BY xG;
RUN;

PROC SORT DATA=encoded_situation;
    BY xG;
RUN;


DATA assign.football_encoded;
    MERGE assign.football_transformed encoded_situation;
    BY xG;
RUN;

PROC CONTENTS DATA=assign.football_encoded;
RUN;

PROC PRINT DATA=assign.football_encoded;
RUN;

DATA assign.football_encoded_renamed;
    SET assign.football_encoded;
    RENAME col1 = situation_set_piece
           col2 = situation_open_play
           col3 = situation_counter_attack;
RUN;


PROC MEANS DATA=assign.football_encoded_renamed N MEAN MEDIAN STD MIN MAX;
VAR x y xG h_goals a_goals shot_distance;
RUN;

PROC FREQ DATA=assign.football_encoded_renamed;
TABLES a_team h_team player situation_set_piece situation_open_play;
RUN;


PROC CORR DATA=assign.football_encoded_renamed;
VAR x y xG h_goals a_goals shot_distance ;
RUN;


PROC SGPLOT DATA=assign.football_encoded_renamed;
    VBOX xG / CATEGORY=a_team;
    TITLE "Boxplot of xG by Team";
RUN;

PROC SGPLOT DATA=assign.football_encoded_renamed;
    SCATTER X=shot_distance Y=xG / GROUP=a_team;
    TITLE "Scatter Plot of Shot Distance vs Expected Goals (xG)";
RUN;

