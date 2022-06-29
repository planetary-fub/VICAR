$!****************************************************************************
$!
$! Build proc for MIPL module hrgetstdscale
$! VPACK Version 1.9, Tuesday, November 25, 2003, 20:45:42
$!
$! Execute by entering:		$ @hrgetstdscale
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
$ write sys$output "*** module hrgetstdscale ***"
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
$ write sys$output "Invalid argument given to hrgetstdscale.com file -- ", primary
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
$   if F$SEARCH("hrgetstdscale.imake") .nes. ""
$   then
$      vimake hrgetstdscale
$      purge hrgetstdscale.bld
$   else
$      if F$SEARCH("hrgetstdscale.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrgetstdscale
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrgetstdscale.bld "STD"
$   else
$      @hrgetstdscale.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrgetstdscale.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrgetstdscale.com -
	-s hrgetstdscale.c -
	-i hrgetstdscale.imake -
	-t tsthrgetstdscale.c tsthrgetstdscale.imake tsthrgetstdscale.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrgetstdscale.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include <stdio.h>
#include <string.h>
#include "hrgetstdscale.h"

/* status values 

 1:  o.k.
-1:  invalid detector_id 

*/

int hrgetstdscale(/* Input */
                 char *det_id,      /* detector ID (MEX IDs are valid) */
                 double scale,      /* given scale [km/pixel]*/
                 
                 /* Output */
                 double *std_scale   /* nearest standard scale to given scale 
				                       for this detector [km/pixel]*/
                 )

{
int         i;
double		std_scales_HRSC[NUMBER_OF_STD_SCALES_HRSC_SRC], std_scales_SRC[NUMBER_OF_STD_SCALES_HRSC_SRC]; 

std_scales_SRC[0]  = BASIC_SCALE_SRC; 
std_scales_HRSC[0] = BASIC_SCALE_HRSC; 

for (i=1;i<NUMBER_OF_STD_SCALES_HRSC_SRC;i++)
	{
	std_scales_SRC[i]  = 2.0 * std_scales_SRC[i-1];
	std_scales_HRSC[i] = 2.0 * std_scales_HRSC[i-1];
	}

if (!strncmp(det_id,"MEX_HRSC_SRC",12))
    {
	if (scale < std_scales_SRC[0])
		{
		*std_scale = std_scales_SRC[0];
		return (1);
		}
	
	for (i=NUMBER_OF_STD_SCALES_HRSC_SRC-1;i>=0;i--) if (scale > std_scales_SRC[i]) break;
	
	if (i == (NUMBER_OF_STD_SCALES_HRSC_SRC-1))
		{
		*std_scale = (double)((int)(scale/std_scales_SRC[NUMBER_OF_STD_SCALES_HRSC_SRC-1] + 0.5)) 
		             * std_scales_SRC[NUMBER_OF_STD_SCALES_HRSC_SRC-1];
		return (1); 
		}
	else
		{
		if ((std_scales_SRC[i+1]-scale) < (scale-std_scales_SRC[i])) i++;

		*std_scale = std_scales_SRC[i]; 
		return (1); 
		}
	return (1); 
	}
else if (!strncmp(det_id,"MEX_HRSC_",9))
    {
	if (scale < std_scales_HRSC[0])
		{
		*std_scale = std_scales_HRSC[0];
		return (1);
		}

	for (i=NUMBER_OF_STD_SCALES_HRSC_SRC-1;i>0;i--) if (scale > std_scales_HRSC[i]) break;

	if (i == (NUMBER_OF_STD_SCALES_HRSC_SRC-1))
		{
		*std_scale = (double)((int)(scale/std_scales_HRSC[NUMBER_OF_STD_SCALES_HRSC_SRC-1] + 0.5)) 
		             * std_scales_HRSC[NUMBER_OF_STD_SCALES_HRSC_SRC-1];
		return (1); 
		}
	else
		{
		if ((std_scales_HRSC[i+1]-scale) < (scale-std_scales_HRSC[i])) i++;

		*std_scale = std_scales_HRSC[i]; 
		return (1); 
		}
	}
return (-1); 
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrgetstdscale.imake
#define SUBROUTINE   hrgetstdscale

#define MODULE_LIST hrgetstdscale.c

#define USES_ANSI_C

#define HW_SUBLIB

$ Return
$!#############################################################################
$Test_File:
$ create tsthrgetstdscale.c
#include "vicmain_c"
#include <stdio.h>
#include <string.h>

#include "hrgetstdscale.h"

/* Testprogramm for Function hrgetstdscale   */
            
void main44()

{
int			count, status;
double		scale, std_scale;
char       	det_id[50];
float		fval;

zvp("INS_ID", det_id, &count);
zvp("SCALE", &fval, &count);
scale = (double)fval;

status = hrgetstdscale(det_id,scale,&std_scale);
if (status != 1)
   		{
		printf("error in hrgetstdscale: invalid DETECTOR_ID %s!\n", det_id);
		zabend();
		}
else	printf("nearest standard scale to %.4lf returned as %.4lf for %s\n", scale, std_scale, det_id);

printf("Now check for status when giving a non-valid DETECTOR-ID ... \n", scale, std_scale, det_id);

status = hrgetstdscale("something",scale,&std_scale);
if (status != 1)
		printf("error in hrgetstdscale: invalid DETECTOR_ID %s!\n", "something");
else 	printf("nearest standard scale to %.4lf returned as %.4lf for %s\n", scale, std_scale, det_id);

zvmessage("","");
zvmessage("TSThrgetstdscale succesfully completed", "");

}
$!-----------------------------------------------------------------------------
$ create tsthrgetstdscale.imake
#define PROGRAM tsthrgetstdscale

#define MODULE_LIST tsthrgetstdscale.c 

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create tsthrgetstdscale.pdf
Process help=*
 PARM      INS_ID   TYPE=(STRING,120) valid=(MEX_HRSC_S2,\
 											 MEX_HRSC_RED,\
											 MEX_HRSC_P2,\
											 MEX_HRSC_BLUE,\
											 MEX_HRSC_NADIR,\
											 MEX_HRSC_GREEN,\
											 MEX_HRSC_P1,\
											 MEX_HRSC_IR,\
											 MEX_HRSC_P2,\
											 MEX_HRSC_SRC) count=1
 PARM      SCALE   TYPE=REAL count=1
											 
END-PROC
.Title
 Testprogramm for hrgetstdscale
.HELP

WRITTEN BY: Frank Scholten, DLR     3-Apr-2003

.End
$ Return
$!#############################################################################
