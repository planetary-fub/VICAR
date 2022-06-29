$!****************************************************************************
$!
$! Build proc for MIPL module hwcarto
$! VPACK Version 1.9, Friday, March 21, 2003, 20:49:12
$!
$! Execute by entering:		$ @hwcarto
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
$ write sys$output "*** module hwcarto ***"
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
$ write sys$output "Invalid argument given to hwcarto.com file -- ", primary
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
$   if F$SEARCH("hwcarto.imake") .nes. ""
$   then
$      vimake hwcarto
$      purge hwcarto.bld
$   else
$      if F$SEARCH("hwcarto.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwcarto
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwcarto.bld "STD"
$   else
$      @hwcarto.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwcarto.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwcarto.com -
	-s hwcarto.c -
	-i hwcarto.imake -
	-t thwcarto.c thwcarto.imake thwcarto.pdf tsthwcarto.pdf -
	-o hwcarto.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwcarto.c
$ DECK/DOLLARS="$ VOKAGLEVE"
				/*					*/
				/* INCLUDE FILES NEEDED FOR ROUTINES 	*/
				/*					*/
#include "xvmaininc.h"		/* Standard VICAR Include File		*/
#include "ftnbridge.h"		/* FORTRAN bridge Include FIle 		*/
#include <math.h>		/* FORTRAN bridge Include FIle 		*/
#include <stdio.h>		/* Standard C I/O Include File		*/
#include <stdlib.h>		/* C Memory Management Include File	*/
#include "mp_routines.h"	/* Private Map Projection Include File	*/
#include "dlrmapsub.h"		/* DLR Earth Map Projection Include File */

#define GEOCENTRIC	1
#define GEODETIC	2
#define SNYDER_DEFINED  3

/*

VICAR SUBROUTINE		hwcarto

Purpose				Converts line and sample points in a map 
				projected image to one of three types of 
				latitude and longitude points on a target body
				and the inverse.

Function			This routine automatically chooses a target
				body model based on the radii found in the
				map projection data object. 

				Supported map projections are ...

				ALBERS 
				CYLINDRICAL EQUAL-AREA
				EQUIDISTANT CYLINDRICAL
				LAMBERT AZIMUTHAL EQUAL-AREA
				LAMBERT CONFORMAL CONIC
				MERCATOR (includes Transverse Mercator)
				MOLLWEIDE (homalographic)
				ORTHOGRAPHIC
				SINUSOIDAL
				STEREOGRAPHIC
				GAUSS_KRUEGER
				UTM
				BMN28, BMN31, BMN34 (Bundesmeldenetz (Oesterreich), Systeme M28,M31,M34)
 				SLK (Schweizer Landes-Koordinaten)
				ING (Irish National Grid)

Libraries and subroutines
required to run routine:	mp_routines suite

Main programs from which 
subroutines are called:		general application software and higher-level
				subroutines; mpLabelRead.

Calling Sequence:		

from C		status = zhwcarto( MP_DATA,prefs,&x,&y,&lat,&lon,ll_type,mode );
from FORTRAN	call hwcarto( &MP_DATA,prefs,&x,&y,&lat,&lon,&ll_type,&mode ) 

Necessary include files
from calling routine 
or program:			mp.h

Arguments:
	
	Name		Type		In/Out		Description
	
	MP_DATA		MP		Input		Address of
							Map Projection 
							Data Object

	prefs 		Earth_prefs	Input		Variable for a group of 
							Earth_case precalculated values.

	x, y		double		In/Out		line, sample
							in desired map
							projection

	lat, lon	double		Out/In		latitude, longitude
							on target body

	ll_type		integer		Input		Type of latitude and
							longitude as input or
							to be returned:
	
							1 - geocentric,
							2 - geodetic,
							3 - Snyder-defined
							    for triaxial
							    ellipsoid.

	mode		integer		Input		Forward or inverse
							transformation.
				
							0 - forward mode
							1 - inverse mode

							( Forward mode is 
							lat/lon to line/sample )
Return:
	status 		integer		0	Successful call to hwcarto

					-1	Invalid latitude value or
						failure in conversion of
						latitude, longitude values

					-2	Invalid ll_type argument


Background and References:	Map Projection Software Set 
				Software Specification Document,
				JPL, April 28, 1993.

Software Platform:		VICAR 11.0 (VMS/UNIX)

Hardware Platforms:		No particular hardware required; tested on 
				VAX 8650 and Sun Sparcstation.

Programming Language:		ANSI C

Specification by:		Justin McNeill, JPL.

Cognizant Programmer:		Justin McNeill, JPL
				(jfm059@ipl.jpl.nasa.gov)

Date:				October 1993

History:			

				December 1994
				Source file updated to reference the new MP 
				include file mp_routines.h.  Also, the test PDF
				was revised.  ANSI C is now used throughout the
				code.  (FR 85094, 85010 and Mars 94 Software 
				Change Request: CR-WM-1000 PE/4/95)

				December 21, 1993
				Success and failure flags revised to
				mpSUCCESS and mpFAILURE to be consistent
				with mp.h include file. (FR 76817) (JFM059)

*/
/*************************************************************************

FORTRAN Callable Version

*************************************************************************/


int FTN_NAME(hwcarto)( int ptr, Earth_prefs prefs, double *x, double *y, double *lat, 
	double *lon, int *ll_type, int *mode )
{
int	status;
MP	mp_obj;

mp_obj = (MP) ptr;
status = zhwcarto( mp_obj, prefs, x, y, lat, lon, *ll_type, *mode );
return status;
}

/*************************************************************************

C Callable Version

*************************************************************************/
int zhwcarto( MP mp, Earth_prefs prefs,
        double *line, double *sample, double *latitude, 
	double *longitude, int ll_type, int mode
 )
{
static int model_set;

int 	status;

/*

Initialize values

*/
status = mpSUCCESS;

/*

Check inputs.

*/
CHECKif( latitude == NULL || longitude == NULL || 
	 line == NULL || sample == NULL || mp == NULL );
CHECKif( mode != 0 && mode != 1 );

switch (prefs.earth_case)
    {
    case 1: /* UTM or GAUSS-KRUEGER or BMN28 or BMN31 or BMN34 or ING */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
	{
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	status = dlr_earth_map_LL2LS_TransverseMercator (latitude, longitude, line, sample, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	}
    else			/* LINE/SAMP -> LAT/LON */
	{
	status = dlr_earth_map_LS2LL_TransverseMercator (line, sample, latitude, longitude, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	}
    break;
	
    case 2: /* SLK */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
	{
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	status = dlr_earth_map_LL2LS_SLK (latitude, longitude, line, sample, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	}
    else			/* LINE/SAMP -> LAT/LON */
	{
	status = dlr_earth_map_LS2LL_SLK (line, sample, latitude, longitude, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	}
    break;
	
    case 3: /* Soldner */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
	{
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	status = dlr_earth_map_LL2LS_SOLDNER (latitude, longitude, line, sample, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	}
    else			/* LINE/SAMP -> LAT/LON */
	{
	status = dlr_earth_map_LS2LL_SOLDNER (line, sample, latitude, longitude, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	}
    break;
	
    case 4: /* RD_Niederlande */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
	{
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	status = dlr_earth_map_LL2LS_RD_Niederlande (latitude, longitude, line, sample, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */	}
    else			/* LINE/SAMP -> LAT/LON */
	{
	status = dlr_earth_map_LS2LL_RD_Niederlande (line, sample, latitude, longitude, prefs);
	if (status==1) status = mpSUCCESS; /* to have a common success value */
	if (*longitude>180.0) *longitude-=360.0;
	else if (*longitude<-180.0) *longitude+=360.0;
	}
    break;
 
    case 50: /* EQUIDISTANT */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
		{
		if (*longitude>360.0) *longitude-=360.0;
		else if (*longitude<0.0) *longitude+=360.0;
	
		if (ll_type == 1) /* input is centric lat */
			{
			if (fabs(*latitude)!=90.0) /* make it planetographic */
		 		*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[0]*prefs.val[0]/(prefs.val[20])));
			}
		status = dlr_earth_map_LL2LS_EQUIDISTANT (latitude, longitude, line, sample, prefs);
		if (status==1) status = mpSUCCESS; /* to have a common success value */	
		if (ll_type == 1) /* input was centric */
			{
			if (fabs(*latitude)!=90.0) /* make it planetocentric again */
		 		*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[20]/(prefs.val[0]*prefs.val[0])));
			}
		}
    else			/* LINE/SAMP -> LAT/LON */
		{
		status = dlr_earth_map_LS2LL_EQUIDISTANT (line, sample, latitude, longitude, prefs);
		if (status==1) 
			{
			status = mpSUCCESS; /* to have a common success value */
			if (*longitude>360.0) *longitude-=360.0;
			else if (*longitude<0.0) *longitude+=360.0;

			if (fabs(*latitude) > 90.0)
				{
				status = mpFAILURE;
				}
			else
				{
				if (ll_type == 1) /* requested output is centric lat */
					{
					if (fabs(*latitude)!=90.0) /* make it planetocentric */
		 			*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[20]/(prefs.val[0]*prefs.val[0])));
					}
				}
			}
		else status = mpFAILURE; /* to have a common success value */
		}
    break;
	
    case 51: /* SINUSOIDAL */
    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
		{
		if (*longitude>360.0) *longitude-=360.0;
		else if (*longitude<0.0) *longitude+=360.0;
	
		if (ll_type == 1) /* input is centric lat */
			{
			if (fabs(*latitude)!=90.0) /* make it planetographic */
		 		*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[0]*prefs.val[0]/(prefs.val[20])));
			}
		status = dlr_earth_map_LL2LS_SINUSOIDAL (latitude, longitude, line, sample, prefs);
		if (status==1) status = mpSUCCESS; /* to have a common success value */	
		if (ll_type == 1) /* input was centric */
			{
			if (fabs(*latitude)!=90.0) /* make it planetocentric again */
		 		*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[20]/(prefs.val[0]*prefs.val[0])));
			}
		}
    else			/* LINE/SAMP -> LAT/LON */
		{
		status = dlr_earth_map_LS2LL_SINUSOIDAL (line, sample, latitude, longitude, prefs);
		if (status==1) 
			{
			status = mpSUCCESS; /* to have a common success value */
			if (*longitude>360.0) *longitude-=360.0;
			else if (*longitude<0.0) *longitude+=360.0;

			if (fabs(*latitude) > 90.0)
				{
				status = mpFAILURE;
				}
			else
				{
				if (ll_type == 1) /* requested output is centric lat */
					{
					if (fabs(*latitude)!=90.0) /* make it planetocentric */
		 			*latitude = PI2DEG * (atan (tan (*latitude*DEG2PI)*prefs.val[20]/(prefs.val[0]*prefs.val[0])));
					}
				}
			}
		else status = mpFAILURE; /* to have a common success value */
		}
    break;

    case -999: /* mp-routines */
    if( ll_type < GEOCENTRIC || ll_type > SNYDER_DEFINED ) return -2;

    if( mode == 0 )		/* LAT/LON -> LINE/SAMP */
	status = mpll2xy( mp,line,sample,*latitude,*longitude,ll_type );
    else			/* LINE/SAMP -> LAT/LON */
	status = mpxy2ll( mp,*line,*sample,latitude,longitude,ll_type );
    break;
	}
 
return status;
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwcarto.imake
/* Imake file for MIPS subroutines HWCARTO */

#define SUBROUTINE  	hwcarto

#define MODULE_LIST  	hwcarto.c 


#define USES_ANSI_C

#define HW_SUBLIB

#define LIB_P2SUB	/* Include to reference include MP.H */

/************************

LOCAL LIBRARY for development

#define LIB_LOCAL
#define LOCAL_LIBRARY hwsublib.olb

************************/
$ Return
$!#############################################################################
$Test_File:
$ create thwcarto.c
#include <stdio.h>
#include "vicmain_c"
#include <math.h>
#include "mp_routines.h"
#include "dlrspice.h"
#include "dlrmapsub.h"

#define MAX_LATS_LONS 	20

/**********************************************************************
 
Test Program THWCARTO

Program calls hwgetpar which calls mpInit to allocate memory 
for a map projection data object and then sets values in the
data object based on values passed by the application programs
parameter list. Then zhwcarto is called.

Author:			Justin McNeill
Cognizant Engineer:	Justin McNeill
Date Written:		October 1993

Revision history:	October 1994	JFM

			HWCARTO test program updated to be
			consistent with revised HWGETPAR
			interface. (Mars 94 Software Change 
			Request: CR-WM-1000 PE/4/94)

*/
void main44()
{
int 	i,j,k;
int	count;
int	status;
int	mode;
int	indices[2],lengthes[2];
int	number_keywords;
int	types[mpNUMBER_OF_KEYWORDS],classes[mpNUMBER_OF_KEYWORDS];
int	ll_type;
int	lat_count,lon_count;
char 	lat_lon_type[20];

double	double_value;
double	lines[MAX_LATS_LONS];
double	samples[MAX_LATS_LONS];
float	latitudes[MAX_LATS_LONS];
float	longitudes[MAX_LATS_LONS];
double	latitude;
double	longitude;

char	keys[mpNUMBER_OF_KEYWORDS][mpMAX_KEYWD_LENGTH+1];
char	string[300];
char	string_value[200];

MP mp_obj;
Earth_prefs	prefs;

mp_obj = NULL;

zvmessage("***************************************************"," ");
zvmessage("\n\tTest of HWCARTO Routine\n"," ");
zvmessage("***************************************************\n"," ");

/*

Load planetary constants kernel

*/

status = hwgetpar( &mp_obj, 0);
if ( status < 0 )
	{
	zvmessage(" ",0);
	zvmessage("*** Error in hwgetpar call"," ");
	zvmessage("*** Test failed."," ");
	zabend();
	}

status = dlr_earth_map_get_prefs (mp_obj, &prefs);


/*

Print output banner for map transformation

*/

zvmessage(" "," ");
zvmessage("***************************************************"," ");
zvmessage("\n\tTransformation results:"," ");
zvmessage(" "," ");

/*

Determine input latitude and longitude type specified as input.

*/

status = zvp("LL_TYPE",lat_lon_type,&count);
ABENDif( status < mpSUCCESS );

if ( strcmp(lat_lon_type,"PLANETOCENTRIC") == 0 )
	{
	ll_type = 1;
	zvmessage("\n\tPlanetocentric lat/lon pairs\n"," ");
	}
if (( strcmp(lat_lon_type,"PLANETOGRAPHIC") == 0 )||(strcmp(lat_lon_type,"PLANETODETIC") == 0 ))
	{
	ll_type = 2;
	zvmessage("\n\tPlanetodetic resp. Planetographic lat/lon pairs\n"," ");
	}
if ( strcmp(lat_lon_type,"SNYDER_DEFINED") == 0 )
	{
	ll_type = 3;
	zvmessage("\n\tSnyder-defined lat/lon pairs\n"," ");
	}
/*

Get latitude and longitude array from parameter values.

*/

status = zvp("LATITUDES",latitudes,&lat_count);
ABENDif( status < mpSUCCESS );

status = zvp("LONGITUDES",longitudes,&lon_count);
ABENDif( status < mpSUCCESS );

if ( lat_count < lon_count )
	count = lat_count;
else
	count = lon_count;

/*

FORWARD AND INVERSE TRANSFORMATION

*/

for( i=0; i<count; i++ )
	{
	latitude = (double) latitudes[i];
	longitude = (double) longitudes[i];

	zvmessage("\n******************************************\n"," ");
	zvmessage("\n\twhen"," ");
	sprintf(string,"\n\t(LAT,LON) = (%5.3f,%6.3f)\n",
		latitude,longitude);
	zvmessage(string," ");
	
	mode = 0;

	status = zhwcarto( mp_obj, prefs,
			&lines[i],&samples[i],
			&latitude,&longitude,
			ll_type,mode );

	zvmessage("\n\t(LAT,LON) -> (X,Y)"," ");
	sprintf(string,"\n\t(%5.3f,%6.3f) -> (%7.3f,%7.3f)",
		latitude,longitude,samples[i],lines[i]);
	zvmessage(string," ");

	zvmessage("\n\tForward transform completed.\n"," ");

	mode = 1;

	status = zhwcarto( mp_obj, prefs,
			&lines[i],&samples[i],
			&latitude,&longitude,
			ll_type,mode );

	zvmessage("\n\t(X,Y) -> (LAT,LON)"," ");
	sprintf(string,"\n\t(%7.3f, %7.3f) -> (%5.3f,%6.3f)",
		samples[i],lines[i],latitude,longitude);

	zvmessage(string," ");
	zvmessage("\n\tInverse transform completed."," ");
	}

zvmessage(" "," ");
zvmessage("***************************************************"," ");
zvmessage("\n\tEnd test of HWCARTO Routine\n"," ");
zvmessage("***************************************************"," ");
zvmessage(" "," ");

mpFree( mp_obj );
}
$!-----------------------------------------------------------------------------
$ create thwcarto.imake
#define  PROGRAM   thwcarto

#define MODULE_LIST thwcarto.c

#define MAIN_LANG_C
#define R2LIB 

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB
#define LIB_CSPICE
#define LIB_HWSUB
#define LIB_FORTRAN

/***********************

LOCAL LIBRARY for development

#define LIB_LOCAL

***********************/
$!-----------------------------------------------------------------------------
$ create thwcarto.pdf
process help=*

	parm inp	type=(string,32) count=1	default=inp.img
	parm out	type=(string,32) count=1	default=out.img
	parm LL_TYPE	type=(string,32) count=0:1	default=PLANETOGRAPHIC
	parm LATITUDES	type=(real)      count=0:20	default=--
	parm LONGITUDES	type=(real)      count=0:20	default=--
	parm A_AXIS	type=(real)      count=0:1	default=--
	parm B_AXIS	type=(real) 	 count=0:1	default=--
	parm C_AXIS	type=(real) 	 count=0:1	default=--
	parm TARGET	type=(string,32) count=1	default=BESSEL
	parm BOD_LONG	type=(real) 	 count=0:1	default=--
	parm MP_TYPE	type=(string,40) count=0:1	default=SINUSOIDAL +
		valid=(	ALBERS_ONE_PARALLEL,				+
			ALBERS_TWO_PARALLELS,				+
			CYLINDRICAL_EQUAL_AREA,				+
			EQUIDISTANT,					+
			LAMBERT_AZIMUTHAL,				+
			LAMBERT_ONE_PARALLEL,				+
			LAMBERT_TWO_PARALLELS,				+
			MERCATOR,					+
			MOLLWEIDE,					+
			ORTHOGRAPHIC,					+
			SINUSOIDAL,					+
			STEREOGRAPHIC,					+
			GAUSS_KRUEGER,				+
			SOLDNER,				+
			UTM,				+
			BMN,				+
			ING,				+
			SLK,				+
			POINT_PERSPECTIVE,				+
			CORRECTION ) 	


	! Map projection parameter

	PARM MP_RES	type=real	count=0:1	default=--
	parm MP_SCALE 	type=real	count=0:1	default=--
	parm POS_DIR	type=(string,5)	count=0:1	default=--
	parm CEN_LAT	type=real	count=0:1	default=--
	parm CEN_LONG	type=real	count=0:1	default=--
	parm SPHER_AZ	type=real	count=0:1	default=--
	parm L_PR_OFF	type=real	count=0:1	default=--
	parm S_PR_OFF	type=real	count=0:1	default=--
	parm CART_AZ	type=real	count=0:1	default=--
	parm F_ST_PAR	type=real	count=0:1	default=--
	parm S_ST_PAR	type=real	count=0:1	default=--

	! parameter for the perspective projection

	parm FOC_LEN	type=real	count=0:1	default=--
	parm FOC_SCAL	type=real	count=0:1	default=--
	parm NORTH_AN	type=real	count=0:1	default=--
	parm INTERC_L	type=real	count=0:1	default=--
	parm INTERC_S	type=real	count=0:1	default=--
	parm PL_CEN_L	type=real	count=0:1	default=--
	parm PL_CEN_S	type=real	count=0:1	default=--
	parm SUB_LAT	type=real	count=0:1	default=--
	parm SUB_LONG	type=real	count=0:1	default=--
	parm SPC_DIST	type=real	count=0:1	default=--

end-proc

.title
VICAR program THWCARTO

.help
PURPOSE:

Test procedure for hwcarto.
.LEVEL1

.VARI INP
Input image

.VARI OUT
Output image

.VARI LL_TYPE
Type of latitude and longitude as input or to be returned.
Valid types are 'PLANETOCENTRIC', 'PLANETOGRAPHIC', 
'PLANETODETIC' (=='PLANETOGRAPHIC'), and 'SNYDER-DEFINED'.

.VARI LATITUDES
Array of planetocentric, planetodetic or Snyder-defined latitudes on
a target body.

.VARI LONGITUDES
Array of planetOcentric, planetodetic or Snyder-defined longitudes on
a target body. NOTE THAT LONGITUDES ARE PLANETODETIC, PLANETOGRAPHIC,
PLANETOCENTRIC OR SNYDER-DEFINED ONLY WITH THE TRIAXIAL ELLIPSOID MODEL.


.VARI A_AXIS
Semimajor axis of target body.

.VARI B_AXIS
Semiminor axis of target body.

.VARI C_AXIS
Polar axis of target body.

.VARI TARGET
Target body of object for which map projection points will
be transformed.

.VARI BOD_LONG
The target body's longitude at which the semimajor equatorial axie is
measured.

.VARI MP_TYPE
Map projection type requested.

.VARI TSCFILE
NAIF SPICE spacecraft clock kernel file.

.VARI TPCFILE
NAIF SPICE planetary constants kernel file.

.VARI TLSFILE
NAIF SPICE leap seconds kernel file.

.VARI MP_RES
Map resolution.

.VARI MP_SCALE
Map scale.

.VARI POS_DIR
Positive longitude direction.

.VARI CEN_LAT
Center latitude

.VARI CEN_LONG
Center longitude

.VARI SPHER_AZ
Spherical azimuth

.VARI CART_AZ
Cartesian azimuth

.VARI L_PR_OFF
Line projection offset

.VARI S_PR_OFF
Sample projection offset

.VARI F_ST_PAR
First standard parallel

.VARI S_ST_PAR
Second standard parallel

.VARI FOC_LEN
Camera focal length

.VARI FOC_SCAL
Focal plane scale in pixels per millimeter

.VARI NORTH_AN
North angle

.VARI INTERC_L
Image line which intersects the optical axis in
the camera focal plane after distortion correction.

.VARI INTERC_S
Image sample which intersects the optical axis in
the camera focal plane after distortion correction.
Sample increases to the right in an image.

.VARI PL_CEN_L
Image line coincident with the center of the planet.

.VARI PL_CEN_S
Image sample coincident with the center of the planet.

.VARI SUB_LAT
Planetocentric latitude of the intersection of a vector
drawn from the planet center to the spacecraft with the
surface of the planet.

.VARI SUB_LONG
West longitude of the intersection of a vector drawn
from the planet center to the spacecraft with the
surface of the planet.

.VARI SPC_DIST
Distance in kilometers between the planet center and the
spacecraft at the time the image was obtained.

.END
$!-----------------------------------------------------------------------------
$ create tsthwcarto.pdf
procedure
refgbl $echo
body
let _onfail="continue"
let $echo="no"

write "		TEST PROCEDURE FOR HWCARTO"

gen inp.img

thwcarto +
	LATITUDES=(45.0,45.0)  		+
	LONGITUDES=(90.0,45.0)  	+
	LL_TYPE="PLANETOCENTRIC"	+
	TARGET="MARS" 		+
	MP_TYPE="SINUSOIDAL"	+
	A_AXIS=6380.0		+
	B_AXIS=6380.0		+
	C_AXIS=6380.0		+
	MP_SCALE=25.0		+
	MP_RES=1.0		+
	POS_DIR="WEST"		+
	SPHER_AZ=0.0		+
	CART_AZ=0.0		+
	CEN_LONG=90.0		+
	CEN_LAT=0.0		+
	L_PR_OFF=0.0		+
	S_PR_OFF=0.0		+
	F_ST_PAR=0.0		+
	S_ST_PAR=0.0	

thwcarto +
	LATITUDES=(45.0,45.0)  		+
	LONGITUDES=(270.0,315.0)  	+
	LL_TYPE="PLANETOCENTRIC"	+
	TARGET="MARS" 		+
	MP_TYPE="SINUSOIDAL"	+
	A_AXIS=6380.0		+
	B_AXIS=6380.0		+
	C_AXIS=6380.0		+
	MP_SCALE=25.0		+
	MP_RES=1.0		+
	POS_DIR="WEST"		+
	SPHER_AZ=0.0		+
	CART_AZ=0.0		+
	CEN_LONG=270.0		+
	CEN_LAT=0.0		+
	L_PR_OFF=0.0	+
	S_PR_OFF=0.0	+
	F_ST_PAR=0.0		+
	S_ST_PAR=0.0	

write " "
write "Numerical Example for SINUSOIDAL (spherical)"
write "forward equations, taken from the USGS"
write "Professional Paper 1395, p. 365."
write " "

thwcarto +
	LATITUDES=(-50.0)  		+
	LONGITUDES=(-75.0)  		+
	LL_TYPE="PLANETOCENTRIC"	+
	TARGET="MARS" 		+
	MP_TYPE="SINUSOIDAL"	+
	A_AXIS=1.0		+
	B_AXIS=1.0		+
	C_AXIS=1.0		+
	MP_SCALE=1.0		+
	MP_RES=99.9		+
	POS_DIR="WEST"		+
	SPHER_AZ=0.0		+
	CART_AZ=0.0		+
	CEN_LONG=-90.0		+
	CEN_LAT=0.0		+
	L_PR_OFF=0.0		+
	S_PR_OFF=0.0		+
	F_ST_PAR=0.0		+
	S_ST_PAR=0.0	

end-proc
$ Return
$!#############################################################################
$Other_File:
$ create hwcarto.hlp
1 VICAR SUBROUTINE hwcarto

Purpose				

The function hwcarto projects points from planet surface
latitude and longitude to line and sample of a specified
map projection.

2 OPERATION

This function uses one of three target body models - sphere,
oblate spheroid, triaxial ellipsoid - to perform the necessary
map transformations. Spherical and auxiliary conformal and
authalic latitude formulae are based on formulae from the USGS
Bulletin 1395. Auxiliary conformal latitude and longitude formulae
for the triaxial ellipsoid are coded from formulae in John Snyder's
paper "Conformal Mapping of the Triaxial Ellipsoid" from the
journal Survey Review of July 1985, volume 28.

Libraries and subroutines required to run this
routine: mp_routines mpll2xy and mpxy2ll.

CALLING SEQUENCE

from C:		status = zhwcarto( MP mp, Earth_prefs prefs, double *line, double *sample,
				double *latitude, double *longitude,
				int ll_type, int *mode );
from FORTRAN:	call hwcarto( mp, prefs, line, sample, latitude, longitude,
				ll_type, mode, status )

Necessary include files
from calling routine 
or program:			mp.h

ARGUMENTS

mp 		(MP type as defined in include file mp.h)

Variable for the address of the map projection data object
as returned by mpInit.

prefs 		(Earth_prefs type as defined in include file dlrmapsub.h)

Variable for a group of Earth_case precalculated (by dlr_earth_map_get_prefs) values.

line		(double)

y position of the map projected point in an image.

sample		(double)

x position of the map projected point in an image.

latitude	(double)

Latitude value of point on a target body, 
the form (planetocentric/planetodetic) is defined by ll_type

longitude	(double)

Longitude value of point on a target body,
the form (planetocentric/planetodetic) is defined by ll_type

ll_type 	(integer)

Form in which latitude/longitude is represented:
planetocentric (ll_type=1), planetodetic (ll_type=2),
Snyder-defined (ll_type=3).

mode		(integer)

Direction of map transformation:

	0	latitude/longitude to line/sample
	1	line/sample to latitude/longitude

RETURN

status 		(integer)

This is an indicator of the success or failure of
retrieving various values for the VICAR pdf file
and initializing the map projection data object.

0 	successful call to hwcarto and
-1 	failure in reading of VICAR pdf parameter 
	values or error in setting of values in 
	map projection data object.

3 ENVIRONMENT and LANGUAGE

Software Platform:		Vicar 11.0 (VMS/UNIX)
Hardware Platforms:		No particular hardware required; 
				tested on VAX 8650 and Sun Sparc.
Programming Language:		ANSI C

3 HISTORY

Author:				Justin McNeill, JPL
Cognizant Engineer:		Justin McNeill (jfm059@ipl.jpl.nasa.gov)
Written:			October 1993
Revision history:		

December 1994		Source file updated to reference the new MP 
			include file mp_routines.h.  Also, the test PDF
			was revised.  ANSI C is now used throughout the
			code.  (FR 85094, 85010 and Mars 94 Software Change 
			Request: CR-WM-1000 PE/4/95)

December 21, 1993	Success and failure flags revised to mpSUCCESS and
			mpFAILURE to be consistent with mp.h include file.
			(FR 76817) (JFM059)

October 8, 1996		Correction of the parameter descriptions in the help 
			file (FR D00023) by M.Waehlisch

Background and References:	

1. Map Projection Software Set Software Specification Document,
	JPL, April 28, 1993;
2. "Conformal Mapping of the Triaxial Ellipsoid," Survey Review,
	vol. 28, July 1985.
$ Return
$!#############################################################################
