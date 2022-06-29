$!****************************************************************************
$!
$! Build proc for MIPL module hwllnorm
$! VPACK Version 1.9, Wednesday, August 20, 2003, 15:49:13
$!
$! Execute by entering:		$ @hwllnorm
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
$ write sys$output "*** module hwllnorm ***"
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
$ write sys$output "Invalid argument given to hwllnorm.com file -- ", primary
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
$   if F$SEARCH("hwllnorm.imake") .nes. ""
$   then
$      vimake hwllnorm
$      purge hwllnorm.bld
$   else
$      if F$SEARCH("hwllnorm.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwllnorm
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwllnorm.bld "STD"
$   else
$      @hwllnorm.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwllnorm.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwllnorm.com -
	-s zhwllnorm.c -
	-i hwllnorm.imake -
	-t tstzhwllnorm.c tstzhwllnorm.imake tstzhwllnorm.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create zhwllnorm.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "dlrspice.h"
#include "math.h"

/*     Written by Thomas Roatsch, DLR     9-Jun-1993
       test program in C and pdf are included
       Rewritten in C by Thomas Roatsch, DLR    20-oct-1998 */


      void zhwllnorm (lat, longi, radii, long_axis,  norm)
      
/*     Subroutine calculates for a given point (latitude and longitude)
      the normal vector on the surface*/


      double       lat;
      double       longi;
      double       radii [3];
      double       long_axis;
      double       norm [3];
 
/*     Variable  I/O  Description
      --------  ---  --------------------------------------------------
      LAT        I   Planetocentri  latitude at the surface in radians.
      LONGI      I   Planetocentri  longitude at the surface in radians.
      RADII      I   Axes of the body.
      LONG_AXIS  I   Positive west longitude, measured from the prime
                     meridian, of the longest axis of the ellipsoid
      NORM       O   Normal vector at the surface (outwards). */

{
      double         point [3];
      double         uvec  [3];
      double         mout  [3][3];
      int            found;
      double         orign[3];
      double         dhelp;
      
      orign[0] = 0;
      orign[1] = 0;
      orign[2] = 0;
      dhelp    = 1;
/*     Find the unit vector pointing from the body center to the
       input surface point. */
       
      dlrlatrec(dhelp, longi, lat, uvec);


/*     ROTATION FROM PM */
      if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
         {
         dlrrotate(-long_axis, 3, mout);
         dlrmxv(mout, uvec, uvec);
         }

/*     Find out where the ray defined by this vector intersects the
     surface.  This intercept is the point we're looking for. */

      dlrsurfpt(orign, uvec, radii[0], radii[1], radii[2], point, &found);
      
      if (!found)
         {
         zvmessage("no point found in hwllnorm","");
         zabend();
         }      

/*     Find the surface normal vector */


      dlrsurfnm(radii[0], radii[1], radii[2], point, norm);

      
/*        ROTATION TO PM  */
         if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
         {
         dlrrotate(long_axis, 3, mout);
         dlrmxv(mout, norm, norm);
         }

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwllnorm.imake

/* Imake file for VICAR subroutine  HWLLNORM   */

#define SUBROUTINE   hwllnorm

#define MODULE_LIST  zhwllnorm.c

#define HW_SUBLIB
#define LIB_CSPICE

#define USES_ANSI_C
$ Return
$!#############################################################################
$Test_File:
$ create tstzhwllnorm.c
#include "vicmain_c"
#include "ftnbridge.h"
#include "hwldker.h"

/*
C-Testprogram for hwllnorm
*/

void main44()

{

   int        count;
   hwkernel_1 tpc;
   SpiceInt   number;
   double     lat;
   double     longi;
   double     radii[3];
   double     long_axis;
   double     norm[3];
   double     hilfe;

   zveaction("sa","");


   hwldker(1, "tpc", &tpc);
   
   lat = 1.2;
   longi = 0.3;

/* Get the Martian (499) axes */
   bodvar_c(499, "RADII", &number, radii);


   hilfe = radii[0] - radii[1];
   if (hilfe < 1e-10)
      {
      long_axis=0;
      }
   else
      {
      bodvar_c(499,"LONG_AXIS", &number, &long_axis);
      }

   
   zhwllnorm(lat, longi, radii, long_axis, norm);


   printf("normal vector: %6.3f %6.3f %6.3f\n", norm[0], norm[1], norm[2]);

   zvmessage("TSTZHWLLNORM task completed","");

}

$!-----------------------------------------------------------------------------
$ create tstzhwllnorm.imake
/* IMAKE file for Test of VICAR subroutine  HWGETSUN   */

#define PROGRAM   tstzhwllnorm

#define MODULE_LIST tstzhwllnorm.c

#define MAIN_LANG_C
#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_CSPICE
#define LIB_HWSUB

$!-----------------------------------------------------------------------------
$ create tstzhwllnorm.pdf
Process help=*
 PARM      TPCFILE  TYPE=(STRING,80) COUNT=1 DEFAULT=HWSPICE_TPC
END-PROC
.Title
 Testprogramm fuer HWLLNORM
.HELP

WRITTEN BY: Thomas Roatsch, DLR     9-Jun-1993

.Level1
.VARI TPCFILE
 Planetary Constants Text Kernel
.End
$ Return
$!#############################################################################
