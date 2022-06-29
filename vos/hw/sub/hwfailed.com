$!****************************************************************************
$!
$! Build proc for MIPL module hwfailed
$! VPACK Version 1.9, Tuesday, November 04, 2003, 11:16:26
$!
$! Execute by entering:		$ @hwfailed
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
$ write sys$output "*** module hwfailed ***"
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
$ write sys$output "Invalid argument given to hwfailed.com file -- ", primary
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
$   if F$SEARCH("hwfailed.imake") .nes. ""
$   then
$      vimake hwfailed
$      purge hwfailed.bld
$   else
$      if F$SEARCH("hwfailed.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwfailed
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwfailed.bld "STD"
$   else
$      @hwfailed.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwfailed.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwfailed.com -
	-s zhwfailed.c -
	-i hwfailed.imake -
	-t tstzhwfailed.c tstzhwfailed.imake tstzhwfailed.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create zhwfailed.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*     Written by Thomas Roatsch, DLR     9-Jun-1993
       Rewritten in C by Thomas Roatsch, DLR     6-Oct-1998 */
       
#include "hwldker.h"

void zhwerrini()

{      
erract_c ( "SET", SPICE_ERR_LENGTH, "RETURN" );

errprt_c ( "SET", SPICE_ERR_LENGTH, "NONE");
}

void zhwfailed()

{

char text[SPICE_ERR_LENGTH+1];

if ( failed_c() )
   { 
   getmsg_c("LONG", SPICE_ERR_LENGTH, text);
   /* to avoid stupid characters at the end */
   text[SPICE_ERR_LENGTH]='\0';
   zvmessage("","");
   zvmessage("#E: SPICE ERROR","");
   zvmessage("","");
   zvmessage(text,"");
   zabend();
   }
   
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwfailed.imake
/* Imake file for VICAR subroutine  HWFAILED   */

#define SUBROUTINE   hwfailed

#define MODULE_LIST  zhwfailed.c 

#define HW_SUBLIB
#define LIB_CSPICE

#define USES_ANSI_C
$ Return
$!#############################################################################
$Test_File:
$ create tstzhwfailed.c
#include "vicmain_c"
#include "SpiceUsr.h"

/* Testprogramm for Function ZHWFAILED.c and ZHWERRINI.C   */

void main44()

{

zhwerrini();
zhwfailed();

zvmessage("","");
zvmessage("TSTHWFAILED succesfully completed", "");

} 
$!-----------------------------------------------------------------------------
$ create tstzhwfailed.imake
/* Imake file for TSTZHWFAILED */

#define PROGRAM tstzhwfailed

#define MODULE_LIST tstzhwfailed.c

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create tstzhwfailed.pdf
Process help=*
END-PROC
.Title
 Testprogramm fuer HWFAILED
.HELP

WRITTEN BY: Thomas Roatsch, DLR     8-Mar-1994

.End
 
$ Return
$!#############################################################################
