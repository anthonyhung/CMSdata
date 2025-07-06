/**********************************************************************/
/* Title:       PROCEDURE CLASSES REFINED                             */
/*              FOR ICD-10-PCS MAPPING PROGRAM                        */
/*                                                                    */
/* Program:     PClassR_Mapping_Program_v2023-1.sas                   */
/*                                                                    */
/* Procedures:  v2023-1 is compatible with ICD-10-PCS procedure       */
/*              codes from October 2015 through September 2023.       */
/*              ICD-10-PCS codes should not include embedded          */
/*              decimals (example: OBH13YZ).                          */
/*                                                                    */
/* Description: This SAS mapping program adds the procedure classes   */
/*              data elements to the user's ICD-10-PCS-coded data.    */
/*                                                                    */
/*              There are two general sections to this program:       */
/*              1) The first section creates a temporary SAS          */
/*                 informat using the Procedure Classes Refined for   */
/*                 ICD-10-PCS CSV file. This informats is used to     */
/*                 create the procedure classes variables.            */
/*              2) The second section loops through the procedure     */
/*                 array in your SAS dataset and assigns the          */
/*                 procedure classes variables added to the output    */
/*                 file.                                              */
/*                                                                    */
/* Output:	    This program appends the procedures classes to the    */
/*	            input SAS file. The data elements are named PCLASSn,  */
/*              where n ranges from 1 to the maximum number of        */
/*              available procedures. Program also adds an indicator  */
/*              that an operating room procedure (major diagnostic or */
/*              therapeutic procedure) was found on the record.       */
/*                                                                    */
/**********************************************************************/

/*******************************************************************/
/*      THE SAS MACRO FLAGS BELOW MUST BE UPDATED BY THE USER      */ 
/*  These macro variables must be set to define the locations,     */
/*  names, and characteristics of your input and output SAS        */
/*  formatted data.                                                */
/*******************************************************************/

/**********************************************/
/*          SPECIFY FILE LOCATIONS            */
/**********************************************/
FILENAME INRAW1  'c:\directory\PClassR_v2023-1.csv' LRECL=300;    * Location of Procedure Classes CSV file.            <===USER MUST MODIFY;
LIBNAME  IN1     'c:\sasdata\';                                   * Location of input discharge data.                  <===USER MUST MODIFY;
LIBNAME  OUT1    'c:\sasdata\';                                   * Location of output data.                           <===USER MUST MODIFY;
                                    
                                       
/*********************************************/
/*   SPECIFY INPUT FILE CHARACTERISTICS      */
/*********************************************/ 
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
/*   SPECIFY INPUT and OUTPUT FILE NAMES      */
/**********************************************/
* Specify the name of the input dataset;                     %LET CORE=YOUR_SAS_FILE_HERE;  *<===USER MUST MODIFY;
* Specify the name of the output dataset;                    %LET OUT1=OUTPUT_SAS_FILE;     *<===USER MUST MODIFY; 


/*********************************************/
/*   SET PCLASS VERSION                      */
/*********************************************/ 
%LET PCLASS_VERSION = "2023.1" ; *<=== DO NOT MODIFY;


TITLE1 'Procedure Classes Refined for ICD-10-PCS Procedures';
TITLE2 'Mapping Program';


/******************* SECTION 1: CREATE INFORMATS ******************/
/*  SAS Load the Procedure Classes Refined for ICD-10-PCS mapping */
/*  file and convert it into a temporary SAS informat that will   */
/*  be used to assign the procedure class fields in the next step.*/
/******************************************************************/
data pclass ;
    infile inraw1 dsd dlm=',' end = eof firstobs=3;
    input
       start            : $char7.
       icd10pcs_label   : $char100.
       label            : 3.
       pclass_label     : $char100.
    ;
   retain hlo " ";
   fmtname = "pclass" ;
   type    = "i" ;
   output;

   if eof then do ;
      start = " " ;
      label = . ;
      hlo   = "o";
      output ;
   end ;
run;

proc format lib=work cntlin = pclass ;
run;

/************** SECTION 2: CREATE REFINED PROCEDURE CLASSES ***********/
/*  Create procedure classes for ICD-10-PCS using the SAS             */
/*  informat created above & the SAS output dataset you specified.    */
/*  Users can change the names of the output procedure class          */
/*  variables if needed here. It is also important to make sure       */
/*  that the correct ICD-10-PCS procedure prefixes are specified      */
/*  correctly in the macro PRPREFIX above.                            */
/**********************************************************************/  
%macro pclass;
%if &numpr > 0 %then %do; 
options obs=&OBS.;

data out1.&OUT1. (DROP = I);
   label pclass_version = "Version of ICD-10-PCS Procedure Classes Refined";
   retain PCLASS_VERSION &PCLASS_VERSION;
   
   set in1.&CORE;

   /****************************************************/
   /* Loop through the PCS procedure array in your SAS */
   /* dataset and create the procedure class           */
   /* variables as well as the pclass_orproc flag.     */
   /****************************************************/
   label pclass_orproc = "Indicates operating room procedure reported on the record";
   pclass_orproc = 0;

   array     pclass (*)  3 pclass1-pclass&NUMPR;           * Suggested name for procedure class variables.  <===USER MAY MODIFY;
   array prs        (*)  $ &PRPREFIX.1-&PRPREFIX.&NUMPR;           

   %if &NPRVAR ne %then %let MAXNPR = &NPRVAR;
   %else                %let MAXNPR = &NUMPR;
   
   do i = 1 to min(&MAXNPR,dim(prs));
      pclass(i) = input(prs(i), pclass.);  
      if pclass(i) in (3,4) then pclass_orproc=1;
   end;
   %do i = 1 %to &NUMPR.;
       label pclass&i. = "ICD-10-PCS Procedure Classes Refined &i.";             * Labels for procedure class variables      <===USER MAY MODIFY;  
   %end;
run;

proc means data=out1.&OUT1. n nmiss mean min max;
   var pclass1-pclass&NUMPR. pclass_orproc;
   title2 "MEANS ON THE OUTPUT ICD-10-PCS PROCEDURE CLASSES";
run;
%end;
%else %do;
   %put;
   %put 'ERROR: NO PROCEDURE CODES SPECIFIED FOR MACRO VARIABLE NUMPR, PROGRAM ENDING';
   %put;
%end;

%mend pclass;
%pclass;