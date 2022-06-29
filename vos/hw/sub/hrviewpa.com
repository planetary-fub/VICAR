$!****************************************************************************
$!
$! Build proc for MIPL module hrviewpa
$! VPACK Version 1.9, Friday, May 20, 2005, 13:49:08
$!
$! Execute by entering:		$ @hrviewpa
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
$ write sys$output "*** module hrviewpa ***"
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
$ write sys$output "Invalid argument given to hrviewpa.com file -- ", primary
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
$   if F$SEARCH("hrviewpa.imake") .nes. ""
$   then
$      vimake hrviewpa
$      purge hrviewpa.bld
$   else
$      if F$SEARCH("hrviewpa.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrviewpa
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrviewpa.bld "STD"
$   else
$      @hrviewpa.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrviewpa.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrviewpa.com -mixed -
	-s hrviewpa.c -
	-i hrviewpa.imake -
	-t tsthrviewpa.pdf tsthrviewpa.imake tsthrviewpa.c
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrviewpa.c
$ DECK/DOLLARS="$ VOKAGLEVE"

/*     Written by Thomas Roatsch, DLR     9-Jun-1993
       Revised by Thomas Roatsch, DLR    10-Sep-1993
       Revised by Thomas Roatsch, DLR    20-Jul-1994
       (check if pixel numbers >= 1 and <= TOTAL_ACTIVE_PIXEL) 
       Revised by Thomas Roatsch, DLR     3-May-1995
       (restore input PIXELS)
       Rewritten in C by Thomas Roatsch, DLR  9-Oct-1998 
       Removed parameters plat and clockid 29-March-2000 
       Changed target and ins to strings, added sc,
       renamed to hrviewpa,
       removed tol,csmat  Aug-2000 */
       

#include <stdio.h>
#include "SpiceUsr.h"
#include "hwconst.h"
#include "dlrspice.h"


int hrviewpa(target,sc, ins, et,npixels,
     pixels,samp_x,samp_y,focal,positn,iv)


/*     Subroutine calculates for given pixel numbers the spacecraft
       position and the viewing direction of this pixels */

      char              *target;
      char              *sc;
      char              *ins;
      double            et;
      int               npixels;
      float             *pixels;
      double            samp_x[TOTAL_ACTIVE_PIXEL];
      double            samp_y[TOTAL_ACTIVE_PIXEL];
      double            focal;
      double            positn[3];
      double            *iv;
      

/* Brief_I/O

       VARIABLE  I/O  DESCRIPTION
       --------  ---  --------------------------------------------------
       TARGET     I   Target name
       SC         I   S/C name
       INS        I   Instrument Name
       ET         I   Ephemeris time     
       NPIXELS    I   Number of pixels
       PIXELS     I   Real numbers of these pixels
                      NON_ACTIVE_HRSC_PIXEL_START is subtracted inside
                      (only for HRSC_94_SPICE_ID) 
       SAMP_X     I   x_coordinate of all pixels in the camera system
       SAMP_Y     I   y_coordinate of all pixels in the camera system
       FOCAL      I   Mean focal length
       POSITN     O   Position of the observer in the prime meridian /equator
                      frame
       IV         O   Line of sight vectors of the pixels in the
                      prime meridian / equator frame */


/* status:

    -101        npixels <1 
    -102        npixels > TOTAL_ACTIVE_PIXEL
    -103        could not find the C-matrix
    -104        pixel number < 1
    -105        pixel number > TOTAL_ACTIVE_PIXEL  
    -201        SPICE error at function start 
    -202        S/C position not found 
    -203        pointing not found 
    -300        unknown target */
    
    
{
      int               laufs,lauf3;
      int               intpixel;
      double            state[6];      
      double            fracpixel;
      double            x,y,x1,x2,y1,y2;
      double            vpoint[3];
      double            cbmat[3][3],imat[3][3],cmat[3][3];
      double            lt;
      SpiceBoolean      found;
      float             accu;
      float             fhelp1,  fhelp2;
      char              help_bary[100],help_iau[100];
      char              help_ins[100],help_sc[100];
      SpiceInt          itarget,number;
      SpiceDouble       body_axes[3];
/* !!!! HAS TO BE DISCUSSED */
      accu = 0.01;

/* check at the begin of function */
      if ( failed_c() ) return -201;

/*     Check of NPIXELS */
      if (npixels < 1 ) return (-101);
      if (npixels > TOTAL_ACTIVE_PIXEL) return(-102);
         
      /*different names in label and SPICE */
      if (strcmp(ins,"HIGH_RESOLUTION_STEREO_CAMERA")) 
         strcpy(help_ins,ins); 
      else
         strcpy(help_ins,"MEX_HRSC_HEAD");
      if (strcmp(sc,"MARS-EXPRESS"))
         strcpy(help_sc,sc);
      else
         strcpy(help_sc,"MARS-EXPRESS");   
      strcpy(help_iau,"IAU_");
      strcat(help_iau,target);
      strcpy(help_bary,target);
      strcat(help_bary," BARYCENTER");
if (!strcmp(target,"PHOBOS"))
   strcpy(help_bary,"PHOBOS");
if (!strcmp(target,"DEIMOS"))
   strcpy(help_bary,"DEIMOS");

      bodn2c_c(target,&itarget, &found);
      if (!found) return -601;
      bodvar_c(itarget, "RADII", &number, body_axes); 
      if (failed_c()) return -602;

      spkezr_c(help_bary, et, help_iau, "LT",  
               help_sc, state, &lt);
      if (failed_c()) return -603;

       if (vnorm_c(state) < 2*body_axes[0])
          { /* no light time correction */
          spkezr_c(help_bary, et, help_iau, "NONE",  
                   help_sc, state, &lt);
          if (failed_c()) return -604;
          /* matrix from prime meridian to camera */
          pxform_c(help_ins,help_iau,et, cbmat);
          if (failed_c()) return -605;
          }
       else
          { /* with light time correction */
          pxform_c(help_ins,"J2000",et, imat);
          if (failed_c()) return -606;
          pxform_c("J2000",help_iau,et-lt, cmat);
          if (failed_c()) return -607;
          mxm_c(cmat, imat, cbmat); 
          }  

      vminus_c(state,positn);

      fhelp1 = 1 - accu;
      fhelp2 = TOTAL_ACTIVE_PIXEL + accu;
      
      for (laufs =0; laufs < npixels; laufs++)
         {

/*    First map sample coordinates to millimeter space (X,Y)
      coordinates. */

/*    Check of pixel numbers */
         if (pixels[laufs] < fhelp1) return (-104);
         if (pixels[laufs] > fhelp2) return (-105);

         intpixel = (int) pixels[laufs];
         fracpixel = pixels[laufs] - (float) intpixel;
         
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

/*
     In order to find the inertial vetor pointing from the amera
     to the atual objet we first need a vetor, all it V, pointing 
     from the x,y oordinate through the foal point to the atual 
     objet.  If we let the foal length of the amera be z, then the 
     vetor <-x,-y,-z> is this vetor V.  The figure below may help you
     piture this (Hint: Put on your 3-D glasses).  The dotted line is 
     the vetor <-x,-y,-z>; it points from the image of the objet to 
     the atual objet.
     
     
                                                   Objet
                                                  * 
                                                .
                                              .              -z  
                         -------------------.----------------|-----  
                        /                 .                  |    /
                       /                .              +x ___|   /
                      /               .                     /   /       /
                     /              . |                    /   /       /
                    /             .   |                   +y  /       /
                   /            .     | z (foal length)     /       /
                  /           .       |                     /       /
                 /       ___._________|                    /       / D-Line
                /      y/ .     x     (x=y=z=0)           /       /
               /       /.                                /       / 
              /       *                                 /       /
             /      Image of                           /       /
            /       objet                            /
           /                                         /
          /                          Foal plane    /
         /                                         /
         ------------------------------------------
                    

   
     
     Pak -X, -Y, and the foal length (the Z dimension -- also in mm) 
     into a 3-D vetor.
     

      This must be (x,y,-focal,vpoint)
      Personal communication by B. Giese (14-August-1996) */

         vpoint[0] = -x;
         vpoint[1] = -y;
         vpoint[2] = focal;

/*     Transformation of VPOINT to the prime meridian / equator frame */
       dlrmxv (cbmat, vpoint, vpoint);
       
/*     Normalize VPOINT */
       dlrvhat(vpoint, vpoint); 
       
       for (lauf3 = 0; lauf3 < 3; lauf3++)
          iv [3*laufs+lauf3] = vpoint[lauf3];
                  
       } /* end of for laufs */
            
    return(1);
    
            
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrviewpa.imake
/* Imake file for VICAR subroutine  hrviewpa   */
#define SUBROUTINE   hrviewpa

#define MODULE_LIST  hrviewpa.c

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE
$ Return
$!#############################################################################
$Test_File:
$ create tsthrviewpa.pdf
Process help=*
 PARM UTC      TYPE=STRING COUNT=1     DEFAULT="2004-JAN-10 00:30" 
 PARM      BSPFILE  TYPE=(STRING,40) COUNT=1:2   DEFAULT=HWSPICE_BSP
 PARM      BCFILE   TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_BC
 PARM      TSCFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_TSC
 PARM      TPCFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=CONSTANTS
 PARM      TLSFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=LEAPSECONDS
 PARM      TIFILE   TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_TI
 PARM      TFFILE   TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_TF
END-PROC
.Title
 Testprogramm fuer hrviewpa
.HELP

WRITTEN BY: Thomas Roatsch, DLR     9-Jun-1993
REVISED BY: Thomas Roatsch, DLR     3-Sep-1993

.LEVEL1
.VARI UTC
 Universal Time String
.VARI BSPFILE
 Binary SP-Kernel 
.VARI BCFILE
 Binary C-Kernel
.VARI TSCFILE
 Text ARGUS Clock Kernel 
.VARI TPCFILE
 Text Planetary Constants Kernel
.VARI TLSFILE
 Text Leapseconds Kernel
.VARI TIFILE
 Text Instrument Kernel
.End
$!-----------------------------------------------------------------------------
$ create tsthrviewpa.imake
/* IMAKE file for Test of VICAR subroutine  hrviewpa   */

#define PROGRAM   tsthrviewpa

#define MODULE_LIST tsthrviewpa.c

#define MAIN_LANG_C
#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_CSPICE
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create tsthrviewpa.c
#include "vicmain_c"

#include "hwldker.h"
#include "hwconst.h"
#include "dlrspice.h"
  
/* C-Testprogram for zhrviewpa */

void main44()

{

   hwkernel_3 bsp;
   hwkernel_6 bc;
   hwkernel_6 tsc;
   hwkernel_1 tpc;
   hwkernel_1 ti;
   hwkernel_1 tf;
   hwkernel_1 tls;
   
   int    count,status;
   char   utc[80];
   char   ins[100], target[100], sc[100];
   double et;
   int lauf, i;
   SpiceInt number;
   int s_max, l_max;
   double positn[3];
   double latlong[2];
   int found;
   float pixels[TOTAL_ACTIVE_PIXEL];
   int npixels = 2;
   double *samp_x; 
   double *samp_y; 
   double focal;
   double iv[TOTAL_ACTIVE_PIXEL][3];
   double radius,lat,longi;
   double helpvec[3],u[3],dhelp;
   double body_axes[3], a,b,c;
   
/* get the parameter */
   zvp("UTC", utc, &count);

   strcpy(target,"MARS");
   strcpy(ins,"HRSC");
   strcpy(sc,"MARS-EXPRESS");

/* 6 kernels have to be loaded */
   status = hwldker(7, "bsp", &bsp,
            "bc",  &bc,
            "tsc", &tsc,
            "tls", &tls,
            "tpc", &tpc,
            "ti", &ti, "tf", &tf);
    
    if (status != 1) 
       {
       printf("problem reading kernels, status %d\n", status);
       zabend();
       }

/* conversion of UTC to ephemeris time */
     str2et_c(utc,&et);
     zhwfailed();

     focal=500.0;
     npixels = 2;
     /* in hrviewpa NON_ACTIVE_HRSC_PIXEL_START will be subtracted */
     pixels[0]=1;   
     pixels[1]=2;

      /*samp_x[0]=0 and samp_y[0]=0 gives the central pixel */
      samp_x = (double *) malloc(TOTAL_ACTIVE_PIXEL * sizeof(double));
      samp_y = (double *) malloc(TOTAL_ACTIVE_PIXEL * sizeof(double));

      samp_x[0]=0;
      samp_y[0]=0;
      samp_x[1]=1;
      samp_y[1]=0;

   status = hrviewpa(target, sc, ins, et, npixels, pixels,
                     samp_x, samp_y, focal, positn, iv);

    if (status != 1) 
       {
       printf("problem in hrviewpa, status %d\n", status);
       zabend();
       }
 
   zvmessage("line of sight vectors:","");

   printf("vector [0][0] %10.5f\n", iv[0][0]);
   printf("vector [0][1] %10.5f\n", iv[0][1]);
   printf("vector [0][2] %10.5f\n", iv[0][2]);
   printf("vector [1][0] %10.5f\n", iv[1][0]);
   printf("vector [1][1] %10.5f\n", iv[1][1]);
   printf("vector [1][2] %10.5f\n", iv[1][2]);

/* conversion from rectangular to latitude/longitude */
   dlrreclat(positn, &radius, &longi, &lat);


   zvmessage("sub spacecraft point:","");

   printf("LATITUDE      %10.5f\n", lat*dpr_c() );
   printf("LONGITUDE     %10.5f\n", longi*dpr_c() );

/* Planetary axes */
   if (!strcmp(target,"MARS"))
      bodvar_c(499, "RADII", &number, body_axes);

/* SPICE error checking */
   zhwfailed();

   a = body_axes[0];
   b = body_axes[1];
   c = body_axes[2];

 /* surface intersection point of the central pixel */
   for (lauf = 0; lauf <=2; lauf++)
   {
      u[lauf] = iv [0][lauf];
   }

   dlrsurfpt(positn, u, a, b, c, helpvec, &found);
   if (found)
      {
      reclat_c(helpvec, &dhelp, &latlong[1], &latlong[0]);
      zvmessage("intersection point:","");
      printf("LATITUDE      %10.5f\n", latlong[0]*dpr_c());
      printf("LONGITUDE     %10.5f\n", latlong[1]*dpr_c());
      }
   else
      zvmessage("no intersection point found","");

subpt_c("Near Point","MARS", et, "LT", "MARS_EXPRESS", positn, &latlong[0]);
zhwfailed();
   dlrreclat(positn, &radius, &longi, &lat);


   zvmessage("sub spacecraft point:","");

   printf("LATITUDE      %10.5f\n", lat*dpr_c() );
   printf("LONGITUDE     %10.5f\n", longi*dpr_c() );
     
   zvmessage("TSTHRVIEWPA task completed","");

}
$ Return
$!#############################################################################
