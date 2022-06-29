$!****************************************************************************
$!
$! Build proc for MIPL module fladjuview
$! VPACK Version 1.9, Friday, April 23, 1999, 13:23:38
$!
$! Execute by entering:		$ @fladjuview
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
$ write sys$output "*** module fladjuview ***"
$!
$ Create_Source = ""
$ Create_Repack =""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Imake .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to fladjuview.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
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
$   if F$SEARCH("fladjuview.imake") .nes. ""
$   then
$      vimake fladjuview
$      purge fladjuview.bld
$   else
$      if F$SEARCH("fladjuview.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake fladjuview
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @fladjuview.bld "STD"
$   else
$      @fladjuview.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create fladjuview.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack fladjuview.com -
	-s zfladjuview.c -
	-i fladjuview.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create zfladjuview.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "dlrspice.h"

/*     Written by Thomas Roatsch, DLR    13-FEB-1997 */


      void zfladjuview (npixels, pixels, rbc, samp_x, samp_y, focal, iv)

/*     Subroutine calculates for given pixel numbers 
       the viewing direction of these pixels */

      int     npixels;          
      float   *pixels;
      double  rbc [3][3];
      double  *samp_x;
      double  *samp_y;
      double  focal;
      double  *iv;

/*      VARIABLE  I/O  DESCRIPTION
       --------  ---  --------------------------------------------------
       NPIXELS    I   Number of pixels
       PIXELS     I   Real numbers of these pixels
       RBC        I   Roation matrix from 
                      body system to photogrammetry system
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
      double   vpoint [3];
      double   accu;
      double   fhelp1;
      
/*    HAS TO BE DISCUSSED */
      accu = 0.01;

      
/* check at the begin of function */
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


/*     The photogrammetry fixed vector for HRSC airplane is (-x,-y,-focal)
       Reference
       private communication by B. Giese (12-Feb-1997) */
      
       vpoint[0] = -x;
       vpoint[1] = -y;
       vpoint[2] = -focal;
      


/*     Transformation of VPOINT to the prime meridian / equator frame */
       dlrmtxv (rbc, vpoint, vpoint);

/*     normalize vpoint */
       dlrvhat (vpoint, vpoint);

        for (lauf3 = 0; lauf3 < 3; lauf3++)
          iv [3*laufs+lauf3] = vpoint[lauf3];
                 
       } /* end of for laufs */

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create fladjuview.imake
/* Imake file for VICAR subroutine  fladjuview   */
#define SUBROUTINE   fladjuview

#define MODULE_LIST  zfladjuview.c

#define HW_SUBLIB

#define USES_ANSI_C
$ Return
$!#############################################################################
