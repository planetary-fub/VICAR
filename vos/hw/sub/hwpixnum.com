$!****************************************************************************
$!
$! Build proc for MIPL module hwpixnum
$! VPACK Version 1.9, Thursday, March 23, 2006, 13:57:44
$!
$! Execute by entering:		$ @hwpixnum
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
$ write sys$output "*** module hwpixnum ***"
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
$ write sys$output "Invalid argument given to hwpixnum.com file -- ", primary
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
$   if F$SEARCH("hwpixnum.imake") .nes. ""
$   then
$      vimake hwpixnum
$      purge hwpixnum.bld
$   else
$      if F$SEARCH("hwpixnum.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwpixnum
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwpixnum.bld "STD"
$   else
$      @hwpixnum.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwpixnum.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwpixnum.com -mixed -
	-s hwpixnum.c -
	-i hwpixnum.imake -
	-t thwpixnum.c thwpixnum.imake thwpixnum.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwpixnum.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/* HWPIXNUM translates an image pixel number into CCD pixel number and vice */
/* versa. ( with Fortran bridge ) */

/* WRITTEN BY */
/* KDM, DLR   13-Oct-1993 */

float  hwpixnum(numb, macro, fip, mode)

float	numb;
int	macro;
int	fip;
int	mode;
{
float	convpix;
float moc27[384];
float cumu;
int lauf;

if (macro == 27)
   {
   printf("MOC Macropixelformat 27 not yet supported\n");
   zabend();
   }
             
if (mode == 0) {
  zvmessage("HWPIXNUM: Parameter MODE must be uneven 0", "");
  zabend();
  }

if (mode > 0) {		/* image pixel --> CCD pixel */
  convpix=(fip-0.5+macro*(numb-0.5));
  }
else {			/* CCD pixel --> image pixel */
  convpix=((numb+0.5-fip)/macro+0.5);
  }

return (convpix);
}

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwpixnum.imake
/* IMAKE file for Subroutine HWPIXNUM */

#define SUBROUTINE hwpixnum  

#define MODULE_LIST hwpixnum.c

#define HW_SUBLIB

#define USES_ANSI_C
$ Return
$!#############################################################################
$Test_File:
$ create thwpixnum.c

#include "vicmain_c"

void main44()
{
int	fip, macro, mode, count;
float	pixel, convpix;
char	msgbuf[255];

float	hwpixnum();

/*
Standard error action for VICAR I/O
*/
zveaction("sa","");

/*
Read parameters
*/
zvp("pixel", &pixel, &count);
zvp("fip",  &fip,  &count);
zvp("macro",  &macro,  &count);
zvp("mode",  &mode,  &count);

convpix = hwpixnum(pixel, macro, fip, mode);

if (mode > 0) 
	sprintf(msgbuf, "Image pixel %g  -->  CCD pixel %g", pixel, convpix);
else
	sprintf(msgbuf, "CCD pixel %g  -->  Image pixel %g", pixel, convpix);

zvmessage(msgbuf, "");
}





$!-----------------------------------------------------------------------------
$ create thwpixnum.imake
/* IMAKE file for Test Program THWPIXNUM */

#define PROGRAM   thwpixnum  

#define MODULE_LIST thwpixnum.c 

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_FORTRAN
#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB 
#define LIB_LOCAL
$!-----------------------------------------------------------------------------
$ create thwpixnum.pdf
Process help=*
 PARM	PIXEL	TYPE=REAL	COUNT=1         DEFAULT=2
 PARM	MACRO	TYPE=INTEGER	COUNT=1		DEFAULT=1
 PARM	FIP	TYPE=INTEGER	COUNT=1		DEFAULT=17
 PARM	MODE	TYPE=INTEGER	COUNT=1		DEFAULT=1

END-PROC
.Title
 Test Program THWPIXNUM for subroutine HWPIXNUM.
.HELP

PURPOSE

HWPIXNUM translates an image pixel number into CCD pixel number and vice versa.

WRITTEN BY

KDM, DLR   13-Oct-1993

.LEVEL1
.VARI PIXEL
 Given pixel number.
.VARI MACRO
 Macropixelformat.
.VARI FIP
 First pixel in file.
.VARI MODE
 Course of translation.

.LEVEL2
.VARI PIXEL
 Given pixel number.
.VARI MACRO
 Macropixelformat (should be 1 or 2 or 4 or 8).
.VARI FIP
 First pixel in file (defined in Data Management Document).
.VARI MODE
 Course of translation.
 mode > 0 ... from image to CCD line
 mode < 0 ... from CCD line to image

.End

$ Return
$!#############################################################################
