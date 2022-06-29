$!****************************************************************************
$!
$! Build proc for MIPL module dlrframe_error
$! VPACK Version 1.9, Monday, August 11, 2003, 15:26:42
$!
$! Execute by entering:		$ @dlrframe_error
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
$ write sys$output "*** module dlrframe_error ***"
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
$ write sys$output "Invalid argument given to dlrframe_error.com file -- ", primary
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
$   if F$SEARCH("dlrframe_error.imake") .nes. ""
$   then
$      vimake dlrframe_error
$      purge dlrframe_error.bld
$   else
$      if F$SEARCH("dlrframe_error.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrframe_error
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrframe_error.bld "STD"
$   else
$      @dlrframe_error.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrframe_error.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrframe_error.com -
	-s dlrframe_error.c -
	-i dlrframe_error.imake -
	-o dlrframe_error.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrframe_error.c
$ DECK/DOLLARS="$ VOKAGLEVE"

/*     Written by Thomas Roatsch, DLR     2-Jun-1999 */

#include "dlrframe.h"

int dlrframe_error (int number, char *routine, 
                    char message[DLRFRAME_ERROR_LENGTH] )

{

if (number > 0) return (-1);

if (!strcmp(routine,"info"))
   {
   switch (number)
      {
case  -1:     strcpy(message,
              "can not read the image system label");
              break;

case  -101:   strcpy(message,
              "image is Voyager, FDS missing");
              break;
case  -102:   strcpy(message,
              "image is Voyager, SCET missing");
              break;
case  -103:   strcpy(message,
              "image is Voyager, CAMERA is neither NA or WA");
              break;
case  -104:   strcpy(message,
              "image is Voyager, CAMERA is missing");
              break;
case  -105:   strcpy(message,
              "image is Voyager, could not determine TARGET");
              break;

case  -201:   strcpy(message,
              "image is DLR-type, SPICE_TARGET_ID missing");
              break;
case  -202:   strcpy(message,
              "image is DLR-type, SPICE_INSTRUMENT_ID missing");
              break;
case  -203:   strcpy(message,
              "image is DLR-type, unknown SPACECRAFT_NAME");
              break;
case  -211:   strcpy(message,
              "image is Viking, IMAGE_TIME missing");
              break;
case  -212:   strcpy(message,
              "image is Viking, IMAGE_NUMBER missing");
              break;
case  -221:   strcpy(message,
              "image is Clementine, START_TIME missing");
              break;
case  -222:   strcpy(message,
              "image is Clementine, FRAME_SEQUENCE_NUMBER missing");
              break;
case  -223:   strcpy(message,
              "image is Clementine, ORBIT_NUMBER missing");
              break;

case  -301:   strcpy(message,
              "image is Galileo-SSI, TARGET missing");
              break;
case  -302:   strcpy(message,
              "image is Galileo-SSI, unknown TARGET");
              break;
case  -303:   strcpy(message,
              "image is Galileo-SSI, RIM missing");
              break;
case  -304:   strcpy(message,
              "image is Galileo-SSI, MOD91 missing");
              break;
case  -305:   strcpy(message,
              "image is Galileo-SSI, SCETYEAR missing");
              break;
case  -306:   strcpy(message,
              "image is Galileo-SSI, SCETDAY missing");
              break;
case  -307:   strcpy(message,
              "image is Galileo-SSI, SCETHOUR missing");
              break;
case  -308:   strcpy(message,
              "image is Galileo-SSI, SCETMIN missing");
              break;
case  -309:   strcpy(message,
              "image is Galileo-SSI, SCETSEC missing");
              break;
case  -310:   strcpy(message,
              "image is Galileo-SSI, SCETMSEC missing");
              break;

case  -401:   strcpy(message,
              "image is Cassini-ISS, INSTRUMENT_ID missing");
              break;
case  -402:   strcpy(message,
              "image is Cassini-ISS, INSTRUMENT_ID is neither ISSNA or ISSWA");
              break;
case  -403:   strcpy(message,
              "image is Cassini-ISS, IMAGE_NUMBER missing");
              break;
case  -404:   strcpy(message,
              "image is Cassini-ISS, IMAGE_TIME missing");
              break;
case  -405:   strcpy(message,
              "image is Cassini-ISS, IMAGE_TARGET missing");
              break;
case  -406:   strcpy(message,
              "image is Cassini-ISS, TARGET-ID not found in SPICE");
              break;
              
case  -501:   strcpy(message,
              "image is MEX-SRC, IMAGE_TIME missing");
              break;
case  -502:   strcpy(message,
              "image is MEX-SRC, IMAGE_TARGET missing");
              break;
case  -503:   strcpy(message,
              "image is MEX-SRC, TARGET-ID not found in SPICE");
              break;
case  -504:   strcpy(message,
              "image is MEX-SRC, FILE_NAME missing");
              break;
case  -505:   strcpy(message,
              "image is MEX-SRC, PROCESSING_LEVEL_ID != 2");
              break;
case  -506:   strcpy(message,
              "image is MEX-SRC, SAMPLE_FIRST_PIXEL missing");
              break;
case  -507:   strcpy(message,
              "image is MEX-SRC, LINE_FIRST_PIXEL missing");
              break;

case  -99:    strcpy(message,
              "unknown camera");
              break;
default:      return (-2);
      }

return (1);

   } /* end of info */  


if (!strcmp(routine,"geo"))
   {
   switch (number)
      {
case    -2:   strcpy(message,"unsupported S/C");
              break;
case  -101:   strcpy(message,"FOCAL_LENGTH missing in I-kernel");
              break;
case  -102:   strcpy(message,"K missing in I-kernel");
              break;
case  -103:   strcpy(message,"S0 missing in I-kernel");
              break;
case  -104:   strcpy(message,"L0 missing in I-kernel");
              break;
case  -105:   strcpy(message,"L_MAX missing in I-kernel");
              break;
case  -106:   strcpy(message,"image NL != L_MAX in I-kernel");
              break;
case  -107:   strcpy(message,"S_MAX missing in I-kernel");
              break;
case  -108:   strcpy(message,"image NS != S_MAX in I-kernel");
              break;
case  -109:   strcpy(message,"ALPHA0 missing in I-kernel");
              break;
case  -110:   strcpy(message, "instrument name missing in frame kernel");
              break;
case  -111:   strcpy(message,"PIXEL_SIZE missing in I-kernel");
              break;
case  -112:   strcpy(message,"CCD_CENTER missing in I-kernel");
              break;
case  -113:   strcpy(message,"PIXEL_LINES missing in I-kernel");
              break;
case  -114:   strcpy(message,"PIXEL_SAMPLES missing in I-kernel");
              break;
              
case  -201:   strcpy(message,"no adjufile given for Voyager");
              break;
case  -211:   strcpy(message,"CROSS_CONE missing in Viking I-kernel");
              break;
case  -212:   strcpy(message,"CONE missing in Viking I-kernel");
              break;
case  -213:   strcpy(message,"RASTER_ORIENTATION missing in Viking I-kernel");
              break;
case  -221:   strcpy(message,"THETAX missing in Clementine I-kernel");
              break;
case  -222:   strcpy(message,"THETAY missing in Clementine I-kernel");
              break;
case  -223:   strcpy(message,"THETAZ missing in Clementine I-kernel");
              break;
case  -231:   strcpy(message,"OFFSET missing in Cassini I-kernel");
              break;
case  -232:   strcpy(message,"AXES missing in Cassini I-kernel");
              break;

case  -501:   strcpy(message,"no Leapsecond kernel loaded");
              break;
case  -502:   strcpy(message,"no clock kernel loaded");
              break;
case  -503:   strcpy(message,"S/C postion missing in S/P-kernel");
              break;
case  -504:   strcpy(message,"Target rotation not in Plan. Const. kernel");
              break;
case  -505:   strcpy(message,"Target radii not in Plan. Const. kernel");
              break;
case  -506:   strcpy(message,"C-Matrix not found in C-kernel");
              break;

case  -601:   strcpy(message,"error in adjufile");
              break;
case  -602:   strcpy(message,"Image-ID not found in adjufile");
              break;

default:      return (-2);
      }

return (1);

   } /* end of geo */

return (-99);

}


$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrframe_error.imake
/* Imake file for VICAR subroutine  dlrframe_error*/

#define SUBROUTINE   dlrframe_error

#define MODULE_LIST  dlrframe_error.c

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_CSPICE
$ Return
$!#############################################################################
$Other_File:
$ create dlrframe_error.hlp
dlrframe_error returns the error message for a given error #.

Return values:

 1: o.k.
 
-1: error number > 0

-2: wrong error number

-3: wrong subroutine
$ Return
$!#############################################################################
