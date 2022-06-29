$!****************************************************************************
$!
$! Build proc for MIPL module dlrmapsub
$! VPACK Version 1.9, Wednesday, March 08, 2006, 13:06:06
$!
$! Execute by entering:		$ @dlrmapsub
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
$ write sys$output "*** module dlrmapsub ***"
$!
$ Create_Source = ""
$ Create_Repack =""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Imake .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to dlrmapsub.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
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
$   if F$SEARCH("dlrmapsub.imake") .nes. ""
$   then
$      vimake dlrmapsub
$      purge dlrmapsub.bld
$   else
$      if F$SEARCH("dlrmapsub.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrmapsub
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrmapsub.bld "STD"
$   else
$      @dlrmapsub.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrmapsub.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrmapsub.com -mixed -
	-s dlrmapsub.c -
	-i dlrmapsub.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrmapsub.c
$ DECK/DOLLARS="$ VOKAGLEVE"

#include "xvmaininc.h"		/* Standard VICAR Include File		*/
#include <stdio.h>		/* Standard C I/O Include File		*/
#include <string.h>		
#include <ctype.h>		
#include <stdlib.h>		/* C Memory Management Include File	*/
#include <math.h>
#include "dlrmapsub.h"
#include "mp_routines.h"

/* ------------------------------------------------------------ */
/* this file contains the following functions:                   
int dlr_load_earth_constants( char *target, double *radii)
int dlr_mpLabelRead( MP mp_obj, int unit, Earth_prefs *prefs)
int dlr_mpLabelWrite( MP mp_obj, int unit, char *in_string, Earth_prefs prefs)
int dlr_earth_map_get_prefs (MP mp, Earth_prefs *prefs)
int dlr_earth_map_LL2LS_RD_Niederlande (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_RD_Niederlande (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_RD_Niederlande (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_RD_Niederlande (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_RD_Niederlande (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_RD_Niederlande (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LL2LS_TransverseMercator (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_TransverseMercator (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_TransverseMercator (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_TransverseMercator (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_TransverseMercator (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_TransverseMercator (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
double dlr_earth_map_ArcLen (double phi, Earth_prefs prefs)
int dlr_earth_map_LL2LS_SLK (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_SLK (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_SLK (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_SLK (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_SLK (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_SLK (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LL2LS_SOLDNER (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_SOLDNER (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_SOLDNER (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_SOLDNER (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_SOLDNER (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_SOLDNER (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LL2LS_EQUIDISTANT (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_EQUIDISTANT  (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_EQUIDISTANT  (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_EQUIDISTANT  (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_EQUIDISTANT  (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_EQUIDISTANT  (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LL2LS_SINUSOIDAL (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LS2LL_SINUSOIDAL  (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LL2RU_SINUSOIDAL  (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LL_SINUSOIDAL  (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
int dlr_earth_map_LS2RU_SINUSOIDAL  (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
int dlr_earth_map_RU2LS_SINUSOIDAL  (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
int dlr_earth_map_LL2RU (double *ll, double *ru, Earth_prefs prefs)
int dlr_earth_map_RU2LL (double *ru, double *ll, Earth_prefs prefs)
int dlr_earth_map_LS2RU (double *ls, double *ru, Earth_prefs prefs)
int dlr_earth_map_RU2LS (double *ru, double *ls, Earth_prefs prefs)
int dlr_get_datumshift (char *filename, DatumShift *shift)
void dlr_datumshift (double *in_vec, DatumShift shift)
void dlr_datumshift_inv (double *in_vec, DatumShift shift)

 ------------------------------------------------------------ */
/*************************************************************************/
int dlr_load_earth_constants( char *target, double *radii)
{
char   *getenv();
char   *value;
char   c_temp[120], ellipsoid_file[120];
FILE   *fp;
int    n;

n=0;
value=getenv("FLKER");
if (value != NULL) strcpy(ellipsoid_file,value);
else return (-1);

strncat (ellipsoid_file, "/", strlen("/"));
strncat (ellipsoid_file, target, strlen(target));
strncat (ellipsoid_file, ".constants", strlen(".constants"));
if ((fp = fopen (ellipsoid_file,"r")) != (FILE *)NULL)
    {
    while (1)
	{
	if ((char *)NULL == fgets (c_temp, 120, fp)) break;
	if (strncmp(c_temp, "#", 1)==0) continue; 
	sscanf ( c_temp, "%lf\n", &radii[n]);
	radii[n] /= 1000.0;
	n++;
	if (n==3) break;
	}
    if (n!=3) return (-1);
    fclose (fp);
    return (1);
    }
else return (-1);
}
/*-------------------------------------------------------------------------------*/
int dlr_mpLabelRead( MP mp_obj, int unit, Earth_prefs *prefs)
{
int	status;
char c_string2[1][500], c_string[500], equidistant[12]="EQUIDISTANT\0";
double	dou;
/*  
		    status = mpLabelRead(mp_obj, unit);	
*/

/* folling parameters are necessary for all map projections */

			status = zlget (unit, "PROPERTY", "TARGET_BODY", c_string, 
					       "PROPERTY","MAP", "FORMAT", "STRING", 0);
			if( status != 1 ) 
				{
				status = zlget (unit, "PROPERTY", "TARGET_NAME", c_string, 
						       "PROPERTY","MAP", "FORMAT", "STRING", 0);
				if( status != 1 ) return mpFAILURE;
				}
			status = mpSetValues ( mp_obj, mpTARGET_NAME, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "MAP_PROJECTION_TYPE", c_string,
					    "PROPERTY","MAP", "FORMAT", "STRING", 0);
			if( status != 1 ) return mpFAILURE;
/*
			if (strcmp (c_string,"SIMPLE_CYLINDRICAL")==0)
			    strcpy (c_string, "EQUIDISTANT" );
*/
			status = mpSetValues ( mp_obj, mpMAP_PROJECTION_TYPE, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "COORDINATE_SYSTEM_NAME", c_string,
					    "PROPERTY","MAP", "FORMAT", "STRING", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpCOORDINATE_SYSTEM_NAME, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "POSITIVE_LONGITUDE_DIRECTION", c_string,
					    "PROPERTY","MAP", "FORMAT", "STRING", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpPOSITIVE_LONGITUDE_DIRECTION, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "A_AXIS_RADIUS", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpA_AXIS_RADIUS, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "B_AXIS_RADIUS", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpB_AXIS_RADIUS, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "C_AXIS_RADIUS", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpC_AXIS_RADIUS, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "BODY_LONG_AXIS", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) dou = 0.0;
			status = mpSetValues ( mp_obj, mpBODY_LONG_AXIS, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "MAP_SCALE", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpMAP_SCALE, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "LINE_PROJECTION_OFFSET", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "SAMPLE_PROJECTION_OFFSET", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
			status = zlget (unit, "PROPERTY", "CENTER_LONGITUDE", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpSetValues ( mp_obj, mpCENTER_LONGITUDE, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
/* folling parameters may miss for specific map projections */
			
			status = zlget (unit, "PROPERTY", "CENTER_LATITUDE", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status == 1 ) 
				{
				status = mpSetValues ( mp_obj, mpCENTER_LATITUDE, dou, NULL);
				if( status != mpSUCCESS ) return mpFAILURE;
				}
			
			status = zlget (unit, "PROPERTY", "FIRST_STANDARD_PARALLEL", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status == 1 ) 
				{
				status = mpSetValues ( mp_obj, mpFIRST_STANDARD_PARALLEL, dou, NULL);
				if( status != mpSUCCESS ) return mpFAILURE;
				}
			
			status = zlget (unit, "PROPERTY", "SECOND_STANDARD_PARALLEL", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status == 1 ) 
				{
				status = mpSetValues ( mp_obj, mpSECOND_STANDARD_PARALLEL, dou, NULL);
				if( status != mpSUCCESS ) return mpFAILURE;
				}
			
			status = zlget (unit, "PROPERTY", "SPHERICAL_AZIMUTH", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status == 1 ) dou = 0.0; 
			status = mpSetValues ( mp_obj, mpSPHERICAL_AZIMUTH, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;

			
			status = zlget (unit, "PROPERTY", "CARTESIAN_AZIMUTH", &dou,
					    "PROPERTY","MAP", "FORMAT", "DOUB", 0);
			if( status == 1 ) dou = 0.0; 
			status = mpSetValues ( mp_obj, mpCARTESIAN_AZIMUTH, dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			
/* MapDesc: no need to be read, since not used. 
   If to be written, then mpLabelWrite automatically re-adds this description to the label
   
			status = zlget (unit, "PROPERTY", "MAP_PROJECTION_DESC", c_string,
					    "PROPERTY","MAP", 0);
			if( status == 1 ) 
				{
				status = mpSetValues ( mp_obj, mpMAP_PROJECTION_DESC, c_string, NULL);
				if( status != mpSUCCESS ) return mpFAILURE;
				}

*/
/* MapDesc: read just the first line to recon, whether it is mp-style or DLR-style */

	status = zlget (unit, "PROPERTY", "MAP_PROJECTION_DESC", c_string2, "FORMAT", "STRING", "ULEN", 100,
					    "NELEMENT", 1, "PROPERTY","MAP", "ERR_ACT", "", 0);
	if (( status != 1 ) || (strncmp(c_string2[0],"not yet",7)==0))/* earth case and/or new DLR SINU/EQUI style) */
		prefs->earth_case =  999;
	else /* no earth case (i.e. mp sw) */				
		prefs->earth_case = -999;
return (mpSUCCESS);
}

int dlr_mpLabelWrite( MP mp_obj, int unit, char *in_string, Earth_prefs prefs)
{
int	status;
char	c_string[120];
double	dou;

status = mpLabelWrite(mp_obj, unit, in_string);	

	if (status != mpSUCCESS)
/* Earth-Projection */
			{
			status = mpGetValues ( mp_obj, mpTARGET_BODY, c_string, NULL);
			if( status != mpSUCCESS ) status = mpGetValues ( mp_obj, mpTARGET_NAME, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "TARGET_NAME", c_string,
					    "FORMAT", "STRING", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpMAP_PROJECTION_TYPE, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "MAP_PROJECTION_TYPE", c_string,
					    "FORMAT", "STRING", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpCOORDINATE_SYSTEM_NAME, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "COORDINATE_SYSTEM_NAME", c_string,
					    "FORMAT", "STRING", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpPOSITIVE_LONGITUDE_DIRECTION, c_string, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "POSITIVE_LONGITUDE_DIRECTION", c_string,
					    "FORMAT", "STRING", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpA_AXIS_RADIUS, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "A_AXIS_RADIUS", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpB_AXIS_RADIUS, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "B_AXIS_RADIUS", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpC_AXIS_RADIUS, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "C_AXIS_RADIUS", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpBODY_LONG_AXIS, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "BODY_LONG_AXIS", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpMAP_SCALE, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "MAP_SCALE", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpCENTER_LATITUDE, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "CENTER_LATITUDE", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpCENTER_LONGITUDE, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "CENTER_LONGITUDE", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpSPHERICAL_AZIMUTH, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "SPHERICAL_AZIMUTH", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpCARTESIAN_AZIMUTH, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "CARTESIAN_AZIMUTH", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "LINE_PROJECTION_OFFSET", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
			status = mpGetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, &dou, NULL);
			if( status != mpSUCCESS ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "SAMPLE_PROJECTION_OFFSET", &dou,
					    "FORMAT", "DOUB", "PROPERTY","MAP", 0);
/*			if( status != 1 ) return mpFAILURE;
			status = zladd (unit, "PROPERTY", "MAP_PROJECTION_DESC", "not yet described",
					    "FORMAT", "STRING", "PROPERTY","MAP", 0);
			if( status != 1 ) return mpFAILURE;
*/
			}
			
	if( prefs.earth_case > 0) status = zldel (unit, "PROPERTY", "MAP_PROJECTION_DESC", "PROPERTY","MAP", 0);
	
return (mpSUCCESS);
}
/* -------------------------------------------------------------------------------------------*/

int dlr_earth_map_get_prefs (MP mp, Earth_prefs *prefs)
{
    int	nof_used_prefs, i, callfunc, status;
    double	b, e1, d_temp;
    char	c_temp[120],pro[120];
	
    for (i=0;i<MAX_EARTH_PREFS;i++) prefs->val[i]=0.0; 

    callfunc = mpGetValues ( mp, mpMAP_PROJECTION_TYPE, pro, NULL);

	callfunc = 0;
	status = zvp ("USEMP", c_temp, &callfunc);
	if (status != 1) 
	    {
		zvmessage ("PDF-Parameter USEMP not in PDF file !!", "");
		zabend();
		}
	if (prefs->earth_case == -999) /* old mp-labeled input detected by dlr_mpLabelRead */ 
	   ; /* nothing to do */ 
	else if ((callfunc) /* USE_MP is set for generation of output */ && (prefs->earth_case != 999)/* no new dlr-mapped input */ )
	   prefs->earth_case = -999; /* old mp-obj */
	else
		{
    	if (
	    	(strcmp(pro, "UTM")==0)||
	    	(strcmp(pro, "GAUSS_KRUEGER")==0)||
	    	(strncmp(pro, "BMN", 3)==0)|| /* Bundesmeldenetz (Oesterreich) */
	    	(strcmp(pro, "ING")==0) /* Ireland National Grid */
       		) 
       		prefs->earth_case = 1;
   	 	else if (strcmp(pro, "SLK")==0) /* Schweizer Landes-Koordinaten */
   	    	prefs->earth_case = 2;
   	 	else if (strcmp(pro, "SOLDNER")==0) /* Soldner-Berlin */
   	    	prefs->earth_case = 3;
   	 	else if (strcmp(pro, "RD")==0) /* Niederlande */
   	    	prefs->earth_case = 4;
    	else if (strcmp(pro, "EQUIDISTANT")==0) /* EQUIDISTANT */
    	   	prefs->earth_case = 50;
  	  	else if (strcmp(pro, "SINUSOIDAL")==0) /* SINUSOIDAL */
  	     	prefs->earth_case = 51;
  	  	else  
  	     	prefs->earth_case = -999;
	   	}
    if (prefs->earth_case == 1) /* Transverse Mercator (UTM or GAUSS_KRUEGER or BMN or ING) */
	{    
	callfunc = mpGetValues ( mp, mpA_AXIS_RADIUS, &prefs->val[0], NULL); 
	    prefs->val[0] *= 1000.0;
	callfunc = mpGetValues ( mp, mpC_AXIS_RADIUS, &b, NULL); 
	b *= 1000.0;

	    prefs->val[1] = (prefs->val[0] * prefs->val[0] - b * b) /(prefs->val[0] * prefs->val[0]);
	    prefs->val[2] = prefs->val[1] * prefs->val[1];
	    prefs->val[3] = prefs->val[2] * prefs->val[1];
	    prefs->val[4] = (prefs->val[0]*(1.-prefs->val[1]/4.0-3.*prefs->val[2]/64.-5.*prefs->val[3]/256.));
	    prefs->val[5] = (1. - prefs->val[1] / 4. - 3. * prefs->val[2] / 64. - 5. * prefs->val[3] / 256.);
	    prefs->val[6] = (3. * prefs->val[1] / 8. + 3. * prefs->val[2] / 32. + 45. * prefs->val[3] / 1024.);
	    prefs->val[7] = (15. * prefs->val[2] / 256. + 45. * prefs->val[3] / 1024.);
	    prefs->val[8] = (35. * prefs->val[3] / 3072.);
	    prefs->val[9] = (prefs->val[0] * prefs->val[0] - b * b) /(b * b);
	    prefs->val[10] = prefs->val[9] * 8.0;
	    prefs->val[11] = prefs->val[9] * 9.0;
	    prefs->val[12] = prefs->val[9] * 58.0;
	    prefs->val[13] = prefs->val[9] * 252.0;
	    prefs->val[14] = prefs->val[9] * 330.0;
	e1 =(1.-sqrt(1.-prefs->val[1]))/(1.+sqrt(1.-prefs->val[1]));
	    prefs->val[15] =(3.*e1/2.-27.*pow(e1,3)/32.);
	    prefs->val[16] =(21.*e1*e1/16.-55.*pow(e1,4)/32.);
	    prefs->val[17] =(151.*pow(e1,3)/96.);
	    prefs->val[18] =(1097.*pow(e1,4)/512.);

	if (strcmp(pro, "ING")==0)
		{
		callfunc = mpSetValues ( mp, mpCENTER_LATITUDE, 53.5, NULL); /* explicit set of cen_lat */
		printf ("CENTER_LATITUDE  is set to %lf by function dlr_earth_map_get_prefs ...\n",53.5);
	    prefs->val[19] = 53.5*DEG2PI; 

		callfunc = mpSetValues ( mp, mpCENTER_LONGITUDE, -8.0, NULL); /* explicit set of cen_lon */
		printf ("CENTER_LONGITUDE is set to %lf by function dlr_earth_map_get_prefs ...\n",-8.0);
	    prefs->val[21] = -8.0*DEG2PI; 
		}
	else if (strncmp(pro, "BMN", 3)==0)
		{
		callfunc = mpSetValues ( mp, mpCENTER_LATITUDE, 0.0, NULL); /* explicit set of cen_lat */
		printf ("CENTER_LATITUDE  is set to %lf by function dlr_earth_map_get_prefs ...\n", 0.0);
	    prefs->val[19] = 0.0; 

		if      (strcmp(pro, "BMN28")==0) d_temp=10.333333333; /* 28 deg east of Ferro (Ferro = 17 40' west of Greenwich) */
		else if (strcmp(pro, "BMN31")==0) d_temp=13.333333333; /* 31 deg east of Ferro (Ferro = 17 40' west of Greenwich) */
		else if (strcmp(pro, "BMN34")==0) d_temp=16.333333333; /* 34 deg east of Ferro (Ferro = 17 40' west of Greenwich) */
		callfunc = mpSetValues ( mp, mpCENTER_LONGITUDE, d_temp, NULL); /* explicit set of cen_lon */
		printf ("CENTER_LONGITUDE is set to %lf by function dlr_earth_map_get_prefs ...\n",d_temp);
	    prefs->val[21] = d_temp*DEG2PI; 
		}
	else
		{
		callfunc = mpGetValues ( mp, mpCENTER_LATITUDE, &prefs->val[19], NULL);
	    prefs->val[19] *= DEG2PI; 

		callfunc = mpGetValues ( mp, mpCENTER_LONGITUDE, &prefs->val[21], NULL);
		if ((prefs->val[21])>180.0) prefs->val[21] -= 360.0; 
	    prefs->val[21] *= DEG2PI; 
		}

	prefs->val[20] = dlr_earth_map_ArcLen(prefs->val[19],*prefs);


	if ((strcmp(pro, "ING")==0)||(strcmp(pro, "UTM")==0)||(strncmp(pro, "BMN", 3)==0))
		{
		callfunc = mpGetValues ( mp, mpPOSITIVE_LONGITUDE_DIRECTION, c_temp, NULL); 
		if (strcmp(c_temp, "WEST")==0)
	    		{
	    		printf ("POSITIVE_LONGITUDE_DIRECTION == WEST is not allowed for this map projection !!!\n");
	    		return(-1); 
	    		}
		}

	if (strcmp(pro, "UTM")==0)
	    { 
	    prefs->val[22] =  0.9996;
	    prefs->val[23] =  500000.0;
	    prefs->val[24] =  0.0;
	    }
	else if (strcmp(pro, "ING")==0)
	    { 
	    prefs->val[22] =  1.000035;
	    prefs->val[23] =  200000.0;
	    prefs->val[24] =  250000.0;
	    }
	else if (strcmp(pro, "BMN28")==0)
	    { 
	    prefs->val[22] =         1.0;
	    prefs->val[23] =    150000.0;
	    prefs->val[24] =  -5000000.0;
	    }
	else if (strcmp(pro, "BMN31")==0)
	    { 
	    prefs->val[22] =         1.0;
	    prefs->val[23] =    450000.0;
	    prefs->val[24] =  -5000000.0;
	    }
	else if (strcmp(pro, "BMN34")==0)
	    { 
	    prefs->val[22] =         1.0;
	    prefs->val[23] =    750000.0;
	    prefs->val[24] =  -5000000.0;
	    }
	else
	    {
	    prefs->val[22] =  1.0;
	    prefs->val[23] =  500000.0;
	    prefs->val[24] =  0.0;
	    }
		
	callfunc = mpGetValues ( mp, mpLINE_PROJECTION_OFFSET, 
	    &prefs->val[25], NULL);
	callfunc = mpGetValues ( mp, mpSAMPLE_PROJECTION_OFFSET, 
	    &prefs->val[26], NULL);
	callfunc = mpGetValues ( mp, mpMAP_SCALE, &prefs->val[27], NULL);
	    prefs->val[27] = (double)((int)((prefs->val[27])*1000000000.0+0.5))/1000000.0;

	nof_used_prefs = 28;
	}
    else if (prefs->earth_case == 2) /* Schweizer Landes-Koordinaten */
	{    
	/* Formulas do not use axes values, just coefficients for l,s<->l,l */
	    prefs->val[0]  =	 0.0;		/* dummy */

	    /* get samp */
	    prefs->val[1]  =    21.1428534;
	    prefs->val[2]  = 	-1.093961e-4;
	    prefs->val[3]  =	-4.4233e-11;
	    prefs->val[4]  =	-2.66e-12;
	    prefs->val[5]  =	-8.54e-16;
	    prefs->val[6]  =     4.292e-16;
	    prefs->val[7]  =    -3.0e-21;
	    prefs->val[8]  =     2.0e-22;
	    
	    /* get line */
	    prefs->val[9]  =    30.8770746;
	    prefs->val[10] =     3.74541e-5;
	    prefs->val[11] =    -1.93793e-10;
	    prefs->val[12] =     7.503e-7;
	    prefs->val[13] =     1.2043e-10;
	    prefs->val[14] =     4.34e-16;
	    prefs->val[15] =    -3.76e-21;
	    prefs->val[16] =    -7.35e-17;
	    prefs->val[17] =     1.44e-21;
	    
	    /* get lat */
	    prefs->val[18]  =    3.23864878e-2;
	    prefs->val[19] =    -2.713538e-9;
	    prefs->val[20] =    -4.5044e-16;
	    prefs->val[21] =    -2.5487e-11;
	    prefs->val[22] =    -1.3246e-16;
	    prefs->val[23] =    -7.55e-23;
	    prefs->val[24] =     2.4428e-23;
	    prefs->val[25] =     1.32e-29;
	    prefs->val[26] =    -2.0e-29;
	    
	    /* get lon */
	    prefs->val[27]  =    4.7297306e-2;
	    prefs->val[28] =     7.925715e-9;
	    prefs->val[29] =    -4.4271e-16;
	    prefs->val[30] =     1.3281e-15;
	    prefs->val[31] =     2.55e-22;
	    prefs->val[32] =    -2.55e-22;
	    prefs->val[33] =     5.0e-29;
	    prefs->val[34] =    -9.63e-29;
	    prefs->val[35] =     9.63e-30;
	    
	    prefs->val[36] =   169028.66/3600.0; /* in deg */
	callfunc = mpSetValues ( mp, mpCENTER_LATITUDE, prefs->val[36], NULL); /* explicit set of cen_lat */
	printf ("CENTER_LATITUDE  is set to %lf by function dlr_earth_map_get_prefs ...",prefs->val[36]);

	    prefs->val[37] =    26782.5/3600.0;  /* in deg */
	callfunc = mpSetValues ( mp, mpCENTER_LONGITUDE, prefs->val[37], NULL); /* explicit set of cen_lon */
	printf ("CENTER_LONGITUDE is set to %lf by function dlr_earth_map_get_prefs ...\n",prefs->val[37]);


	callfunc = mpGetValues ( mp, mpPOSITIVE_LONGITUDE_DIRECTION, c_temp, NULL); 
	if (strcmp(c_temp, "WEST")==0)
	    		{
	    		printf ("POSITIVE_LONGITUDE_DIRECTION == WEST is not allowed for this map projection !!!\n");
	    		return(-1); 
	    		}


	    prefs->val[38] =  600000.0;
	    prefs->val[39] =  200000.0;
		
	callfunc = mpGetValues ( mp, mpLINE_PROJECTION_OFFSET, 
	    &prefs->val[40], NULL);
	callfunc = mpGetValues ( mp, mpSAMPLE_PROJECTION_OFFSET, 
	    &prefs->val[41], NULL);
	callfunc = mpGetValues ( mp, mpMAP_SCALE, &prefs->val[42], NULL);
	    prefs->val[42] = (double)((int)((prefs->val[42])*1000000000.0+0.5))/1000000.0;
	nof_used_prefs = 43;
	}
     else if (prefs->earth_case == 3) /* Soldner-Koordinaten */
	{    
	    prefs->val[0]  =	 6398786.848;		/* Polkruemmungshalbmesser */

	    prefs->val[1]  =     6.719218798e-3;
	    prefs->val[2]  = 	 52.41864828*DEG2PI;
	    prefs->val[3]  =	 13.62720367*DEG2PI;
	callfunc = mpSetValues ( mp, mpCENTER_LATITUDE, 52.41864828, NULL); /* explicit set of cen_lat */
	printf ("CENTER_LATITUDE  is set to %lf by function dlr_earth_map_get_prefs ...\n",52.41864828);

	callfunc = mpSetValues ( mp, mpCENTER_LONGITUDE, 13.62720367, NULL); /* explicit set of cen_lon */
	printf ("CENTER_LONGITUDE is set to %lf by function dlr_earth_map_get_prefs ...\n",13.62720367);

	callfunc = mpGetValues ( mp, mpPOSITIVE_LONGITUDE_DIRECTION, c_temp, NULL); 
	if (strcmp(c_temp, "WEST")==0)
	    		{
	    		printf ("POSITIVE_LONGITUDE_DIRECTION == WEST is not allowed for this map projection !!!\n");
	    		return(-1); 
	    		}

	    /* for ll2ls and ll2ru */
	    prefs->val[4]  =	 1.0 
				 - 3.0/4.0*prefs->val[1] 
				 + 45.0/64.0*prefs->val[1]*prefs->val[1]
				 - 175.0/256.0*prefs->val[1]*prefs->val[1]*prefs->val[1]
				 + 11025.0/16384.0*prefs->val[1]*prefs->val[1]*prefs->val[1]*prefs->val[1];
	    prefs->val[5]  =	 - 3.0/4.0*prefs->val[1] 
				 + 15.0/16.0*prefs->val[1]*prefs->val[1]
				 - 525.0/512.0*prefs->val[1]*prefs->val[1]*prefs->val[1]
				 + 2205.0/2048.0*prefs->val[1]*prefs->val[1]*prefs->val[1]*prefs->val[1];
	    prefs->val[6]  =	 15.0/64.0*prefs->val[1]*prefs->val[1]
				 - 105.0/256.0*prefs->val[1]*prefs->val[1]*prefs->val[1]
				 + 2205.0/4096.0*prefs->val[1]*prefs->val[1]*prefs->val[1]*prefs->val[1];
	    prefs->val[7]  =	 - 35.0/512.0*prefs->val[1]*prefs->val[1]*prefs->val[1]
				 + 315.0/2048.0*prefs->val[1]*prefs->val[1]*prefs->val[1]*prefs->val[1];

	    prefs->val[8]  =     prefs->val[0]*
				 (
				 prefs->val[4]*prefs->val[2]
				 + prefs->val[5]*1.0/2.0*sin(2.0*prefs->val[2])
				 + prefs->val[6]*1.0/4.0*sin(4.0*prefs->val[2])
				 + prefs->val[7]*1.0/6.0*sin(6.0*prefs->val[2])
				 );
	    
	    /* for ls2ll and ru2ll */
	    prefs->val[9]  =     1.0;
	    prefs->val[10] =    -8.31729565e-3;
	    prefs->val[11] =     4.24914906e-3;
	    prefs->val[12] =    -1.13566119e-3;
	    prefs->val[13] =     2.2976983e-4;
	    prefs->val[14] =    -4.36398e-5;
	    prefs->val[15] =     5.62025e-6;
	    
	    prefs->val[16] =    325632.08677;
	    prefs->val[17] =  10000855.7646;
	    

	    prefs->val[18] =  40000.0;
	    prefs->val[19] =  10000.0;
		
	callfunc = mpGetValues ( mp, mpLINE_PROJECTION_OFFSET, 
	    &prefs->val[20], NULL);
	callfunc = mpGetValues ( mp, mpSAMPLE_PROJECTION_OFFSET, 
	    &prefs->val[21], NULL);
	callfunc = mpGetValues ( mp, mpMAP_SCALE, &prefs->val[22], NULL);
	    prefs->val[22] = (double)((int)((prefs->val[22])*1000000000.0+0.5))/1000000.0;
	nof_used_prefs = 23;
	}
     else if (prefs->earth_case == 4) /* RD_Niederlande */
	{    
	    prefs->val[0]  =	 190066.98903;
	    prefs->val[1]  =     -11830.85831;
	    prefs->val[2]  =     -114.19754;
	    prefs->val[3]  =     -32.38360;
	    prefs->val[4]  =     -2.34078;
	    prefs->val[5]  =     -0.60639;
	    prefs->val[6]  =     0.15774;
	    prefs->val[7]  =     -0.04158;
	    prefs->val[8]  =     -0.00661;
	    prefs->val[9]  =     309020.31810;
	    prefs->val[10]  =     3638.36193;
	    prefs->val[11]  =     -157.95222;
	    prefs->val[12]  =     72.97141;
	    prefs->val[13]  =     59.79734;
	    prefs->val[14]  =     -6.43481;
	    prefs->val[15]  =     0.09351;
	    prefs->val[16]  =     -0.07379;
	    prefs->val[17]  =     -0.05419;
	    prefs->val[18]  =     -0.03444;
	    prefs->val[20]  = 	 52.15616056;
	    prefs->val[21]  =	  5.38763889;

	    prefs->val[22]  =	  3236.0331637;
	    prefs->val[23]  =	  -32.5915821;
	    prefs->val[24]  =	  -0.2472814;
	    prefs->val[25]  =	  -0.8501341;
	    prefs->val[26]  =	  -0.0655238;
	    prefs->val[27]  =	  -0.0171137;
	    prefs->val[28]  =	  0.0052771;
	    prefs->val[29]  =	  -0.0003859;
	    prefs->val[30]  =	  0.0003314;
	    prefs->val[31]  =	  0.0000371;
	    prefs->val[32]  =	  0.0000143;
	    prefs->val[33]  =	  -0.0000090;
	    prefs->val[34]  =	  5261.3028966;
	    prefs->val[35]  =	  105.9780241;
	    prefs->val[36]  =	  2.4576469;
	    prefs->val[37]  =	  -0.8192156;
	    prefs->val[38]  =	  -0.0560092;
	    prefs->val[39]  =	  0.0560089;
	    prefs->val[40]  =	  -0.0025614;
	    prefs->val[41]  =	  0.0012770;
	    prefs->val[42]  =	  0.0002574;
	    prefs->val[43]  =	  -0.0000973;
	    prefs->val[44]  =	  0.0000293;
	    prefs->val[45]  =	  0.0000291;

	callfunc = mpSetValues ( mp, mpCENTER_LATITUDE, 52.15616056, NULL); /* explicit set of cen_lat */
	printf ("CENTER_LATITUDE  is set to %lf by function dlr_earth_map_get_prefs ...\n",52.15616056);

	callfunc = mpSetValues ( mp, mpCENTER_LONGITUDE, 5.38763889, NULL); /* explicit set of cen_lon */
	printf ("CENTER_LONGITUDE is set to %lf by function dlr_earth_map_get_prefs ...\n",5.38763889);

	callfunc = mpGetValues ( mp, mpPOSITIVE_LONGITUDE_DIRECTION, c_temp, NULL); 
	if (strcmp(c_temp, "WEST")==0)
	    		{
	    		printf ("POSITIVE_LONGITUDE_DIRECTION == WEST is not allowed for this map projection !!!\n");
	    		return(-1); 
	    		}

	    prefs->val[46] =  155000.0;
	    prefs->val[47] =  463000.0;
		
	callfunc = mpGetValues ( mp, mpLINE_PROJECTION_OFFSET, 
	    &prefs->val[48], NULL);
	callfunc = mpGetValues ( mp, mpSAMPLE_PROJECTION_OFFSET, 
	    &prefs->val[49], NULL);
	callfunc = mpGetValues ( mp, mpMAP_SCALE, &prefs->val[26], NULL);
	    prefs->val[50] = (double)((int)((prefs->val[26])*1000000000.0+0.5))/1000000.0;
	nof_used_prefs = 51;
	}
     else if ((prefs->earth_case == 50)||(prefs->earth_case == 51)) /* EQUIDISTANT or SINUSOIDAL*/
	{    
	callfunc = mpGetValues ( mp, mpA_AXIS_RADIUS, &prefs->val[0], NULL); 
	    prefs->val[0] *= 1000.0;
	callfunc = mpGetValues ( mp, mpC_AXIS_RADIUS, &b, NULL); 
	b *= 1000.0;

	    prefs->val[1] = (prefs->val[0] * prefs->val[0] - b * b) /(prefs->val[0] * prefs->val[0]);
	    prefs->val[2] = prefs->val[1] * prefs->val[1];
	    prefs->val[3] = prefs->val[2] * prefs->val[1];
	    prefs->val[4] = (prefs->val[0]*(1.-prefs->val[1]/4.0-3.*prefs->val[2]/64.-5.*prefs->val[3]/256.));
	    prefs->val[5] = (1. - prefs->val[1] / 4. - 3. * prefs->val[2] / 64. - 5. * prefs->val[3] / 256.);
	    prefs->val[6] = (3. * prefs->val[1] / 8. + 3. * prefs->val[2] / 32. + 45. * prefs->val[3] / 1024.);
	    prefs->val[7] = (15. * prefs->val[2] / 256. + 45. * prefs->val[3] / 1024.);
	    prefs->val[8] = (35. * prefs->val[3] / 3072.);

	callfunc = mpGetValues ( mp, mpCENTER_LATITUDE, &d_temp, NULL); /* check for cen_lat != 0*/
	if (fabs(d_temp)>0.001)
	    		{
	    		printf ("CENTER_LATITUDE != 0 is not allowed for this map projection !!!\n");
	    		return(-1); 
	    		}
		prefs->val[9] = 0.0; 

	callfunc = mpGetValues ( mp, mpCENTER_LONGITUDE, &prefs->val[10], NULL); 

	callfunc = mpGetValues ( mp, mpPOSITIVE_LONGITUDE_DIRECTION, c_temp, NULL); 
	if (strcmp(c_temp, "WEST")==0) 
		{
		prefs->val[11] = -1.;
		prefs->val[10] *= prefs->val[11];
		}
	else							
		{
		prefs->val[11] =  1.;
		prefs->val[10] *= prefs->val[11];
		}

	if (prefs->val[10]>360.0) prefs->val[10]-=360.0; /* make cen_lon from 0 - 360 East*/
	else if (prefs->val[10]<0.0) prefs->val[10]+=360.0;

		prefs->val[10] *= DEG2PI;

			
	callfunc = mpGetValues ( mp, mpLINE_PROJECTION_OFFSET, 
	    &prefs->val[12], NULL);
	callfunc = mpGetValues ( mp, mpSAMPLE_PROJECTION_OFFSET, 
	    &prefs->val[13], NULL);
	callfunc = mpGetValues ( mp, mpMAP_SCALE, &prefs->val[14], NULL);
	    prefs->val[14] = (double)((int)((prefs->val[14])*10000.0+0.5))/10.0;

	e1 =(1.-sqrt(1.-prefs->val[1]))/(1.+sqrt(1.-prefs->val[1]));
	    prefs->val[15] =(3.*e1/2.-27.*pow(e1,3)/32.);
	    prefs->val[16] =(21.*e1*e1/16.-55.*pow(e1,4)/32.);
	    prefs->val[17] =(151.*pow(e1,3)/96.);
	    prefs->val[18] =(1097.*pow(e1,4)/512.);

	    prefs->val[19] = (prefs->val[0]*(1.-prefs->val[1]/4.0-3.*prefs->val[2]/64.-5.*prefs->val[3]/256.));
	    prefs->val[20] = b*b;
	nof_used_prefs = 21;
	}
   else nof_used_prefs = 0;

if (prefs->earth_case > 0) callfunc = mpSetValues ( mp, mpCARTESIAN_AZIMUTH, 0.0, NULL); 

for (i=nof_used_prefs;i<MAX_EARTH_PREFS;i++) prefs->val[i]=0.0;
return(1);
}

/* -------------------------------------------------------------------------------------------*/
/* RD_Niederlande */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_RD_Niederlande (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	df, dl, dx, dy, df_2, df_3, df_4, dl_2, dl_3, dl_4, dl_5;
   	df = (*lat - prefs.val[20]) * 0.36;
  	dl = (*lon - prefs.val[21]) * 0.36; 

	df_2 = pow(df,2); df_3 = pow(df,3); df_4 = pow(df,4);
	dl_2 = pow(dl,2); dl_3 = pow(dl,3); dl_4 = pow(dl,4); dl_5 = pow(dl,5);
	
   	dx  = prefs.val[0] * dl + prefs.val[1]  * df*dl + prefs.val[2] * df_2 * dl + prefs.val[3] * dl_3;
   	dx += prefs.val[4] * df_3 * dl    + prefs.val[5] * df * dl_3 + prefs.val[6] * df_2 * dl_3;
   	dx += prefs.val[7] * df_4 * dl    + prefs.val[8] * dl_5;

/* corrected Scholten 9.11.01 */
   	*sample = dx/prefs.val[50] + prefs.val[49] + 1.0;
/* corrected Scholten 9.11.01 */

  	dy  = prefs.val[9] * df + prefs.val[12] * df_2 + prefs.val[10] * dl_2 + prefs.val[11]* df * dl_2;
   	dy += prefs.val[13] * df_3 + prefs.val[14] * df_2 * dl_2 + prefs.val[18] * df_4;
   	dy += prefs.val[15] * dl_4 + prefs.val[16] * df_3 * dl_2 + prefs.val[17] * df * dl_4;

/* corrected Scholten 9.11.01 */
   	*line = -dy/prefs.val[50] + prefs.val[48] + 1.0;
/* corrected Scholten 9.11.01 */
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_RD_Niederlande (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	df, dl, dx, dy, dx_2, dx_3, dx_4, dx_5, dy_2, dy_3, dy_4, dy_5, p10_5=pow(10,-5);

/* corrected Scholten 9.11.01 */
   	dx = (*sample - prefs.val[49] - 1.0)*prefs.val[50] * p10_5;
   	dy = (prefs.val[48] + 1.0 - *line)*prefs.val[50] * p10_5;
/* corrected Scholten 9.11.01 */

	dx_2 = pow(dx,2); dx_3 = pow(dx,3); dx_4 = pow(dx,4); dx_5 = pow(dx,5);
	dy_2 = pow(dy,2); dy_3 = pow(dy,3); dy_4 = pow(dy,4); dy_5 = pow(dy,5);

   	df  = prefs.val[22] * dy + prefs.val[23] * dx_2 + prefs.val[24] * dy_2 + prefs.val[25] * dx_2 * dy + prefs.val[26] * dy_3;
   	df += prefs.val[28] * dx_4 + prefs.val[27] * dx_2 * dy_2 + prefs.val[31] * pow(dy,4) + prefs.val[30] * dx_4 * dy;
   	df += prefs.val[29] * dx_2 * dy_3 + prefs.val[32] * dx_4 * dy_2 + prefs.val[33] * dx_2 * dy_4;
   
   
   	*lat = prefs.val[20] + df / 3600.0;

   	dl  = prefs.val[34] * dx + prefs.val[35] * dx * dy + prefs.val[37] * dx_3 + prefs.val[36] * dx * dy_2 + prefs.val[38] * dx_3 * dy;
   	dl += prefs.val[39] * dx * dy_3 + prefs.val[42] * dx_5 + prefs.val[40] * dx_3 * dy_2 + prefs.val[41] * dx * dy_4;
   	dl += prefs.val[44] * dx_5 * dy + prefs.val[43] * dx_3 * dy_3 + prefs.val[45] * dx * dy_5;
   
   	*lon = prefs.val[21] + dl / 3600.0;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* RD_Niederlande */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_RD_Niederlande (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{

	double	df, dl, dx, dy, df_2, df_3, df_4, dl_2, dl_3, dl_4, dl_5;

   	df = (*lat - prefs.val[20]) * 0.36;
  	dl = (*lon - prefs.val[21]) * 0.36; 

	df_2 = pow(df,2); df_3 = pow(df,3); df_4 = pow(df,4);
	dl_2 = pow(dl,2); dl_3 = pow(dl,3); dl_4 = pow(dl,4); dl_5 = pow(dl,5);
	
   	dx  = prefs.val[0] * dl + prefs.val[1]  * df*dl + prefs.val[2] * df_2 * dl + prefs.val[3] * dl_3;
   	dx += prefs.val[4] * df_3 * dl    + prefs.val[5] * df * dl_3 + prefs.val[6] * df_2 * dl_3;
   	dx += prefs.val[7] * df_4 * dl    + prefs.val[8] * dl_5;

   	*right = dx + prefs.val[46];

  	dy  = prefs.val[9] * df + prefs.val[12] * df_2 + prefs.val[10] * dl_2 + prefs.val[11]* df * dl_2;
   	dy += prefs.val[13] * df_3 + prefs.val[14] * df_2 * dl_2 + prefs.val[18] * df_4;
   	dy += prefs.val[15] * dl_4 + prefs.val[16] * df_3 * dl_2 + prefs.val[17] * df * dl_4;

   	*up = dy + prefs.val[47];

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_RD_Niederlande (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	df, dl, dx, dy, dx_2, dx_3, dx_4, dx_5, dy_2, dy_3, dy_4, dy_5, p10_5=pow(10,-5);

   	dx = (*right-prefs.val[46]) * p10_5;
   	dy = (*up-prefs.val[47]) * p10_5;

	dx_2 = pow(dx,2); dx_3 = pow(dx,3); dx_4 = pow(dx,4); dx_5 = pow(dx,5);
	dy_2 = pow(dy,2); dy_3 = pow(dy,3); dy_4 = pow(dy,4); dy_5 = pow(dy,5);

   	df  = prefs.val[22] * dy + prefs.val[23] * dx_2 + prefs.val[24] * dy_2 + prefs.val[25] * dx_2 * dy + prefs.val[26] * dy_3;
   	df += prefs.val[28] * dx_4 + prefs.val[27] * dx_2 * dy_2 + prefs.val[31] * pow(dy,4) + prefs.val[30] * dx_4 * dy;
   	df += prefs.val[29] * dx_2 * dy_3 + prefs.val[32] * dx_4 * dy_2 + prefs.val[33] * dx_2 * dy_4;
   
   
   	*lat = prefs.val[20] + df / 3600.0;

   	dl  = prefs.val[34] * dx + prefs.val[35] * dx * dy + prefs.val[37] * dx_3 + prefs.val[36] * dx * dy_2 + prefs.val[38] * dx_3 * dy;
   	dl += prefs.val[39] * dx * dy_3 + prefs.val[42] * dx_5 + prefs.val[40] * dx_3 * dy_2 + prefs.val[41] * dx * dy_4;
   	dl += prefs.val[44] * dx_5 * dy + prefs.val[43] * dx_3 * dy_3 + prefs.val[45] * dx * dy_5;
   
   	*lon = prefs.val[21] + dl / 3600.0;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* RD_Niederlande */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_RD_Niederlande (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[49] - 1.0)*prefs.val[50] + prefs.val[46];
	*up    =   (prefs.val[48] + 1.0 - *line)*prefs.val[50] + prefs.val[47];
	
	return(1);
}
int dlr_earth_map_RU2LS_RD_Niederlande (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*sample = (*right - prefs.val[46])/prefs.val[50] + prefs.val[49] + 1.0;
	*line   = (prefs.val[47] - *up)/prefs.val[50] + prefs.val[48] + 1.0;
	
	return(1);
}


/* -------------------------------------------------------------------------------------------*/
/* TransverseMercator */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_TransverseMercator (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	N, T, TT, C, A, M, tan_lat, sin_lat, cos_lat, rad_lat, rad_lon;

	rad_lat = *lat*DEG2PI;
	rad_lon = *lon*DEG2PI;
	
	sin_lat=sin(rad_lat);
	cos_lat=cos(rad_lat);
	tan_lat=tan(rad_lat);
	
	N = (prefs.val[0]) /(sqrt (1 - (prefs.val[1])*sin_lat*sin_lat));
	T = pow (tan_lat, 2);
	TT = T*T;
	C = prefs.val[9] * pow (cos_lat, 2);
	A = (rad_lon - prefs.val[21]) * cos_lat;
	M = dlr_earth_map_ArcLen (rad_lat, prefs);
	*sample = (prefs.val[22]*N*(A+(1.-T+C)*pow(A,3)/6. +(5.-18.*T+TT+72.*C-prefs.val[12])*pow(A,5)/120.))
		  / prefs.val[27] + prefs.val[26] + 1.0;
	*line   = -(prefs.val[22]*(M-prefs.val[20]+N*tan(rad_lat)*(A*A/2+(5.-T+9.*C+4.*C*C)*pow(A,4)/24.
		                       +(61.-58.*T+TT+600.*C-prefs.val[14])*pow(A,6)/720.)))
		  / prefs.val[27] + prefs.val[25] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_TransverseMercator (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	M,phi1;
	double	my;
	double	CC,C,TT,T,N,R,D;
	double	tan_phi1, sin_phi1, cos_phi1;
	
	M=prefs.val[20]+((prefs.val[25] + 1.0 - *line)*prefs.val[27]/prefs.val[22]);
	my=M/prefs.val[4];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

	sin_phi1=sin(phi1);
	cos_phi1=cos(phi1);
	tan_phi1=tan(phi1);
	
	C=prefs.val[9]*pow(cos_phi1,2);
	CC=C*C;
	T=pow(tan_phi1,2);
	TT=T*T;
	N=prefs.val[0]/sqrt(1.-prefs.val[1]*sin_phi1*sin_phi1);
	R=prefs.val[0]*(1.-prefs.val[1])/sqrt(pow(1.-prefs.val[1]*sin_phi1*sin_phi1,3));
	D=(*sample - prefs.val[26] - 1.0)*prefs.val[27]/(N*prefs.val[22]);
	*lat=phi1-(N*tan_phi1/R)*(D*D/2.-(5.+.3*T+10.*C-4.*CC-prefs.val[11])*pow(D,4)/24.
						+(61.+90.*T+298.*C+45.*TT-prefs.val[13]-3.*CC)*pow(D,6)/720.);
	*lon=prefs.val[21] + (D-(1.+2.*T+C)*pow(D,3)/6.+(5.-2.*C+28.*T-3.*CC+prefs.val[10]+24.*TT)*pow(D,5)/120.)/cos_phi1;

	*lat *= PI2DEG;
	*lon *= PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* TransverseMercator */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_TransverseMercator (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{
	double	N, T, TT, C, A, M, tan_lat, sin_lat, cos_lat, rad_lat, rad_lon;

	rad_lat = *lat*DEG2PI;
	rad_lon = *lon*DEG2PI;
	
	sin_lat=sin(rad_lat);
	cos_lat=cos(rad_lat);
	tan_lat=tan(rad_lat);
	
	N = (prefs.val[0]) /(sqrt (1 - (prefs.val[1])*sin_lat*sin_lat));
	T = pow (tan_lat, 2);
	TT = T*T;
	C = prefs.val[9] * pow (cos_lat, 2);
	A = (rad_lon - prefs.val[21]) * cos_lat;
	M = dlr_earth_map_ArcLen (rad_lat, prefs);
	*right = prefs.val[23] + prefs.val[22]*N*(A+(1.-T+C)*pow(A,3)/6.
				      +(5.-18.*T+TT+72.*C-prefs.val[12])*pow(A,5)/120.);
	*up    = prefs.val[24] + prefs.val[22]*(M-prefs.val[20]+N*tan(rad_lat)*(A*A/2+(5.-T+9.*C+4.*C*C)*pow(A,4)/24.
		                       +(61.-58.*T+TT+600.*C-prefs.val[14])*pow(A,6)/720.));
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_TransverseMercator (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	M,phi1;
	double	my;
	double	CC,C,TT,T,N,R,D;
	double	tan_phi1, sin_phi1, cos_phi1;
	
	M=prefs.val[20]+((*up-prefs.val[24])/prefs.val[22]);
	my=M/prefs.val[4];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

	sin_phi1=sin(phi1);
	cos_phi1=cos(phi1);
	tan_phi1=tan(phi1);
	
	C=prefs.val[9]*pow(cos_phi1,2);
	CC=C*C;
	T=pow(tan_phi1,2);
	TT=T*T;
	N=prefs.val[0]/sqrt(1.-prefs.val[1]*sin_phi1*sin_phi1);
	R=prefs.val[0]*(1.-prefs.val[1])/sqrt(pow(1.-prefs.val[1]*sin_phi1*sin_phi1,3));
	D=(*right-prefs.val[23])/(N*prefs.val[22]);
	*lat=phi1-(N*tan_phi1/R)*(D*D/2.-(5.+.3*T+10.*C-4.*CC-prefs.val[11])*pow(D,4)/24.
						+(61.+90.*T+298.*C+45.*TT-prefs.val[13]-3.*CC)*pow(D,6)/720.);
	*lon=prefs.val[21] + (D-(1.+2.*T+C)*pow(D,3)/6.+(5.-2.*C+28.*T-3.*CC+prefs.val[10]+24.*TT)*pow(D,5)/120.)/cos_phi1;

	*lat *= PI2DEG;
	*lon *= PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* TransverseMercator */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_TransverseMercator (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[26] - 1.0)*prefs.val[27] + prefs.val[23];
	*up    =   (prefs.val[25] + 1.0 - *line)*prefs.val[27] + prefs.val[24];
	
	return(1);
}
int dlr_earth_map_RU2LS_TransverseMercator (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*sample = (*right - prefs.val[23])/prefs.val[27] + prefs.val[26] + 1.0;
	*line   = (prefs.val[24] - *up)/prefs.val[27] + prefs.val[25] + 1.0;
	
	return(1);
}
/* ------------------------------------------------------------ */
double dlr_earth_map_ArcLen (double phi, Earth_prefs prefs)
{
  return (prefs.val[0] * (
		     prefs.val[5] * phi
		   - prefs.val[6] * sin (2. * phi)
		   + prefs.val[7] * sin (4. * phi)
		   - prefs.val[8] * sin (6. * phi)
	  )
    );
}
/* -------------------------------------------------------------------------------------------*/
/* Schweizer Landes-Koordinaten */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_SLK (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	sec_lat, sec_lat_2, sec_lat_3, sec_lon, sec_lon_2, sec_lon_3, sec_lon_4, sec_lon_5;

	sec_lat = (*lat - prefs.val[36])*3600.0;
	sec_lat_2 = sec_lat*sec_lat;
	sec_lat_3 = sec_lat_2*sec_lat;
	sec_lon = (*lon - prefs.val[37])*3600.0;
	sec_lon_2 = sec_lon*sec_lon;
	sec_lon_3 = sec_lon_2*sec_lon;
	sec_lon_4 = sec_lon_2*sec_lon_2;
	sec_lon_5 = sec_lon_3*sec_lon_2;
	
	*sample = (
		     prefs.val[1]*sec_lon 
	           + prefs.val[2]*sec_lon   *sec_lat 
	           + prefs.val[3]*sec_lon_3 
	           + prefs.val[4]*sec_lon   *sec_lat_2 
	           + prefs.val[5]*sec_lon   *sec_lat_3 
	           + prefs.val[6]*sec_lon_3 *sec_lat 
	           + prefs.val[7]*sec_lon_3 *sec_lat_2 
	           + prefs.val[8]*sec_lon_5 
		  ) / prefs.val[42] + prefs.val[41] + 1.0;
	*line   =-(
		     prefs.val[9]            *sec_lat 
	           + prefs.val[10]*sec_lon_2 
	           + prefs.val[11]*sec_lon_2 *sec_lat
	           + prefs.val[12]           *sec_lat_2 
	           + prefs.val[13]           *sec_lat_3 
	           + prefs.val[14]*sec_lon_2 *sec_lat_2 
	           + prefs.val[15]*sec_lon_2 *sec_lat_3 
	           + prefs.val[16]*sec_lon_4 
	           + prefs.val[17]*sec_lon_4 *sec_lat
	          )
		  / prefs.val[42] + prefs.val[40] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_SLK (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	r, u, r2, r3, r4, r5, u2, u3, u4;
	
	r = (*sample - prefs.val[41] - 1.0)*prefs.val[42];
	u = (prefs.val[40] + 1.0 - *line)*prefs.val[42];
	r2=r*r;
	r3=r2*r;
	r4=r2*r2;
	r5=r4*r;
	u2=u*u;
	u3=u2*u;
	u4=u2*u2;
		
	*lat=(
		     prefs.val[18]    *u 
	           + prefs.val[19]*r2 
	           + prefs.val[20]*r2 *u 
	           + prefs.val[21]    *u2 
	           + prefs.val[22]    *u3 
	           + prefs.val[23]*r2 *u2 
	           + prefs.val[24]*r4 
	           + prefs.val[25]*r4 *u 
	           + prefs.val[26]*r2 *u3 
	     );
	*lon=(
		     prefs.val[27]*r 
	           + prefs.val[28]*r  *u 
	           + prefs.val[29]*r3 
	           + prefs.val[30]*r  *u2 
	           + prefs.val[31]*r  *u3 
	           + prefs.val[32]*r3 *u 
	           + prefs.val[33]*r  *u4 
	           + prefs.val[34]*r3 *u2 
	           + prefs.val[35]*r5 
	     );

	*lat /= 3600.0;
	*lon /= 3600.0;
	*lat += prefs.val[36];
	*lon += prefs.val[37];

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* Schweizer Landes-Koordinaten */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_SLK (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{
	double	sec_lat, sec_lat_2, sec_lat_3, sec_lon, sec_lon_2, sec_lon_3, sec_lon_4, sec_lon_5;

	sec_lat = (*lat - prefs.val[36])*3600.0;
	sec_lat_2 = sec_lat*sec_lat;
	sec_lat_3 = sec_lat_2*sec_lat;
	sec_lon = (*lon - prefs.val[37])*3600.0;
	sec_lon_2 = sec_lon*sec_lon;
	sec_lon_3 = sec_lon_2*sec_lon;
	sec_lon_4 = sec_lon_2*sec_lon_2;
	sec_lon_5 = sec_lon_3*sec_lon_2;
	
	*right = prefs.val[38] + (
		     prefs.val[1]*sec_lon 
	           + prefs.val[2]*sec_lon   *sec_lat 
	           + prefs.val[3]*sec_lon_3 
	           + prefs.val[4]*sec_lon   *sec_lat_2 
	           + prefs.val[5]*sec_lon   *sec_lat_3 
	           + prefs.val[6]*sec_lon_3 *sec_lat 
	           + prefs.val[7]*sec_lon_3 *sec_lat_2 
	           + prefs.val[8]*sec_lon_5 
		  );
	*up   =  prefs.val[39] + (
		     prefs.val[9]            *sec_lat 
	           + prefs.val[10]*sec_lon_2 
	           + prefs.val[11]*sec_lon_2 *sec_lat
	           + prefs.val[12]           *sec_lat_2 
	           + prefs.val[13]           *sec_lat_3 
	           + prefs.val[14]*sec_lon_2 *sec_lat_2 
	           + prefs.val[15]*sec_lon_2 *sec_lat_3 
	           + prefs.val[16]*sec_lon_4 
	           + prefs.val[17]*sec_lon_4 *sec_lat
	          );
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_SLK (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	r, u, r2, r3, r4, r5, u2, u3, u4;
	
	r = (*right - prefs.val[38]);
	u = (*up - prefs.val[39]);
	r2=r*r;
	r3=r2*r;
	r4=r2*r2;
	r5=r4*r;
	u2=u*u;
	u3=u2*u;
	u4=u2*u2;
		
	*lat=(
		     prefs.val[18]    *u 
	           + prefs.val[19]*r2 
	           + prefs.val[20]*r2 *u 
	           + prefs.val[21]    *u2 
	           + prefs.val[22]    *u3 
	           + prefs.val[23]*r2 *u2 
	           + prefs.val[24]*r4 
	           + prefs.val[25]*r4 *u 
	           + prefs.val[26]*r2 *u3 
	     );
	*lon=(
		     prefs.val[27]*r 
	           + prefs.val[28]*r  *u 
	           + prefs.val[29]*r3 
	           + prefs.val[30]*r  *u2 
	           + prefs.val[31]*r  *u3 
	           + prefs.val[32]*r3 *u 
	           + prefs.val[33]*r  *u4 
	           + prefs.val[34]*r3 *u2 
	           + prefs.val[35]*r5 
	     );

	*lat /= 3600.0;
	*lon /= 3600.0;
	*lat += prefs.val[36];
	*lon += prefs.val[37];

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* Schweizer Landes-Koordinaten */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_SLK (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[41] - 1.0)*prefs.val[42] + prefs.val[38];
	*up    = (prefs.val[40] + 1.0 - *line)*prefs.val[42] + prefs.val[39];
	
	return(1);
}
int dlr_earth_map_RU2LS_SLK (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*sample = (*right - prefs.val[38])/prefs.val[42] + prefs.val[41] + 1.0;
	*line   = (prefs.val[39] - *up)/prefs.val[42] + prefs.val[40] + 1.0;
	
	return(1);
}

/* -------------------------------------------------------------------------------------------*/
/* Soldner-Koordinaten */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_SOLDNER (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	rad_lat, rad_lon, sin_lat, cos_lat, cos_lat2, tan_lat, dl, dl2, xi2, v, n, vi, yi, bfi,
		cos_bfi, cos_bfi2, v2, t, t2, b01, b03, a02, a04, vi1, vi12, bf, sf;

	rad_lat = *lat*DEG2PI;
	rad_lon = *lon*DEG2PI;
	
	sin_lat = sin(rad_lat);
	cos_lat = cos(rad_lat);
	cos_lat2= cos_lat*cos_lat;
	tan_lat = tan(rad_lat);

	dl   = rad_lon-prefs.val[3];
	dl2  = dl*dl;
	xi2  = prefs.val[1]*cos_lat2;
	v    = sqrt(1.0+xi2);
	n    = prefs.val[0]/v;
	vi   = dl*cos_lat;
	yi   = vi*n;
	
	bfi  = rad_lat + 0.5*v*v*sin_lat*cos_lat*dl2;
	
	while(1)
	    {
	    cos_bfi = cos(bfi);
	    cos_bfi2= cos_bfi*cos_bfi;
	    xi2     = prefs.val[1]*cos_bfi2;
	    v       = sqrt(1.0+xi2);
	    v2      = v*v;
	    t       = tan(bfi);
	    t2      = t*t;
	    b01     = cos_bfi;
	    b03     = t2*cos_bfi2*cos_bfi/3.0;
	    a02     = -0.5*v2*t;
	    a04     = v2*t/24.0*(1.0+3.0*t2+xi2-9.0*xi2*t2);
	    
	    vi1     = b01*dl + b03*dl2*dl;
	    vi12    = vi1*vi1;
	    bf      = rad_lat - a02*vi12 - a04*vi12*vi12;
	    
	    n       = prefs.val[0]/v;
	    *sample = vi1*n;
	    if ((fabs(bf-bfi)<3.0e-8)&&(fabs(*sample-yi)<0.01))break;
	    bfi=bf;
	    yi = *sample;
	    }
	
	*sample = *sample / prefs.val[22] + prefs.val[21] + 1.0;
	
	sf  =     prefs.val[0]* (
				 prefs.val[4]*bf
				 + prefs.val[5]*1.0/2.0*sin(2.0*bf)
				 + prefs.val[6]*1.0/4.0*sin(4.0*bf)
				 + prefs.val[7]*1.0/6.0*sin(6.0*bf)
				 );
	*line   =-( sf - prefs.val[8]) / prefs.val[22] + prefs.val[20] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_SOLDNER (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	r, u,sf, psi, psi2, psi22, psi23, psi24, psi25, psi26, bf, cos_bf, xi2, v, n, t, 
		a02, a04, b01, b03, help, help2, db, dl;
	
	r = (*sample - prefs.val[21] - 1.0)*prefs.val[22];
	u = (prefs.val[20] + 1.0 - *line)*prefs.val[22];

	sf   = prefs.val[8] + u;
	psi  = sf / prefs.val[17];		
	psi2 = psi*psi;		
	psi22 = psi2*psi2;		
	psi23 = psi22*psi2;		
	psi24 = psi22*psi22;		
	psi25 = psi22*psi23;		
	psi26 = psi23*psi23;		

	bf   = prefs.val[16] * psi *
		(
		prefs.val[9]
		+ prefs.val[10] * psi2
		+ prefs.val[11] * psi22
		+ prefs.val[12] * psi23
		+ prefs.val[13] * psi24
		+ prefs.val[14] * psi25
		+ prefs.val[15] * psi26
		) / 3600.0 * DEG2PI;
	
	cos_bf = cos(bf); 
	xi2    = prefs.val[1]*cos_bf*cos_bf;
	v      = sqrt(1.0+xi2);
	n      = prefs.val[0]/v;
	t      = tan(bf);
	
	a02    = -0.5*v*v*t;
	a04    = v*v*t*(1.0+3.0*t*t + xi2 - 9.0*xi2*t*t)/24.0;
	b01    = 1.0/cos_bf;
	b03    = -t*t/(3.0*cos_bf);
	
	help   = r / n;
	help2   = help*help;
	
	db     = a02*help2 + a04*help2*help2;
	dl     = b01*help  + b03*help*help2;
	
	*lat=bf + db;
	*lon=prefs.val[3] + dl;

	*lat *= PI2DEG;
	*lon *= PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* Soldner-Koordinaten */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_SOLDNER (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{
	double	rad_lat, rad_lon, sin_lat, cos_lat, cos_lat2, tan_lat, dl, dl2, xi2, v, n, vi, yi, bfi,
		cos_bfi, cos_bfi2, v2, t, t2, b01, b03, a02, a04, vi1, vi12, bf, sf;

	rad_lat = *lat*DEG2PI;
	rad_lon = *lon*DEG2PI;
	
	sin_lat = sin(rad_lat);
	cos_lat = cos(rad_lat);
	cos_lat2= cos_lat*cos_lat;
	tan_lat = tan(rad_lat);

	dl   = rad_lon-prefs.val[3];
	dl2  = dl*dl;
	xi2  = prefs.val[1]*cos_lat2;
	v    = sqrt(1.0+xi2);
	n    = prefs.val[0]/v;
	vi   = dl*cos_lat;
	yi   = vi*n;
	
	bfi  = rad_lat + 0.5*v*v*sin_lat*cos_lat*dl2;
	
	while(1)
	    {
	    cos_bfi = cos(bfi);
	    cos_bfi2= cos_bfi*cos_bfi;
	    xi2     = prefs.val[1]*cos_bfi2;
	    v       = sqrt(1.0+xi2);
	    v2      = v*v;
	    t       = tan(bfi);
	    t2      = t*t;
	    b01     = cos_bfi;
	    b03     = t2*cos_bfi2*cos_bfi/3.0;
	    a02     = -0.5*v2*t;
	    a04     = v2*t/24.0*(1.0+3.0*t2+xi2-9.0*xi2*t2);
	    
	    vi1     = b01*dl + b03*dl2*dl;
	    vi12    = vi1*vi1;
	    bf      = rad_lat - a02*vi12 - a04*vi12*vi12;
	    
	    n       = prefs.val[0]/v;
	    *right = vi1*n;
	    if ((fabs(bf-bfi)<3.0e-8)&&(fabs(*right-yi)<0.01))break;
	    bfi=bf;
	    yi = *right;
	    }
	
	*right += prefs.val[18];
	
	sf      = prefs.val[0]* (
				 prefs.val[4]*bf
				 + prefs.val[5]*1.0/2.0*sin(2.0*bf)
				 + prefs.val[6]*1.0/4.0*sin(4.0*bf)
				 + prefs.val[7]*1.0/6.0*sin(6.0*bf)
				 );
	*up   = sf - prefs.val[8] + prefs.val[19];
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_SOLDNER (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	r, u,sf, psi, psi2, psi22, psi23, psi24, psi25, psi26, bf, cos_bf, xi2, v, n, t, 
		a02, a04, b01, b03, help, help2, db, dl;
	
	r = (*right - prefs.val[18]);
	u = (*up - prefs.val[19]);

	sf   = prefs.val[8] + u;
	psi  = sf / prefs.val[17];		
	psi2 = psi*psi;		
	psi22 = psi2*psi2;		
	psi23 = psi22*psi2;		
	psi24 = psi22*psi22;		
	psi25 = psi22*psi23;		
	psi26 = psi23*psi23;		

	bf   = prefs.val[16] * psi *
		(
		prefs.val[9]
		+ prefs.val[10] * psi2
		+ prefs.val[11] * psi22
		+ prefs.val[12] * psi23
		+ prefs.val[13] * psi24
		+ prefs.val[14] * psi25
		+ prefs.val[15] * psi26
		) / 3600.0 * DEG2PI;
	
	cos_bf = cos(bf);
	xi2    = prefs.val[1]*cos_bf*cos_bf;
	v      = sqrt(1.0+xi2);
	n      = prefs.val[0]/v;
	t      = tan(bf);
	
	a02    = -0.5*v*v*t;
	a04    = v*v*t*(1.0+3.0*t*t + xi2 - 9.0*xi2*t*t)/24.0;
	b01    = 1.0/cos_bf;
	b03    = -t*t/(3.0*cos_bf);
	
	help   = r / n;
	help2   = help*help;
	
	db     = a02*help2 + a04*help2*help2;
	dl     = b01*help  + b03*help*help2;
	
	*lat=bf + db;
	*lon=prefs.val[3] + dl;

	*lat *= PI2DEG;
	*lon *= PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* Soldner-Koordinaten */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_SOLDNER (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[21] - 1.0)*prefs.val[22] + prefs.val[18];
	*up    = (prefs.val[20] + 1.0 - *line)*prefs.val[22] + prefs.val[19];
	
	return(1);
}
int dlr_earth_map_RU2LS_SOLDNER (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*sample = (*right - prefs.val[18])/prefs.val[22] + prefs.val[21] + 1.0;
	*line   = (prefs.val[19] - *up)/prefs.val[22] + prefs.val[20] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* EQUIDISTANT */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_EQUIDISTANT (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	df, dl, M;
	double	temp_lon;
	
	temp_lon = *lon*prefs.val[11] - prefs.val[10] * PI2DEG;
	if (temp_lon<-180.0) temp_lon += 360.0;
	else if (temp_lon>180.0) temp_lon -= 360.0;
	
   	df = *lat*DEG2PI;
  	dl = temp_lon*DEG2PI; 

	M = dlr_earth_map_ArcLen (df, prefs);
	
	*line = -M /prefs.val[14] + prefs.val[12] + 1.0;
   	*sample = prefs.val[0] * dl /prefs.val[14] + prefs.val[13] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_EQUIDISTANT (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	M, my, phi1,temp;

	M = (prefs.val[12] + 1.0 - *line)*prefs.val[14];
	my = M/prefs.val[19];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

   	*lat = phi1 * PI2DEG;
  	temp = (*sample - prefs.val[13] - 1.0)*prefs.val[14]/prefs.val[0];
	if (fabs (temp) < PI) *lon = (prefs.val[10] + temp)*prefs.val[11] * PI2DEG;
	else return (-1);

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* EQUIDISTANT */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_EQUIDISTANT (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{

	double	df, dl, M;
	double	temp_lon;
	
	temp_lon = *lon*prefs.val[11] - prefs.val[10] * PI2DEG;
	if (temp_lon<-180.0) temp_lon += 360.0;
	else if (temp_lon>180.0) temp_lon -= 360.0;
	
   	df = *lat*DEG2PI;
  	dl = temp_lon*DEG2PI; 

	M = dlr_earth_map_ArcLen (df, prefs);
	
	*up = M;
   	*right = prefs.val[0] * dl;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_EQUIDISTANT (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	M, my, phi1;

	M = *up;
	my = M/prefs.val[19];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

   	*lat = phi1 * PI2DEG;
  	*lon = (prefs.val[10] + *right/prefs.val[0])*prefs.val[11] * PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* EQUIDISTANT */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_EQUIDISTANT (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[13] - 1.0)*prefs.val[14];
	*up    =   (prefs.val[12] + 1.0 - *line)*prefs.val[14];
	
	return(1);
}
int dlr_earth_map_RU2LS_EQUIDISTANT (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*line   = (prefs.val[12] - *up)/prefs.val[14] + 1.0;
	*sample = (*right - prefs.val[13])/prefs.val[14] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* SINUSOIDAL */
/* Transformations between lat/lon and image coordinates line/sample */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2LS_SINUSOIDAL (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs)
{
	double	df, dl, M;
	double	temp_lon;
	
	temp_lon = *lon*prefs.val[11] - prefs.val[10] * PI2DEG;
	if (temp_lon<-180.0) temp_lon += 360.0;
	else if (temp_lon>180.0) temp_lon -= 360.0;
	
   	df = *lat*DEG2PI;
  	dl = temp_lon*DEG2PI; 

	M = dlr_earth_map_ArcLen (df, prefs);
	
	*line = -M /prefs.val[14] + prefs.val[12] + 1.0;
   	*sample = prefs.val[0] * dl /prefs.val[14]*cos(df)/sqrt(1.-prefs.val[1]*sin(df)*sin(df)) + prefs.val[13] + 1.0;
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2LL_SINUSOIDAL (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs)
{
	double	M, my, phi1, df, temp;

	M = (prefs.val[12] + 1.0 - *line)*prefs.val[14];
	my = M/prefs.val[19];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

   	*lat = phi1;
	df = *lat;
   	*lat *= PI2DEG;
	
	if ((PI/2.-fabs (df)) > 0.00001)
  		{
		temp = (*sample - prefs.val[13] - 1.0)*sqrt(1.-prefs.val[1]*sin(df)*sin(df))/cos(df)
		    *prefs.val[14]/prefs.val[0];
		if (fabs (temp) < PI) *lon = (prefs.val[10] + temp)*prefs.val[11] * PI2DEG;
		else return (-1);
		}
	else *lon = prefs.val[10] * prefs.val[11] * PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* SINUSOIDAL */
/* Transformations between lat/lon and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LL2RU_SINUSOIDAL (double *lat, double *lon, double *right, double *up, Earth_prefs prefs)
{

	double	df, dl, M;
	double	temp_lon;
	
	temp_lon = *lon*prefs.val[11] - prefs.val[10] * PI2DEG;
	if (temp_lon<-180.0) temp_lon += 360.0;
	else if (temp_lon>180.0) temp_lon -= 360.0;
	
   	df = *lat*DEG2PI;
  	dl = temp_lon*DEG2PI; 
	
	M = dlr_earth_map_ArcLen (df, prefs);
	
	*up = M;
   	*right = prefs.val[0] * dl * cos(df)/sqrt(1.-prefs.val[1]*sin(df)*sin(df));
	
	return(1);
}
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_RU2LL_SINUSOIDAL (double *right, double *up, double *lat, double *lon, Earth_prefs prefs)
{
	double	M, my, phi1, df;

	M = *up;
	my = M/prefs.val[19];
	phi1=my+ prefs.val[15]*sin(2.*my) + prefs.val[16]*sin(4.*my)
	       + prefs.val[17]*sin(6.*my) + prefs.val[18]*sin(8.*my);

   	*lat = phi1;
	df = *lat;
   	*lat *= PI2DEG;

	if ((PI/2.-fabs (df)) > 0.00001)
  		*lon = (prefs.val[10] + *right*sqrt(1.-prefs.val[1]*sin(df)*sin(df))/cos(df)/prefs.val[0])*prefs.val[11] * PI2DEG;
	else *lon = prefs.val[10] * prefs.val[11] * PI2DEG;

	return(1);
}
/* -------------------------------------------------------------------------------------------*/
/* SINUSOIDAL */
/* Transformations between image coordinates line/sample and metric map coordinates right/up in meter */
/* -------------------------------------------------------------------------------------------*/
int dlr_earth_map_LS2RU_SINUSOIDAL (double *line, double *sample, double *right, double *up, Earth_prefs prefs)
{
	
	*right = (*sample - prefs.val[13] - 1.0)*prefs.val[14];
	*up    =   (prefs.val[12] + 1.0 - *line)*prefs.val[14];
	
	return(1);
}
int dlr_earth_map_RU2LS_SINUSOIDAL (double *right, double *up, double *line, double *sample, Earth_prefs prefs)
{
	
	*line   = (prefs.val[12] - *up)/prefs.val[14] + 1.0;
	*sample = (*right - prefs.val[13])/prefs.val[14] + 1.0;
	
	return(1);
}
/* ------------------------------------------------------------ */
int dlr_earth_map_LL2RU (double *ll, double *ru, Earth_prefs prefs)
	{
	int 	callfunc;
	if (prefs.earth_case == 51)
		callfunc = dlr_earth_map_LL2RU_SINUSOIDAL  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 50)
		callfunc = dlr_earth_map_LL2RU_EQUIDISTANT  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 4)
		callfunc = dlr_earth_map_LL2RU_RD_Niederlande  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 3)
		callfunc = dlr_earth_map_LL2RU_SOLDNER  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 2)
		callfunc = dlr_earth_map_LL2RU_SLK      
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else 
		callfunc = dlr_earth_map_LL2RU_TransverseMercator 
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	return (1);
	}

/* ------------------------------------------------------------ */
int dlr_earth_map_RU2LL (double *ru, double *ll, Earth_prefs prefs)
	{
	int 	callfunc;
	if (prefs.earth_case == 51)
		callfunc = dlr_earth_map_RU2LL_SINUSOIDAL  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 50)
		callfunc = dlr_earth_map_RU2LL_EQUIDISTANT  
				(&ll[0], &ll[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 4)
		callfunc = dlr_earth_map_RU2LL_RD_Niederlande  
				(&ru[0], &ru[1], &ll[0], &ll[1], prefs);
	else if (prefs.earth_case == 3)
		callfunc = dlr_earth_map_RU2LL_SOLDNER  
				(&ru[0], &ru[1], &ll[0], &ll[1], prefs);
	else if (prefs.earth_case == 2)
		callfunc = dlr_earth_map_RU2LL_SLK      
				(&ru[0], &ru[1], &ll[0], &ll[1], prefs);
	else 
		callfunc = dlr_earth_map_RU2LL_TransverseMercator 
				(&ru[0], &ru[1], &ll[0], &ll[1], prefs);
	return (1);
	}

/* ------------------------------------------------------------ */
int dlr_earth_map_LS2RU (double *ls, double *ru, Earth_prefs prefs)
	{
	int 	callfunc;
	if (prefs.earth_case == 51)
		callfunc = dlr_earth_map_LS2RU_SINUSOIDAL  
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 50)
		callfunc = dlr_earth_map_LS2RU_EQUIDISTANT  
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 4)
		callfunc = dlr_earth_map_LS2RU_RD_Niederlande  
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 3)
		callfunc = dlr_earth_map_LS2RU_SOLDNER  
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	else if (prefs.earth_case == 2)
		callfunc = dlr_earth_map_LS2RU_SLK      
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	else 
		callfunc = dlr_earth_map_LS2RU_TransverseMercator 
				(&ls[0], &ls[1], &ru[0], &ru[1], prefs);
	return (1);
	}

/* ------------------------------------------------------------ */
int dlr_earth_map_RU2LS (double *ru, double *ls, Earth_prefs prefs)
	{
	int 	callfunc;
	if (prefs.earth_case == 51)
		callfunc = dlr_earth_map_RU2LS_SINUSOIDAL  
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	else if (prefs.earth_case == 50)
		callfunc = dlr_earth_map_RU2LS_EQUIDISTANT  
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	else if (prefs.earth_case == 4)
		callfunc = dlr_earth_map_RU2LS_RD_Niederlande  
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	else if (prefs.earth_case == 3)
		callfunc = dlr_earth_map_RU2LS_SOLDNER  
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	else if (prefs.earth_case == 2)
		callfunc = dlr_earth_map_RU2LS_SLK      
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	else 
		callfunc = dlr_earth_map_RU2LS_TransverseMercator 
				(&ru[0], &ru[1], &ls[0], &ls[1], prefs);
	return (1);
	}

/* ------------------------------------------------------------ */
int dlr_get_datumshift (char *filename, DatumShift *shift)
{
	int	i, n=0;
	double	val[7];
	double	alpha, beta, gamma, sin_a, sin_b, sin_g, cos_a, cos_b, cos_g;
	char	c_temp[120];
	FILE	*fp;
	
  	if ((fp = fopen ( filename, "r"))==(FILE *)NULL) return (0);
	
	while (1)
	    {
	    if ( (char *)NULL == fgets ( c_temp, 120, fp)) break;
	    if (strncmp(c_temp, "#", 1)==0) continue; 
	    sscanf ( c_temp, "%lf\n", &val[n]);
	    n++;
	    if (n==7) break;
	    }

	if (n!=7)
	    {
	    printf ("Error in dlr_get_datumshift !! ");
	    exit(0);
	    }

	shift->d[0]    = val[0];
	shift->d[1]    = val[1];
	shift->d[2]    = val[2];
	shift->m       = 1.0 + val[3] * 1.e-6;

	alpha = val[4] * DEG2PI;
	beta  = val[5] * DEG2PI;
	gamma = val[6] * DEG2PI;
	
	sin_a = sin (alpha);
	sin_b = sin (beta);
	sin_g = sin (gamma);
	cos_a = cos (alpha);
	cos_b = cos (beta);
	cos_g = cos (gamma);


/*
	shift->rotmat[0][0] = cos_b * cos_g;
	shift->rotmat[1][0] = cos_a * sin_g  +  sin_a * sin_b * cos_g;
	shift->rotmat[2][0] = sin_a * sin_g  -  cos_a * sin_b * cos_g;
	shift->rotmat[0][1] =-cos_b * sin_g;
	shift->rotmat[1][1] = cos_a * cos_g  -  sin_a * sin_b * sin_g;
	shift->rotmat[2][1] = sin_a * cos_g  +  cos_a * sin_b * sin_g;
	shift->rotmat[0][2] = sin_b;
	shift->rotmat[1][2] =-sin_a * cos_b;
	shift->rotmat[2][2] = cos_a * cos_b;
*/
	shift->rotmat[0][0] = 1.0;
	shift->rotmat[1][0] = -gamma;
	shift->rotmat[2][0] = beta;
	shift->rotmat[0][1] = gamma;
	shift->rotmat[1][1] = 1.0;
	shift->rotmat[2][1] = -alpha;
	shift->rotmat[0][2] = -beta;
	shift->rotmat[1][2] =  alpha;
	shift->rotmat[2][2] = 1.0;

	fclose(fp);

	return (1);
}
/* ------------------------------------------------------------ */
void dlr_datumshift (double *in_vec, DatumShift shift)
{
	int	i;
	double temp_vec[3], temp_vec2[3];
	
	for (i=0; i<3; i++) temp_vec[i] = (in_vec[i] - shift.d[i]) / shift.m;
	for (i=0; i<3; i++) temp_vec2[i] = ( shift.rotmat[0][i]*temp_vec[0] + 
					     shift.rotmat[1][i]*temp_vec[1] + 
					     shift.rotmat[2][i]*temp_vec[2] );
	for (i=0; i<3; i++) in_vec[i] = temp_vec2[i];
	
	return;
}
/* ------------------------------------------------------------ */
void dlr_datumshift_inv (double *in_vec, DatumShift shift)
{
	int	i;
	double temp_vec[3];
	
	for (i=0; i<3; i++) temp_vec[i] = ( shift.rotmat[i][0]*in_vec[0] + 
					    shift.rotmat[i][1]*in_vec[1] + 
					    shift.rotmat[i][2]*in_vec[2] ) * shift.m;
	for (i=0; i<3; i++) in_vec[i] = temp_vec[i] + shift.d[i];
	
	return;
}
/* ------------------------------------------------------------ */
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrmapsub.imake
/* IMAKE file for subroutine dlrmapsub */

#define SUBROUTINE dlrmapsub

#define MODULE_LIST dlrmapsub.c

#define USES_ANSI_C

#define HW_SUBLIB

#define LIB_P1SUB
$ Return
$!#############################################################################
