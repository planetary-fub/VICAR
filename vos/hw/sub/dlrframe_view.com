$!****************************************************************************
$!
$! Build proc for MIPL module dlrframe_view
$! VPACK Version 1.9, Monday, June 11, 2001, 14:18:21
$!
$! Execute by entering:		$ @dlrframe_view
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
$!   TEST        Only the test files are created.
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
$ write sys$output "*** module dlrframe_view ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_Test = ""
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
$ if primary .eqs. "TEST" then Create_Test = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Test .or. Create_Imake .or -
        Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to dlrframe_view.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Test then gosub Test_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_Test = "Y"
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
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("dlrframe_view.imake") .nes. ""
$   then
$      vimake dlrframe_view
$      purge dlrframe_view.bld
$   else
$      if F$SEARCH("dlrframe_view.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrframe_view
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrframe_view.bld "STD"
$   else
$      @dlrframe_view.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrframe_view.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrframe_view.com -
	-s dlrframe_view.c -
	-i dlrframe_view.imake -
	-t tstdlrframe_view.c tstdlrframe_view.imake tstdlrframe_view.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrframe_view.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include <stdio.h>
#include <string.h>

#include "SpiceUsr.h"
#include "dlrframe.h"

/*     Written by Thomas Roatsch, DLR     3-Jun-1999 */


int dlrframe_getview (dlrframe_info dlrframe_info, FILE *adjuptr,
                     int npixels, float *pixels, double mat[3][3],
                     double *samp_x, double *samp_y, double focal,
                     double *iv)

/* dlrframe_info is not used yet, may be necessary later */

/*      VARIABLE  I/O  DESCRIPTION
        --------  ---  --------------------------------------------------
        NPIXELS    I   Number of pixels
        PIXELS     I   Real numbers of these pixels
        Mat        I   Roation matrix from dlrframe_getgeo
        SAMP_X     I   x_coordinate of all pixels in the camera system
        SAMP_Y     I   y_coordinate of all pixels in the camera system
        FOCAL      I   Mean focal length
        IV         O   Line of sight vectors of the pixels in the
                       prime meridian / equator frame */


{
      int      laufs, lauf3;
      int      intpixel;
      double   fracpixel;
      double   x, y, x1, x2, y1, y2;
      double   vpoint[3];
      double   accu;
      double   fhelp1;
      
/* !!!! HAS TO BE DISCUSSED */
      accu = 0.01;

      fhelp1 = 1 - accu;
      for (laufs =0; laufs < npixels; laufs++)
         {
         intpixel = (int) pixels[laufs];
         fracpixel = (double)pixels[laufs] - (double) intpixel;

         if ( (fracpixel > accu) && (fracpixel < fhelp1) )
            {
            x1 = samp_x[intpixel-1];
            x2 = samp_x[intpixel];
            y1 = samp_y[intpixel-1];
            y2 = samp_y[intpixel];
            x  = x1 + fracpixel * (x2 - x1);
            y  = y1 * (1 - fracpixel) + fracpixel * y2;
            }
         else
            {
            /* would be +0.4 (truncation) - 1 (C) */
            x = samp_x [ (int) (pixels[laufs] - 0.6) ];
            y = samp_y [ (int) (pixels[laufs] - 0.6) ];
            }

         if (adjuptr <= (FILE *) NULL)
            {
            /* camera system, may be instrument dependent */
            vpoint[0] = x;
            vpoint[1] = y;
            vpoint[2] = focal;

            /* Transformation of VPOINT to the 
              prime meridian / equator frame,
              mat is matrix from camera to body */
            mxv_c (mat, vpoint, vpoint);
            }
         else
            {
            /* The photogrammetry fixed vector is (x,-y,-focal),
              private communication by B. Giese */
            vpoint[0] = x;
            vpoint[1] = -y;
            vpoint[2] = -focal;

            /*  Transformation of VPOINT to the 
               prime meridian / equator frame,
               mat is matrix from body to photogrammetry */
             mtxv_c (mat, vpoint, vpoint);
            }

         /* Normalize VPOINT */
         vhat_c (vpoint, vpoint);

         for (lauf3 = 0; lauf3 < 3; lauf3++)
            iv [3*laufs+lauf3] = vpoint[lauf3];
                 
         } /* end of for laufs */
           
return (1);

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrframe_view.imake
/* Imake file for VICAR subroutine  dlrframe_view */

#define SUBROUTINE   dlrframe_view

#define MODULE_LIST  dlrframe_view.c

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE

$ Return
$!#############################################################################
$Test_File:
$ create tstdlrframe_view.c
#include "vicmain_c"

#include "dlrframe.h"
#include "hwldker.h"

void main44()

{
int unit;
int status;
double *samp_x, *samp_y, focal;
double positn [3];
double mat[3][3];
char   adjufile[120];
char   error_message[DLRFRAME_ERROR_LENGTH];
int adjucount;
FILE   *adjuptr;
char   *getenv();
char   *value;
int    ihelp,line,lauf;
float  *pixels;
int    npixels = 2;
double iv[6];

dlrframe_info dlrframe_info;
hwkernel_3 bsp;
hwkernel_6 bc;
hwkernel_6 tsc;
hwkernel_1 tpc;
hwkernel_1 bpc;
hwkernel_1 ti;
hwkernel_1 tls;

/* SPICE error action */
erract_c ("SET", SPICE_ERR_LENGTH, "REPORT");
errprt_c ("SET", SPICE_ERR_LENGTH, "NONE");

status = zvunit (&unit, "INP", 1, "");
status = zvopen(unit, "");
if (status != 1)  
   {
   zvmessage("error open input file","");
   zabend();
   } 

status = dlrframe_getinfo(unit,&dlrframe_info);

printf("status %d\n", status);
if (status != 1) 
   {
   status = dlrframe_error(status, "info", error_message);
   zvmessage("dlrframe_getinfo","");
   zvmessage(error_message,"");
   zabend();
   }
   
printf("%d %d %d %d %s\n",       dlrframe_info.spacecraft_id,
                                 dlrframe_info.instrument_id,
                                 dlrframe_info.target_id,
                                 dlrframe_info.adju_id,
                                 dlrframe_info.utc);

   
samp_x = (double *) 
       malloc(dlrframe_info.nl * dlrframe_info.ns * sizeof(double));
if (samp_x == NULL) 
   {
   zvmessage("not enough memory","");
   zabend();
   }

samp_y = (double *) 
       malloc(dlrframe_info.nl * dlrframe_info.ns * sizeof(double));
if (samp_y == NULL) 
   {
   zvmessage("not enough memory","");
   zabend();
   }


zvp("ADJUFILE", adjufile, &adjucount);
if (adjucount == 0)
   {
   adjuptr = NULL;

   status = hwldker(4, "bsp", &bsp, "bc",  &bc, "tsc", &tsc, "tls", &tls); 
   if (status != 1)
      {
      zvmessage("HWLDKER problem","");
      printf("hwldker-status: %d\n",status);
      zabend();
      }
    if (dlrframe_info.target_id == 301)
      {/* bpcfile exists only for Moon */
      status = hwldker(1, "bpc",&bpc);
      if (status != 1)
         {
         zvmessage("HWLDKER problem","");
         printf("hwldker-status: %d\n",status);
         zabend();
         }
      }
   }
else
   {
   value=getenv(adjufile);
   if (value != NULL) strcpy(adjufile,value);
   adjuptr=fopen(adjufile,"r");
   if (adjuptr <= (FILE *)NULL)
      {
      zvmessage ("could not open adjufile","");
      zabend();
      }    
   }   

/* we need these kernels always */
status = hwldker(2, "ti",&ti, "tpc", &tpc);
if (status != 1)
   {
   zvmessage("HWLDKER problem","");
   printf("hwldker-status: %d\n",status);
   zabend();
   }

status = dlrframe_getgeo(dlrframe_info, adjuptr,
                            samp_x, samp_y, &focal,
                            positn, mat);

printf("status %d\n", status);

/* we can also print the NAIF error message:
   getmsg_c ( "LONG", DLRFRAME_ERROR_LENGTH, error_message);
   zvmessage(error_message,""); */

if (status != 1) 
   {
   status = dlrframe_error(status, "geo", error_message);
   zvmessage("dlrframe_getgeo","");
   zvmessage(error_message,"");
   zabend();
   }
   
printf("position: %12.2f %12.2f %12.2f\n", positn[0],positn[1],positn[2]);

/* memory allocation for the pixels vector */
pixels = (float *) malloc (dlrframe_info.ns * sizeof(float));
pixels[0] = (float) dlrframe_info.ns /2;
pixels[1] = pixels[0] + 10;


status = dlrframe_getview (dlrframe_info, adjuptr,
                     npixels, pixels, mat,
                     &samp_x[dlrframe_info.nl/2*dlrframe_info.ns], 
                     &samp_y[dlrframe_info.nl/2*dlrframe_info.ns], 
                     focal,
                     iv);   
                                              
zvmessage("vector[0-2]","");
printf("%12.5f %12.5f %12.5f\n",iv[0],iv[1],iv[2]);
zvmessage("vector[2-5]","");
printf("%12.5f %12.5f %12.5f\n",iv[3],iv[4],iv[5]);

}

$!-----------------------------------------------------------------------------
$ create tstdlrframe_view.imake
/* IMAKE file for test program TSTdlrframe_view */

#define PROGRAM   tstdlrframe_view  

#define MODULE_LIST  tstdlrframe_view.c

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_P2SUB    /* for find_hist_key */
#define LIB_CSPICE

$!-----------------------------------------------------------------------------
$ create tstdlrframe_view.pdf
Process help=*
PARM INP
PARM BSPFILE  TYPE=(STRING,120) COUNT=(0:3)     DEFAULT=--
PARM BCFILE   TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=--
PARM TSCFILE  TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=--
PARM TPCFILE  TYPE=(STRING,120)      
PARM BPCFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=--
PARM TLSFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=--
PARM TIFILE   TYPE=(STRING,120) 
PARM ADJUFILE                   COUNT=(0:1)     DEFAULT=--
PARM TOL      TYPE=REAL         COUNT=(0:1)     DEFAULT=--
END-PROC
.Title
 Test Program for dlrframe_view
.HELP

WRITTEN BY:     Thomas Roatsch, DLR   25-May-1999

.LEVEL1
.VARI INP
Input image
.VARI BSPFILE
Binary SP-Kernel 
.VARI BCFILE
Binary C-Kernel
.VARI TSCFILE
Text Clock Kernel 
.VARI TPCFILE
Text Planetary 
Constants Kernel
.VARI BPCFILE
Binary Planetary 
Constants Kernel
.VARI TLSFILE
Text Leapseconds Kernel
.VARI TIFILE
Text Instrument Kernel
.VARI ADJUFILE
Name of Adjufile
.VARI TOL
Clock tolerance of pointing requests
.End

$ Return
$!#############################################################################
