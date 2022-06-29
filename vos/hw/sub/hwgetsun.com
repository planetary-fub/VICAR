$!****************************************************************************
$!
$! Build proc for MIPL module hwgetsun
$! VPACK Version 1.9, Wednesday, August 20, 2003, 15:47:18
$!
$! Execute by entering:		$ @hwgetsun
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
$ write sys$output "*** module hwgetsun ***"
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
$ write sys$output "Invalid argument given to hwgetsun.com file -- ", primary
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
$   if F$SEARCH("hwgetsun.imake") .nes. ""
$   then
$      vimake hwgetsun
$      purge hwgetsun.bld
$   else
$      if F$SEARCH("hwgetsun.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwgetsun
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwgetsun.bld "STD"
$   else
$      @hwgetsun.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwgetsun.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwgetsun.com -
	-s zhwgetsun.c -
	-i hwgetsun.imake -
	-t tstzhwgetsun.pdf tstzhwgetsun.imake tstzhwgetsun.c ttstzhwgetsun.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create zhwgetsun.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "SpiceUsr.h"

/*    Written by Thomas Roatsch, DLR     9-Jun-1993
      Revised by Thomas Roatsch, DLR    10-Sep-1993
      Change Sun-ID     Roatsch. DLR    24-Mar-1998
      Rewritten in C by Thomas Roatsch, DLR 20-oct-1998 */

/*    Subroutine returns for given ephemeris time and target
      the position of the sun as seen from the target */

      int zhwgetsun (et, target, sunposition)

      double       et;
      int          target;
      double       sunposition [3];
 
/*    Variable    I/O  Description
     --------    ---  --------------------------------------------------
     ET           I   Epoch in ephemeris seconds past J2000.
     TARGET       I   SPICE-ID of the target
     SUNPOSITION  O   Position of the Sun in the Mars centered system
                      (Light time correction is included) */
{
      double       lts;
      double       tipm [3][3];
      double       sunstate [6];
      int          target100;
      int          lauf;
      
      if (target > 100) 
        target100 = (int) (target / 100) ;
      else
        target100 = (int) (target + 0.4);

/*    Find the state of the Sun (ID=10) as seen from the target at ET.
      Also obtain the J2000-to-body equator and prime meridian
      transformation for this time. */

      spkez_c  ( 10, et, "j2000", "lt", target100, sunstate, &lts );
      if (failed_c() ) return -1;
      
      tipbod_c("J2000", target,et,tipm);
      if (failed_c() ) return -2;
      
/*    Grab the position portions of the state (the first three
      elements of each state) */  
      for (lauf=0; lauf < 3; lauf++)
         sunposition[lauf] = sunstate[lauf];

/*     We need the sun position in body-fixed coordinates. */

      dlrmxv ( tipm, sunposition, sunposition );
      
      return 1;

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwgetsun.imake
/* Imake file for VICAR subroutine  HWGETSUN   */

#define SUBROUTINE   hwgetsun

#define MODULE_LIST  zhwgetsun.c

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_CSPICE
$ Return
$!#############################################################################
$Test_File:
$ create tstzhwgetsun.pdf
Process help=*
 PARM UTC      TYPE=STRING COUNT=1     DEFAULT="1995-280 // 16:55:04" 
 PARM      TPCFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_TPC
 PARM      TLSFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_TLS
 PARM      SUNFILE  TYPE=(STRING,40) COUNT=1     DEFAULT=HWSPICE_SUN
END-PROC
.Title
 Testprogramm fuer ZHWGETSUN
.HELP

WRITTEN BY: Thomas Roatsch, DLR     9-Jun-1993
REVISED BY: Thomas Roatsch, DLR     3-Sep-1993

.LEVEL1
.VARI UTC
 Universal Time String
.VARI TPCFILE
 Text Planetary Constants Kernel
.VARI TLSFILE
 Text Leapseconds Kernel
.VARI SUNFILE
 Binary SP-Kernel for the Sun
.End
$!-----------------------------------------------------------------------------
$ create tstzhwgetsun.imake
/* IMAKE file for Test of VICAR subroutine  HWGETSUN   */

#define PROGRAM   tstzhwgetsun  

#define MODULE_LIST tstzhwgetsun.c

#define MAIN_LANG_C
#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_CSPICE
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create tstzhwgetsun.c
#include "vicmain_c"
#include "ftnbridge.h"
#include "hwldker.h"
#include <string.h>

/*
C-Testprogram for hwgetsun
*/

void main44()

{

   hwkernel_1 tpc;
   hwkernel_1 sunker;
   hwkernel_1 tls;

   int    count,status;

   double sunposition[3];
   char   utc[80];
   double et;
   int    target;

   zveaction("sa","");

/*
   target is Mars, SPICE-ID 499
*/
   target = 499;

/* SPICE error action */
erract_c ("SET", SPICE_ERR_LENGTH, "REPORT");
errprt_c ("SET", SPICE_ERR_LENGTH, "NONE");

/* hwldker has to be first */
   status = hwldker(3, "tpc", &tpc,
           "tls", &tls,
           "sunker", &sunker); 
   if (status != 1) 
      {
      zvmessage("hwldker problem","");
      printf("hwldker status %d\n",status);
      zabend();
      }
      
   zvp("UTC", utc, &count);

/* conversion of UTC to ephemeris time */
   utc2et_c(utc,&et);
   if (failed_c() )
      {
      zvmessage("utc2et problem","");
      zabend();
      }

   status = zhwgetsun(et, target, sunposition);
   if (status != 1) 
      {
      zvmessage("hwgetsun problem","");
      printf("hwgetsun status %d\n",status);
      zabend();
      }


   zvmessage("sun position","");

   printf("%12.3f %12.3f %12.3f\n",
          sunposition[0], sunposition[1], sunposition[2]);

   zvmessage("","");
   zvmessage("TSTZHWGETSUN task completed","");

}
$!-----------------------------------------------------------------------------
$ create ttstzhwgetsun.pdf
procedure
refgbl $echo
body
let _onfail="continue"
tstzhwgetsun
end-proc
$ Return
$!#############################################################################
