$!****************************************************************************
$!
$! Build proc for MIPL module hwldker_error
$! VPACK Version 1.9, Monday, December 06, 2004, 14:04:16
$!
$! Execute by entering:		$ @hwldker_error
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
$ write sys$output "*** module hwldker_error ***"
$!
$ Create_Source = ""
$ Create_Repack =""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if primary .eqs. "OTHER" then Create_Other = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Imake .or. Create_Other .or -
        Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hwldker_error.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Create_Other then gosub Other_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
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
$   if F$SEARCH("hwldker_error.imake") .nes. ""
$   then
$      vimake hwldker_error
$      purge hwldker_error.bld
$   else
$      if F$SEARCH("hwldker_error.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwldker_error
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwldker_error.bld "STD"
$   else
$      @hwldker_error.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwldker_error.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwldker_error.com -mixed -
	-s hwldker_error.c -
	-i hwldker_error.imake -
	-o hwldker_error.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwldker_error.c
$ DECK/DOLLARS="$ VOKAGLEVE"

/*     Written by Thomas Roatsch, DLR     15-Jun-2000 */

#include "hwldker.h"

int hwldker_error (int number, 
                    char message[HWLDKER_ERROR_LENGTH] )

{

if (number > 0) return (-1);

switch (number)
      {
case  -11:    strcpy(message,
              "can not get the BSPFILE from PDF");
              break;
case  -12:    strcpy(message,
              "less than one BSPFILE specified");
              break;
case  -13:    strcpy(message,
              "BSPFILE does not exist");
              break;
case  -14:    strcpy(message,
              "can not laod the BSPFILE");
              break;

case  -21:    strcpy(message,
              "can not get the SUNFILE from PDF");
              break;
case  -22:    strcpy(message,
              "less than or more than one SUNFILE specified");
              break;
case  -23:    strcpy(message,
              "SUNFILE does not exist");
              break;
case  -24:    strcpy(message,
              "can not laod the SUNFILE");
              break;

case  -31:    strcpy(message,
              "can not get the PHO_DEI from PDF");
              break;
case  -32:    strcpy(message,
              "less than or more than one PHO_DEI specified");
              break;
case  -33:    strcpy(message,
              "PHO_DEI does not exist");
              break;
case  -34:    strcpy(message,
              "can not laod the PHO_DEI");
              break;

case  -41:    strcpy(message,
              "can not get the BCFILE from PDF");
              break;
case  -42:    strcpy(message,
              "less than one BCFILE specified");
              break;
case  -43:    strcpy(message,
              "BCFILE does not exist");
              break;
case  -44:    strcpy(message,
              "can not laod the BCFILE");
              break;
              
case  -51:    strcpy(message,
              "can not get the TSCFILE from PDF");
              break;
case  -52:    strcpy(message,
              "less than or more than one TSCFILE specified");
              break;
case  -53:    strcpy(message,
              "TSCFILE does not exist");
              break;
case  -54:    strcpy(message,
              "can not laod the TSCFILE");
              break;
              
case  -61:    strcpy(message,
              "can not get the TPCFILE from PDF");
              break;
case  -62:    strcpy(message,
              "less than or more than one TPCFILE specified");
              break;
case  -63:    strcpy(message,
              "TPCFILE does not exist");
              break;
case  -64:    strcpy(message,
              "can not laod the TPCFILE");
              break;
              
case  -71:    strcpy(message,
              "can not get the BPCFILE from PDF");
              break;
case  -72:    strcpy(message,
              "less than or more than one BPCFILE specified");
              break;
case  -73:    strcpy(message,
              "BPCFILE does not exist");
              break;
case  -74:    strcpy(message,
              "can not laod the BPCFILE");
              break;
              
case  -81:    strcpy(message,
              "can not get the TLSFILE from PDF");
              break;
case  -82:    strcpy(message,
              "less than or more than one TLSFILE specified");
              break;
case  -83:    strcpy(message,
              "TLSFILE does not exist");
              break;
case  -84:    strcpy(message,
              "can not laod the TLSFILE");
              break;
              
case  -91:    strcpy(message,
              "can not get the TIFILE from PDF");
              break;
case  -92:    strcpy(message,
              "less than or more than one TIFILE specified");
              break;
case  -93:    strcpy(message,
              "TIFILE does not exist");
              break;
case  -94:    strcpy(message,
              "can not laod the TIFILE");
              break;
              
              
case  -101:    strcpy(message,
              "can not get the TFFILE from PDF");
              break;
case  -102:    strcpy(message,
              "less than or more than one TFFILE specified");
              break;
case  -103:    strcpy(message,
              "TFFILE does not exist");
              break;
case  -104:    strcpy(message,
              "can not laod the TFFILE");
              break;
              

default:      return (-2);
      }

return (1);

   } /* end of info */  
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwldker_error.imake
/* Imake file for VICAR subroutine  hwldker_error*/

#define SUBROUTINE   hwldker_error

#define MODULE_LIST  hwldker_error.c

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_CSPICE
$ Return
$!#############################################################################
$Other_File:
$ create hwldker_error.hlp
hwldker_error returns the error message for a given error #.

Return values:

 1: o.k.
 
-1: error number > 0

-2: wrong error number
$ Return
$!#############################################################################
