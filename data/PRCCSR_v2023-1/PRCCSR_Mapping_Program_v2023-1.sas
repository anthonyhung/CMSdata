/******************************************************************/
/* Title:       CLINICAL CLASSIFICATIONS SOFTWARE REFINED (CCSR)  */
/*              FOR ICD-10-PCS MAPPING PROGRAM                    */
/*                                                                */
/* Program:     PRCCSR_Mapping_Program_v2023-1.SAS                */
/*                                                                */
/* Procedures:  v2023-1 is compatible with ICD-10-PCS procedure   */
/*              codes from October 2015 through September 2023.   */
/*              ICD-10-PCS codes should not include embedded      */
/*              decimals (example: OBH13YZ).                      */
/*                                                                */
/* Description: This SAS mapping program creates up to two files  */
/*              that include the CCSR for ICD-10-PCS data elements*/
/*		        based on the user provided ICD-10-PCS codes.      */
/*                                                                */
/*              There are two general sections to this program:   */
/*              1) The first section creates temporary SAS        */
/*                 informats using the PRCCSR CSV file.           */
/*                 These informats are used in step 2 to create   */
/*                 the CCSR variables.                            */
/*              2) The second section loops through the procedure */
/*                 array in your SAS dataset and assigns          */
/*                 CCSR categories in the output files.           */
/*                                                                */
/* Output:	    This program creates up to two different types    */
/*		    of output files with the CCSR data elements.          */
/*                                                                */
/*              + Vertical file includes the data elements:       */
/*                    RECID PRCCSR PR_POSITION                    */
/*                    PRCCSR_VERSION                              */
/*                                                                */
/*              + Horizontal file includes the data elements:     */
/*                    RECID PRCCSR_BBBNNN where                   */
/*                       BBB is 3-letter clinical domain          */
/*                       NNN is 3-digit number                    */
/*                    PRCCSR_VERSION                              */
/******************************************************************/

/*******************************************************************/
/*      THE SAS MACRO FLAGS BELOW MUST BE UPDATED BY THE USER      */ 
/*  These macro variables must be set to define the locations,     */
/*  names, and characteristics of your input and output SAS        */
/*  formatted data.                                                */
/*******************************************************************/

/**********************************************/
/*          SPECIFY FILE LOCATIONS            */
/**********************************************/
FILENAME INRAW1  'c:\directory\PRCCSR_v2023-1.csv' LRECL=3000;  * Location of CCSR CSV file.        <===USER MUST MODIFY;
LIBNAME  IN1     'c:\sasdata\';                                 * Location of input discharge data. <===USER MUST MODIFY;
LIBNAME  OUT1    'c:\sasdata\';                                 * Location of output data.          <===USER MUST MODIFY;

/*********************************************/
/*   SPECIFY INPUT FILE CHARACTERISTICS      */
/*********************************************/ 
* Specify the unique record identifier on the input 
  SAS file that can be used to link information back to 
  original input SAS data file;                              %LET RECID=KEY;        *<=== USER MUST MODIFY; 

* Specify the prefix used to name the ICD-10-PCS 
  procedure data element array in the input dataset. 
  In this example the procedure data elements would be 
  named I10_PR1, I10_PR2, etc., similar to the naming 
  of ICD-10-PCS data elements in HCUP databases;             %LET PRPREFIX=I10_PR;  *<===USER MUST MODIFY;

* Specify the maximum number of procedure codes on 
  any record in the input file;                              %LET NUMPR=15;         *<===USER MUST MODIFY;

* Specify the name of the variable that contains a 
  count of the ICD-10-PCS codes reported on a record.  
  If no such variable exists, leave macro blank;             %LET NPRVAR=I10_NPR;   *<=== USER MUST MODIFY;

* Specify the number of observations to use from the 
  input dataset.  Use MAX to use all observations and
  use a smaller value for testing the program;               %LET OBS=MAX;          *<===USER MAY MODIFY;

/**********************************************/
/*          SPECIFY OUTPUT FILE TYPES         */
/**********************************************/
* Build vertical file? 1=yes, 0=no;           %LET VERT=1;                          *<=== USER MUST MODIFY;
* Build horizontal file? 1=yes, 0=no;         %LET HORZ=1;                          *<=== USER MUST MODIFY;

/**********************************************/
/*   SPECIFY INPUT and OUTPUT FILE NAMES      */
/**********************************************/
* Input SAS file member name;                 %LET CORE=INPUT_SAS_FILE;             *<=== USER MUST MODIFY;
* Output SAS file name, vertical;             %LET VERTFILE=OUTPUT_VERT_FILE_NAME;  *<=== USER MUST MODIFY; 
* Output SAS file name, horizontal;           %LET HORZFILE=OUTPUT_HORZ_FILE_NAME;  *<=== USER MUST MODIFY;

/*********************************************/
/*   SET CCSR VERSION                        */
/*********************************************/ 
%LET PRCCSR_VERSION = "2023.1" ; *<=== DO NOT MODIFY;


TITLE1 'Clinical Classifications Software Refined (CCSR) for ICD-10-PCS Procedures';
TITLE2 'Mapping Program';


/******************* SECTION 1: CREATE INFORMATS ****************************/
/*  SAS Load the CCSR CSV file & convert into temporary SAS informats that  */
/*  will be used to assign the PRCCSR variables in the next step.           */
/****************************************************************************/
DATA PRCCSR;
    LENGTH LABEL $1140;
    INFILE INRAW1 DSD DLM=',' END = EOF FIRSTOBS=2;
    INPUT
       START             : $CHAR7.
       I10Label          : $CHAR124.
       I10CCSR           : $10.
       I10CCSRLabel      : $CHAR228.
       I10CCSRCD         : $CHAR228.
    ;

   RETAIN HLO " " FMTNAME "$PRCCSR" TYPE  "J" ;
   
   LABEL = I10CCSR;
   OUTPUT;

   IF EOF THEN DO ;
      START = " " ;
      LABEL = " " ;
      HLO   = "O";
      OUTPUT ;
   END ;
RUN;

PROC FORMAT LIB=WORK CNTLIN = PRCCSR;
RUN;

DATA PRCCSRL(KEEP=START LABEL FMTNAME TYPE HLO);
  SET PRCCSR(KEEP=I10CCSR: rename=(I10CCSR=START I10CCSRLabel=LABEL)) END=EOF;

  RETAIN HLO " " FMTNAME "$PRCCSRL" TYPE  "J" ;
  OUTPUT;
  
  IF EOF THEN DO ;
     START = " " ;
     LABEL = " " ;
     HLO   = "O";
     OUTPUT;
  END;
run;

PROC SORT DATA=PRCCSRL NODUPKEY; 
  BY START; 
RUN;

PROC FORMAT LIB=WORK CNTLIN = PRCCSRL;
RUN;

DATA PRCCSRCD(KEEP=START LABEL FMTNAME TYPE HLO);
  SET PRCCSR(KEEP=I10CCSR: rename=(I10CCSR=START I10CCSRCD=LABEL)) END=EOF;

  RETAIN HLO " " FMTNAME "$PRCCSRCD" TYPE  "J" ;
  OUTPUT;
  IF EOF THEN DO ;
     START = " " ;
     LABEL = " " ;
     HLO   = "O";
     OUTPUT;
  END;
RUN;

PROC SORT DATA=PRCCSRCD NODUPKEY; 
   BY START; 
RUN;

PROC FORMAT LIB=WORK CNTLIN = PRCCSRCD;
RUN;

/*********** SECTION 2: CREATE ICD-10-PCS CCSR OUTPUT FILES **********************/
/*  Create CCSR categories for ICD-10-PCS using the SAS informats created        */
/*  in Section 1 and the ICD-10_PCS codes in your SAS dataset.                   */
/*  At most two separate output files are created plus a few intermediate files  */
/*  for the construction of the horizontal file                                  */
/*********************************************************************************/  

%MACRO prccsr_vt;
   DATA &VERTFILE (KEEP=&RECID PRCCSR PR_POSITION PRCCSR_VERSION) ;
     RETAIN &RECID;
     LENGTH ICD10_Code $7 PRCCSR $6 PR_POSITION 3 PRCCSR_VERSION $6;
     LABEL PRCCSR   = "CCSR category for ICD-10-PCS procedures"
		   PR_POSITION = "Position of code in input procedure array"
		   PRCCSR_VERSION = "Version of CCSR for ICD-10-PCS procedures"
		   ;
     RETAIN PRCCSR_VERSION &PRCCSR_VERSION;

     SET &CORE.Skinny;
	 BY &RECID;
     ARRAY A_PR(&NUMPR) &PRPREFIX.1-&PRPREFIX.&NUMPR;

     %IF &NPRVAR NE %THEN %LET MAXNPR = &NPRVAR;
     %ELSE %LET MAXNPR=&NUMPR;
 
     IF missing(&PRPREFIX.1) THEN DO;
        PR_POSITION = 1;
        PRCCSR = 'NoPR1';
        OUTPUT &VERTFILE;
     END;
     DO I=1 TO min(&MAXNPR,dim(A_PR));
       ICD10_CODE=A_PR(I);
       PR_POSITION=I;
       PRCCSR=INPUT(A_PR(I), $PRCCSR.); 
       IF not missing(ICD10_CODE) and missing(PRCCSR) THEN DO;
	      ***invalid ICD-10-PCS found;
		  PRCCSR='InvlPR';
	   END;
       IF not missing(ICD10_CODE) THEN OUTPUT &VERTFILE;
     END; 
RUN;
TITLE3 "Vertical file";
PROC CONTENTS DATA=&VERTFILE VARNUM;
RUN;
TITLE3 "Sample print of vertical file";
PROC PRINT DATA=&VERTFILE(obs=10);
RUN;
%MEND;

* =========================================================================== * 
* Count maximum number of PRCCSR values for each clinical domain.             *
* Please do not change this code. It is necessary to the program function.    *
* =========================================================================== *;
%MACRO count_prccsr;
  DATA ClinicalDomain;
    LENGTH cd cdnum $3 ;
    SET PRCCSR(KEEP=I10CCSR:) END=EOF;
    
    cd=substr(I10CCSR, 1, 3);
    cdnum=substr(I10CCSR, 4, 3);
    output;
    KEEP cd cdnum;
   RUN;
   PROC SORT DATA=ClinicalDomain; 
     BY cd cdnum ; 
   RUN;
   DATA cd_max;
     SET ClinicalDomain;
     BY cd cdnum;
     IF last.cd;
   RUN;
   %GLOBAL mncd;
   %GLOBAL cd_;
   PROC SQL NOPRINT;
     SELECT DISTINCT cd INTO :cd_ SEPARATED BY ' '
     FROM cd_max
     ; 
   QUIT;
   DATA _NULL_;
     SET cd_max END=eof;
     IF EOF THEN CALL symput("mncd", put(_N_, 2.)); 
   RUN; 

   %DO i=1 %TO &mncd;
     %LET cd=%scan(&cd_, &i);
     %GLOBAL max&cd. ;
   %END;  

   DATA _NULL_;
     SET cd_max END=eof;
     mcd="max" || cd; 
     CALL symput(mcd, cdnum); 
   RUN; 

   %PUT verify macro definition:;
   %PUT mncd=&mncd;
   %DO i=1 %TO &mncd;
     %LET cd=%scan(&cd_, &i);
     %PUT max&cd._ = &&&max&cd;
   %END;  
%MEND;

%MACRO prccsr_hz;
* =========================================================================== * 
* Create horizontal file layout using vertical file                           *
* =========================================================================== *;
DATA PRCCSR_First(KEEP=&RECID PRCCSR) PRCCSR_second(KEEP=&RECID PRCCSR);
  SET &VERTFILE;
  BY &RECID;
  IF PRCCSR not in ('NoPR1','InvlPR');
  IF PR_Position = 1 THEN OUTPUT PRCCSR_First;
  ELSE OUTPUT PRCCSR_Second;
RUN;

PROC SORT DATA=PRCCSR_second NODUPKEY;
  BY &RECID PRCCSR;
RUN;
PROC SORT DATA=PRCCSR_First;
  BY &RECID PRCCSR;
RUN;

DATA PRCCSR;
  LENGTH PR_Position 3;
  MERGE PRCCSR_First(IN=inp) PRCCSR_Second(IN=ins);
  BY &RECID PRCCSR;
  IF inp and not ins THEN PR_Position = 1;
  ELSE IF ins and not inp THEN PR_Position = 3;
  ELSE PR_Position = 2;
RUN;

PROC TRANSPOSE DATA=PRCCSR OUT=PRCCSR_Transposed(DROP=_NAME_) PREFIX=PRCCSR_; 
  BY &RECID;
  ID PRCCSR;
  VAR PR_Position;
RUN; 

**** Some input records may not have any or only invalid ICD-10_PCS codes 
     and not be represented in the vertical file.
     Ensure the horizontal output file has the same number of records as input file;
DATA out1.&HORZFILE ;
  RETAIN &RECID; 
  LENGTH PRCCSR_VERSION $6
    %DO i=1 %TO &mncd; 
      %LET cd=%scan(&cd_, &i);
      PRCCSR_&cd.001-PRCCSR_&cd.&&max&cd. 
    %END;
    3 ;
   LABEL PRCCSR_VERSION = "Version of CCSR for ICD-10-PCS procedures" 
     %DO i=1 %TO &mncd; 
      %LET cd=%scan(&cd_, &i);
	  %DO j=1 %TO &&max&cd. ;
	     %IF &j < 10 %THEN PRCCSR_&cd.00&j = "Indication that at least one ICD-10-PCS procedure on the record is included in CCSR &cd.00&j" ;
	     %ELSE %IF &j < 100 %THEN PRCCSR_&cd.0&j = "Indication that at least one ICD-10-PCS procedure on the record is included in CCSR &cd.0&j" ;
	     %ELSE PRCCSR_&cd.&j = "Indication that at least one ICD-10-PCS procedure on the record is included in CCSR &cd.&j" ;
	  %END;
    %END;
    ;
  RETAIN PRCCSR_VERSION &PRCCSR_VERSION;
  
  MERGE &CORE.Skinny(IN=ini KEEP=&RECID) PRCCSR_Transposed;
  BY &RECID;

  IF not ini THEN abort; 

  ***If no ICD-10-PCS are found on the record, or any PRCCSR not exists on records, set PRCCSR_* values to 0;
  ARRAY a _numeric_;
  DO OVER a;
    IF a = . THEN a=0;
  END;
RUN;

TITLE3 "Horizontal file";
PROC CONTENTS DATA=out1.&HORZFILE VARNUM;
RUN;
TITLE3 "Sample print of horizontal file";
PROC PRINT DATA=out1.&HORZFILE(OBS=10);
RUN;
%MEND;

%MACRO main;
   %count_prccsr;
   PROC SORT DATA=IN1.&CORE(OBS = &OBS KEEP=&RECID &NPRVAR &PRPREFIX.1-&PRPREFIX.&NUMPR) OUT=&CORE.Skinny; 
     BY &RECID;  
   RUN;
   %prccsr_vt;
   %if &vert = 1 %then %do; 
	 DATA OUT1.&VERTFILE(SORTEDBY=&RECID);
	   SET &VERTFILE;
	   BY &RECID;
	 RUN;  
   %END;
   %IF &horz = 1 %THEN %DO; 
     %prccsr_hz;
   %END;
%MEND;
%main;