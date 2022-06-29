$!****************************************************************************
$!
$! Build proc for MIPL module hwpho
$! VPACK Version 1.9, Wednesday, August 20, 2003, 16:23:52
$!
$! Execute by entering:		$ @hwpho
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
$ write sys$output "*** module hwpho ***"
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
$ write sys$output "Invalid argument given to hwpho.com file -- ", primary
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
$   if F$SEARCH("hwpho.imake") .nes. ""
$   then
$      vimake hwpho
$      purge hwpho.bld
$   else
$      if F$SEARCH("hwpho.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwpho
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwpho.bld "STD"
$   else
$      @hwpho.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwpho.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwpho.com -
	-s hwpho.c -
	-i hwpho.imake -
	-o hwphoeco.hlp hwphoeco2.hlp hwphoco.hlp -
	-t tzhwpho.c tzhwpho.imake tzhwpho.pdf txhwpho.f txhwpho.imake -
	   txhwpho.pdf tsthwpho.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwpho.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "xvmaininc.h"		/* Standard VICAR Include File		*/
/*#include "errdefs.h"*/
#include "ftnbridge.h"		/* FORTRAN bridge Include File 		*/
#include <limits.h>		/* containes computer limits		*/
#include <math.h>		/* Standard math library include	*/
/*#include <stdio.h>*/		/* Standard C I/O Include File		*/
/*#include <varargs.h> /*		/* variable paramter list		*/

#include "dlrpho.h" 		/* photometry Include File		*/


/*************************************************************************

				hwphoco

**************************************************************************/

/*************************************************************************

FORTRAN Callable Version	xhwphoco

**************************************************************************/

void
FTN_NAME(xhwphoco)(pho_obj,DirectionsSurf,DirectionsEllips,MessDirectionsInc,MessDirectionsView,TargDirectionsInc,TargDirectionsView,MessSunShadow,MessViewShadow,TargSunShadow,TargViewShadow,phoCoVal,status)


PHO *pho_obj;
double *DirectionsSurf;
double *DirectionsEllips;
double *MessDirectionsInc;
double *MessDirectionsView;
double *TargDirectionsInc;
double *TargDirectionsView;
int *MessSunShadow;
int *MessViewShadow;
int *TargSunShadow;
int *TargViewShadow;
double *phoCoVal;
int *status;

{


*status = hwphoco(*pho_obj,
DirectionsSurf,
DirectionsEllips,
MessDirectionsInc,
MessDirectionsView,
TargDirectionsInc,
TargDirectionsView,
*MessSunShadow,
*MessViewShadow,
*TargSunShadow,
*TargViewShadow,
phoCoVal);

return;

}


/*************************************************************************

	C Callable Version of hwphoco

*************************************************************************/


int hwphoco( 
 PHO pho,
 double DirectionsSurf[3],
 double DirectionsEllips[3],
 double MessDirectionsInc[3],
 double MessDirectionsView[3],
 double TargDirectionsInc[3],
 double TargDirectionsView[3],
 int MessSunShadow,
 int MessViewShadow,
 int TargSunShadow,
 int TargViewShadow,
 double *phoCoVal  ) 


{

  int	 status;
  PHO_ILLUM Millum, Tillum;
  PHO pho_obj; 

  pho_obj = pho;

  
  Millum.mode = illDTMDir;
  Tillum.mode = illDTMDir;

  Millum.type.sunshadow = MessSunShadow;
  Millum.type.viewshadow = MessViewShadow;
  Tillum.type.sunshadow = TargSunShadow;
  Tillum.type.viewshadow = TargViewShadow;

  Millum.direction.inc[0] = -MessDirectionsInc[0];
  Millum.direction.inc[1] = -MessDirectionsInc[1];
  Millum.direction.inc[2] = -MessDirectionsInc[2];
  Tillum.direction.inc[0] = -TargDirectionsInc[0];
  Tillum.direction.inc[1] = -TargDirectionsInc[1];
  Tillum.direction.inc[2] = -TargDirectionsInc[2];
  Millum.direction.em[0] = -MessDirectionsView[0];
  Millum.direction.em[1] = -MessDirectionsView[1];
  Millum.direction.em[2] = -MessDirectionsView[2];
  Tillum.direction.em[0] = -TargDirectionsView[0];
  Tillum.direction.em[1] = -TargDirectionsView[1];
  Tillum.direction.em[2] = -TargDirectionsView[2];
  memcpy(&(Millum.direction.ellips), DirectionsEllips, 3 * sizeof(double));
  memcpy(&(Tillum.direction.ellips), DirectionsEllips, 3 * sizeof(double));
  memcpy(&(Millum.direction.surf), DirectionsSurf, 3 * sizeof(double));
  memcpy(&(Tillum.direction.surf), DirectionsSurf, 3 * sizeof(double));


  status = phoCorrect ( pho_obj, &Millum, &Tillum, phoCoVal );
  	if (status =! phoSUCCESS) { *phoCoVal = 1.0; }


  return status;
}


/*************************************************************************

				hwphoeco

**************************************************************************/

/*************************************************************************

FORTRAN Callable Version	xhwphoeco

**************************************************************************/
void FTN_NAME(xhwphoeco)(pho_obj,DirectionsEllips,MessDirectionsInc,MessDirectionsView,TargIncAng,TargViewAng,TargAzimAng,phoCoVal,status)


PHO *pho_obj;
double *DirectionsEllips;
double *MessDirectionsInc;
double *MessDirectionsView;
double *TargIncAng;
double *TargViewAng;
double *TargAzimAng;
double *phoCoVal;
int *status;

{


*status = hwphoeco(*pho_obj,
DirectionsEllips,
MessDirectionsInc,
MessDirectionsView,
*TargIncAng,
*TargViewAng,
*TargAzimAng,
phoCoVal);

return;

}



/*************************************************************************

	C Callable Version of hwphoeco

*************************************************************************/

int hwphoeco( 
 PHO pho,
 double DirectionsEllips[3],
 double MessDirectionsInc[3],
 double MessDirectionsView[3],
 double TargIncAng,
 double TargViewAng,
 double TargAzimAng,
 double *phoCoVal  ) 


{

  int	 status;
  PHO_ILLUM Millum, Tillum;
  PHO pho_obj; 

/*char msg[133],cval1[133];*/

  pho_obj = pho;

  
  Millum.mode = illEllDir;
  Tillum.mode = illEllCos;

  Millum.type.sunshadow = illNoShadow;
  Millum.type.viewshadow = illNoShadow;
  Tillum.type.sunshadow = illNoShadow;
  Tillum.type.viewshadow = illNoShadow;

  Millum.direction.inc[0] = -MessDirectionsInc[0];
  Millum.direction.inc[1] = -MessDirectionsInc[1];
  Millum.direction.inc[2] = -MessDirectionsInc[2];
  Millum.direction.em[0]  = -MessDirectionsView[0];
  Millum.direction.em[1]  = -MessDirectionsView[1];
  Millum.direction.em[2]  = -MessDirectionsView[2];
  Tillum.cos.inc          = cos(RETURN_RADIANS(TargIncAng));
  Tillum.cos.em           = cos(RETURN_RADIANS(TargViewAng));
  Tillum.cos.phas         = COSPHAS(TargIncAng,TargViewAng,TargAzimAng);

  memcpy(&(Millum.direction.ellips), DirectionsEllips, 3 * sizeof(double));


  status = phoCorrect ( pho_obj, &Millum, &Tillum, phoCoVal );
  	if (status =! phoSUCCESS) { *phoCoVal = 1.0; }


  return status;
}




/*************************************************************************

				hwphoeco2

**************************************************************************/

/*************************************************************************

FORTRAN Callable Version	xhwphoeco2

**************************************************************************/
void FTN_NAME(xhwphoeco2)(pho_obj,DirectionsEllips,MessDirectionsInc,MessDirectionsView,TargIncAng,TargViewAng,TargAzimAng,PhoLimb,PhoTerm,phoCoVal,status)


PHO *pho_obj;
double *DirectionsEllips;
double *MessDirectionsInc;
double *MessDirectionsView;
double *TargIncAng;
double *TargViewAng;
double *TargAzimAng;
double *PhoLimb;
double *PhoTerm;
double *phoCoVal;
int *status;

{


*status = hwphoeco2(*pho_obj,
DirectionsEllips,
MessDirectionsInc,
MessDirectionsView,
*TargIncAng,
*TargViewAng,
*TargAzimAng,
*PhoLimb,
*PhoTerm,
phoCoVal);

return;

}


/*************************************************************************

	C Callable Version of hwphoeco2

*************************************************************************/

int hwphoeco2( 
 PHO pho,
 double DirectionsEllips[3],
 double MessDirectionsInc[3],
 double MessDirectionsView[3],
 double TargIncAng,
 double TargViewAng,
 double TargAzimAng,
 double PhoLimb,
 double PhoTerm,
 double *phoCoVal  ) 


{

  int	 status;
  double dumy;
  double DirectionsInc[3];
  double DirectionsView[3];
  PHO_ILLUM Millum, Tillum;
  PHO pho_obj; 

/*char msg[133],cval1[133];*/

  pho_obj = pho;

  
/*  Millum.mode = illEllDir; */
  Millum.mode = illEllCos;
  Tillum.mode = illEllCos;

  Millum.type.sunshadow = illNoShadow;
  Millum.type.viewshadow = illNoShadow;
  Tillum.type.sunshadow = illNoShadow;
  Tillum.type.viewshadow = illNoShadow;

  DirectionsInc[0] = -MessDirectionsInc[0];
  DirectionsInc[1] = -MessDirectionsInc[1];
  DirectionsInc[2] = -MessDirectionsInc[2];
  DirectionsView[0]  = -MessDirectionsView[0];
  DirectionsView[1]  = -MessDirectionsView[1];
  DirectionsView[2]  = -MessDirectionsView[2];

  Millum.cos.inc          = - DIRCOS(DirectionsEllips,DirectionsInc);
  Millum.cos.em           = DIRCOS(DirectionsEllips,DirectionsView);
  Millum.cos.phas         = - DIRCOS(DirectionsView,DirectionsInc);

  Tillum.cos.inc          = cos(RETURN_RADIANS(TargIncAng));
  Tillum.cos.em           = cos(RETURN_RADIANS(TargViewAng));
  Tillum.cos.phas         = COSPHAS(TargIncAng,TargViewAng,TargAzimAng);

  memcpy(&(Millum.direction.ellips), DirectionsEllips, 3 * sizeof(double));


  dumy = RETURN_DEGREES( acos( Millum.cos.inc ) );
  dumy = 90.0 - dumy;

  if ( dumy <= PhoTerm) 
  {
    status = 1.0e-5;
    *phoCoVal = DBL_MIN;
    return status;
  }

  dumy = RETURN_DEGREES( acos( Millum.cos.em ) );
  dumy = 90.0e0 - dumy;

  if ( dumy <= PhoLimb) 
  {
    status = 1.0e-5;
    return status;
  }


  status = phoCorrect ( pho_obj, &Millum, &Tillum, phoCoVal );
  switch (status)
  {
    case phoSUCCESS:
	return status;
    case phoCORRECT_LIMITS:
 	return status;
    case phoANG_LIMITS:
	return status;
   default:
	 *phoCoVal = 1.0;
  }

  return status;
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwpho.imake
#define SUBROUTINE  	hwpho

#define MODULE_LIST  	hwpho.c 

#define USES_ANSI_C

#define FTN_STRING
#define HW_SUBLIB
#define LIB_P2SUB
$ Return
$!#############################################################################
$Other_File:
$ create hwphoeco.hlp
NAME OF PROGRAM:	hwphoeco
	
Purpose:	Returns the value for the photometric correction (ellipsoid 
		case).
	
	
Function:	Returns the value for the photometric correction from messured 
		nativ illumination geometry (given by directions as comming 
		from SPICE-Interface) to targeted artificial illumination 
		geometry (given by angles).  

		It fills the illumination unions and calls the photometry 
		routine phoCorrect.

		For the supported functions see the help of the 
		photometry routine phoBidiRef

	
Requirements and Dependencies:

Libraries required to run program:	P2SUB

Subroutines required to run program:	pho_routines package

Include Files required to run program:	dlrpho.h, pho.fin

Main Program from which subroutine will be called:	HWGEOM


Calling Sequence:		

calling from C :	include "dlrpho.h"
			PHO PHO_DATA;
			double DirEll[3];
			double MDirInc[3], MDirView[3];
			double TargIncAng, TargViewAng, TargAzimAng;
			double phoCorVal;
			int status;
			...
			status = hwphoeco( PHO_DATA, DirEll,
			MDirInc, MDirVie, TargIncAng, TargViewAng, TargAzimAng,
			&phoCorVal );


calling from FORTRAN :	INCLUDE 'pho'
			INTEGER PHO_DATA
			DOUBLE PRECISION illuArray(*) 
			DOUBLE PRECISION phoCorVal
			DOUBLE PRECISION DirEll
			DOUBLE PRECISION MDirInc, MDirView
			DOUBLE PRECISION TargIncAng, TargViewAng, TargAzimAng
			INTEGER status
			...
			call xhwphoco( PHO_DATA, DirEll,
		+	MDirInc, MDirView, TargIncAng, TargViewAng, TargAzimAng,
		+	phoCorVal, status )

Necessary include files
from calling routine 
or program:		dlrpho.h (for C routines )
			pho.fin ( for FORTRAN routines )




VICAR Parameter:

Name		Type	In/Out	Description
	

PHO_DATA	PHO	Input	Address of the photometric data object

DirSurf      double[3]	Input	Direction of the surface normal 
				(directed aware from the surface)

DirEll	     double[3]	Input	Direction of the ellipsoid normal 
				(directed aware from the surface)

MDirInc	     double[3]	Input	Measured Sun direction
				(directed to the sun)

MDirView     double[3]	Input	Measured observer direction 
				(directed to the planet)

TargIncAng   double	Input	Target artifitial incidence angle in degree
				(angle between ellipsoid normal and 
				illumination direction)

TargViewAng  double	Input	Target artififitial emission angle in degree
				(angle between ellipsoid normal and 
				emmission direction)

TargAzimAng  double	Input	Target artififitial azimuth angle in degree
				(related to the sun direction)

phoCorVal	double	Output	Photometric correction value 

status		int	Output	Error status:
				phoSUCCESS - success
				phoFAILURE - failed
				phoFUNC_NOT_SET - failed : 
					photometric function not set in the PHO
				phoKEYWD_NOT_SET - failed :
					one of the required parameter values has
							not been set in the PHO
				phoINVALID_KEYWD - failed :
					one of the parameterkeywords is invalid
				phoARGUMENT_OUT_OF_RANGE-failed:
					one of the arguments is out of the valid
					range



Software Platform:		VICAR (VMS/UNIX)

Hardware Platform:		No particular hardware required;
				tested on SUN_OS, SUN_SOLARIS, VAX, AXP

Programming Language:		C

Date of specification:		March '95

Cognizant programmer:		Friedel Oschuetz, DLR
				Institute of Planetary Exploration
				DLR
				12484 Berlin (FRG)


History:			March '95, F. Oschuetz, original			
$!-----------------------------------------------------------------------------
$ create hwphoeco2.hlp
NAME OF PROGRAM:	hwphoeco2
	
Purpose:	Returns the value for the photometric correction (ellipsoid 
		case).
	
	
Function:	Returns the value for the photometric correction from messured 
		nativ illumination geometry (given by directions as comming 
		from SPICE-Interface) to targeted artificial illumination 
		geometry (given by angles).  

		It fills the illumination unions and calls the photometry 
		routine phoCorrect.

		For the supported functions see the help of the 
		photometry routine phoBidiRef

	
Requirements and Dependencies:

Libraries required to run program:	P2SUB

Subroutines required to run program:	pho_routines package

Include Files required to run program:	dlrpho.h, pho.fin

Main Program from which subroutine will be called:	HWGEOM


Calling Sequence:		

calling from C :	include "dlrpho.h"
			PHO PHO_DATA;
			double DirEll[3];
			double MDirInc[3], MDirView[3];
			double TargIncAng, TargViewAng, TargAzimAng;
 			double PhoLimb, PhoTerm;
			double phoCorVal;
			int status;
			...
			status = hwphoeco2( PHO_DATA, DirEll,
			MDirInc, MDirVie, TargIncAng, TargViewAng, TargAzimAng,
			PhoLimb, PhoTerm, &phoCorVal );


calling from FORTRAN :	INCLUDE 'pho'
			INTEGER PHO_DATA
			DOUBLE PRECISION illuArray(*) 
			DOUBLE PRECISION DirEll
			DOUBLE PRECISION MDirInc, MDirView
			DOUBLE PRECISION TargIncAng, TargViewAng, TargAzimAng
 			DOUBLE PhoLimb, PhoTerm
			DOUBLE PRECISION phoCorVal
			INTEGER status
			...
			call xhwphoco2( PHO_DATA, DirEll,
		+	MDirInc, MDirView, TargIncAng, TargViewAng, TargAzimAng,
		+	PhoLimb, PhoTerm, phoCorVal, status )

Necessary include files
from calling routine 
or program:		dlrpho.h (for C routines )
			pho.fin ( for FORTRAN routines )




VICAR Parameter:

Name		Type	In/Out	Description
	

PHO_DATA	PHO	Input	Address of the photometric data object

DirSurf       double[3]	Input	Direction of the surface normal 
				(directed aware from the surface)

DirEll	      double[3]	Input	Direction of the ellipsoid normal 
				(directed aware from the surface)

MDirInc	      double[3]	Input	Measured Sun direction
				(directed to the sun)

MDirView      double[3]	Input	Measured observer direction 
				(directed to the planet)

TargIncAng   	double	Input	Target artifitial incidence angle in degree
				(angle between ellipsoid normal and 
				illumination direction)

TargViewAng  	double	Input	Target artififitial emission angle in degree
				(angle between ellipsoid normal and 
				emmission direction)

TargAzimAng  	double	Input	Target artififitial azimuth angle in degree
				(related to the sun direction)

LimitIncAng	double	Input	Limit incidence angle, used if incidence angle  
				is larger then LimIncAng

LimitViewAng	double	Input	Limit viewing angle, used if emission angle is  
				larger then LimitViewAng

LimitPhasAng	double	Input	Limit phase angle, used if phase angle is  
				smaller then LimitPhasAng

MaxPhoFac	 double	Input	This is the maximum permitted intensity 
				factor to correct for the limb and terminator 
				darkening caused by the photometric function. 
				If the determined photometric correction factor 
				is greater than this, the DN will be marked as 
				non-valid (see above).

MinPhoFac	 double	Input	This is the minimum permitted intensity
				factor to correct for the back scattering  
				caused by the photometric function. If the  
				determinedphotometric correction factor is less
				than this, the DN will be marked as non-valid.

PhoLimb		 double	Input	Is a floating point number specifying the 
				closest distance of the anchor points to the 
				limb in degrees. If an anchor point lies 
				outside,  its DN will be marked as non-valid 
				(see above). 
				if PHO_LIMB > 0 --> pixels are only inside the 
						    limb margin
				if PHO_LIMB < 0 --> pixels may be also outside 
						    the limb margin (can occur 
						    if there are hills). 

PhoTerm 	 double	Input	Is a floating point number specifying the 
				closest distance of the anchor points to the 
				terminator
				in degree. If an anchor point lies outside, 
				its DN will be marked as non-valid (see above). 
				if PHO_TERM > 0 -->  pixels are only inside the 
						     terminator margin
				if PHO_TERM < 0 -->  pixels may be also outside 
						     the terminator margin (can 
						     occur if there are hills).
				default = 0.0


phoCorVal	double	Output	Photometric correction value 

status		int	Output	Error status:
				phoSUCCESS - success
				phoFAILURE - failed
				phoFUNC_NOT_SET - failed : 
					photometric function not set in the PHO
				phoKEYWD_NOT_SET - failed :
					one of the required parameter values has
							not been set in the PHO
				phoINVALID_KEYWD - failed :
					one of the parameterkeywords is invalid
				phoARGUMENT_OUT_OF_RANGE - failed:
					one of the arguments is out of the valid
					range
				phoANG_LIMITS - Success:
					But at least one of the angle limits is
					overflown. The related angle is set to 
					this limit.
				phoBDRF_LIMITS - Success:
					But a BDRF limit is overflown. The 
					related BDRF value is set to this limit.
				phoFUNC_LIMITS - Success:
					But a photometric function value limit 
					is overflown. The related function 
					value is set to this limit.
				phoCORRECT_LIMITS - Success:
					But a limit for the photometric 
					correction  factor is overflown.
					The related BDRF value is set to this 
					limit. 
				1.0e-5 - Success:
					But the point is in the limb or termimator. The related function value is set to 



Software Platform:		VICAR (VMS/UNIX)

Hardware Platform:		No particular hardware required;
				tested on SUN_OS, SUN_SOLARIS, VAX, AXP

Programming Language:		C

Date of specification:		March '95

Cognizant programmer:		Friedel Oschuetz, DLR
				Institute of Planetary Exploration
				DLR
				12484 Berlin (FRG)


History:			March '95, F. Oschuetz, original			
$!-----------------------------------------------------------------------------
$ create hwphoco.hlp
Name of Program:	hwphoco
	
Purpose:	Returns the value for the photometric correction (DTM case).
	
	
Function:	Returns the value for the photometric correction from messured 
		nativ illumination geometry (given by directions as comming 
		from SPICE-Interface) to targeted artificial illumination 
		geometry (given by directions as comming from SPICE-Interface).
		The DTM is determined by the ellipsoid normal and the surface 
		normal.

		It fills the illumination union and calls the photometry 
		routine phoCorrect.

		For the supported functions see the help of the 
		photometry routine phoBidiRef

	
Requirements and Dependencies:

Libraries required to run program:	P2SUB

Subroutines required to run program:	pho_routines package

Include Files required to run program:	dlrpho.h, pho.fin

Main Program from which subroutine will be called:	HWORTHO


Calling Sequence:		

calling from C :	include "dlrpho.h"
			PHO PHO_DATA;
			double DirSurf[3], DirEll[3];
			double MDirInc[3], MDirView[3];
			double TDirInc[3], TDirView[3];
			int MSunShadow, MViewShadow;
			int TSunShadow, TViewShadow;
			double phoCorVal;
			int status;
			...
			status = hwphoco( PHO_DATA, DirSurf, DirEll,
			MDirInc, MDirVie, TDirInc, TDirView,
			MSunShadow, MViewShadow, TSunShadow, TViewShadow,
			&phoCorVal );


calling from FORTRAN :	INCLUDE 'pho'
			INTEGER PHO_DATA
			DOUBLE PRECISION illuArray(*) 
			DOUBLE PRECISION phoCorVal
			DOUBLE PRECISION DirSurf, DirEll
			DOUBLE PRECISION MDirInc, MDirView
			DOUBLE PRECISION TDirInc, TDirView
			INTEGER MSunShadow, MViewShadow, 	
			INTEGER TSunShadow, TViewShadow, 	
			INTEGER status
			...
			call xhwphoco( PHO_DATA, DirSurf, DirEll,
		+	MDirInc, MDirView, TDirInc, TDirView,
		+	MSunShadow, MViewShadow, TSunShadow, TViewShadow,
		+	phoCorVal, status )

Necessary include files
from calling routine 
or program:		dlrpho.h (for C routines )
			pho.fin ( for FORTRAN routines )




VICAR Parameter:

Name		Type	In/Out	Description
	

PHO_DATA	PHO	Input	Address of the photometric data object

DirSurf      double[3]	Input	Direction of the surface normal 
				(directed aware from the surface)

DirEll	     double[3]	Input	Direction of the ellipsoid normal 
				(directed aware from the surface)

MDirInc	     double[3]	Input	Measured Sun direction
				(directed to the sun)

MDirView     double[3]	Input	Measured observer direction 
				(directed to the planet)

TDirInc	     double[3]	Input	Target artifitial sun dierection
				(directed to the sun)

TDirView     double[3]	Input	Target artififitial observer direction
				(directed to the planet)

MSunShadow	int	Input	The parameter indicates if the point is 
				in the "Sun Shadow"(for measured illumination )

TSunShadow	int	Input	The parameter indicates if the point is 
				in the "Sun Shadow"(for target illumination )

MViewShadow  	int	Input	The parameter indicates if the point is 
				in the "View Shadow"(for measured viewing 
				direction )

TViewShadow  	int	Input	The parameter indicates if the point is 
				in the "View Shadow"(for target viewing 
				direction )

phoCorVal	double	Output	Photometric correction value 

status		int	Output	Error status:
				phoSUCCESS - success
				phoFAILURE - failed
				phoFUNC_NOT_SET - failed : 
					photometric function not set in the PHO
				phoKEYWD_NOT_SET - failed :
					one of the required parameter values has
							not been set in the PHO
				phoINVALID_KEYWD - failed :
					one of the parameterkeywords is invalid
				phoARGUMENT_OUT_OF_RANGE-failed:
					one of the arguments is out of the valid
					range



Software Platform:		VICAR (VMS/UNIX)

Hardware Platform:		No particular hardware required;
				tested on SUN_OS, SUN_SOLARIS, VAX, AXP

Programming Language:		C

Date of specification:		July '94

Cognizant programmer:		Friedel Oschuetz, DLR
				Institute of Planetary Exploration
				DLR
				12484 Berlin (FRG)


History:			Jun '94, F. Oschuetz, original			
$ Return
$!#############################################################################
$Test_File:
$ create tzhwpho.c
#include <math.h>
#include "vicmain_c"
#include "dlrpho.h"

/* Program TZHWPHO  */

void main44()
{
  int cnt, def, i, ival, ival1, num, illMode, MillMode, TillMode, shadow, status;

  double dval, dval1, phoFuncVal;
  char illuMod[20];
  char ctemp[133], subcmd[9], cval[133], cval1[133], msg[133],
   keylist[phoMAX_PARAM_PER_FUNC][phoMAX_KEYWD_LENGTH+1];
  char *pkeylist;

 PHO pho_obj;
 double DirectionsSurf[3];
 double DirectionsEllips[3];
 double MessDirectionsInc[3];
 double MessDirectionsView[3];
 double TargDirectionsInc[3];
 double TargDirectionsView[3];
 double TargIncAng, TargViewAng, TargAzimAng, TargPhaseAng;
 double PhoLimb;
 double PhoTerm;
 int MessSunShadow;
 int MessViewShadow;
 int TargSunShadow;
 int TargViewShadow;
 double phoCoVal;

  float temp, tempAr[3];

/*  zveaction("sau",""); */

  zvmessage( " ", "");
  zvmessage(" program TZHWPHO", "");
  zvmessage( " ", "");

  status = phoInit( &pho_obj);

/* get the photometric function and there input parameters from the PDF     */
/* and set these in the photometric object :				    */

  status = phoGetParms( pho_obj);

/* get the number of parameters of the current photometric function : */

  status = phoGetKeys( pho_obj, 0, &num); 
/* get the list of parameter keywords for the current photometric function : */

  pkeylist = (char *)malloc( phoMAX_PARAM_PER_FUNC * ( phoMAX_KEYWD_LENGTH+1 ) * sizeof(char));
  pkeylist = (char *)keylist;

  status = phoGetKeys( pho_obj, pkeylist, &num);

/* get the photometric function name : */

  status = phoGetFunc( pho_obj, cval1);
  strcpy( msg, " Function =" );
  strcat( msg, cval1);
  zvmessage( msg, "");

  strcpy( msg, " Parameter number = " );
  sprintf( cval1, " %i", num);
  strcat( msg, cval1);
  zvmessage( msg, "");


  for (i=0; i<num; i++) {

    status = phoGetVal( pho_obj, keylist[i], &dval1);
    strcpy( msg, "  ");
    strcat( msg, keylist[i]);
    strcat( msg, " = ");
    sprintf( cval1, " %10.3e", dval1);
    strcat( msg, cval1);
    zvmessage( msg, "");
  }

/* reads in the function arguments from the PDF : */


    MillMode = illDTMDir;
    TillMode = illDTMDir;		/* test for an DTM surface */

    zvp("M_SUN_SHADOW", &ctemp, &cnt);
    if (EQUAL(ctemp,"NOSHADOW")){ MessSunShadow=illNoShadow;}
    else 			{MessSunShadow=illShadow;}

    zvp("M_VIEW_SHADOW", &ctemp, &cnt);
    if (EQUAL(ctemp,"NOSHADOW")) {MessViewShadow=illNoShadow;}
    else 			{MessViewShadow=illShadow;}

    zvp("T_SUN_SHADOW", &ctemp, &cnt);
    if (EQUAL(ctemp,"NOSHADOW")) {TargSunShadow=illNoShadow;}
    else 			{TargSunShadow=illShadow;}

    zvp("T_VIEW_SHADOW", &ctemp, &cnt);
    if (EQUAL(ctemp,"NOSHADOW")) {TargViewShadow=illNoShadow;}
    else 			{TargViewShadow=illShadow;}



    zvp("M_INC_DIR", tempAr, &cnt);
    MessDirectionsInc[0] = (double )tempAr[0];
    MessDirectionsInc[1] = (double )tempAr[1];
    MessDirectionsInc[2] = (double )tempAr[2];

    zvp("M_VIEW_DIR", tempAr, &cnt);
    MessDirectionsView[0] = (double )tempAr[0];
    MessDirectionsView[1] = (double )tempAr[1];
    MessDirectionsView[2] = (double )tempAr[2];

    zvp("T_INC_DIR", tempAr, &cnt);
    TargDirectionsInc[0] = (double )tempAr[0];
    TargDirectionsInc[1] = (double )tempAr[1];
    TargDirectionsInc[2] = (double )tempAr[2];

    zvp("T_VIEW_DIR", tempAr, &cnt);
    TargDirectionsView[0] = (double )tempAr[0];
    TargDirectionsView[1] = (double )tempAr[1];
    TargDirectionsView[2] = (double )tempAr[2];

    zvp("SURF_DIR", tempAr, &cnt);
    DirectionsSurf[0] = (double )tempAr[0];
    DirectionsSurf[1] = (double )tempAr[1];
    DirectionsSurf[2] = (double )tempAr[2];

    zvp("ELL_DIR", tempAr, &cnt);
    DirectionsEllips[0] = (double )tempAr[0];
    DirectionsEllips[1] = (double )tempAr[1];
    DirectionsEllips[2] = (double )tempAr[2];



/* get the correction value from hwphoco : */

   status = hwphoco(pho_obj,
	DirectionsSurf,
 	DirectionsEllips,
	MessDirectionsInc,
 	MessDirectionsView,
	TargDirectionsInc,
	TargDirectionsView,
	MessSunShadow,
	MessViewShadow,
	TargSunShadow,
	TargViewShadow,
	&phoCoVal  );

  zvmessage( " ", "");
  strcpy( msg, " Correction Value from hwphoco =");
  sprintf( cval1, " %10.3e", phoCoVal);
  strcat( msg, cval1);
  zvmessage( msg, "");


/* get the correction value from hwphoeco : */

  TargIncAng  = acos(DIRCOS(DirectionsEllips,TargDirectionsInc) ) * 180.0 / M_PI;
  TargViewAng = 180.0 - acos(DIRCOS(DirectionsEllips,TargDirectionsView))*180.0/M_PI;
  TargPhaseAng = 180.0 - acos(DIRCOS(TargDirectionsView,TargDirectionsInc) ) * 180.0 / M_PI;
  TargAzimAng = acos((cos(TargPhaseAng*M_PI/180.0)-cos(TargIncAng*M_PI/180.0)*cos(TargViewAng*M_PI/180.0))/(sin(TargIncAng*M_PI/180.0)*sin(TargViewAng*M_PI/180.0)))*180.0/M_PI;

/*TargIncAng  = 30;
TargViewAng = 0;
TargAzimAng = 180;
TargPhaseAng = acos(COSPHAS(TargIncAng,TargViewAng,TargAzimAng))*180.0/M_PI;

  zvmessage( " ", "");
  strcpy( msg, " Target incidence angle =");
  sprintf( cval1, " %10.3e", TargIncAng);
  strcat( msg, cval1);
  zvmessage( msg, "");
  strcpy( msg, " Target emission angle  =");
  sprintf( cval1, " %10.3e", TargViewAng);
  strcat( msg, cval1);
  zvmessage( msg, "");
  strcpy( msg, " Target phase angle     =");
  sprintf( cval1, " %10.3e", TargPhaseAng);
  strcat( msg, cval1);
  zvmessage( msg, "");
  strcpy( msg, " Target azimuth angle   =");
  sprintf( cval1, " %10.3e", TargAzimAng);
  strcat( msg, cval1);
  zvmessage( msg, "");
*/

  status = hwphoeco(pho_obj,
 	DirectionsEllips,
	MessDirectionsInc,
 	MessDirectionsView,
	TargIncAng,
	TargViewAng,
	TargAzimAng,
	&phoCoVal  );

  strcpy( msg, " Correction Value from hwphoeco = ");
  sprintf( cval1, " %10.3e", phoCoVal);
  strcat( msg, cval1);
  zvmessage( msg, "");
  zvmessage( " ", "");

  zvp("PHO_LIMB", &temp, &cnt);
  PhoLimb = (double )temp;
  zvp("PHO_TERM", &temp, &cnt);
  PhoTerm = (double )temp;

  status = hwphoeco2(pho_obj,
 	DirectionsEllips,
	MessDirectionsInc,
 	MessDirectionsView,
	TargIncAng,
	TargViewAng,
	TargAzimAng,
	PhoLimb,
	PhoTerm,
	&phoCoVal  );

  strcpy( msg, " Correction Value from hwphoeco2 = ");
  sprintf( cval1, " %10.3e", phoCoVal);
  strcat( msg, cval1);
  zvmessage( msg, "");
  zvmessage( " ", "");

  status = phoFree( pho_obj);

  return;





}
$!-----------------------------------------------------------------------------
$ create tzhwpho.imake

#define PROGRAM tzhwpho

#define MODULE_LIST tzhwpho.c 

#define USES_ANSI_C

#define MAIN_LANG_C

#define TEST

/********************************************
LOCAL LIBRARY and DEBUGGER for development */

#define LIB_LOCAL
#define DEBUG
#define LIB_P2SUB_DEBUG

/*******************************************/

#define LIB_HWSUB
#define LIB_P2SUB
#define LIB_RTL
#define LIB_TAE

$!-----------------------------------------------------------------------------
$ create tzhwpho.pdf
process execute=tzhwpho help=*



	! dummy inputs :

!	parm inp	type=(string,32) count=0:1	default=inp.img
!	parm out	type=(string,32) count=0:1	default=out.img

	! photometric functions :

	parm PHO_FUNC type=(string,32) count=1 		+
			valid = (			+
				NONE,			+
				PAR_FILE,		+
				LAMBERT,		+
				MINNAERT,		+
				IRVINE,			+
				VEVERKA,		+
				BURATTI1,		+
				BURATTI2,		+
				BURATTI3,		+
				MOSHER,			+
				LUMME_BOWEL_HG1,	+
				HAPKE_81_LE2,		+
				HAPKE_81_COOK,		+
				HAPKE_86_HG1,		+
				HAPKE_86_HG2,		+
				HAPKE_86_LE2,		+
				HAPKE_HG1_DOM,		+
				REGNER_HAPKE_HG1, 	+
				ATMO_CORR_REGNER	+
				) 	default=MINNAERT
	! illumination conditions :

!	parm M_ILL_MODE	type=(string,32) count=1	default=illDTMDir
!	parm T_ILL_MODE	type=(string,32) count=1	default=illDTMDir

	parm M_INC_DIR real  count=(0:3)			+
			default=(-1.542e+8,-1.607e+8,3.0e+7)
	parm M_VIEW_DIR real  count=(0:3)			+
			default=(0.81997,0.56783,-0.07229)

	parm T_INC_DIR real  count=(0:3)			+
			default=(-1.542e+8,-1.607e+8,3.0e+7)
	parm T_VIEW_DIR real  count=(0:3)			+
			default=(0.81997,-0.56783,0.07229)

	parm SURF_DIR real  count=(0:3)				+
			default=(-0.8199,-0.5678,-0.07303)
	parm ELL_DIR real  count=(0:3)				+
			default=(-0.8199,-0.5678,-0.07303)

	parm M_SUN_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm M_VIEW_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm T_SUN_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm T_VIEW_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm L_INC_A 	real	default=89.95

	parm L_EMI_A 	real	default=89.95

	parm L_PHAS_A 	real	default=0.05

	parm MA_PHO_C 	real 	default=5.0

	parm MI_PHO_C 	real	default=1.0e-5

	parm PHO_LIMB 	real	default=0.0

	parm PHO_TERM 	real	default=0.0



  ! SPICE parameters (HRSC/WAOSS parameters) :

!	parm GECALDIR	type=(string,80) count = 0:2		+
!			default = (HRSC_GEOCAL_DIR, WAOSS_GEOCAL_DIR)
!	parm GECALDAT	type=(string,32) count = 0:1		+
!			default = HRSC_GEOCAL_DATE
!	parm BSPFILE	type=(string,32) count = 0:3		+
!			default = HWSPICE_BSP
!	parm SUNFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_SUN
!	parm BCFILE	type=(string,32) count = 0:6		+
!			default = HWSPICE_BC
!	parm TSCFILE	type=(string,32) count = 0:6		+
!			default = HWSPICE_TSC
!	parm TIFFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TI
!	parm TPCFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TPC
!	parm TLSFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TLS
!	parm PHO_DEI	type=(string,32) count = 0:1		+
!			default = PHO_DEI
	
  ! photometric parameters:

       parm PHO_PAR_FILE	string  count=0:1 	default=--

       parm ALBEDO 	real count=0:1 valid=(0:1)	default=1.0
       parm EXPONENT 	real count=0:1 valid=(0:1)	default=0.5
       parm A_VEVERKA 	real count=0:1 			default=--
       parm B_VEVERKA 	real count=0:1 			default=--
       parm C_VEVERKA 	real count=0:1 			default=--
       parm D_VEVERKA 	real count=0:1 			default=-- 
       parm MO_EXP1 	real count=0:1 			default=--
       parm MO_EXP2 	real count=0:1 			default=--
       parm E_BURATTI 	real count=0:1 			default=--
       parm DEN_SOIL 	real count=0:1 			default=--
       parm W_SOIL 	real count=0:1 valid=(0:1)	default=--
       parm HG1_SOIL 	real count=0:1 			default=--
       parm HG2_SOIL 	real count=0:1 			default=--
       parm HG_ASY_SOIL real count=0:1 			default=--
       parm LE1_SOIL 	real count=0:1 			default=--
       parm LE2_SOIL 	real count=0:1 			default=--
       parm H_SHOE 	real count=0:1 			default=--
       parm B_SHOE 	real count=0:1 			default=--
       parm H_CBOE 	real count=0:1 			default=--
       parm B_CBOE 	real count=0:1 			default=--
       parm THETA 	real count=0:1 			default=--
       parm COOK 	real count=0:1 			default=--
       parm TAU_ATM 	real count=0:1			default=--
       parm W_ATM 	real count=0:1 valid=(0:1)	default=--
       parm HG1_ATM 	real count=0:1 			default=--
       parm IRV_EXP1 	real count=0:1 			default=--
       parm IRV_EXP2 	real count=0:1 			default=--

end-proc
 
.Title
 TPHO_ROUTINES_C - test general photometric subroutine package

.HELP
 C test program for the general photometric subroutine package

.LEVEL1

.VARI PHO_FUNC
photometric function

.VARI M_INC_DIR
meassured incidence direction

.VARI M_VIEW_DIR
meassured viewing direction

.VARI T_INC_DIR
target incidence direction

.VARI T_VIEW_DIR
target viewing direction

.VARI SURF_DIR
surface normale

.VARI ELL_DIR
ellipsoid normale

.VARI M_SUN_SHADOW
in sun or shadow

.VARI M_VIEW_SHADOW
in viewing shadow or not

.VARI T_SUN_SHADOW
target in sun or shadow

.VARI T_VIEW_SHADOW
target in viewing shadow or not

.VARI L_INC_A
limit of incidence angle

.VARI L_EMI_A
limit of emission angle

.VARI L_PHAS_A
limit of phase angle

.VARI MA_PHO_F

.VARI MI_PHO_F

.VARI PHO_LIMB

.VARI PHO_TERM

.VARI PHO_PAR_FILE

.VARI ALBEDO
albedo

.VARI EXPONENT
Minnaert's konstant

.VARI A_VEVERKA 
Veverka parameter

.VARI B_VEVERKA
Veverka parameter

.VARI C_VEVERKA
Veverka parameter

.VARI D_VEVERKA
Veverka parameter

.VARI MO_EXP2
Mosher's exponent

.VARI MO_EXP1
Mosher's exponent

.VARI E_BURATTI
Buratti's parameter

.VARI DEN_SOIL
Hapke parameter

.VARI W_SOIL
Hapke parameter

.VARI HG1_SOIL
Hapke Parameter

.VARI HG2_SOIL
Hapke parameter

.VARI HG_ASY_SOIL
Hapke parameter

.VARI LE1_SOIL
Hapke parameter

.VARI LE2_SOIL
Hapke parameter

.VARI H_SHOE
Hapke parameter

.VARI B_SHOE
Hapke parameter

.VARI H_CBOE
Hapke-Dominique parameter

.VARI B_CBOE
Hapke-Dominique parameter

.VARI THETA
Hapke parameter

.VARI COOK
Hapke-Cook parameter

.VARI TAU_ATM
Regner parameter

.VARI W_ATM
Regner parameter

.VARI HG1_ATM
Regner parameter

.VARI IRV_EXP1
Irvine parameter

.VARI IRV_EXP2
Irvine parameter

.VARI INC_ANG
incidence angle

.VARI EM_ANG
emission angle

.VARI PHAS_ANG
phase angle

.LEVEL2

.VARI PHO_FUNC
Name of the photometric function

.VARI M_INC_DIR

.VARI M_INC_DIR

.VARI M_VIEW_DIR

.VARI T_INC_DIR

.VARI T_VIEW_DIR

.VARI SURF_DIR

.VARI ELL_DIR

.VARI M_SUN_SHADOW

.VARI M_VIEW_SHADOW

.VARI T_SUN_SHADOW

.VARI T_VIEW_SHADOW

.VARI L_INC_A

.VARI L_EMI_A

.VARI L_PHAS_A

.VARI MA_PHO_F

.VARI MI_PHO_F

.VARI PHO_LIMB

.VARI PHO_TERM

.VARI PHO_PAR_FILE

.VARI ALBEDO
Albedo -  valid for the Lambert and Minnaert photometric functions.

.VARI EXPONENT
Exponent - the geometrical constant k of the Minnaert photometric function.

.VARI A_VEVERKA 
Parameter of the Veverka, Squyres-Veverka and Mosher photometric functions.

.VARI B_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI C_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI D_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI E_BURATTI
Buratti's parameter for modification of the Veverka photometric function.

.VARI MO_EXP1
Modification of the coefficient k in the Minnaert part 
of Mosher's photometric function (goes along with MO_EXP2).

.VARI MO_EXP2
Modification of the coefficient k in the Minnaert part 
of Mosher's photometric function (goes along with MO_EXP1).

.VARI DEN_SOIL
Specific volume density of the soil.

.VARI W_SOIL
Single-scattering albedo of the soil particles. It characterizes the efficiencu of an average particle to scatter and absorb light. 
One of the classical Hapke parameter.

.VARI HG1_SOIL
Parameter of the first term of the Henyey-Greenstein soil particle 
phase function.

.VARI HG2_SOIL
Parameter of the second term of the Henyey-Greenstein soil particle 
phase function.

.VARI HG_ASY_SOIL
Asymmetry parameter (weight of the two terms 
in the Henyey-Greenstein soil phase function).

.VARI LE1_SOIL
Parameter of the first term of the Legendre-Polynomial soil particle 
phase function.

.VARI LE2_SOIL
Parameter of the second term of the Legendre-Polynomial soil particle 
phase function.

.VARI H_SHOE
Parameter which characterizes the soil structure in the terms of porosity, particle-size distribution, and rate of compaction with depth (angular width of opposition surge due to shadowing). 
One of the classical Hapke parameter.

.VARI B_SHOE
Opposition magnitude coefficient (total amplitude of the opposition surge due to shadowing).
One of the classical Hapke parameter. 
B_SHOE=S(0)/(W_SOIL*p(0))
with p(0) - soil phase function
S(0) - opposition surge amplitude term which characterizes the contribution of 
light scattered from near the front surface of individual particles at zero 
phase 

.VARI H_CBOE
Parameter of the coherent backscattering ( width of theopposition surge due 
to the backscatter ).

.VARI B_CBOE
Opposition magnitude coefficient of the coherent backscattering 
(height of opposition surge due to backscatter). 

.VARI THETA
Average topographic slope angle of surface roughness at subresolution scale.
One of the classical Hapke parameter. 

.VARI COOK
 Parameter of the Cook's modification of the old Hapke function.

.VARI TAU_ATM
Optical depth of the atmosphere.

.VARI W_ATM
Single scattering albedo of the atmospheric aerosols.

.VARI HG1_ATM
Parameter of the first term of the Henyey-Greenstein atmospheric phase function.

.VARI IRV_EXP1
Parameter of the Irvine photometric function.

.VARI IRV_EXP2
Parameter of the Irvine photometric function.


.VARI INC_ANG
Incidence angle in degree.

.VARI EM_ANG
Emission angle in degree.

.VARI PHAS_ANG
Phase angle in degree.

.END
$!-----------------------------------------------------------------------------
$ create txhwpho.f
c  Program TXPHO_ROUTINES

	INCLUDE 'VICMAIN_FOR'

	SUBROUTINE MAIN44

        INCLUDE 'pho'


	integer pho, status, num
	character*132 msg, ctemp
	character*(pho_max_func_name_length) cval1
	character*(pho_max_keywd_length) keylist(pho_max_param_func)
 	integer*4 MessSunShadow, MessViewShadow 
 	integer*4 TargSunShadow, TargViewShadow
	real*4 tempAr(3)
	real*4 temp
	real*8 dval1
	real*8 DirectionsSurf(3), DirectionsEllips(3)
	real*8 MessDirectionsInc(3), MessDirectionsView(3)
	real*8 TargDirectionsInc(3), TargDirectionsView(3)
	real*8 TargIncAng, TargViewAng, TargAzimAng, TargPhaseAng
	real*8 PhoLimb, PhoTerm
	real*8 phoCoVal

	call xvmessage( ' ', ' ')
	call xvmessage(' program TXHWPHO', ' ')
	call xvmessage( ' ', ' ')

c	call xveaction('sau ',' ')

	call pho_init( pho, status)
c get the photometric function and there input parameters from the PDF
c and set these in the photometric object :

	call pho_get_Parms( pho, status)


c get the photometric function name :

	call pho_get_func( pho, cval1, status)

	msg = ' Function = '//cval1
	call xvmessage( msg, ' ')

c get the list of parameter keywords for the current photometric function : 

	call pho_get_keys( pho, keylist, num, status)

	  write( msg, 1000)  num
1000	  format( ' Parameter number = ', i4)
	  call xvmessage( msg, ' ')

	do i=1,num
	  call pho_get_val( pho, keylist(i), dval1, status)
	  write( msg, 1010) keylist(i), dval1
1010	  format('  ', a<pho_max_keywd_length>, ' = ', 1pe10.3)
	  call xvmessage( msg, ' ')
	enddo

c  reads in the function arguments from the PDF :


	MillMode = illDTMDir
	TillMode = illDTMDir

	call xvp('M_SUN_SHADOW', ctemp, cnt)
	IF ( ctemp .eq. 'NOSHADOW') THEN
		MessSunShadow = illNoShadow
	ELSE IF ( ctemp .eq. 'SHADOW')  THEN
		MessSunShadow = illShadow
	ELSE
	  	call xvmessage( 'M_SUN_SHADOW invalid keyword' , ' ')
	  	call abend
	ENDIF
	

	call xvp('M_VIEW_SHADOW', ctemp, cnt)
	IF ( ctemp .eq. 'NOSHADOW')  THEN
		MessViewShadow = illNoShadow
	ELSE IF ( ctemp .eq. 'SHADOW') THEN
		MessViewShadow = illShadow
	ELSE
	  	call xvmessage( 'M_VIEW_SHADOW invalid keyword' , ' ')
	  	call abend
	ENDIF

	call xvp('T_SUN_SHADOW', ctemp, cnt)
	IF ( ctemp .eq. 'NOSHADOW') THEN
		TargSunShadow = illNoShadow
	ELSE IF ( ctemp .eq. 'SHADOW') THEN
		TargSunShadow = illShadow
	ELSE
	  	call xvmessage( 'T_SUN_SHADOW invalid keyword' , ' ')
	  	call abend
	ENDIF

	call xvp('T_VIEW_SHADOW', ctemp, cnt)
	IF ( ctemp .eq. 'NOSHADOW') THEN
		TargViewShadow = illNoShadow
	ELSE IF ( ctemp .eq. 'SHADOW') THEN
		TargViewShadow = illShadow
	ELSE
	  	call xvmessage( 'T_VIEW_SHADOW invalid keyword' , ' ')
	  	call abend
	ENDIF

	call xvp('M_INC_DIR', tempAr, cnt)
	MessDirectionsInc(1) = tempAr(1)
	MessDirectionsInc(2) = tempAr(2)
	MessDirectionsInc(3) = tempAr(3)

	call xvp('M_VIEW_DIR', tempAr, cnt)
	MessDirectionsView(1) = tempAr(1)
	MessDirectionsView(2) = tempAr(2)
	MessDirectionsView(3) = tempAr(3)

	call xvp('T_INC_DIR', tempAr, cnt)
	TargDirectionsInc(1) = tempAr(1)
	TargDirectionsInc(2) = tempAr(2)
	TargDirectionsInc(3) = tempAr(3)

	call xvp('T_VIEW_DIR', tempAr, cnt)
	TargDirectionsView(1) = tempAr(1)
	TargDirectionsView(2) = tempAr(2)
	TargDirectionsView(3) = tempAr(3)

	call xvp('SURF_DIR', tempAr, cnt)
	DirectionsSurf(1) = tempAr(1)
	DirectionsSurf(2) = tempAr(2)
	DirectionsSurf(3) = tempAr(3)

	call xvp('ELL_DIR', tempAr, cnt)
	DirectionsEllips(1) = tempAr(1)
	DirectionsEllips(2) = tempAr(2)
	DirectionsEllips(3) = tempAr(3)

c get the correction value from xhwphoco :

   	call xhwphoco( pho,
     + 			DirectionsSurf,
     + 			DirectionsEllips,
     + 			MessDirectionsInc,
     + 			MessDirectionsView,
     + 			TargDirectionsInc,
     + 			TargDirectionsView,
     + 			MessSunShadow,
     + 			MessViewShadow,
     + 			TargSunShadow,
     + 			TargViewShadow,
     + 			phoCoVal,
     + 			status  )


	call xvmessage( ' ', ' ')
	write( msg, 1020)  phoCoVal
1020	format( ' Correction Value from xhwphoco = ', G14.4E3)	
	call xvmessage( msg, ' ')

c get the correction value from xhwphoco :

	dval1 = 	DirectionsEllips(1) * DirectionsEllips(1) 
     +                + DirectionsEllips(2) * DirectionsEllips(2) 
     +                + DirectionsEllips(3) * DirectionsEllips(3)

  	TargIncAng  =  TargDirectionsInc(1) * TargDirectionsInc(1) 
     +                + TargDirectionsInc(2) * TargDirectionsInc(2) 
     +                + TargDirectionsInc(3) * TargDirectionsInc(3) 

  	TargIncAng  = acos( ( DirectionsEllips(1) * TargDirectionsInc(1) 
     +                + DirectionsEllips(2) * TargDirectionsInc(2) 
     +                + DirectionsEllips(3) * TargDirectionsInc(3) )   
     +                / sqrt( dval1 * TargIncAng) )
     +                * 180.0 / pi



	dval1 = 	DirectionsEllips(1) * DirectionsEllips(1) 
     +                + DirectionsEllips(2) * DirectionsEllips(2) 
     +                + DirectionsEllips(3) * DirectionsEllips(3)

  	TargViewAng = TargDirectionsView(1) * TargDirectionsView(1) 
     +                + TargDirectionsView(2) * TargDirectionsView(2) 
     +                + TargDirectionsView(3) * TargDirectionsView(3)

  	TargViewAng = 180.0 - acos(
     +                (DirectionsEllips(1) * TargDirectionsView(1) 
     +                + DirectionsEllips(2) * TargDirectionsView(2) 
     +                + DirectionsEllips(3) * TargDirectionsView(3) )  
     +                / sqrt( dval1  * TargViewAng ) )
     +                * 180.0 / pi

  	TargPhaseAng = 180.0 - acos( 
     +                ( TargDirectionsView(1) * TargDirectionsInc(1) 
     +                + TargDirectionsView(2) * TargDirectionsInc(2)
     +                + TargDirectionsView(3) * TargDirectionsInc(3) )
     +                /sqrt((TargDirectionsView(1)*TargDirectionsView(1) 
     +                + TargDirectionsView(2) * TargDirectionsView(2) 
     +                + TargDirectionsView(3) * TargDirectionsView(3) )
     +                * ( TargDirectionsInc(1) * TargDirectionsInc(1) 
     +                + TargDirectionsInc(2) * TargDirectionsInc(2) 
     +                + TargDirectionsInc(3) * TargDirectionsInc(3))) )
     +                * 180.0 / pi

	TargAzimAng = acos( (cos ( TargPhaseAng * rad_deg ) 
     +                - cos( TargIncAng * rad_deg ) * cos( TargViewAng 
     +                * rad_deg ) ) / ( sin( TargIncAng * rad_deg ) 
     +                * sin( TargViewAng * rad_deg ) ) ) * 180.0 / pi


c	call xvmessage( ' ', ' ')
c	write( msg, 1030)  TargIncAng
c 1030	format( 'TargIncAng = ', F7.2)
c	call xvmessage( msg, ' ')
c	call xvmessage( ' ', ' ')
c	write( msg, 1040)  TargViewAng
c 1040	format( 'TargViewAng = ', F7.2)
c	call xvmessage( msg, ' ')
c	call xvmessage( ' ', ' ')
c	write( msg, 1050)  TargPhaseAng
c 1050	format( 'TargPhaseAng = ', F7.2)
c	call xvmessage( msg, ' ')
c	call xvmessage( ' ', ' ')
c	write( msg, 1060)  TargAzimAng
c 1060	format( 'TargAzimAng = ', F7.2)
c	call xvmessage( msg, ' ')
c	call xvmessage( ' ', ' ')

  	call xhwphoeco(pho,
     + 			DirectionsEllips,
     + 			MessDirectionsInc,
     + 			MessDirectionsView,
     + 			TargIncAng,
     + 			TargViewAng,
     + 			TargAzimAng,
     + 			phoCoVal,
     + 			status  )

	write( msg, 1070)  phoCoVal
1070	format( ' Correction Value from hwphoeco = ', G14.4E3)
	call xvmessage( msg, ' ')
	call xvmessage( ' ', ' ')

	call xvp('PHO_LIMB', temp, cnt)
	PhoLimb = temp
	call xvp('PHO_TERM', temp, cnt)
	PhoTerm = temp
  	call xhwphoeco2(pho,
     + 			DirectionsEllips,
     + 			MessDirectionsInc,
     + 			MessDirectionsView,
     + 			TargIncAng,
     + 			TargViewAng,
     + 			TargAzimAng,
     + 			phoCoVal,
     +			PhoLimb,
     +			PhoTerm,
     + 			status  )

	write( msg, 1080)  phoCoVal
1080	format( ' Correction Value from hwphoeco = ', G14.4E3)
	call xvmessage( msg, ' ')
	call xvmessage( ' ', ' ')


	call pho_free( pho, status)
	return
	end
$!-----------------------------------------------------------------------------
$ create txhwpho.imake

#define PROGRAM txhwpho

#define MODULE_LIST txhwpho.f 

#define FTNINC_LIST pho

#define MAIN_LANG_FORTRAN
#define USES_FORTRAN

#define FTN_STRING

#define TEST

/********************************************
LOCAL LIBRARY and DEBUGGER for development */

#define LIB_LOCAL
#define DEBUG
#define LIB_P2SUB_DEBUG

/*******************************************/

#define LIB_HWSUB
#define LIB_P2SUB
#define LIB_RTL
#define LIB_TAE

$!-----------------------------------------------------------------------------
$ create txhwpho.pdf
process execute=txhwpho help=*



	! dummy inputs :

!	parm inp	type=(string,32) count=0:1	default=inp.img
!	parm out	type=(string,32) count=0:1	default=out.img

	! photometric functions :

	parm PHO_FUNC type=(string,32) count=1 		+
			valid = (			+
				NONE,			+
				PAR_FILE,		+
				LAMBERT,		+
				MINNAERT,		+
				IRVINE,			+
				VEVERKA,		+
				BURATTI1,		+
				BURATTI2,		+
				BURATTI3,		+
				MOSHER,			+
				LUMME_BOWEL_HG1,	+
				HAPKE_81_LE2,		+
				HAPKE_81_COOK,		+
				HAPKE_86_HG1,		+
				HAPKE_86_HG2,		+
				HAPKE_86_LE2,		+
				HAPKE_HG1_DOM,		+
				REGNER_HAPKE_HG1, 	+
				ATMO_CORR_REGNER	+
				) 	default=MINNAERT
	! illumination conditions :

!	parm M_ILL_MODE	type=(string,32) count=1	default=illDTMDir
!	parm T_ILL_MODE	type=(string,32) count=1	default=illDTMDir

	parm M_INC_DIR real  count=(0:3)			+
			default=(-1.542e+8,-1.607e+8,3.0e+7)
	parm M_VIEW_DIR real  count=(0:3)			+
			default=(0.81997,0.56783,-0.07229)

	parm T_INC_DIR real  count=(0:3)			+
			default=(-1.542e+8,-1.607e+8,3.0e+7)
	parm T_VIEW_DIR real  count=(0:3)			+
			default=(0.81997,-0.56783,0.07229)

	parm SURF_DIR real  count=(0:3)				+
			default=(-0.8199,-0.5678,-0.07303)
	parm ELL_DIR real  count=(0:3)				+
			default=(-0.8199,-0.5678,-0.07303)

	parm M_SUN_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm M_VIEW_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm T_SUN_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm T_VIEW_SHADOW type=(string,9) count=1 		+
			valid=(SHADOW, NOSHADOW)  default=NOSHADOW

	parm L_INC_A 	real	default=89.95

	parm L_EMI_A 	real	default=89.95

	parm L_PHAS_A 	real	default=0.05

	parm MA_PHO_C 	real 	default=5.0

	parm MI_PHO_C 	real	default=1.0e-5

	parm PHO_LIMB 	real	default=0.0

	parm PHO_TERM 	real	default=0.0



  ! SPICE parameters (HRSC/WAOSS parameters) :

!	parm GECALDIR	type=(string,80) count = 0:2		+
!			default = (HRSC_GEOCAL_DIR, WAOSS_GEOCAL_DIR)
!	parm GECALDAT	type=(string,32) count = 0:1		+
!			default = HRSC_GEOCAL_DATE
!	parm BSPFILE	type=(string,32) count = 0:3		+
!			default = HWSPICE_BSP
!	parm SUNFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_SUN
!	parm BCFILE	type=(string,32) count = 0:6		+
!			default = HWSPICE_BC
!	parm TSCFILE	type=(string,32) count = 0:6		+
!			default = HWSPICE_TSC
!	parm TIFFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TI
!	parm TPCFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TPC
!	parm TLSFILE	type=(string,32) count = 0:1		+
!			default = HWSPICE_TLS
!	parm PHO_DEI	type=(string,32) count = 0:1		+
!			default = PHO_DEI
	
  ! photometric parameters:

       parm PHO_PAR_FILE	string  count=0:1 	default=--

       parm ALBEDO 	real count=0:1 valid=(0:1)	default=1.0
       parm EXPONENT 	real count=0:1 valid=(0:1)	default=0.5
       parm A_VEVERKA 	real count=0:1 			default=--
       parm B_VEVERKA 	real count=0:1 			default=--
       parm C_VEVERKA 	real count=0:1 			default=--
       parm D_VEVERKA 	real count=0:1 			default=-- 
       parm MO_EXP1 	real count=0:1 			default=--
       parm MO_EXP2 	real count=0:1 			default=--
       parm E_BURATTI 	real count=0:1 			default=--
       parm DEN_SOIL 	real count=0:1 			default=--
       parm W_SOIL 	real count=0:1 valid=(0:1)	default=--
       parm HG1_SOIL 	real count=0:1 			default=--
       parm HG2_SOIL 	real count=0:1 			default=--
       parm HG_ASY_SOIL real count=0:1 			default=--
       parm LE1_SOIL 	real count=0:1 			default=--
       parm LE2_SOIL 	real count=0:1 			default=--
       parm H_SHOE 	real count=0:1 			default=--
       parm B_SHOE 	real count=0:1 			default=--
       parm H_CBOE 	real count=0:1 			default=--
       parm B_CBOE 	real count=0:1 			default=--
       parm THETA 	real count=0:1 			default=--
       parm COOK 	real count=0:1 			default=--
       parm TAU_ATM 	real count=0:1			default=--
       parm W_ATM 	real count=0:1 valid=(0:1)	default=--
       parm HG1_ATM 	real count=0:1 			default=--
       parm IRV_EXP1 	real count=0:1 			default=--
       parm IRV_EXP2 	real count=0:1 			default=--

end-proc
 
.Title
 TXHWPHO - test hw-specific photometric subroutine package 

.HELP
 C test program for the general photometric subroutine package

.LEVEL1

.VARI PHO_FUNC
photometric function

.VARI L_INC_A
limit of incidence angle

.VARI L_EMI_A
limit of emission angle

.VARI L_PHAS_A
limit of phase angle

.VARI MA_PHO_F

.VARI MI_PHO_F

.VARI PHO_LIMB

.VARI PHO_TERM

.VARI ALBEDO
albedo

.VARI EXPONENT
Minnaert's konstant

.VARI A_VEVERKA 
Veverka parameter

.VARI B_VEVERKA
Veverka parameter

.VARI C_VEVERKA
Veverka parameter

.VARI D_VEVERKA
Veverka parameter

.VARI MO_EXP2
Mosher's exponent

.VARI MO_EXP1
Mosher's exponent

.VARI E_BURATTI
Buratti's parameter


.VARI DEN_SOIL
Hapke parameter

.VARI W_SOIL
Hapke parameter

.VARI HG1_SOIL
Hapke Parameter

.VARI HG2_SOIL
Hapke parameter

.VARI HG_ASY_SOIL
Hapke parameter

.VARI LE1_SOIL
Hapke parameter

.VARI LE2_SOIL
Hapke parameter

.VARI H_SHOE
Hapke parameter

.VARI B_SHOE
Hapke parameter

.VARI H_CBOE
Hapke-Dominique parameter

.VARI B_CBOE
Hapke-Dominique parameter

.VARI THETA
Hapke parameter

.VARI COOK
Hapke-Cook parameter

.VARI TAU_ATM
Regner parameter

.VARI W_ATM
Regner parameter

.VARI HG1_ATM
Regner parameter

.VARI IRV_EXP1
Irvine parameter

.VARI IRV_EXP2
Irvine parameter

.VARI INC_ANG
incidence angle

.VARI EM_ANG
emission angle

.VARI PHAS_ANG
phase angle

.LEVEL2

.VARI PHO_FUNC
Name of the photometric function

.VARI L_INC_A

.VARI L_EMI_A

.VARI L_PHAS_A

.VARI MA_PHO_F

.VARI MI_PHO_F

.VARI PHO_LIMB

.VARI PHO_TERM

.VARI ALBEDO
Albedo -  valid for the Lambert and Minnaert photometric functions.

.VARI EXPONENT
Exponent - the geometrical constant k of the Minnaert photometric function.

.VARI A_VEVERKA 
Parameter of the Veverka, Squyres-Veverka and Mosher photometric functions.

.VARI B_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI C_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI D_VEVERKA
Parameter of the Veverka, Mosher, Squyres-Veverka and Buratti 
photometric functions.

.VARI E_BURATTI
Buratti's parameter for modification of the Veverka photometric function.

.VARI MO_EXP1
Modification of the coefficient k in the Minnaert part 
of Mosher's photometric function (goes along with MO_EXP2).

.VARI MO_EXP2
Modification of the coefficient k in the Minnaert part 
of Mosher's photometric function (goes along with MO_EXP1).

.VARI DEN_SOIL
Specific volume density of the soil.

.VARI W_SOIL
Single-scattering albedo of the soil particles. It characterizes the efficiencu of an average particle to scatter and absorb light. 
One of the classical Hapke parameter.

.VARI HG1_SOIL
Parameter of the first term of the Henyey-Greenstein soil particle 
phase function.

.VARI HG2_SOIL
Parameter of the second term of the Henyey-Greenstein soil particle 
phase function.

.VARI HG_ASY_SOIL
Asymmetry parameter (weight of the two terms 
in the Henyey-Greenstein soil phase function).

.VARI LE1_SOIL
Parameter of the first term of the Legendre-Polynomial soil particle 
phase function.

.VARI LE2_SOIL
Parameter of the second term of the Legendre-Polynomial soil particle 
phase function.

.VARI H_SHOE
Parameter which characterizes the soil structure in the terms of porosity, particle-size distribution, and rate of compaction with depth (angular width of opposition surge due to shadowing). 
One of the classical Hapke parameter.

.VARI B_SHOE
Opposition magnitude coefficient (total amplitude of the opposition surge due to shadowing).
One of the classical Hapke parameter. 
B_SHOE=S(0)/(W_SOIL*p(0))
with p(0) - soil phase function
S(0) - opposition surge amplitude term which characterizes the contribution of 
light scattered from near the front surface of individual particles at zero 
phase 

.VARI H_CBOE
Parameter of the coherent backscattering ( width of theopposition surge due 
to the backscatter ).

.VARI B_CBOE
Opposition magnitude coefficient of the coherent backscattering 
(height of opposition surge due to backscatter). 

.VARI THETA
Average topographic slope angle of surface roughness at subresolution scale.
One of the classical Hapke parameter. 

.VARI COOK
 Parameter of the Cook's modification of the old Hapke function.

.VARI TAU_ATM
Optical depth of the atmosphere.

.VARI W_ATM
Single scattering albedo of the atmospheric aerosols.

.VARI HG1_ATM
Parameter of the first term of the Henyey-Greenstein atmospheric phase function.

.VARI IRV_EXP1
Parameter of the Irvine photometric function.

.VARI IRV_EXP2
Parameter of the Irvine photometric function.


.VARI INC_ANG
Incidence angle in degree.

.VARI EM_ANG
Emission angle in degree.

.VARI PHAS_ANG
Phase angle in degree.

.END
$!-----------------------------------------------------------------------------
$ create tsthwpho.pdf
procedure tsthwpho
body
tzhwpho
txhwpho
end-proc
$ Return
$!#############################################################################
