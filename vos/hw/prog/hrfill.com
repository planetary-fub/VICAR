$!****************************************************************************
$!
$! Build proc for MIPL module hrfill
$! VPACK Version 1.9, Friday, April 15, 2005, 17:36:11
$!
$! Execute by entering:		$ @hrfill
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
$!   OTHER       Only the "other" files are created.
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
$ write sys$output "*** module hrfill ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_PDF = ""
$ Create_Imake = ""
$ Create_Other = ""
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
$ if primary .eqs. "OTHER" then Create_Other = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_PDF .or. Create_Imake .or -
        Create_Other .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hrfill.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_PDF then gosub PDF_File
$ if Create_Imake then gosub Imake_File
$ if Create_Other then gosub Other_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_PDF = "Y"
$   Create_Imake = "Y"
$   Create_Other = "Y"
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
$   if F$SEARCH("hrfill.imake") .nes. ""
$   then
$      vimake hrfill
$      purge hrfill.bld
$   else
$      if F$SEARCH("hrfill.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrfill
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrfill.bld "STD"
$   else
$      @hrfill.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrfill.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrfill.com -mixed -
	-s hrfill.c hrfill_patch.c hrfill_median.c hrfill.h -
	-i hrfill.imake -
	-p hrfill.pdf -
	-o hrfill_change.log
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrfill.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#define HRFILL_MAIN

#include "hrfill.h"

void main44()

{
int             status, count, inunit, outunit, flagunit, vicar_instance=0;
int             dnmax, proc_level, numtask;
long int        i, j, snum, lnum, lout;
char            filename_in[513], filename_out[513], cdummy[513];
short int       *line, *badline, *lp;
hrpref_typ      prefix;
short int       s_blem, s_lost, s_satt;


/* Get the filenames */
zvp("INP", filename_in, &count);
zvp( "OUT", filename_out, &count);

/*    Open the input file */
printf("#I  Scanning input data file %s for bad pixels\n",filename_in);

status=zvunit(&inunit, "INP", 1, 0);
if (status != 1) {
    printf("#E  Unable to get the unit number\n");
    printf("#E  VICAR Error Code = %d\n",status);
    return;
    }

status=zvopen(inunit, "U_FORMAT","HALF", "CONVERT","ON", "COND","BINARY", 0);
if (status != 1) {
    printf("#E  Error by opening input file %s\n", filename_in);
    printf("#E  VICAR Error Code = %d\n",status);
    return;
    }

/* Check the processing level (only 2 allowed) */
status=zlget(inunit,"PROPERTY","PROCESSING_LEVEL_ID",&proc_level,"FORMAT","INT",
        	"PROPERTY","FILE",0);
if (status != 1) {
    printf("#E  Error by reading label PROCESSING_LEVEL_ID\n");
    printf("#E  Error status code: %d\n",status);
    return;
    }

if (proc_level != 2) {
    printf("#E  PROCESSING_LEVEL_ID != 2\n");
    return;
    }


status=zvget(inunit,"NL",&nl, 0);
if (status != 1) {
    printf("#E  Error by reading label NL\n");
    printf("#E  VICAR Error Code = %d\n",status);
    return;
    }

status=zvget(inunit,"NS",&ns, 0);
if (status != 1) {
    printf("#E  Error by reading label NS\n");
    printf("#E  VICAR Error Code = %d\n",status);
    return;
    }

status=zvget(inunit,"NBB",&nbb, 0);
if (status != 1) {
    printf("#E  Error by reading label NS\n");
    printf("#E  VICAR Error Code = %d\n",status);
    return;
    }

status=zlget(inunit,"PROPERTY","MACROPIXEL_SIZE",&hrfill_mpf, "FORMAT","INT",
             "PROPERTY","M94_CAMERAS", 0);
if (status != 1) {
    /* Probably a SRC image - check it */
    status=zlget(inunit,"PROPERTY","DETECTOR_ID",cdummy,"FORMAT","STRING",
                 "PROPERTY","M94_INSTRUMENT",0);
    if (status != 1) {
        printf("#E  Error by reading label DETECTOR_ID\n");
        printf("#E  VICAR Error Code = %d\n",status);
        return;
        }
    if (!strcmp(cdummy,"MEX_HRSC_SRC")) {
        /* Yes, a SRC image - use MPF#1 */
        hrfill_mpf=1;
        }
    else {
        printf("#E  Error by reading label MACROPIXEL_FORMAT\n");
        printf("#E  VICAR Error Code = %d\n",status);
        return;
        }
    }

has_prefix=(nbb == HRPREF_LEN);
if (!has_prefix) {
    /* Fill prefix with default values */
    prefix.ActPixel = ns*hrfill_mpf;
    }


/* Allocate vectors */
line = (short int *)malloc(ns*sizeof(short int));

count=0;

for (lnum=1; lnum<=nl; lnum++) {

    if (has_prefix) hrrdpref(inunit, lnum, &prefix);

    if (prefix.ActPixel/hrfill_mpf < ns) {
        count=1;
        break;
        }

       /* Read data line */
    status=zvread(inunit, line, "LINE",lnum, "SAMP",nbb+1, 0);
    if (status!=1) {
        printf("#E  Error by reading data line #%ld\n",lnum);
        printf("#E  VICAR Error Code = %d\n",status);
        zabend();
        }

    for (i=prefix.ActPixel/hrfill_mpf; i--; )
        if (line[i] < 0) {
            count=1;
            break;
            }

    if (count) break;

    }

/* Anything to fill? */
if (count == 0)  {
    printf("#I  %s contains no bad pixel\n",filename_in);
    status=zvclose(inunit, 0);
    return;
    }

status=find_hist_key(inunit, "MAXIMUM", 1, cdummy, &numtask);
if (status != 1) {
    printf("#E  Error by searching label MAXIMUM\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

status=zlget(inunit, "HISTORY", "MAXIMUM",&dnmax, "HIST", cdummy,
             "INSTANCE", numtask, "FORMAT","INT", 0);
if (status != 1) {
    printf("#E  Error by reading label MAXIMUM\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

/* How to mark the overflow (aka saturated) pixels? */
satval=(dnmax < 32767 ? dnmax+1 : dnmax);


/* Open the output data file */
printf("#I  Opening output data file %s\n",filename_out);

status=zvunit(&outunit, "OUT", 1, 0);
if (status != 1) {
    printf("#E  Error by assigning unit number for output file\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

status=zvopen(outunit, "OP","WRITE", "U_FORMAT","HALF", "COND","BINARY", 
              "U_NBB",nbb, 0);
if (status != 1) {
    printf("#E  Error by opening output file %s\n", filename_out);
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }


for (lnum=1; lnum<=nl; lnum++) {

    if (has_prefix) hrrdpref(inunit, lnum, &prefix);

    /* Read data line */
    status=zvread(inunit, line, "LINE",lnum, "SAMP",nbb+1, 0);
    if (status!=1) {
        printf("#E  Error by reading data line #%ld\n",lnum);
        printf("#E  VICAR Error Code = %d\n",status);
        zabend();
        }

    /* This variables will contain the index of the first pixel of the
       respective type */
    s_blem=-1; s_satt=-1; s_lost=-1;

    /* Remove type combinations - every pixel should have one type only */
    for (i=ns; i--; )
        if (line[i] < 0) {
            if (-line[i] & PIXEL_LOST) {
                line[i]=-PIXEL_LOST;
                s_lost=i;
                }
            else if (-line[i] & PIXEL_BLEMISH) {
                line[i]=-PIXEL_BLEMISH;
                s_blem=i;
                }
            else if (-line[i] & PIXEL_SATURATION) {
                line[i]=-PIXEL_SATURATION;
                s_satt=i;
                }
            else { /* Unknown pixel type */
                line[i]=-PIXEL_LOST;
                s_lost=i;
                }
            }

    /* Now fill the holes */

    if (s_blem >= 0) hrfill_blem(&prefix, line, s_blem);

    if (s_satt >= 0) hrfill_satt(&prefix, line, s_satt);

    if (s_lost >= 0) hrfill_lost(&prefix, line, s_lost, lnum);


    /* All holes are filled - all pixel are valid
    prefix.ActPixel=ns*hrfill_mpf; */

    /* Write line prefix into data file*/
    if (has_prefix) hrwrpref(outunit, lnum, &prefix);

    /* Write data line */
    status=zvwrit(outunit, line, "LINE",lnum, "SAMP",nbb+1, 0);
    if (status != 1) {
        printf("#E  Error by writing data line #%ld\n",lnum);
        printf("VICAR Error Code = %d\n",status);
        break;
        }

    }

/* Change some Header keywords */

strcpy(cdummy, filename_out);
hwnopath(cdummy);
status=zladd(outunit, "PROPERTY", "FILE_NAME", cdummy,
             "FORMAT", "STRING", "PROPERTY", "FILE", "MODE", "REPLACE", 
             "ELEMENT", 1, 0);
if (status != 1 ) {
    printf("#E  Error by modifying label FILE_NAME\n");
    printf("#E  Error status code: %d\n",status);
    zabend();
    }

status=zladd(outunit, "PROPERTY", "PRODUCT_ID", cdummy,
             "FORMAT", "STRING", "PROPERTY", "FILE", "MODE", "REPLACE", 
             "ELEMENT", 1, 0);
if (status != 1 ) {
    printf("#E  Error by modifying label PRODUCT_ID\n");
    printf("#E  Error status code: %d\n",status);
    zabend();
    }

/* Add some Header keywords */

status=zladd(outunit,"HISTORY","PROCESSING_HISTORY_TEXT",PROGRAMM_VERSION,
                "FORMAT","STRING","MODE","ADD",0);
if (status != 1) {
    printf("#E  Error by writing label PROCESSING_HISTORY_TEXT\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }

status=zladd(outunit,"HISTORY","OVERFLOW_VALUE",&satval,
                "FORMAT","INT","MODE","ADD",0);
if (status != 1) {
    printf("#E  Error by writing label OVERFLOW_VALUE\n");
    printf("#E  VICAR Error Code = %d\n",status);
    zabend();
    }


/* Close the files */
status=zvclose(inunit, 0);
status=zvclose(outunit, 0);

}

    
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create hrfill_patch.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "hrfill.h"

/*----------------------------------------------------------------------------*/

void    hrfill_satt(hrpref_typ  *prefix, short int *line, short int s_satt)

{
int     i,j;

for (i=s_satt; i<ns; i++)
    if (line[i] == -PIXEL_SATURATION) 
        line[i]=satval;

}

/*----------------------------------------------------------------------------*/

void    hrfill_blem(hrpref_typ  *prefix, short int *line, short int s_blem)

{
int     i,j, blem_pre, blem_aft;
float   slope;

for (i=s_blem; i<prefix->ActPixel/hrfill_mpf; i++) {

    if (line[i] == -PIXEL_BLEMISH) {

        /* Predecessor */
        blem_pre=(i > 0 ? i-1 : -1);

        /* Successor */
        j=i+1;
        while ((line[j] == -PIXEL_BLEMISH) && (j<prefix->ActPixel/hrfill_mpf-1)) j++;
        blem_aft=(line[j] == -PIXEL_BLEMISH ? 9999 : j);

        /* Fill the hole */

        if ((blem_pre > -1) && (blem_aft < 9999)) {

            slope = (line[blem_aft]-line[blem_pre])/(blem_aft-blem_pre-1.0);

            for (j=i; j<blem_aft; j++)
                line[j] = slope*(j-blem_pre) + line[blem_pre];

            }
        else if (blem_aft < 9999) {

            for (j=i; j<blem_aft; j++)
                line[j] = line[blem_aft];

            }
        else if (blem_pre > -1) {

            for (j=i; j<prefix->ActPixel/hrfill_mpf; j++)
                line[j] = line[blem_pre];

            }

        i=blem_pre;
        }
    }
}

/*----------------------------------------------------------------------------*/

static int          sl_lost=-8;
static short int    *filval;


void    hrfill_lost(hrpref_typ  *prefix, short int *line, short int s_lost,
                    long int lnum)

{
int         i, j, k, status, n_neighbor, nix, ss_lost, es_lost;
long int    lix;
short int   *nb_line[10], valid[10], *nb_pixels, nb_median;

/* First time we call this routine? */
if (sl_lost < 0) {
    /* Allocate the buffers */
    filval=(short int *)malloc(ns*sizeof(short int));
    }


if (lnum-sl_lost > 7) {

    /* This is definitively a new hole */
    sl_lost = lnum;

    /* Read the neighbor lines */
    j=0;
    for (lix=lnum-1; lix < lnum+9; lix++) {

        if ((lix > 0) && (lix <= nl)) {

            nb_line[lix-lnum+1]=(short int *)malloc(ns*sizeof(short int));

            status=zvread(inunit, nb_line[lix-lnum+1], "LINE",lix, 
                          "SAMP",nbb+1, 0);
            if (status!=1) {
                printf("#E  Error by reading data line #%ld\n",lix);
                printf("#E  VICAR Error Code = %d\n",status);
                zabend();
                }

            valid[lix-lnum+1]=1;
            }
        else {
            valid[lix-lnum+1]=0;
            }

        }


    for (i=s_lost; i<ns; i++) {

        if (line[i] == -PIXEL_LOST) {
            /* Start pixel of the hole */
            ss_lost=i;

            /* Find the end of the hole */

            if (ss_lost >= prefix->ActPixel/hrfill_mpf) {
                /* The hole goes up to the end of the line */
                es_lost = ns-2; /* Set this to one pixel before the end to avoid
                                   segmentation faults */
                }
            else {
                /* There are valid pixels beyond the hole - find it */
                for (j=s_lost; j<ns; j++)
                    if (line[j] != -PIXEL_LOST) break;

                es_lost = j-1;
                }
        
            /* Calculate the median of the valid border pixels of the hole */
            n_neighbor=2*(es_lost-ss_lost+3)+16;

            nb_pixels=(short int *)malloc(n_neighbor*sizeof(short int));

            nix=0;

            if (valid[0])
                for (j=ss_lost-1; j<es_lost+2; j++)
                    if ((nb_line[0])[j] > 0) 
                        nb_pixels[nix++] = (nb_line[0])[j];

            for (k=1; k<9; k++)
                if (valid[k]) {
                    if ((nb_line[k])[ss_lost-1] > 0) 
                        nb_pixels[nix++] = (nb_line[k])[j];
                    if ((nb_line[k])[es_lost+1] > 0) 
                        nb_pixels[nix++] = (nb_line[k])[j];
                    }

            if (valid[9])
                for (j=s_lost-1; j<es_lost+2; j++)
                    if ((nb_line[9])[j] > 0) 
                        nb_pixels[nix++] = (nb_line[9])[j];

            if (nix > 0) {
                /*
                printf("#D  Filling hole from sample %d to %d and",ss_lost,es_lost);
                printf(" from line %d to line %d\n",lnum,lnum+7); */

                nb_median = hrfill_median(nb_pixels, nix);

                for (j=ss_lost; j<es_lost+1; j++)
                    filval[j] = nb_median;
                }
            else {

                printf("#W  Lost pixels surrounded by bad pixels only");
                printf(" from line %d to line %d\n",lnum,lnum+7);
                printf("#W  Filling lost pixels with white value %d\n",satval);

                for (j=ss_lost; j<es_lost+1; j++)
                    filval[j] = satval;
                }

            i = es_lost+1;
            }

        }

    /* Free buffers */
    for (i=0; i<10; i++)
        if (valid[i]) free(nb_line[i]);
    }

for (i=0; i<ns; i++)
    if (line[i] == -PIXEL_LOST) line[i]=filval[i];

}
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create hrfill_median.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*
 *  This Quickselect routine is based on the algorithm described in
 *  "Numerical recipes in C", Second Edition,
 *  Cambridge University Press, 1992, Section 8.5, ISBN 0-521-43108-5
 *  This code by Nicolas Devillard - 1998. Public domain.
 */


#define ELEM_SWAP(a,b) { register short int t=(a);(a)=(b);(b)=t; }

short int hrfill_median(short int arr[], int n) 
{
int low, high ;
int median;
int middle, ll, hh;

low = 0 ; high = n-1 ; median = (low + high) / 2;

for (;;) {

    if (high <= low) /* One element only */
        return arr[median] ;

    if (high == low + 1) {  /* Two elements only */
        if (arr[low] > arr[high])
            ELEM_SWAP(arr[low], arr[high]) ;
        return arr[median] ;
        }

    /* Find median of low, middle and high items; swap into position low */
    middle = (low + high) / 2;
    if (arr[middle] > arr[high])    ELEM_SWAP(arr[middle], arr[high]) ;
    if (arr[low] > arr[high])       ELEM_SWAP(arr[low], arr[high]) ;
    if (arr[middle] > arr[low])     ELEM_SWAP(arr[middle], arr[low]) ;

    /* Swap low item (now in position middle) into position (low+1) */
    ELEM_SWAP(arr[middle], arr[low+1]) ;

    /* Nibble from each end towards middle, swapping items when stuck */
    ll = low + 1;
    hh = high;
    for (;;) {
        do ll++; while (arr[low] > arr[ll]) ;
        do hh--; while (arr[hh]  > arr[low]) ;

        if (hh < ll)
        break;

        ELEM_SWAP(arr[ll], arr[hh]) ;
        }

    /* Swap middle item (in position low) back into correct position */
    ELEM_SWAP(arr[low], arr[hh]) ;

    /* Re-set active partition */
    if (hh <= median) low = ll;
    if (hh >= median) high = hh - 1;
    }
}

#undef ELEM_SWAP
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create hrfill.h
$ DECK/DOLLARS="$ VOKAGLEVE"
#define PROGRAMM_VERSION    "hrfill v5.1  15.04.2005"

#ifdef HRFILL_MAIN
    #include "vicmain_c"
#endif

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "hrpref.h"

/* From hrcal.h */
#define   PIXEL_BLEMISH               1
#define   PIXEL_LOST                  2
#define   PIXEL_DC                    2
#define   PIXEL_OVERFLOW              2
#define   PIXEL_SATURATION            8
#define   PIXEL_BADCONF              16

/*----------------------------------------------------------------------------*/

short int hrfill_median(short int arr[], int n);

void    hrfill_blem(hrpref_typ  *prefix, short int *line, short int s_blem);
void    hrfill_satt(hrpref_typ  *prefix, short int *line, short int s_satt);
void    hrfill_lost(hrpref_typ  *prefix, short int *line, short int s_lost,
                    long int lnum);

/*----------------------------------------------------------------------------*/

#ifdef HRFILL_MAIN

    /* Global variables */
    long int        nl, ns, nbb;
    int             satval, hrfill_mpf;
    int             inunit;
    unsigned char   has_prefix;


#else 

    /* Global variables */
    extern long int        nl, ns, nbb;
    extern int             satval, hrfill_mpf;
    extern int             inunit;
    extern unsigned char   has_prefix;

#endif
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrfill.imake
#define PROGRAM hrfill

#define MODULE_LIST hrfill.c hrfill_patch.c hrfill_median.c

#define INCLUDE_LIST hrfill.h

#define MAIN_LANG_C
#define USES_ANSI_C

#define HWLIB

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB

#define LIB_HWSUB

/*#define DEBUG*/

$ Return
$!#############################################################################
$PDF_File:
$ create hrfill.pdf
process help=*

PARM INP             TYPE=(STRING,250)  COUNT=1
PARM OUT             TYPE=(STRING,250)  COUNT=1

end-proc

.TITLE
  Fills error pixel with valid values.

.HELP

  This program changes the DN value of all pixels which were flaged as bad
  during the calibration process.

  A pixel can be flaged as "bad" due to several reasons:
    - The pixel was saturated.
    - The pixel has a physical defect (aka blemish pixel).
    - The pixel value was lost during compression or transmission.

  HRFILL tries to fill the pixels with useful values:
    - Maximum_of_valid_pixels+1 for the saturated pixels
    - Median of the surrounding valid pixels otherwise

  HRFILL updates the VICAR label keyword OVERFLOW_VALUE with the new value of
  the saturated pixels ("Maximum_of_valid_pixels+1").


  Written by: Klaus-Dieter Matz, DLR, 15.08.2003 (Initial version)


.LEVEL1

.VARIABLE  INP
  STRING - Input file name

.VARIABLE  OUT
  STRING - Output file name

.LEVEL2

.VARIABLE  INP
  STRING - Input file name

.VARIABLE  OUT
  STRING - Output file name
$ Return
$!#############################################################################
$Other_File:
$ create hrfill_change.log
Version 3.1     15.08.2003

- Initial version

Version 3.2     27.11.2003

- Grundlegender Umbau zu einer verwendbaren Version

Version 3.3     01.12.2003

- prefix.ActPixel wird nicht mehr verändert

Version 3.4     04.12.2003

- Fehler bei Files ohne BinaryPrefix (d.h. SRC)
- Update der Keywörter FILE_NAME und PRODUCT_ID eingebaut
- .pdf erweitert

Version 3.5     08.12.2003

- Abfrage mit find_hist_key, wo das HISTORY-Keyword MAXIMUM gesetzt wurde

Version 5.1     15.04.2005

- Gesättigte Pixel werden bis zu NS mit Max_DN gefüllt, nicht nur bis NAP


$ Return
$!#############################################################################
