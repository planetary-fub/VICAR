$!****************************************************************************
$!
$! Build proc for MIPL module hrpref2asc
$! VPACK Version 1.9, Thursday, March 24, 2005, 14:21:22
$!
$! Execute by entering:		$ @hrpref2asc
$!
$! The primary option controls how much is to be built.  It must be in
$! the first parameter.  Only the capitalized letters below are necessary.
$!
$! Primary options are:
$!   COMPile     Compile the program modules
$!   ALL         Build a private version, and unpack the PDF and DOC files.
$!   STD         Build a private version, and unpack the PDF file(s).
$!   SYStem      Build the system version with the CLEAN option, and
$!               unpack the PDF and DOC files.
$!   CLEAN       Clean (delete/purge) parts of the code, see secondary options
$!   UNPACK      All files are created.
$!   REPACK      Only the repack file is created.
$!   SOURCE      Only the source files are created.
$!   SORC        Only the source files are created.
$!               (This parameter is left in for backward compatibility).
$!   PDF         Only the PDF file is created.
$!   IMAKE       Only the IMAKE file (used with the VIMAKE program) is created.
$!
$!   The default is to use the STD parameter if none is provided.
$!
$!****************************************************************************
$!
$! The secondary options modify how the primary option is performed.
$! Note that secondary options apply to particular primary options,
$! listed below.  If more than one secondary is desired, separate them by
$! commas so the entire list is in a single parameter.
$!
$! Secondary options are:
$! COMPile,ALL:
$!   DEBug      Compile for debug               (/debug/noopt)
$!   PROfile    Compile for PCA                 (/debug)
$!   LISt       Generate a list file            (/list)
$!   LISTALL    Generate a full list            (/show=all)   (implies LIST)
$! CLEAN:
$!   OBJ        Delete object and list files, and purge executable (default)
$!   SRC        Delete source and make files
$!
$!****************************************************************************
$!
$ write sys$output "*** module hrpref2asc ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_PDF = ""
$ Create_Imake = ""
$ Do_Make = ""
$!
$! Parse the primary option, which must be in p1.
$ primary = f$edit(p1,"UPCASE,TRIM")
$ if (primary.eqs."") then primary = " "
$ secondary = f$edit(p2,"UPCASE,TRIM")
$!
$ if primary .eqs. "UNPACK" then gosub Set_Unpack_Options
$ if (f$locate("COMP", primary) .eqs. 0) then gosub Set_Exe_Options
$ if (f$locate("ALL", primary) .eqs. 0) then gosub Set_All_Options
$ if (f$locate("STD", primary) .eqs. 0) then gosub Set_Default_Options
$ if (f$locate("SYS", primary) .eqs. 0) then gosub Set_Sys_Options
$ if primary .eqs. " " then gosub Set_Default_Options
$ if primary .eqs. "REPACK" then Create_Repack = "Y"
$ if primary .eqs. "SORC" .or. primary .eqs. "SOURCE" then Create_Source = "Y"
$ if primary .eqs. "PDF" then Create_PDF = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_PDF .or. Create_Imake .or -
        Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hrpref2asc.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_PDF then gosub PDF_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_PDF = "Y"
$   Create_Imake = "Y"
$ Return
$!
$ Set_EXE_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Default_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$   Create_PDF = "Y"
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$   Create_PDF = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Create_PDF = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("hrpref2asc.imake") .nes. ""
$   then
$      vimake hrpref2asc
$      purge hrpref2asc.bld
$   else
$      if F$SEARCH("hrpref2asc.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrpref2asc
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrpref2asc.bld "STD"
$   else
$      @hrpref2asc.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrpref2asc.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrpref2asc.com -mixed -
	-s hrpref2asc.c -
	-i hrpref2asc.imake -
	-p hrpref2asc.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrpref2asc.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "vicmain_c"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include <hrpref.h>
#include "hwldker.h"


void main44()

{
int             inunit, ns, nl, nbb;
FILE            *ascfile;
int             status, count, idummy;
int             i, linp, max_lines, sl, increment;
char            ct0[9], ct1[9], ct2[9], ct3[9], ct4[9];
char            lv1filename[512], ascfilename[512];
char            cdummy[512], mode[32], check[20];
float           comp;
char            comp_name[30];
hrpref_typ      prefix;
hwkernel_1	tls;


/* load the LEAPSECONDS kernel */
status=hwldker(1, "tls", &tls);
if (status != 1) {
    printf("#E  Unable to load the Leapseconds kernel\n");
    printf("#E  Error Code = %d\n",status);
    zabend();
    }


/*    Open the input file */
zvp("INP", lv1filename, &count);

status=zvunit(&inunit, "INP", 1, 0);
if (status != 1) {
    printf("#E  Unable to get the unit number\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

status=zvopen(inunit, "COND","BINARY", 0);
if (status != 1) {
    printf("#E  Error by opening input file %s\n", lv1filename);
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

/*    Test the image properties - is this the right image? */
zvp("CHECK", check, &count);
if (strcmp(check, "NOCHECK")) {

    /* HRSC Image ? */
    status=zlget(inunit,"PROPERTY","INSTRUMENT_ID",cdummy,"FORMAT","STRING",
        	    "PROPERTY","M94_INSTRUMENT",0);

    if (status != 1) {
        printf("#E  Error by reading label INSTRUMENT_ID");
        printf("#E  Error status code: %d",status);
        zabend();
        }

    if (strcmp(cdummy,"HRSC")) {
        printf("#E  This is not a HRSC image! (Wrong INSTRUMENT_ID)");
        zabend();
        }

    /* correct processing level? */
    status=zlget(inunit,"PROPERTY","PROCESSING_LEVEL_ID",&idummy,"FORMAT","INT",
        	    "PROPERTY","FILE",0);

    if (status != 1) {
        printf("#E  Error by reading label PROCESSING_LEVEL_ID");
        printf("#E  Error status code: %d",status);
        zabend();
        }

    if ((idummy != 1) && (idummy != 2)) {
        printf("#E  Wrong PROCESSING_LEVEL_ID");
        zabend();
        }

    }

/*    Read the needed image labels */

status=zvget(inunit,"NL",&nl, "NS", &ns, "NBB", &nbb, 0);
if (status != 1) {
    printf("#E  Error by reading label NL\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

if (nbb != HRPREF_LEN) {
    printf("#E  This image contains no HRSC prefix.\n");
    zabend();
    }

/*  Start at line SL */
zvp( "SL", &sl, &count);
if (sl < 1) sl=1;
if (sl > nl) {
    printf("#E  Starting Line > Number of Lines in the file (%d)\n",nl);
    zabend();
    }
/*  Maximum prefixes to read */
zvp( "NL", &max_lines, &count);
if (max_lines <= 0) max_lines=nl;
if (max_lines+sl-1 > nl) max_lines=nl+1-sl;

/*  Increment of prefixes to read */
zvp( "IL", &increment, &count);
if (increment <= 0) increment=1;

/* Output mode */
zvp( "MODE", mode, &count);

/* Open the output data file */
zvp( "OUT", ascfilename, &count);
if (count < 1) {
    ascfile=stdout;
    }
else {
    if( (ascfile = fopen(ascfilename,"w")) == NULL) {
        perror("#E  hrpref2ASC");
        printf("#E  Can't open ASCII file %s\n", ascfilename);
        zabend();
        }
    }

if (strcmp(mode,"SHORT") == 0)
    fprintf(ascfile, " Line            UTC             ExpTime Gain   FPM     FEE    OBench  CamObj   DU  \n\n");

if (strcmp(mode,"LONG") == 0)
    {
    status=zlget(inunit,"PROPERTY","INST_CMPRS_NAME",comp_name,"FORMAT","STRING",
                 "PROPERTY","M94_CAMERAS",0);

    if (status != 1) {
        printf("#E  Error by reading label INST_CMPRS_NAME\n");
        printf("#W  No compression will be displayed\n");
        strcpy(comp_name,"UNKNOWN");
        }

    fprintf(ascfile, " Line            UTC             ExpTime Gain   FPM     FEE    OBench  CamObj   DU     FrameCnt ActPxl  EphTime        Comp\n\n");
    }    

/* Analyze the data */
for (linp=sl; linp <= sl+max_lines-1; linp+=increment) {

    /* Read line prefix */
    hrrdpref(inunit, linp, &prefix);

    et2utc_c(prefix.EphTime, "C", 3, 80, cdummy);

    if (prefix.FPMTemp   > 1) sprintf(ct0,"%5.1f°C",(prefix.FPMTemp  -27315)/100.);
    else                      sprintf(ct0,"   - °C");
    if (prefix.FEETemp   > 1) sprintf(ct1,"%5.1f°C",(prefix.FEETemp  -27315)/100.);
    else                      sprintf(ct1,"   - °C");              
    if (prefix.OBTemp    > 1) sprintf(ct2,"%5.1f°C",(prefix.OBTemp   -27315)/100.);
    else                      sprintf(ct2,"   - °C");              
    if (prefix.COT       > 1) sprintf(ct3,"%5.1f°C",(prefix.COT      -27315)/100.);
    else                      sprintf(ct3,"   - °C");
    if (prefix.reserved1 > 1) sprintf(ct4,"%5.1f°C",(prefix.reserved1-27315)/100.);
    else                      sprintf(ct4,"   - °C");

    if (strcmp(mode,"SHORT") == 0)
        fprintf(ascfile, "%5d %25s %5.1fms %4d  %s %s %s %s %s\n",
                linp,
                cdummy,
                prefix.Exposure,
                prefix.Pischel,
                ct0, ct1, ct2, ct3, ct4
                );
    if (strcmp(mode,"LONG") == 0)
        {
        if (!strcmp(comp_name,"NONE"))
           comp = 1;
        else if (!strcmp(comp_name,"UNKNOWN"))
           comp = 0;
        else
           comp = ns/( (float) prefix.CmpDataLen)*8;   /*CmpDataLen is for frame */    
        fprintf(ascfile, "%5d %25s %5.1fms %4d  %s %s %s %s %s %8d %6d  %13.4lf %5.1f\n",
                linp,
                cdummy,
                prefix.Exposure,
                prefix.Pischel,
                ct0, ct1, ct2, ct3, ct4,
                prefix.FrameCount,
                prefix.ActPixel,
                prefix.EphTime,
                comp
                );
        }        
    }


/* Close the files */
status=zvclose(inunit, 0);

if (ascfile != stdout) fclose(ascfile);

}

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrpref2asc.imake


#define PROGRAM hrpref2asc

#define MODULE_LIST hrpref2asc.c

#define MAIN_LANG_C
#define USES_ANSI_C

#define HWLIB

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB
#define LIB_CSPICE

#define LIB_HWSUB
$ Return
$!#############################################################################
$PDF_File:
$ create hrpref2asc.pdf
process help=*

PARM INP            TYPE=(STRING,250)  COUNT=1
PARM OUT            TYPE=(STRING,250)  COUNT=(0:1)     DEFAULT=--
PARM SL             TYPE=INTEGER       COUNT=(0:1)     DEFAULT=1
PARM NL             TYPE=INTEGER       COUNT=(0:1)     DEFAULT=0
PARM IL             TYPE=INTEGER       COUNT=(0:1)     DEFAULT=1
PARM MODE           TYPE=KEYWORD       COUNT=1         DEFAULT=SHORT +
                    VALID=(LONG, SHORT)
PARM CHECK          TYPE=KEYWORD       COUNT=1         DEFAULT=CHECK +
                    VALID=(CHECK, NOCHECK)
PARM TLSFILE         TYPE=(STRING,120)                 DEFAULT=LEAPSECONDS
end-proc

.TITLE
  Print the content of the prefixes of a HRSC file.

.HELP
No help.

.END

$ Return
$!#############################################################################
