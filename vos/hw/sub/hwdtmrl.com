$!****************************************************************************
$!
$! Build proc for MIPL module hwdtmrl
$! VPACK Version 1.9, Thursday, March 23, 2000, 13:57:40
$!
$! Execute by entering:		$ @hwdtmrl
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
$ write sys$output "*** module hwdtmrl ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_Test = ""
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
$ if primary .eqs. "TEST" then Create_Test = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if primary .eqs. "OTHER" then Create_Other = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Test .or. Create_Imake .or -
        Create_Other .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hwdtmrl.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Test then gosub Test_File
$ if Create_Imake then gosub Imake_File
$ if Create_Other then gosub Other_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_Test = "Y"
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
$   if F$SEARCH("hwdtmrl.imake") .nes. ""
$   then
$      vimake hwdtmrl
$      purge hwdtmrl.bld
$   else
$      if F$SEARCH("hwdtmrl.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwdtmrl
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwdtmrl.bld "STD"
$   else
$      @hwdtmrl.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwdtmrl.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwdtmrl.com -
	-s hwdtmrl.c -
	-i hwdtmrl.imake -
	-o hwdtmrl.hlp -
	-t thwdtmrl.c thwdtmrl.imake thwdtmrl.pdf tsthwdtmrl.pdf thwdtmwl.c -
	   thwdtmwl.imake thwdtmwl.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwdtmrl.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*****************************************************************************
This routine is supposed to read information specific from a certain Digital
 Terrain Model from a property label called "DTM". (The DTM is stored like a
 map and has a Map-property label and a DTM-property label, which is necessary
 to compute the elevation from the DN-value.)

The application program has to include the following file:
dtm.h

calling from C : status=hwdtmrl(inp_unit, &dtm_struct);

******************************************************************************/

#include "dtm.h"

int hwdtmrl(int inpunit, dtm *dtm_struct)

{int status;

 
status=zlget(inpunit,"property","DTM_MAXIMUM_DN",&(dtm_struct->dtm_maximum_dn),
"format","int","property","DTM","ERR_ACT","",0);
if (status != 1)
{
/*zvmessage("keyword DTM_MAXIMUM_DN missing",""); */
return(status);
}

status=zlget(inpunit,"property","DTM_MINIMUM_DN",&(dtm_struct->dtm_minimum_dn),
"format","int","property","DTM","ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_MINIMUM_DN missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_MISSING_DN",&(dtm_struct->dtm_missing_dn),
"format","int","property","DTM","ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_MISSING_DN missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_OFFSET",&(dtm_struct->dtm_offset),
"format","real","property","DTM","ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_OFFSET missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_SCALING_FACTOR",
&(dtm_struct->dtm_scaling_factor),"format","real","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_SCALING_FACTOR missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_A_AXIS_RADIUS",
&(dtm_struct->dtm_a_axis_radius),"format","real","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_A_AXIS_RADIUS missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_B_AXIS_RADIUS",
&(dtm_struct->dtm_b_axis_radius),"format","real","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_B_AXIS_RADIUS missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_C_AXIS_RADIUS",
&(dtm_struct->dtm_c_axis_radius),"format","real","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_C_AXIS_RADIUS missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_BODY_LONG_AXIS",
&(dtm_struct->dtm_body_long_axis),"format","real","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_BODY_LONG_AXIS missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_POSITIVE_LONGITUDE_DIRECTION",
&(dtm_struct->dtm_positive_longitude_direction),
"format","string","property","DTM","ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_POSITIVE_LONGITUDE_DIRECTION missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_HEIGHT_DIRECTION",
&(dtm_struct->dtm_height_direction),"format","string","property","DTM",
"ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_HEIGHT_DIRECTION missing","");
return(status);
}

status=zlget(inpunit,"property","DTM_DESC",&(dtm_struct->dtm_desc),
"format","string","property","DTM","ERR_ACT","",0);
if (status != 1)
{
zvmessage("keyword DTM_DESC missing","");
return(status);
}

return(status);
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwdtmrl.imake
#define SUBROUTINE hwdtmrl

#define MODULE_LIST hwdtmrl.c 

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE

$ Return
$!#############################################################################
$Other_File:
$ create hwdtmrl.hlp

NAME OF PROGRAM:	hwdtmrl
	
Purpose:	Reads the DTM-property label
	
	
Function:	

Requirements and Dependencies:

Libraries required to run program:	RTL

Subroutines required to run program:	

Include Files required to run program:	dtm.h

Main Program from which subroutine will be called:	HWORTHO


Calling Sequence:	status=hwdtmrl(inp_unit, &dtm_struct);	


Necessary include files
from calling routine 
or program:		dtm.h

VICAR Parameter:

Name		Type	In/Out	Description
	

inp_unit	char	Input	name of the input image
dtm_struct	dtm	Output	structure containing the DTM keywords


Software Platform:		VICAR (VMS/UNIX)

Hardware Platform:		No particular hardware required;
				tested on SUN_OS, SUN_SOLARIS, VAX, AXP

Programming Language:		C

Date of specification:		July of 1994

Cognizant programmer:		Marita Waehlisch, DLR
				Institute of Planetary Exploration
				DLR
				12484 Berlin (FRG)


History:			July of 1994, M.Waehlisch, original			
$ Return
$!#############################################################################
$Test_File:
$ create thwdtmrl.c

#include "vicmain_c"
#include "dtm.h"

void main44()
{
int count,status,inpunit;
dtm dtm_struct;

zveaction("su","");

status=zvunit(&inpunit,"inp",1,0);
status=zvopen(inpunit,0);
status=hwdtmrl(inpunit, &dtm_struct);

if (status==1)
{
status=zprnt(4,1,&dtm_struct.dtm_maximum_dn,"maximum");
status=zprnt(4,1,&dtm_struct.dtm_minimum_dn,"minimum");
status=zprnt(4,1,&dtm_struct.dtm_missing_dn,"missing");
status=zprnt(7,1,&dtm_struct.dtm_offset,"offset");
status=zprnt(7,1,&dtm_struct.dtm_scaling_factor,"scaling_factor");
status=zprnt(7,1,&dtm_struct.dtm_a_axis_radius,"a_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_b_axis_radius,"b_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_c_axis_radius,"c_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_body_long_axis,"body_long_axis");
zvmessage(dtm_struct.dtm_positive_longitude_direction,"");
zvmessage(dtm_struct.dtm_height_direction,"");
zvmessage(dtm_struct.dtm_desc,"");
}

status=zvclose(inpunit,0);

}
$!-----------------------------------------------------------------------------
$ create thwdtmrl.imake
#define PROGRAM thwdtmrl

#define MODULE_LIST thwdtmrl.c

#define MAIN_LANG_C

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P2SUB
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create thwdtmrl.pdf
Process help=*


parm inp        type=string		count=1

END-PROC
.Title
thwdtmrl
.help
PURPOSE
test the reading of an DTM-label
WRITTEN BY

Marita Waehlisch, DLR  1.7.94

.Level1
.VARI inp
 necessary string
.Level2
.VARI inp
 This neccessary parameter consists the unit number of the Vicar-image.
.END
$!-----------------------------------------------------------------------------
$ create tsthwdtmrl.pdf
procedure

body

gen a.img
thwdtmwl inp=a.img dtm_max=3000 dtm_min=-10 dtm_miss=0 dtm_off=1000 dtm_scal=1
label-list a.img
thwdtmrl a.img

end-proc
$!-----------------------------------------------------------------------------
$ create thwdtmwl.c

#include "vicmain_c"
#include "dtm.h"

void main44()
{
int count,status,inpunit,def;
dtm dtm_struct;

status=zvparm("dtm_max",&dtm_struct.dtm_maximum_dn,&count,&def,1,0);
status=zvparm("dtm_min",&dtm_struct.dtm_minimum_dn,&count,&def,1,0);
status=zvparm("dtm_miss",&dtm_struct.dtm_missing_dn,&count,&def,1,0);
status=zvparm("dtm_off",&dtm_struct.dtm_offset,&count,&def,1,0);
status=zvparm("dtm_scal",&dtm_struct.dtm_scaling_factor,&count,&def,1,0);
status=zvparm("dtm_a_ax",&dtm_struct.dtm_a_axis_radius,&count,&def,1,0);
status=zvparm("dtm_b_ax",&dtm_struct.dtm_b_axis_radius,&count,&def,1,0);
status=zvparm("dtm_c_ax",&dtm_struct.dtm_c_axis_radius,&count,&def,1,0);
status=zvparm("dtm_b_lo",&dtm_struct.dtm_body_long_axis,&count,&def,1,0);
status=zvparm("dtm_pl_d",&dtm_struct.dtm_positive_longitude_direction,&count,
&def,1,0);
status=zvparm("dtm_h_d",&dtm_struct.dtm_height_direction,&count,&def,1,0);
status=zvparm("dtm_desc",&dtm_struct.dtm_desc,&count,&def,1,0);

zveaction("sua","");

status=zvunit(&inpunit,"inp",1,0);

status=zprnt(4,1,&dtm_struct.dtm_maximum_dn,"maximum");
status=zprnt(4,1,&dtm_struct.dtm_minimum_dn,"minimum");
status=zprnt(4,1,&dtm_struct.dtm_missing_dn,"missing");
status=zprnt(7,1,&dtm_struct.dtm_offset,"offset");
status=zprnt(7,1,&dtm_struct.dtm_scaling_factor,"scaling_factor");
status=zprnt(7,1,&dtm_struct.dtm_a_axis_radius,"a_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_b_axis_radius,"b_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_c_axis_radius,"c_axis_radius");
status=zprnt(7,1,&dtm_struct.dtm_body_long_axis,"body_long_axis");
zvmessage(dtm_struct.dtm_positive_longitude_direction,"");
zvmessage(dtm_struct.dtm_height_direction,"");
zvmessage(dtm_struct.dtm_desc,"");


status=zvopen(inpunit,"OP","UPDATE",0);
status=hwdtmwl(inpunit, &dtm_struct);
status=zprnt(4,1,&status,"status von hwdtmwl =");
status=zvclose(inpunit,0);

}
$!-----------------------------------------------------------------------------
$ create thwdtmwl.imake
#define PROGRAM thwdtmwl

#define MODULE_LIST thwdtmwl.c

#define MAIN_LANG_C

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P2SUB
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create thwdtmwl.pdf
Process help=*


parm inp        type=(string,32)	count=1
parm dtm_max	type=int		count=0:1	default=--
parm dtm_min	type=int		count=0:1	default=--
parm dtm_miss	type=int		count=0:1	default=--
parm dtm_off	type=real		count=0:1	default=--
parm dtm_scal	type=real		count=0:1	default=--
parm dtm_a_ax	type=real		count=0:1	default=3394.6
parm dtm_b_ax	type=real		count=0:1	default=3393.3
parm dtm_c_ax	type=real		count=0:1	default=3376.3
parm dtm_b_lo	type=real		count=0:1	default=105.0
parm dtm_pl_d	type=(string,5)		count=0:1	default=WEST +
							valid=(EAST,WEST)
parm dtm_h_d	type=(string,7)		count=0:1	default=RADIAL +
							valid=(RADIAL,NORMAL)
parm dtm_desc	type=(string,250)	count=0:1	+
default="datum=triaxial ellipsoid, elevation= DTM_SCALING_FACTOR * DN + DTM_OFFSET " 
END-PROC
.Title
thwdtmwl
.help
PURPOSE
test the writing of an DTM-label
WRITTEN BY

Marita Waehlisch, DLR  1.7.94

.Level1
.VARI inp
 name of the input image
.VARI dtm_max
 DTM_MAXIMUM_DN
.VARI dtm_min
 DTM_MIMNIMUM_DN
.VARI dtm_miss
 DTM_MISSING_DN
.VARI dtm_off
 DTM_OFFSET
.VARI dtm_scal
 DTM_SCALING_FACTOR
.VARI dtm_a_ax
 DTM_A_AXIS_RADIUS
.VARI dtm_b_ax
 DTM_B_AXIS_RADIUS
.VARI dtm_c_ax
 DTM_C_AXIS_RADIUS
.VARI dtm_b_lo
 DTM_BODY_LONG_AXIS
.VAR dtm_pl_d
 DTM_POSITIVE_LONGITUDE_ +
 DIRECTION
.VAR dtm_h_d
 DTM_HEIGHT_DIRECTION
.VARI dtm_desc
 DTM_DESC

.Level2
.VARI inp
 This neccessary parameter consists the name of the Vicar-image.
.VARI dtm_max
 the maximum DN value in the DTM image file
.VARI dtm_min
 the minimum DN value in the DTM image file
.VARI dtm_miss
 defines the DN value of areas of the DTM where data are missing
.VARI dtm_off
 defines the altitude in meters of the 0 DN value
.VARI dtm_scal
 the numbers of meters between two consecutive DN values in a DTM. To convert
 from DN to elevation, we have:
 elevation= = DTM_SCALING_FACTOR * DN + DTM_OFFSET
.VARI dtm_a_ax
 semimajor equatorial radius of the triaxial ellipsoid, used as a reference
 body for the height
.VARI dtm_b_ax
 semiminor equatorial radius of the triaxial ellipsoid, used as a reference
 body for the height
.VARI dtm_c_ax
 polar radius of the triaxial ellipsoid, used as a reference body for the 
 height
.VARI dtm_b_lo
 The longitude of the semimajor (longest) axis of a triaxial 
 ellipsoid,used as a reference body for the height.  
 Some bodies, like Mars, have the prime meridian 
 defined at a longitude which does not correspond to the 
 equatorial semimajor axis, if the equatorial plane is modeled 
 as an ellipse.
.VAR dtm_pl_d
 Identifies the direction of longitude (e.g. EAST, WEST) for a planet. 
 The IAU definition for direction of positive longitude is adopted.  
 Typically, for planets with prograde rotations, positive longitude 
 direction is to the west. For planets with retrograde rotations, positive
 longitude direction is to the east.
.VAR dtm_h_d
 direction of the height, radial or normal to the reference surface
.VARI dtm_desc
 description of the DTM , including, e.g. accuracy of the elevation information
, and definition of the absolute 0 (reference surface) 
 .END
$ Return
$!#############################################################################
