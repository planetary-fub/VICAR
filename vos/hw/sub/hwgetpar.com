$!****************************************************************************
$!
$! Build proc for MIPL module hwgetpar
$! VPACK Version 1.9, Friday, August 27, 2004, 12:11:21
$!
$! Execute by entering:		$ @hwgetpar
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
$ write sys$output "*** module hwgetpar ***"
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
$ write sys$output "Invalid argument given to hwgetpar.com file -- ", primary
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
$   if F$SEARCH("hwgetpar.imake") .nes. ""
$   then
$      vimake hwgetpar
$      purge hwgetpar.bld
$   else
$      if F$SEARCH("hwgetpar.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwgetpar
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwgetpar.bld "STD"
$   else
$      @hwgetpar.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwgetpar.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwgetpar.com -
	-s hwgetpar.h hwgetpar.c -
	-i hwgetpar.imake -
	-t thwgetpar.c thwgetpar.imake thwgetpar.pdf tsthwgetpar.pdf -
	   thwgetpar2.c thwgetpar2.imake thwgetpar2.pdf tsthwgetpar.csh -
	-o hwgetpar.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwgetpar.h
$ DECK/DOLLARS="$ VOKAGLEVE"
/*

Include file for program HWGETPAR

Written by:	Justin McNeill
Date:		July 1994

*/

/*

changed all TARGET_BODY occurances to TARGET_NAME (Scholten 7/00)

*/
#define	pdfTARGET_NAME				"TARGET"
#define pdfA_AXIS_RADIUS			"A_AXIS"
#define pdfB_AXIS_RADIUS			"B_AXIS"
#define pdfC_AXIS_RADIUS			"C_AXIS"
#define pdfBODY_LONG_AXIS 			"BOD_LONG"
#define pdfMAP_PROJECTION_TYPE 			"MP_TYPE"

#define pdfMAP_RESOLUTION			"MP_RES"
#define pdfMAP_SCALE				"MP_SCALE"
#define pdfPOSITIVE_LONGITUDE_DIRECTION		"POS_DIR"
#define pdfCENTER_LATITUDE			"CEN_LAT"
#define pdfCENTER_LONGITUDE			"CEN_LONG"
#define pdfSPHERICAL_AZIMUTH			"SPHER_AZ"
#define pdfLINE_PROJECTION_OFFSET		"L_PR_OFF"
#define pdfSAMPLE_PROJECTION_OFFSET		"S_PR_OFF"
#define pdfCARTESIAN_AZIMUTH			"CART_AZ"
#define pdfFIRST_STANDARD_PARALLEL		"F_ST_PAR"
#define pdfSECOND_STANDARD_PARALLEL		"S_ST_PAR"

#define pdfFOCAL_LENGTH				"FOC_LEN"
#define pdfFOCAL_PLANE_SCALE			"FOC_SCAL"
#define pdfNORTH_ANGLE				"NORTH_AN"
#define pdfOPT_AXIS_INTERCEPT_LINE		"INTERC_L"
#define pdfOPT_AXIS_INTERCEPT_SAMPLE		"INTERC_S"
#define pdfPLANET_CENTER_LINE			"PL_CEN_L"
#define pdfPLANET_CENTER_SAMPLE			"PL_CEN_S"
#define pdfSUB_SPACECRAFT_LATITUDE		"SUB_LAT"
#define pdfSUB_SPACECRAFT_LONGITUDE		"SUB_LONG"
#define pdfSPACECRAFT_DISTANCE			"SPC_DIST"

#define NUMBER_MAIN_MENU_KEYS 			6
#define NUMBER_SUB_MENU_KEYS 			11
#define NUMBER_PERSPECTIVE_KEYS 		10

/*

HWGETPAR error status flags

*/

#define PROJECTION_TYPE_NOT_SET			-1
#define UNABLE_TO_READ_PCK_FILE			-2
#define PDF_PARAMETER_NOT_FOUND			-3
#define UNKNOWN_PROJECTION_TYPE			-4
#define COULDNT_CONVERT_TARG_ID			-5
#define OTHER_ERROR				-6
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create hwgetpar.c
$ DECK/DOLLARS="$ VOKAGLEVE"

				/*					*/
				/* INCLUDE FILES NEEDED FOR ROUTINES 	*/
				/*					*/
#include "xvmaininc.h"		/* Standard VICAR Include File		*/
#include "ftnbridge.h"		/* FORTRAN bridge Include FIle 		*/
#include <math.h>		/* FORTRAN bridge Include FIle 		*/
#include <stdio.h>		/* Standard C I/O Include File		*/
#include <ctype.h>		
#include <stdlib.h>		/* C Memory Management Include File	*/
#include "mp_routines.h"	/* Map Projection Include File		*/
#include "hwgetpar.h"		/* Definition of PDF parameter names 	*/
#include "SpiceUsr.h"           /* Prototypes for C-SPICE */
#include "dlrspice.h"
#include "dlrmapsub.h"

#define PARAMETER_NOT_FOUND -86	/* VICAR Run Time Library error code    */
				/* for a PDF parameter value not found  */

				/* Structure defining the relationship  */
				/* between MP PDS compatible keywords   */
				/* and PDF file parameter names.	*/

static 	char *pds_main_menu[] = {	mpTARGET_NAME,
					mpA_AXIS_RADIUS,
					mpB_AXIS_RADIUS,
					mpC_AXIS_RADIUS,
					mpBODY_LONG_AXIS,
					mpMAP_PROJECTION_TYPE };

static 	char *pdf_main_menu[] = {	pdfTARGET_NAME,
					pdfA_AXIS_RADIUS,
					pdfB_AXIS_RADIUS,
					pdfC_AXIS_RADIUS,
					pdfBODY_LONG_AXIS,
					pdfMAP_PROJECTION_TYPE };

static 	char *pds_sub_menu[] = { 	mpMAP_RESOLUTION,
					mpMAP_SCALE,
					mpPOSITIVE_LONGITUDE_DIRECTION,
					mpCENTER_LATITUDE,
					mpCENTER_LONGITUDE,	
					mpSPHERICAL_AZIMUTH,
					mpLINE_PROJECTION_OFFSET,
					mpSAMPLE_PROJECTION_OFFSET,
					mpCARTESIAN_AZIMUTH,
					mpFIRST_STANDARD_PARALLEL,
					mpSECOND_STANDARD_PARALLEL };
	
static 	char *pdf_sub_menu[] = { 	pdfMAP_RESOLUTION,
					pdfMAP_SCALE,
					pdfPOSITIVE_LONGITUDE_DIRECTION,
					pdfCENTER_LATITUDE,
					pdfCENTER_LONGITUDE,	
					pdfSPHERICAL_AZIMUTH,
					pdfLINE_PROJECTION_OFFSET,
					pdfSAMPLE_PROJECTION_OFFSET,
					pdfCARTESIAN_AZIMUTH,
					pdfFIRST_STANDARD_PARALLEL,
					pdfSECOND_STANDARD_PARALLEL };

static 	char *pds_perspective[] = { 	mpFOCAL_LENGTH,
					mpFOCAL_PLANE_SCALE,
					mpNORTH_ANGLE,
					mpOPT_AXIS_INTERCEPT_LINE,
					mpOPT_AXIS_INTERCEPT_SAMPLE,
					mpPLANET_CENTER_LINE,
					mpPLANET_CENTER_SAMPLE,	
					mpSUB_SPACECRAFT_LATITUDE,
					mpSUB_SPACECRAFT_LONGITUDE,
					mpSPACECRAFT_DISTANCE };

static 	char *pdf_perspective[] = { 	pdfFOCAL_LENGTH,
					pdfFOCAL_PLANE_SCALE,
					pdfNORTH_ANGLE,
					pdfOPT_AXIS_INTERCEPT_LINE,
					pdfOPT_AXIS_INTERCEPT_SAMPLE,
					pdfPLANET_CENTER_LINE,
					pdfPLANET_CENTER_SAMPLE,	
					pdfSUB_SPACECRAFT_LATITUDE,
					pdfSUB_SPACECRAFT_LONGITUDE,
					pdfSPACECRAFT_DISTANCE };

char valid_projections[mpNUMBER_OF_PROJECTIONS][mpMAX_KEYWD_LENGTH] = {

	mpALBERS, 			/* Alber's Equal-Area Conic 	*/
	mpALBERS_ONE_PARALLEL, 
	mpALBERS_TWO_PARALLELS,		

	mpCYLINDRICAL_EQUAL_AREA,	/* Cylindrical Equal-Area	*/
	mpNORMAL_CYLINDRICAL, 

	mpEQUIDISTANT, 			/* Equidistant Cylindrical	*/
	mpCYLINDRICAL, 
	mpRECTANGULAR,
	mpSIMPLE_CYLINDRICAL, 
	mpOBLIQUE_CYLINDRICAL,
	mpOBLIQUE_SIMPLE_CYLINDRICAL,

	mpLAMBERT_AZIMUTHAL,		/* Lambert Azimuthal Equal-Area */

	mpLAMBERT, 			/* Lambert Conformal Conic	*/
	mpLAMBERT_CONFORMAL,
	mpLAMBERT_ONE_PARALLEL,
	mpLAMBERT_TWO_PARALLELS,

	mpMERCATOR, 			/* Mercator			*/
	mpTRANSVERSE_MERCATOR,

	mpMOLLWEIDE,			/* Molleweide (Homalographic)	*/
	mpHOMALOGRAPHIC,		

	mpORTHOGRAPHIC,			/* Orthographic			*/
	mpOBLIQUE_ORTHOGRAPHIC, 
	mpPOLAR_ORTHOGRAPHIC,

	mpSINUSOIDAL, 			/* Sinusoidal			*/
	mpOBLIQUE_SINUSOIDAL,

	mpSTEREOGRAPHIC, 		/* Stereographic		*/
	mpOBLIQUE_STEREOGRAPHIC, 
	mpPOLAR_STEREOGRAPHIC,

	mpPOINT_PERSPECTIVE
};

/*

VICAR SUBROUTINE		hwgetpar

Purpose				Routine to extract map projection values defined
				by VICAR/TAE procedure definition file (.PDF)
				and initialize a map projection data object
				using mp_init for subsequent use in performing
				point map transformations using mpll2xy and/or
				mpxy2ll, part of the mp_routine suite of map
				projection software.


Libraries and subroutines
required to run routine:	mp_routines suite

Main programs from which 
subroutines are called:		general application software and higher-level
				subroutines: HWORTHO8, HWORTHO16, HWGEOM8,
				HWGEOM16, HWDTM, and others.

Calling Sequence:		

from C  	status = hwgetpar( MP_DATA, target_id);

Necessary include files
from calling routine 
or program:			mp.h

Arguments:
	
Name			Type		In/Out		Description
	
MP_DATA			MP		Output		Address of
							Map Projection 
							Data Object
target_id               int             Input           Spice target Id

Return:
	
status 		integer		0	Successful call to hwgetpar

				-1	Successful completion, but
					no map projection type was set.
	
				-2	Unable to read planet constants
					kernel data

				-3 	Error, PDF parameter was not found.
			
				-4	Error, unknown map projection type.

				-5      Error, COULDNT_CONVERT_TARG_ID
				-6	Error, general

Background and References:	HWGETPAR specification by Marita Waehlisch.

Software Platform:		VICAR 11.0 (VMS/UNIX)

Hardware Platforms:		No particular hardware required; tested on 
				VAX, Alpha, SGI, Sun OS, and Sun Solaris.

Programming Language:		ANSI C

Specification by:		Justin McNeill, JPL.

Cognizant Programmer:		Justin McNeill, JPL
				(jfm059@ipl.jpl.nasa.gov)

Date:				October 1993

History:			
				December 1994
				Reference made to new MP include file,
				mp_routines.h.  File label I/O processing
				removed.  Status flag set to zero (0) when
				BODYxxx_LONG_AXIS is not found in a PCK file.
				Input image requirement removed from test PDF.
				(FRs 85094, 85666) (JFM059)

				July 1994
				Interface simplified, include file hwgetpar.h
				and internal structure added to contain the 
				mappings of PDF file parameter names to MP 
				map projection keyword names. 
				(Mars 94 Change Request) (JFM059)
			
				December 21, 1993
				Success and failure flags revised to
				mpSUCCESS and mpFAILURE to be consistent
				with mp.h include file. (FR76817) (JFM059)	

*/
/*************************************************************************

FORTRAN Callable Version

void FTN_NAME(xhwgetpar)(int *ptr, int *target_id, int *status)
FORSTR_DEF
{
FORSTR_BLOCK
int	status, target_id;

MP	mp_obj;

mp_obj = (MP) ptr;
*status = hwgetpar( mp_obj, target_id );
}
*************************************************************************/

/*************************************************************************

C Callable Version

*************************************************************************/
int hwgetpar( MP *mp, int target_id )
{
int	i,j,k;
int	count;
int	map_projection_set;
int	return_status;
int 	status, dummy, new_target;

SpiceInt body_id;
SpiceInt temp_body_id;
SpiceBoolean found;

int	len, num, type[mpNUMBER_OF_KEYWORDS], class[mpNUMBER_OF_KEYWORDS];

char 	keywords[mpNUMBER_OF_KEYWORDS][mpMAX_KEYWD_LENGTH+1];
char	projection_type[60];
char 	string[100];
char	target_body[40], target_body_old[40];
char	sval[10], c_temp[2];

float 	rval;
double	dval;

return_status = 0;

/*

Initialize memory for MP data object if input is NULL address.

*/

if( *mp == NULL )
	{
	status = mpInit( mp );
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR ERROR",0);
		zvmessage("***",0);
		zvmessage("*** mpInit failed.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}
	}
	
/*

Retrieve target body name and set in MP data object

*/

if (target_id<=0)
	{
	status = zvp( pdfTARGET_NAME,target_body,&count );
	if (count == 0)
		{
		dummy = mpGetValues( 	*mp,
					mpTARGET_NAME,
					target_body,
					0 );
		if (dummy == mpKEYWORD_NOT_SET)
			{
			zvmessage("***",0);
			zvmessage("*** HWGETPAR ERROR",0);
			zvmessage("***",0);
			zvmessage("*** Required parameter missing.",0);
			zvmessage("*** Processing terminated.",0);
			zabend();
			}
		}
	else
		{
		for (i=0;i<strlen(target_body);i++)
    			{
    			strncpy (c_temp,target_body+i,1);
    			j=(int)(c_temp[0]);
    			c_temp[1]=(char)(toupper(j));
    			strncpy (c_temp,c_temp+1,1);
    			strncpy (target_body+i,c_temp,1);
    			}
		}
	}
else
	{
	bodc2n_c ( (SpiceInt)target_id, (SpiceInt)41, (SpiceChar*)target_body, &found );
        if (!found)
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR ERROR",0);
		zvmessage("***",0);
		zvmessage("*** Could not convert target_id",0);
		zvmessage("***",0);
		return  COULDNT_CONVERT_TARG_ID;
		}
	}

status = mpGetValues( *mp,mpTARGET_NAME,target_body_old,0 );
if (strcmp(target_body,target_body_old)!=0)
	{
	new_target = 1;
	if ((target_id<=0)&&(count == 0)) strcpy (target_body,target_body_old);
	}
else    new_target = 0;

status = mpSetValues( *mp,mpTARGET_NAME,target_body,0 );
if( status < mpSUCCESS )
	{
	zvmessage("***",0);
	zvmessage("*** HWGETPAR ERROR",0);
	zvmessage("***",0);
	zvmessage("*** mpSetValues failed."," ");
	zvmessage("*** No target body value set.",0);
	zvmessage("***",0);
	}
else
	{
	status = process_radii_body_long_axis( *mp, target_body, new_target );
	if( status < 0 )
		return_status = status;
	}
	

/*

Determine map projection type

*/

status = zvp( pdfMAP_PROJECTION_TYPE,projection_type,&count );
if( count==0 || status==PARAMETER_NOT_FOUND ) 
    {
    dummy = mpGetValues( *mp,mpMAP_PROJECTION_TYPE,projection_type,0 );
    if (dummy == mpKEYWORD_NOT_SET)
    	return (PROJECTION_TYPE_NOT_SET);
    }

map_projection_set = FALSE;

/* Earth-Projections */
if (!strncmp(projection_type,"UTM",3))
	{strcpy(projection_type,"UTM");map_projection_set = TRUE;}
if (!strncmp(projection_type,"ING",3))
	{strcpy(projection_type,"ING");map_projection_set = TRUE;}
if (!strncmp(projection_type,"BMN28",5))
	{strcpy(projection_type,"BMN28");map_projection_set = TRUE;}
if (!strncmp(projection_type,"BMN31",5))
	{strcpy(projection_type,"BMN31");map_projection_set = TRUE;}
if (!strncmp(projection_type,"BMN34",5))
	{strcpy(projection_type,"BMN34");map_projection_set = TRUE;}
if (!strncmp(projection_type,"SLK",3))
	{strcpy(projection_type,"SLK");map_projection_set = TRUE;}
if (!strncmp(projection_type,"GAUSS_KRUEGER",13))
	{strcpy(projection_type,"GAUSS_KRUEGER");map_projection_set = TRUE;}
if (!strncmp(projection_type,"SOLDNER",7))
	{strcpy(projection_type,"SOLDNER");map_projection_set = TRUE;}
if (!strncmp(projection_type,"RD",2))
	{strcpy(projection_type,"RD");map_projection_set = TRUE;}

if (map_projection_set) /* Earth-Projection */
	{ 
	status = mpSetValues(   *mp, mpMAP_PROJECTION_TYPE, projection_type, 0 );
	if( status < mpSUCCESS )
	    {
	    zvmessage("***",0);
	    zvmessage("*** HWGETPAR ERROR",0);
	    zvmessage("***",0);
	    zvmessage("*** mpSetValues of Earth-mpMAP_PROJECTION_TYPE failed."," ");
	    zvmessage("*** No map projection type set.",0);
	    zvmessage("***",0);
	    return (UNKNOWN_PROJECTION_TYPE);	
	    }
	}
/* Earth-Projections */
    else
/* mpProjections */
	{


/* changed by Roatsch/Waehlisch, 15-jan-1996 to make VMS shell TAE happy */
	if (!strncmp(projection_type,"ALBERS_ONE_PAR",14))
	    strcpy(projection_type,"ALBERS_ONE_PARALLEL");

	if (!strncmp(projection_type,"ALBERS_TWO_PAR",14))
	    strcpy(projection_type,"ALBERS_TWO_PARALLELS");

	if (!strncmp(projection_type,"LAMBERT_ONE_PAR",15))
	    strcpy(projection_type,"LAMBERT_ONE_PARALLEL");

	if (!strncmp(projection_type,"LAMBERT_TWO_PAR",15))
	    strcpy(projection_type,"LAMBERT_TWO_PARALLELS");

	if (!strncmp(projection_type,"LAMBERT_AZIMUTH",15))
	    strcpy(projection_type,"LAMBERT_AZIMUTHAL");

	if (!strncmp(projection_type,"CYLINDRICAL_E_A",15))
	    strcpy(projection_type,"CYLINDRICAL_EQUAL_AREA");

	if (!strncmp(projection_type,"PERSPECTIVE",11))
	    strcpy(projection_type,"POINT_PERSPECTIVE");


	for( i=0;i<mpNUMBER_OF_PROJECTIONS;i++ )
	    if( strcmp(projection_type,valid_projections[i])==0 ) 
		{
		status = mpSetValues(   *mp,
					mpMAP_PROJECTION_TYPE,
					projection_type,
					0 );
		if( status < mpSUCCESS )
			{
			zvmessage("***",0);
			zvmessage("*** HWGETPAR WARNING",0);
			zvmessage("***",0);
			zvmessage("*** mpSetValues failed."," ");
			zvmessage("*** No map projection type set.",0);
			zvmessage("***",0);
			}
		else
			map_projection_set = TRUE;
		}
	if( !map_projection_set ) 
	    return_status = UNKNOWN_PROJECTION_TYPE;
	}

    if( strcmp(projection_type,mpPOINT_PERSPECTIVE)==0 )

	for( i=0;i<NUMBER_PERSPECTIVE_KEYS;i++ )
		{
		status = zvparmd( pdf_perspective[i],&dval,&count,&dummy,0,0);
		
		if (count == 0)
			{
			dummy = mpGetValues( 	*mp,
					pds_perspective[i],
					&dval,
					0 );
			if (dummy == mpKEYWORD_NOT_SET)
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
			}
		else
			{
			if( status==PARAMETER_NOT_FOUND ||
		    		status<VICARrtlSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter value missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
		
			status = mpSetValues( *mp,pds_perspective[i],dval,0 );
			if( status < mpSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR WARNING",0);
				zvmessage("***",0);
				zvmessage("*** mpSetValues failed."," ");
				zvmessage("***",0);
				}
			}

		}
    else
	{
	for( i=0;i<(NUMBER_SUB_MENU_KEYS-2);i++ )
		{
		if ( i == 2 )
			status = zvp(   pdf_sub_menu[i],
					sval,
					&count );
		else    status = zvparmd(pdf_sub_menu[i],
					&dval,
					&count,
					&dummy, 0, 0);
	
		if( status==PARAMETER_NOT_FOUND ||
		    status<VICARrtlSUCCESS )
			{
			zvmessage("***",0);
			zvmessage("*** HWGETPAR ERROR",0);
			zvmessage("***",0);
			zvmessage("*** Required parameter value missing.",0);
			zvmessage("*** Processing terminated.",0);
			zabend();
			}

		if( count>0 )
			if ( i != 2 )
				{
				status = mpSetValues( *mp,
						pds_sub_menu[i],
						dval,
						0 );
				if( status < mpSUCCESS )
					{
					zvmessage("***",0);
					zvmessage("*** HWGETPAR WARNING",0);
					zvmessage("***",0);
					zvmessage("*** mpSetValues failed."," ");
					zvmessage("***",0);
					}
				}
			else
				{
				status = mpSetValues( *mp,
						pds_sub_menu[i],
						sval,
						0 );
				if( status < mpSUCCESS )
					{
					zvmessage("***",0);
					zvmessage("*** HWGETPAR WARNING",0);
					zvmessage("***",0);
					zvmessage("*** mpSetValues failed."," ");
					zvmessage("***",0);
					}
				}
		}

	if( strcmp(mpALBERS_ONE_PARALLEL,projection_type)==0 ||
	    strcmp(mpLAMBERT_ONE_PARALLEL,projection_type)==0 )
	    	{
		status = zvparmd( pdfFIRST_STANDARD_PARALLEL,
					&dval,
					&count,
					&dummy, 0, 0);

		if (count == 0)
			{
			dummy = mpGetValues( 	*mp,
					mpFIRST_STANDARD_PARALLEL,
					&dval,
					0 );
			if (dummy == mpKEYWORD_NOT_SET)
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter FIRST_STANDARD_PARALLEL missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
			}
		else
			{
			if( status==PARAMETER_NOT_FOUND ||
		    		status<VICARrtlSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter value missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
			status = mpSetValues( 	*mp,
					mpFIRST_STANDARD_PARALLEL,
					dval,
					0 );
			if( status < mpSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR WARNING",0);
				zvmessage("***",0);
				zvmessage("*** mpSetValues failed."," ");
				zvmessage("***",0);
				}
			}
	
		}

	if( strcmp(mpALBERS_TWO_PARALLELS,projection_type)==0 ||
	    strcmp(mpLAMBERT_TWO_PARALLELS,projection_type)==0 )
		{
		status = zvparmd( pdfFIRST_STANDARD_PARALLEL,
					&dval,
					&count,
					&dummy, 0, 0);
		
		if (count == 0)
			{
			dummy = mpGetValues( 	*mp,
					mpFIRST_STANDARD_PARALLEL,
					&dval,
					0 );
			if (dummy == mpKEYWORD_NOT_SET)
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter FIRST_STANDARD_PARALLEL missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
			}
		else
			{
			if( status==PARAMETER_NOT_FOUND ||
		    		status<VICARrtlSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter value missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}

			status = mpSetValues( 	*mp,
					mpFIRST_STANDARD_PARALLEL,
					dval,
					0 );
			if( status < mpSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR WARNING",0);
				zvmessage("***",0);
				zvmessage("*** mpSetValues failed."," ");
				zvmessage("***",0);
				}
			}


		status = zvparmd( pdfSECOND_STANDARD_PARALLEL,
					&dval,
					&count,
					&dummy, 0, 0);
		
		if (count == 0)
			{
			dummy = mpGetValues( 	*mp,
					mpSECOND_STANDARD_PARALLEL,
					&dval,
					0 );
			if (dummy == mpKEYWORD_NOT_SET)
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter SECOND_STANDARD_PARALLEL missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}
			}
		else
			{
			if( status==PARAMETER_NOT_FOUND ||
		   		 status<VICARrtlSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR ERROR",0);
				zvmessage("***",0);
				zvmessage("*** Required parameter value missing.",0);
				zvmessage("*** Processing terminated.",0);
				zabend();
				}

			status = mpSetValues( 	*mp,
					mpSECOND_STANDARD_PARALLEL,
					dval,
					0 );
			if( status < mpSUCCESS )
				{
				zvmessage("***",0);
				zvmessage("*** HWGETPAR WARNING",0);
				zvmessage("***",0);
				zvmessage("*** mpSetValues failed."," ");
				zvmessage("***",0);
				}
			}
		}
	}
return return_status;
}
/***********************************************************************

check_body_id

Checks for a given NAIF body id if item is found.
If not, replace body_id with barycenter body_id when
body_id is x99. (See NAIF PCK values for target bodies.)

*/
static int check_body_id( SpiceInt *body_id, char *item )
{
int 	status;
int	temp_body_id;
double  double_argument,fractional_part,integer_part;

status = bodfnd_c(*body_id,item);
if ( status == FALSE )
	{
	double_argument = (double)*body_id / 100.0;
	fractional_part = modf(double_argument,&integer_part);
	if ( fractional_part > 0.989 )			/* A planet is always */
		{					/* the 99th satellite */
		temp_body_id = (int)integer_part;	/* of its own baryctr */
							/* Use baryctr to get */
							/* keyword value.     */
		status = bodfnd_c(temp_body_id,item);
		CHECKif( status == FALSE );

		*body_id = temp_body_id;
		}
	else
		return mpFAILURE;
	}

return mpSUCCESS;
}

/****************************************************************************

process_radii_body_long_axis

Routine to set radii and body long axis values in MP data object from 
three possible sources: old settings or p_constants.ker 
		        or (strongest) from user defined pdf-parameters.

*/

int process_radii_body_long_axis( MP mp, char *target_body, int new_target)
{
SpiceInt body_id;
int	 count, dummy;
SpiceInt dimensions;
int	 status;
SpiceBoolean found_spb;
SpiceInt temp_body_id;
int	 unit;

float   rval;
double	dval;
double	radii[3];

int    earth_case;

if (new_target)
	{

	status = dlr_load_earth_constants( target_body, radii);
	if (status==1) earth_case = 1;
	else
    		{
    		earth_case = 0;
/*

Retrieve TARGET_BODY_ID from SPICE routine BODN2C_C

*/

    		bodn2c_c(target_body, &temp_body_id, &found_spb);

    		if (!found_spb) return UNABLE_TO_READ_PCK_FILE;
	
/*

Determine if keyword RADII exists in the P_constants.ker for specified
NAIF body and get measures from the kernel.

*/
    		body_id = temp_body_id;

    		status = check_body_id(&temp_body_id,"RADII");
    		if ( status != mpSUCCESS ) return UNABLE_TO_READ_PCK_FILE;

    		dimensions = 3;
    		bodvar_c(temp_body_id,"RADII",&dimensions,radii);
    		} /* end of no earth_case */
/*

Set body axes measures in data object.

*/

	status = mpSetValues(mp,mpA_AXIS_RADIUS,radii[0],0);
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}

	status = mpSetValues(mp,mpB_AXIS_RADIUS,radii[1],0);
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}

	status = mpSetValues(mp,mpC_AXIS_RADIUS,radii[2],0);
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}

	}

/*

Override these values of A-, B-, C-axis, and body long axis if
PDF parameters are set.

*/

status = zvparmd( pdfA_AXIS_RADIUS,	&dval,
					&count,
					&dummy, 0, 0);

if( status < VICARrtlSUCCESS )
    return PDF_PARAMETER_NOT_FOUND;
else
    if( count==1 )
	{
	mpSetValues( mp,mpA_AXIS_RADIUS,dval,0 );
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}
	}

status = zvparmd( pdfB_AXIS_RADIUS,	&dval,
					&count,
					&dummy, 0, 0);
if( status < VICARrtlSUCCESS )
    return PDF_PARAMETER_NOT_FOUND;
else
    if( count==1 )
	{
	mpSetValues( mp,mpB_AXIS_RADIUS,dval,0 );
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}
	}

status = zvparmd( pdfC_AXIS_RADIUS,	&dval,
					&count,
					&dummy, 0, 0);
if( status < VICARrtlSUCCESS )
    return PDF_PARAMETER_NOT_FOUND;
else
    if( count==1 )
	{
	mpSetValues( mp,mpC_AXIS_RADIUS,dval,0 );
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No axis radius value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}
	}

if (earth_case)
	    {
/*
LONG_AXIS = 0.0
*/
            dval = 0.0;
            }
            else
            {
/*

Determine if keyword LONG_AXIS exists in the P_constants.ker for specified
NAIF body and get values from the kernel.

*/

temp_body_id = body_id;
status = check_body_id(&temp_body_id,"LONG_AXIS");
if ( status == 0 )
	{
	dimensions = 1;
	bodvar_c(temp_body_id,"LONG_AXIS",&dimensions,&dval);
	}
else
	dval = 0.0;


             } /* end of no earth_case */
/*
Set body long axis measures in data object.

*/

status = mpSetValues(mp,mpBODY_LONG_AXIS,dval,0);
if( status < mpSUCCESS )
	{
	zvmessage("***",0);
	zvmessage("*** HWGETPAR WARNING",0);
	zvmessage("***",0);
	zvmessage("*** mpSetValues failed."," ");
	zvmessage("*** No body long axis value set.",0);	
	zvmessage("***",0);
	return OTHER_ERROR;
	}

status = zvparmd( pdfBODY_LONG_AXIS,	&dval,
					&count,
					&dummy, 0, 0);
if( status < VICARrtlSUCCESS )
    return PDF_PARAMETER_NOT_FOUND;
else
   if( count != 0 )
	{
	status = mpSetValues( mp,mpBODY_LONG_AXIS,dval,0 );
	if( status < mpSUCCESS )
		{
		zvmessage("***",0);	
		zvmessage("*** HWGETPAR WARNING",0);
		zvmessage("***",0);
		zvmessage("*** mpSetValues failed."," ");
		zvmessage("*** No body long axis value set.",0);
		zvmessage("***",0);
		return OTHER_ERROR;
		}
	}

return mpSUCCESS;
}
 
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwgetpar.imake
/* Imake file for MIPS subroutines HWGETPAR */

#define SUBROUTINE  	hwgetpar

#define MODULE_LIST  	hwgetpar.c 

#define INCLUDE_LIST  	hwgetpar.h

#define USES_ANSI_C

#define HW_SUBLIB

#define LIB_P1SUB	/* Included to include file MP.H */
#define LIB_CSPICE

$ Return
$!#############################################################################
$Test_File:
$ create thwgetpar.c
#include <stdio.h>
#include "vicmain_c"
#include <math.h>
#include "mp_routines.h"
#include "hwldker.h"

/**********************************************************************
 
Test Program THWGETPAR

Program calls hwgetpar which calls mpInit to allocate memory 
for a map projection data object and then sets values in the
data object based on values passed by the application programs
parameter list.

Author:			Justin McNeill
Cognizant Engineer:	Justin McNeill
Date Written:		October 1993
Revision history:	

			July 1994

			Test simplified to call hwldker, hwgetpar
			and mpGetKeywords.
			(Mars 94 Change Request) (JFM059)
*/

void main44()
{
int	count;
int 	i,j,k;
int	status;

int	number_keywords;
int	types[mpNUMBER_OF_KEYWORDS],classes[mpNUMBER_OF_KEYWORDS];

char	keys[mpNUMBER_OF_KEYWORDS][mpMAX_KEYWD_LENGTH+1];
char	string[300];
char	string_value[200];

double	double_value;

hwkernel_1 tpc;

MP mp_obj;

mp_obj = NULL;

zvmessage("***************************************************"," ");
zvmessage("\n\tTest of HWGETPAR Routine\n"," ");
zvmessage("***************************************************\n"," ");

/*

Load planetary constants kernel

*/

hwldker(1, "tpc",&tpc);

/*

Call hwgetpar without having first allocated memory for MP data object

*/

status = hwgetpar( &mp_obj );

zvmessage("***",0);
sprintf(string,"*** Status flag returned by HWGETPAR is %d",status);
zvmessage(string,0);
zvmessage("***\n",0);

/*

Display keywords retrieved from MP data object

*/

if( status >= -2 )
	{
	status = mpGetKeywords( mp_obj,keys,&number_keywords,types,classes );
	if ( status < 0 )
		{
		zvmessage("***",0);
		zvmessage("*** Error in mpGetKeywords call"," ");
		zvmessage("*** Test failed."," ");
		zvmessage("***",0);
		zabend();
		}

	for ( i=0; i<number_keywords; i++ )

		switch ( types[i] )	{

		case mpCHAR:

		status = mpGetValues( mp_obj,keys[i],string_value,"" );
		ABENDif( status < mpSUCCESS );
		
		sprintf(string,"KEYWORD %s equals %s\n",keys[i],string_value);
		zvmessage(string," ");
		
		break;

		case mpDBLE:

		status = mpGetValues( mp_obj,keys[i],&double_value,"" );
		ABENDif( status < mpSUCCESS );
		
		sprintf(string,"KEYWORD %s equals %4.3e\n",keys[i],double_value);
		zvmessage(string," ");

		break;

		default:

		zvmessage("PDS KEY of unacceptable data type"," ");
		break;	}
	}

/*

Free the memory of the data object

*/

mpFree( mp_obj );

zvmessage(" "," ");
zvmessage("***************************************************"," ");
zvmessage("\n\tEnd test of HWGETPAR Routine\n"," ");
zvmessage("***************************************************"," ");
zvmessage(" "," ");

}
$!-----------------------------------------------------------------------------
$ create thwgetpar.imake
#define PROGRAM   thwgetpar

#define MODULE_LIST thwgetpar.c

#define MAIN_LANG_C
#define R2LIB 

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB
#define LIB_HWSUB
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create thwgetpar.pdf
process help=*

	parm LL_TYPE	type=(string,32) count=0:1	default=PLANETOGRAPHIC
	parm LATITUDES	type=(real)      count=0:20	default=--
	parm LONGITUDES	type=(real)      count=0:20	default=--
	parm A_AXIS	type=(real)      count=0:1	default=--
	parm B_AXIS	type=(real) 	 count=0:1	default=--
	parm C_AXIS	type=(real) 	 count=0:1	default=--
	parm TARGET	type=(string,32) count=1	default=MARS
	parm BOD_LONG	type=(real) 	 count=0:1	default=--
	parm MP_TYPE	type=(string,40) count=0:1	default=SINUSOIDAL +
		valid=(	ALBERS_ONE_PAR,				+
			ALBERS_TWO_PAR,				+
			CYLINDRICAL_E_A,				+
			EQUIDISTANT,					+
			LAMBERT_AZIMUTH,				+
			LAMBERT_ONE_PAR,				+
			LAMBERT_TWO_PAR,					+
			MERCATOR,					+
			MOLLWEIDE,					+
			ORTHOGRAPHIC,					+
			SINUSOIDAL,					+
			STEREOGRAPHIC,					+
			PERSPECTIVE,				+
			CORRECTION ) 	

	! SPICE parameters (dummy parameters) :

	PARM    TSCFILE  TYPE=(STRING,80) COUNT=(0:6)     DEFAULT=HWSPICE_TSC
	PARM 	TPCFILE  TYPE=(STRING,80) COUNT=(0:1)     DEFAULT=HWSPICE_TPC
	PARM    TLSFILE  TYPE=(STRING,80) COUNT=(0:1)     DEFAULT=HWSPICE_TLS

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
VICAR program THWGETPAR

.help
PURPOSE:

Test procedure for hwgetpar.
.LEVEL1

.VARI LL_TYPE
Type of latitude and longitude as input or to be returned.
Valid types are 'PLANETOCENTRIC', 'PLANETODETIC', 
'PLANETOGRAPHIC' (=='PLANETODETIC') and 'SNYDER-DEFINED'.

.VARI LATITUDES
Array of planetocentric, planetodetic or Snyder-defined latitudes on
a target body.

.VARI LONGITUDES
Array of planetOcentric, planetodetic or Snyder-defined longitudes on
a target body. NOTE THAT LONGITUDES ARE PLANETODETIC, PLANETOCENTRIC,
PLANETOGRAPHIC OR SNYDER-DEFINED ONLY WITH THE TRIAXIAL ELLIPSOID MODEL.


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
$ create tsthwgetpar.pdf
procedure
body


write " "
write "*****************************************************************"
write "*****************************************************************"
write " "
write "		TEST PROCEDURE FOR HWGETPAR"
write " "
write "		July 1994"
write " "
write "		Justin McNeill, JPL"
write " "
write "*****************************************************************"
write "*****************************************************************"
write " "
write " "
write " 	*** Special Note to MIPL Testers ***"
write " "
write " "
write " On the VMS systems . . ."
write " "
write " The command DCL @DEFLOGICALS_HWSPICE must be included in this"
write " test PDF on the VMS system.  This defines the location of SPICE"
write " kernels used for Mars 94 testing.  This COM file can be found in"
write " the directory DEV:[JFM059.MARS94.SPICE_KERNELS]."

!dcl @deflogicals_hwspice

write " "
write " On the UNIX systems . . ."
write " "
write " Be sure the following environment variables are set as shown below:"
write "   HWSPICE_TI=/home/jfm/mars94/spice_kernels/ik/m94cam01.ti"
write "   HWSPICE_TPC=/home/jfm/mars94/spice_kernels/pck/naf0000c.tpc"
write "   HWSPICE_TSC=/home/jfm/mars94/spice_kernels/sclk/m94sim.tsc"
write "   HWSPICE_TLS=/home/jfm/mars94/spice_kernels/leap/leapseconds.ker"
write " "
write " "
write "*****************************************************************"
write " "

thwgetpar MP_TYPE=ALBERS_ONE_PAR CEN_LONG=150 L_PR_OFF=100 +
		S_PR_OFF=150 CART_AZ=20	F_ST_PAR=45

thwgetpar  MP_TYPE=ALBERS_TWO_PAR CEN_LONG=10 L_PR_OFF=400 +
		S_PR_OFF=20 CART_AZ=150	F_ST_PAR=15 S_ST_PAR=65 


write " "
write "*****************************************************************"
write " "
write "	Run test on some warning and error conditions of HWGETPAR"
write " "
write " "
write " The first call of thwgetpar results in a status flag of -2"
write " because MOON is not found in kernel data file."
write " "
write " The second call of thwgetpar results in a status flag of -6"
write " and an error message because the CORRECTION mode is attempted"
write " when no existing MP address is passed to the hwgetpar routine."
write " "
write "*****************************************************************"
write " "

thwgetpar  MP_TYPE=PERSPECTIVE TARGET=MOON FOC_LEN=1.2 SUB_LAT=35.0

thwgetpar  MP_TYPE=CORRECTION  MP_RES=4.0 CART_AZ=180.0

end-proc
$!-----------------------------------------------------------------------------
$ create thwgetpar2.c
#include <stdio.h>
#include "vicmain_c"
#include <math.h>
#include "mp_routines.h"
#include "hwldker.h"

/**********************************************************************
 
Test Program THWGETPAR

Program calls hwgetpar which calls mpInit to allocate memory 
for a map projection data object and then sets values in the
data object based on values passed by the application programs
parameter list.

Author:			Justin McNeill
Cognizant Engineer:	Justin McNeill
Date Written:		October 1993
Revision history:	

			July 1994

			Test simplified to call hwldker, hwgetpar
			and mpGetKeywords.
			(Mars 94 Change Request) (JFM059)
*/

void main44()
{
int	count;
int 	i,j,k;
int	status;

int	number_keywords;
int	types[mpNUMBER_OF_KEYWORDS],classes[mpNUMBER_OF_KEYWORDS];

char	keys[mpNUMBER_OF_KEYWORDS][mpMAX_KEYWD_LENGTH+1];
char	string[300];
char	string_value[200];

double	double_value;

hwkernel_1 tpc;

MP mp_obj;

mp_obj = NULL;

zvmessage("***************************************************"," ");
zvmessage("\n\tTest of HWGETPAR Routine\n"," ");
zvmessage("***************************************************\n"," ");

/*

Load planetary constants kernel

*/

hwldker(1, "tpc",&tpc);

/*

Call hwgetpar having first allocated memory for MP data object
with mpInit

*/

status = mpInit( &mp_obj );

status = hwgetpar( &mp_obj );

zvmessage("***",0);
sprintf(string,"*** Status flag returned by HWGETPAR is %d",status);
zvmessage(string,0);
zvmessage("***\n",0);

/*

Display keywords retrieved from MP data object

*/

if( status >= -2 )
	{
	status = mpGetKeywords( mp_obj,keys,&number_keywords,types,classes );
	if ( status < 0 )
		{
		zvmessage("***",0);
		zvmessage("*** Error in mpGetKeywords call"," ");
		zvmessage("*** Test failed."," ");
		zvmessage("***",0);
		zabend();
		}

	for ( i=0; i<number_keywords; i++ )

		switch ( types[i] )	{

		case mpCHAR:

		status = mpGetValues( mp_obj,keys[i],string_value,"" );
		ABENDif( status < mpSUCCESS );
		
		sprintf(string,"KEYWORD %s equals %s\n",keys[i],string_value);
		zvmessage(string," ");
		
		break;

		case mpDBLE:

		status = mpGetValues( mp_obj,keys[i],&double_value,"" );
		ABENDif( status < mpSUCCESS );
		
		sprintf(string,"KEYWORD %s equals %4.3e\n",keys[i],double_value);
		zvmessage(string," ");

		break;

		default:

		zvmessage("PDS KEY of unacceptable data type"," ");
		break;	}
	}

/*

Free the memory of the data object

*/

mpFree( mp_obj );

zvmessage(" "," ");
zvmessage("***************************************************"," ");
zvmessage("\n\tEnd test of HWGETPAR Routine\n"," ");
zvmessage("***************************************************"," ");
zvmessage(" "," ");

}
$!-----------------------------------------------------------------------------
$ create thwgetpar2.imake
#define PROGRAM   thwgetpar2

#define MODULE_LIST thwgetpar2.c

#define MAIN_LANG_C
#define R2LIB 

#define USES_ANSI_C

#define LIB_CSPICE
#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_P1SUB

$!-----------------------------------------------------------------------------
$ create thwgetpar2.pdf
process help=*

	parm LL_TYPE	type=(string,32) count=0:1	default=PLANETOGRAPHIC
	parm LATITUDES	type=(real)      count=0:20	default=--
	parm LONGITUDES	type=(real)      count=0:20	default=--
	parm A_AXIS	type=(real)      count=0:1	default=--
	parm B_AXIS	type=(real) 	 count=0:1	default=--
	parm C_AXIS	type=(real) 	 count=0:1	default=--
	parm TARGET	type=(string,32) count=1	default=MARS
	parm BOD_LONG	type=(real) 	 count=0:1	default=--
	parm MP_TYPE	type=(string,40) count=0:1	default=SINUSOIDAL +
		valid=(	ALBERS_ONE_PAR,				+
			ALBERS_TWO_PAR,				+
			CYLINDRICAL_E_A,				+
			EQUIDISTANT,					+
			LAMBERT_AZIMUTH,				+
			LAMBERT_ONE_PAR,				+
			LAMBERT_TWO_PAR,				+
			MERCATOR,					+
			MOLLWEIDE,					+
			ORTHOGRAPHIC,					+
			SINUSOIDAL,					+
			STEREOGRAPHIC,					+
			PERSPECTIVE,				+
			CORRECTION ) 	

	! SPICE parameters (dummy parameters) :

	PARM    TSCFILE  TYPE=(STRING,80) COUNT=(0:6)     DEFAULT=HWSPICE_TSC
	PARM 	TPCFILE  TYPE=(STRING,80) COUNT=(0:1)     DEFAULT=HWSPICE_TPC
	PARM    TLSFILE  TYPE=(STRING,80) COUNT=(0:1)     DEFAULT=HWSPICE_TLS

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
VICAR program THWGETPAR

.help
PURPOSE:

Test procedure for hwgetpar.
.LEVEL1

.VARI LL_TYPE
Type of latitude and longitude as input or to be returned.
Valid types are 'PLANETOCENTRIC', 'PLANETODETIC', 
'PLANETODGRAPHIC' (=='PLANETODETIC'), and 'SNYDER-DEFINED'.

.VARI LATITUDES
Array of planetocentric, planetodetic or Snyder-defined latitudes on
a target body.

.VARI LONGITUDES
Array of planetOcentric, planetodetic or Snyder-defined longitudes on
a target body. NOTE THAT LONGITUDES ARE PLANETODETIC, PLANETODGRAPHIC,
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
$ create tsthwgetpar.csh
#!/bin/csh

echo " "
echo "*****************************************************************"
echo "*****************************************************************"
echo " "
echo "		TEST PROCEDURE FOR HWGETPAR"
echo " "
echo "		July 1994"
echo " "
echo "		Justin McNeill, JPL"
echo " "
echo "*****************************************************************"

./thwgetpar MP_TYPE=ALBERS_ONE_PAR CEN_LONG=150 L_PR_OFF=100 \
		S_PR_OFF=150 CART_AZ=20	F_ST_PAR=45

./thwgetpar  MP_TYPE=ALBERS_TWO_PAR CEN_LONG=10 L_PR_OFF=400 \
		S_PR_OFF=20 CART_AZ=150	F_ST_PAR=15 S_ST_PAR=65 


echo " "
echo "*****************************************************************"
echo " "
echo "	Run test on some warning and error conditions of HWGETPAR"
echo " "
echo " "
echo " The first call of ./thwgetpar results in a status flag of -2"
echo " because MOON is not found in kernel data file."
echo " "
echo " The second call of ./thwgetpar results in a status flag of -6"
echo " and an error message because the CORRECTION mode is attempted"
echo " when no existing MP address is passed to the hwgetpar routine."
echo " "
echo "*****************************************************************"
echo " "

./thwgetpar  MP_TYPE=PERSPECTIVE TARGET=MOON FOC_LEN=1.2 SUB_LAT=35.0

./thwgetpar  MP_TYPE=CORRECTION  MP_RES=4.0 CART_AZ=180.0

$ Return
$!#############################################################################
$Other_File:
$ create hwgetpar.hlp
1 VICAR SUBROUTINE		hwgetpar

Purpose				

Routine to extract map projection values defined
by VICAR/TAE procedure definition file (.PDF)
and initialize a map projection (MP) data object
using mpInit for subsequent use in performing
point map transformations using mpll2xy and/or
mpxy2ll, part of the mp_routine suite of map
projection software.

2 OPERATION

Reads in values for a specific map projection
stored in VICAR parmeter values from an
application program .pdf file and initializes
a map projection data object with those values. 

The steps below are followed in hwgetpar software:

1) Checks if there is a NULL (0) passed in as
the address of MP data object.  If so, mpInit()
is called to initialize the MP data object.

2) Reads the name of the target body from the
PDF file and sets this value in the MP data
object.

3) Calls the SPICE routines zbodvar, zbodn2c,
and zbodfnd and reads the radii and body long 
axis values from the planetary constants NAIF 
kernel file (PCK).  Note that if SPICE_TARGET_ID
is available in the image files' M94_ORBIT
property label, then ZBODN2C is not called.

4) Reads the PDF parameters pertaining to
the A_AXIS_RADIUS, B_AXIS_RADIUS, C_AXIS_RADIUS,
and BODY_LONG_AXIS.  If these four PDF 
parameter values are set, then the values in
the MP data object are overwritten.

5) Reads the PDF parameter for the value
MAP_PROJECTION_TYPE and sets this value in
the MP data object.  For a particular 
projection, the respective map projection
keywords are read from the PDF file and
set in the MP data object.  The valid 
map projection types are as follows:
   -- Alber's Equal-Area Conic
   mpALBERS,
   mpALBERS_ONE_PARALLEL,
   mpALBERS_TWO_PARALLELS,

   -- Cylindrical Equal-Area
   mpCYLINDRICAL_EQUAL_AREA,
   mpNORMAL_CYLINDRICAL,

   -- Equidistant Cylindrical
   mpEQUIDISTANT,
   mpCYLINDRICAL,
   mpRECTANGULAR,
   mpSIMPLE_CYLINDRICAL,
   mpOBLIQUE_CYLINDRICAL,
   mpOBLIQUE_SIMPLE_CYLINDRICAL,

   -- Lambert Azimuthal Equal-Area
   mpLAMBERT_AZIMUTHAL,

   mpLAMBERT,
   mpLAMBERT_CONFORMAL,
   mpLAMBERT_ONE_PARALLEL,
   mpLAMBERT_TWO_PARALLELS,

   -- Mercator
   mpMERCATOR,
   mpTRANSVERSE_MERCATOR,

   -- Molleweide (Homalographic)
   mpMOLLWEIDE,
   mpHOMALOGRAPHIC,

   -- Orthographic
   mpORTHOGRAPHIC,
   mpOBLIQUE_ORTHOGRAPHIC,
   mpPOLAR_ORTHOGRAPHIC,

   -- Sinusoidal
   mpSINUSOIDAL,
   mpOBLIQUE_SINUSOIDAL,

   -- Stereographic
   mpSTEREOGRAPHIC,
   mpOBLIQUE_STEREOGRAPHIC,
   mpPOLAR_STEREOGRAPHIC,

   mpPOINT_PERSPECTIVE

6) In the case where the MP data object was
passed to hwgetpar as a non-NULL value
(i.e. the MP data object already exists)
and if the map projection type CORRECTION is
set in the PDF file, the routine checks all 21
map projection parameters from the PDF file
and sets the values in the MP data object.

7) After all processing steps, the MP data object
address is returned to the calling application.

3 DEPENDENCIES

Libraries and subroutines required to run this
routine: VICAR RTL, mp_routines.com from VICAR
subroutines library P2, NAIF SPICELIB library

Main programs from which subroutines are called:
general application software and higher-level
subroutines: HWORTHO8, HWORTHO16, HWGEOM8,
HWGEOM16, HWDTM, and others.

Necessary include files from calling routine
or application program:	mp.h, hwgetpar.h

3 CALLING SEQUENCE

from C  	status = hwgetpar( &MP_DATA, target_id);
from FORTRAN	call xhwgetpar( MP_DATA, target_id )


	     *** IMPORTANT NOTE ***
MP_DATA should be set to NULL (0) if the user wishes
hwgetpar to call mpInit internally; otherwise
it is assumed that the MP data object referenced
by MP_DATA has been initialized prior to the call
of hwgetpar.


INPUT/OUTPUT

	MP_DATA			(MP data type)

	The address of map projection data object.
	If input MP_DATA is set to a value of NULL
	(zero), mpInit is called internal to hwgetpar.
	If input MP_DATA is a non-NULL value,
	it is assumed that mpInit has already been
	called to allocate memory for the MP data
	object.		

	target_id			(int)

	Precalculated Spice_Target_Id. 
        If <=0, hwgetpar calls zvp to get Target_Body
        and converts it to a Spice_Target_Id		

RETURN 		

	status 			(integer)

	This is an indicator of the success or failure
	of hwgetpar processing.

	0	Successful call to hwgetpar

	-1	Successful completion, but
		no map projection type was set.
	
	-2	Unable to read planet constants
		kernel data

	-3 	Error, PDF parameter was not found.
	
	-4	Error, unknown map projection type.

	-5      Error, COULDNT_CONVERT_TARG_ID
	
	-6	Error, general processing failure.


3 ENVIRONMENT and LANGUAGE

Software Platform:		VICAR 11.0 (VMS/UNIX)
Hardware Platforms:		No particular hardware required; tested on 
				DEC VAX and Alpha, SGI, Sparcstations running
				SunOS and Solaris.
Programming Language:		ANSI C


3 HISTORY

Author:				Justin McNeill, JPL
Cognizant Engineer:		Justin McNeill, JPL
Written:			October 1993
Background and References:	HWGETPAR specification by Marita Waehlisch.
Revision history:		

History:			
				Juli 1999
				Use of Earth Projection (UTM etc.) enabled.
				New Target_Body/Target_Id handling (new parameter)
				
				December 1994
				Reference made to new MP include file,
				mp_routines.h.  File label I/O processing
				removed.  Status flag set to zero (0) when
				BODYxxx_LONG_AXIS is not found in a PCK file.
				Input image requirement removed from test PDF.
				(FRs 85094, 85666) (JFM059)
				
				July 1994
				Interface simplified; include file hwgetpar.h
				and internal structure added to contain the 
				mappings of PDF file parameter names to MP 
				map projection keyword names. 
				(Mars 94 Change Request) (JFM059)
			
				December 21, 1993
				Success and failure flags revised to
				mpSUCCESS and mpFAILURE to be consistent
				with mp.h include file. (FR76817) (JFM059)	
$ Return
$!#############################################################################
