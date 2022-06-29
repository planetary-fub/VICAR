$!****************************************************************************
$!
$! Build proc for MIPL module dlrspice
$! VPACK Version 1.9, Wednesday, March 31, 2004, 18:24:07
$!
$! Execute by entering:		$ @dlrspice
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
$ write sys$output "*** module dlrspice ***"
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
$ write sys$output "Invalid argument given to dlrspice.com file -- ", primary
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
$   if F$SEARCH("dlrspice.imake") .nes. ""
$   then
$      vimake dlrspice
$      purge dlrspice.bld
$   else
$      if F$SEARCH("dlrspice.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrspice
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrspice.bld "STD"
$   else
$      @dlrspice.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrspice.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrspice.com -
	-s dlrspice.c -
	-i dlrspice.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrspice.c
$ DECK/DOLLARS="$ VOKAGLEVE"

#include "dlrspice.h"
#include <math.h>
/* ------------------------------------------------------------ */
/* this file contains the following fuctions:                   */

/* void dlrsurfpt (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double point[3],
                int    *found); */

/* void dlrsurfptl_llr (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double long_axis,
                double latlong,
                double *radius,
                int    *found); */

/* void dlrsurfptl_xyz (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double long_axis,
                double point[3],
                int    *found); */

/* void dlrsurfnm (double a,
                double b,
                double c, 
                double point[3],
                double normal[3]); */
/* void dlrmxm (double M1[3][3], double M2[3][3], double MOUT[3][3]); */
/* void dlrmtxm (double M1[3][3], double M2[3][3], double MOUT[3][3]); */
/* void dlrmxmt (double M1[3][3], double M2[3][3], double MOUT[3][3]); */ 
/* void dlrmxv (double M[3][3], double *V, double *VOUT);  */
/* void dlrmtxv (double M[3][3], double *V, double *VOUT);  */
/* void dlropk2m (double omega, double phi, double kappa, double MOUT[3][3]); */
/* void dlrkpo2m (double kappa, double phi, double omega, double MOUT[3][3]); */
/* void dlrkop2m (double kappa, double omega, double phi, double MOUT[3][3]); */
/* void dlrkok2m (double kappa2, double omega, double kappa1, double MOUT[3][3]); */
/* void dlrm2kop (double M[3][3], double *kappa, double *omega, double *phi); */
/* void dlrvhat (double *V, double *VOUT); */
/* double dlrvnorm (double *V); */
/* double dlrvdot (double *V1, double *V2); */
/* void dlrvlcom (double A, double *V1, double B, double *V2, double *SUMOUT); */
/* void dlrreclat ( double *xyz, double *radius, double *lon, double *lat); */
/* void dlrlatrec ( double radius, double lon, double lat, double *xyz); */
/* void dlrrotate ( double ANGLE, int IAXIS, double MOUT[3][3]); */
/* void hrscori (double position1[3], double position2[3], double rbp[3][3], 
	  			     float *scori); */
/* ------------------------------------------------------------ */
/* ********************************************************************** */

/* Procedure      SURFPT ( Surface point on an ellipsoid ) */
/* NAIF 0047 routine rewritten in C by Th. Roatsch, DLR 25-Nov-1998 */
 
void dlrsurfpt ( positn, u, a, b, c, point, found)
 
/*      Determine the intersection of a line-of-sight vector with the
C      surface of an ellipsoid.
C
C$ Copyright
C
C     Copyright (1995), California Institute of Technology.
C     U.S. Government sponsorship acknowledged.
C
C$ Required_Reading
C
C     None.
C
C$ Keywords
C
C      ELLIPSOID,  GEOMETRY
C */
 
      double     positn[3];
      double     u[3];
      double     a;
      double     b;
      double     c;
      double     point[3];      
      int        *found;
      
/*
C      VARIABLE  I/O  DESCRIPTION
C      --------  ---  --------------------------------------------------
C      POSITN     I   Position of the observer in body-fixed coordinates
C      U          I   Vector from the observer in some direction
C      A          I   Length of the ellisoid semi-axis along the x-axis
C      B          I   Length of the ellisoid semi-axis along the y-axis
C      C          I   Length of the ellisoid semi-axis along the z-axis
C      POINT      O   Point on the ellipsoid pointed to by U
C      FOUND      O   Flag indicating if U points at the ellipsoid
C
C$ Detailed_Input
C
C      POSITN     This is a 3-vector giving the bodyfixed coordinates
C                 of an observer with respect to the center of an
C                 ellipsoid. In body-fixed coordinates, the semi-axes of
C                 the ellipsoid are aligned with the x, y, and z-axes of
C                 the coordinate system.
C
C      U          Vector from the observer in some direction.
C                 Presumably, this vector points towards some point on
C                 the ellipsoid.
C
C      A          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the x-axis of the body-fixed
C                 coordinate system.
C
C      B          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the y-axis of the body-fixed
C                 coordinate system.
C
C      C          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the z-axis of the body-fixed
C                 coordinate system.
C
C
C$ Detailed_Output
C
C      POINT      If the ray with direction vector U emmenating from
C                 POSITN intersects the ellipsoid, POINT will be
C                 returned with the body-fixed coordinates of the point
C                 where the ray first meets the ellipsoid.  Otherwise,
C                 POINT will be returned as (0, 0, 0).
C
C      FOUND      This is a logical flag indicating whether or not the
C                 ray from POSITN with direction U actually intersects
C                 the ellipsoid.  If the ray does intersect the
C                 ellipsoid, FOUND will be returned as .TRUE. If the
C                 ray misses the ellipsoid, FOUND will be returned as
C                 .FALSE.
C
C$ Parameters
C
C      None.
C
C$ Particulars
C
C      This routine assumes that an ellipsoid having semi-axes of length
C      A, B and C is given.  Moreover, it is assumed that these axes
C      are parallel to the x-, y-, and z-axes of a coordinate system
C      centered at the geometric center of the ellipsoid---this is calle
C      the body-fixed coordinate frame.  Let a a ray be given with
C      endpoint at POSITN with direction vector U (both in body-fixed
C      coordinates).  If the ray intersects the ellipsoid, this routine
C      sets a logical flag to .TRUE. and returns the first point of
C      intersection of the ray with the ellipsoid.  If the ray does
C      not intersect the ellipsoid, the routine sets a logical flag
C      to FALSE and returns the point (0,0,0).
C
      DOUBLE PRECISION VDOT 

Return Values:

-1 :   zero input vector u;
-2 :   a <= 0
-3 :   b <= 0
-4 :   c <= 0
-5 :   not found

*/

{
 
      double  x[3];
      double  y[3];
      double  dscrm;
      double  alpha;
      double  beta;
      double  gamma;
      double  scalar; 

 
/*    We need to find the smallest positive value of t, such that
      POSITN + t * U lies on the ellipsoid.  That is, plug this variable
      point into the equation of the ellipsoid, and solve the resulting
      quadrati  equation for t.  Take the smallest positive value found
      if one exists.

      First set up some temporary vectors for computing the coefficients
      of the quadrati  equation:

                 ALPHA t**2  +  2*BETA t + GAMMA = 0  */

      x[0]  = u [0] / a;
      x[1]  = u [1] / b;
      x[2]  = u [2] / c;
 
      y[0]  = positn[0] / a;
      y[1]  = positn[1] / b;
      y[2]  = positn[2] / c;

      alpha = dlrvdot(x,x);
      beta  = dlrvdot(x,y);
      gamma = dlrvdot(y,y) -1;
      
 
/*     The solutions to the equation are of course

      ( -BETA (+ or -) DSQRT( BETA*BETA - ALPHA*GAMMA ) ) / ALPHA

      Let's first make sure the discriminant is non-negative. */

      dscrm = beta*beta - alpha*gamma;
      if ( dscrm < 0 )
         {
 
/*       In this case there can be no solutions.  We can't take a real
         square root of a negative number. */
          
         *found = 0;
         }
      else
         {
         if (gamma < 0)
            {
 
/*       The discriminant is positive. GAMMA < 0 implies that the
         point POSITN is inside the ellipsoid.  Clearly there must be
         a point where the ray intersects the ellipsoid.  Moreover,
         POSITN plus a positive SCALAR multiple of U must give this
         point. POSITN  plus some negative scalar multiple of U will
         give a point of intersection of the anti-ray and the ellipsoid.
         These scalar multiples must both be roots of the quadratic
         equation.  In our case we want the positive root --- that is
         the larger of the two roots. */
 
            scalar =   ( - beta + sqrt ( dscrm ) ) / alpha;
 
            dlrvlcom ( 1.0, positn, scalar, u, point );
         
            *found = 1;
            }
         else
            {
            if ( gamma == 0 )
               { 

/*       The point must be ON the ellipsoid.  We'll take it to be the
         intercept point */

               point[0] = positn[0];
               point[1] = positn[1];
               point[2] = positn[2];

               *found = 1;
               }
             else
               {
               if ( beta < 0 )
                  {

/*
C        The discriminant is positive, and the point POSITN is outside
C        the ellipsoid.  One of two cases must be true.
C
C            1. The ray intersects the ellipsoid in two points or
C                tangentially
C
C            2. The anti-ray intersects the ellipsoid in two points or
C                tangentially.
C
C        In case 1. both roots of the quadratic expression must be
C        positive.  This is where the sign of BETA comes in --- if BETA
C        is negative, we know that at least one of the two roots of the
C        quadratic is positive,  but since we've made it this far, it
C        follows that both roots (counting multiplicities in the
C        tangential case) must be positive.  Thus the ray must intersect
C        and the first intersection of the ray corresponds to the
C        smaller root of the quadratic expression.
*/

                  scalar =   ( - beta - sqrt ( dscrm ) ) / alpha;

                  dlrvlcom ( 1, positn, scalar, u, point );

                  *found = 1;
                  }
               else
                  {

/*
C        In Case 2, if BETA is positive or zero there will be at
C        least one negative root,  but again since we've made it this
C        far, we know from geometry that both roots must have the
C        same sign.  Thus both roots must be negative.  Consequently
C        it is the anti-ray and not the ray that intersects the
C        ellipsoid.
*/

                  *found = 0;
                  }
               }
            }
         }
 
}
/* ********************************************************************** */
void dlrsurfptl_llr (positn, u, a, b, c, long_axis, latlong, radius, found)

      double positn[3];
      double u[3];
      double a,b,c;
      double long_axis;
      double latlong[2];
      double *radius;
      int    *found;

{ 
/* Brief_I/O

      VARIABLE  I/O  DESRIPTION
      --------  ---  --------------------------------------------------
      POSITN     I   Position of the observer in the PM frame
      U          I   Vetor from the observer in some diretion in the
                     PM frame
      A          I   Length of the ellipsoid semi-axis along the x-axis
      B          I   Length of the ellipsoid semi-axis along the y-axis
      C          I   Length of the ellipsoid semi-axis along the z-axis
      LONG_AXIS  I   Positive west longitude, measured from the prime
                     meridian, of the longest axis of the ellipsoid 
      LATLONG    O   Latitude/Longitude on the ellipsoid pointed to by U
      FOUND      O   Flag indiating if U points at the ellipsoid */
      
      double positn_s[3];
      double u_s[3];
      double mout[3][3];
      double point[3];
      int    lauf;
                  
/*     ROTATION FROM PM */
      if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
         {
/*       Copy position and line_of_sight vector */
         for (lauf=0; lauf < 3; lauf++)
            {
            positn_s[lauf] = positn[lauf];
            u_s[lauf] = u[lauf];
            }
         dlrrotate(-long_axis, 3, mout);
         dlrmxv(mout, u_s, u_s);
         dlrmxv(mout, positn_s, positn_s);
      	 dlrsurfpt (positn_s, u_s, a, b, c, point, found);
         }
      else dlrsurfpt (positn, u, a, b, c, point, found);
      
      if (*found)
         {
/*        ROTATION TO PM  */
         if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
            {
            dlrrotate(long_axis, 3, mout);
            dlrmxv(mout, point, point);
            }
         dlrreclat(point, radius, &latlong[1], &latlong[0]);
         }
}
/* ********************************************************************** */
void dlrsurfptl_xyz (positn, u, a, b, c, long_axis, point, found)

      double positn[3];
      double u[3];
      double a,b,c;
      double long_axis;
      double point[3];
      int    *found;

{ 
/* Brief_I/O

      VARIABLE  I/O  DESRIPTION
      --------  ---  --------------------------------------------------
      POSITN     I   Position of the observer in the PM frame
      U          I   Vetor from the observer in some diretion in the
                     PM frame
      A          I   Length of the ellipsoid semi-axis along the x-axis
      B          I   Length of the ellipsoid semi-axis along the y-axis
      C          I   Length of the ellipsoid semi-axis along the z-axis
      LONG_AXIS  I   Positive west longitude, measured from the prime
                     meridian, of the longest axis of the ellipsoid 
      POINT      O   Body-centered XYZ on the ellipsoid pointed to by U
      FOUND      O   Flag indiating if U points at the ellipsoid */
      
      double positn_s[3];
      double u_s[3];
      double radius;
      double mout[3][3];
      int    lauf;
                  
/*     ROTATION FROM PM */
      if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
         {
/*       Copy position and line_of_sight vector */
         for (lauf=0; lauf < 3; lauf++)
            {
            positn_s[lauf] = positn[lauf];
            u_s[lauf] = u[lauf];
            }
         dlrrotate(-long_axis, 3, mout);
         dlrmxv(mout, u_s, u_s);
         dlrmxv(mout, positn_s, positn_s);
      	 dlrsurfpt (positn_s, u_s, a, b, c, point, found);
         }
      else dlrsurfpt (positn, u, a, b, c, point, found);
      
      if (*found)
         {
/*        ROTATION TO PM  */
         if (fabs(long_axis) > LONG_AXIS_THRESHOLD)
            {
            dlrrotate(long_axis, 3, mout);
            dlrmxv(mout, point, point);
            }
         }
}
/* ********************************************************************** */
/* Procedure      SURFNM ( Surface normal vector on an ellipsoid ) */
/* NAIF 0047 routine rewritten in C by Th. Roatsch, DLR 25-Nov-1998 */
 
      void dlrsurfnm ( a, b, c, point, normal )
 
/*     This routine computes the outward-pointing, unit normal vector
C     from a point on the surface of an ellipsoid.
C
C$ Copyright
C
C     Copyright (1995), California Institute of Technology.
C     U.S. Government sponsorship acknowledged.
C
C$ Required_Reading
C
C     None.
C
C$ Keywords
C
C      ELLIPSOID,  GEOMETRY */
 
      double    a;
      double    b;
      double    c;
      double    point[3];
      double    normal[3];

{
 
/* Brief_I/O
C
C      VARIABLE  I/O  DESCRIPTION
C      --------  ---  --------------------------------------------------
C      A          I   Length of the ellisoid semi-axis along the x-axis.
C      B          I   Length of the ellisoid semi-axis along the y-axis.
C      C          I   Length of the ellisoid semi-axis along the z-axis.
C      POINT      I   Body-fixed coordinates of a point on the ellipsoid
C      NORMAL     O   Outward pointing unit normal to ellipsoid at POINT
C
C$ Detailed_Input
C
C      A          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the x-axis of the body-fixed
C                 coordinate system.
C
C      B          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the y-axis of the body-fixed
C                 coordinate system.
C
C      C          This is the length of the semi-axis of the ellipsoid
C                 that is parallel to the z-axis of the body-fixed
C                 coordinate system.
C
C      POINT      This is a 3-vector giving the bodyfixed coordinates
C                 of a point on the ellipsoid. In bodyfixed coordinates,
C                 the semi-axes of the ellipsoid are aligned with the
C                 x, y, and z-axes of the coordinate system.
C
C$ Detailed_Output
C
C      NORMAL    A unit vector pointing away from the ellipsoid and
C                normal to the ellipsoid at POINT.
C
C$ Parameters
C
C      None.
C
C$ Particulars
C
C      This routine computes the outward pointing unit normal vector to
C      the ellipsoid having semi-axes of length A, B, and C from the
C      point POINT.
C
C$ Examples
C
C      A typical use of SURFNM would be to find the angle of incidence
C      of the light from the sun at a point on the surface of an
C      ellipsoid.
C
C      Let Q be a 3-vector representing the rectangular body-fixed
C      coordinates of a point on the ellipsoid (we are assuming that
C      the axes of the ellipsoid are aligned with the axes of the
C      body fixed frame.)  Let V be the vector from Q to the sun in
C      bodyfixed coordinates.  Then the following code fragment could
C      be used to compute angle of incidence of sunlight at Q.
C
C            CALL SURFNM   ( A, B, C, Q, NRML )
C
C            INCIDN = VSEP ( V,          NRML )
C
C
C$ Restrictions
C
C      It is assumed that the input POINT is indeed on the ellipsoid.
C      No checking for this is done.
C
C
C$ Exceptions
C
C     1) If any of the axes are non-positive, the error
C        'SPICE(BADAXISLENGTH)' will be signalled. */



      double       m;
      double       a1;
      double       b1;
      double       c1;
  
 

/*    Mathematically we want to compute (Px/a**2, Py/b**2, Pz/c**2)
      and then convert this to a unit vector. However, computationally
      this can blow up in our faces.  But note that only the ratios
      a/b, b/  and a/  are important in computing the unit normal.
      We can use the trick below to avoid the unpleasantness of
      multiplication and division overflows. */

      if (a < b) m = a;
      else m = b;
      if (c < m) m = c;
 
/*    M can be divided by A,B or C without fear of an overflow
      occuring. */

      a1        = m/a;
      b1        = m/b;
      c1        = m/c;
 
/*    All of the terms A1,B1,C1 are less than 1. Thus no overflows
      can occur. */

      normal[0] = point[0] * (a1*a1);
      normal[1] = point[1] * (b1*b1);
      normal[2] = point[2] * (c1*c1);
 
      dlrvhat(normal,normal);

}
void dlrmxm (double M1[3][3], double M2[3][3], double MOUT[3][3])
/* function calculates M1 * M2 = MOUT (matrix times Matrix)*/
/* MOUT may overwrite M1 or M2 */
{
int    i, j, k;
double tmp[3][3];

for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	tmp[i][j]=0.0;
	for (k=0;k<3;k++) 
	    {
	    tmp[i][j] += M1[i][k]*M2[k][j];
	    }
	}
    }
for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	MOUT[i][j] = tmp[i][j];
	}
    }
}
void dlrmtxm (double M1[3][3], double M2[3][3], double MOUT[3][3])
/* function calculates M1_transp * M2 = MOUT (matrix_transposed times Matrix)*/
/* MOUT may overwrite M1 or M2 */
{
int    i, j, k;
double tmp[3][3];

for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	tmp[i][j]=0.0;
	for (k=0;k<3;k++) 
	    {
	    tmp[i][j] += M1[k][i]*M2[k][j];
	    }
	}
    }
for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	MOUT[i][j] = tmp[i][j];
	}
    }
}
void dlrmxmt (double M1[3][3], double M2[3][3], double MOUT[3][3])
/* function calculates M1 * M2_transp = MOUT (matrix times Matrix_transposed)*/
/* MOUT may overwrite M1 or M2 */
{
int    i, j, k;
double tmp[3][3];

for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	tmp[i][j]=0.0;
	for (k=0;k<3;k++) 
	    {
	    tmp[i][j] += M1[i][k]*M2[j][k];
	    }
	}
    }
for (i=0;i<3;i++) 
    {
    for (j=0;j<3;j++) 
	{
	MOUT[i][j] = tmp[i][j];
	}
    }
}
/* ------------------------------------------------------------ */
void dlrmxv (double M[3][3], double *V, double *VOUT)
/* function calculates M * V = VOUT (matrix times vector) */
/* VOUT may overwrite V */
{
int    i, j;
double tmp[3];

for (i=0;i<3;i++) 
    {
    tmp[i]=0.0;
    for (j=0;j<3;j++) tmp[i] += M[i][j]*V[j];
    }
for (i=0;i<3;i++) VOUT[i]=tmp[i];
}
/* ------------------------------------------------------------ */
void dlrmtxv (double M[3][3], double *V, double *VOUT)
/* function calculates Mt * V = VOUT (matrix(transposed) times vector) */
/* VOUT may overwrite V */
{
int    i, j;
double tmp[3];

for (i=0;i<3;i++) 
    {
    tmp[i]=0.0;
    for (j=0;j<3;j++) tmp[i] += M[j][i]*V[j];
    }
for (i=0;i<3;i++) VOUT[i]=tmp[i];
}
/* ------------------------------------------------------------ */
void dlropk2m (double omega, double phi, double kappa, double MOUT[3][3])
/* function calculate the matrix product: MOUT = Romega * Rphi * Rkappa */
/* where:  */

/*          |    1            0           0     |                 */
/* Romega = |    0        cos(omega)  sin(omega)|                 */
/*          |    0       -sin(omega)  cos(omega)|                 */

/*          |  cos(phi)       0       -sin(phi) |                 */
/*  Rphi  = |     0           1            0    |                 */
/*          |  sin(phi)       0        cos(phi) |                 */

/*          | cos(kappa)  sin(kappa)      0     |                 */
/* Rkappa = |-sin(kappa)  cos(kappa)      0     |                 */
/*          |    0            0           1     |                 */

{
double cp, sp, co, so, ck, sk;

   ck = cos (kappa);
   sk = sin (kappa);
   cp = cos (phi);
   sp = sin (phi);
   co = cos (omega);
   so = sin (omega);

   MOUT[0][0] =  cp * ck;
   MOUT[1][0] = -sk * co + ck * sp * so;
   MOUT[2][0] =  sk * so + ck * sp * co;
   MOUT[0][1] =  sk * cp;
   MOUT[1][1] =  ck * co + sk * sp * so;
   MOUT[2][1] = -ck * so + sk * sp * co;
   MOUT[0][2] = -sp;
   MOUT[1][2] =  cp * so;
   MOUT[2][2] =  co * cp;
}
/* ------------------------------------------------------------ */
void dlrkpo2m (double kappa, double phi, double omega, double MOUT[3][3])
/* function calculate the matrix product: MOUT = Rkappa * Rphi * Romega */
/* where:  */
/*          | cos(kappa)  sin(kappa)      0     |                 */
/* Rkappa = |-sin(kappa)  cos(kappa)      0     |                 */
/*          |    0            0           1     |                 */

/*          |  cos(phi)       0       -sin(phi) |                 */
/*  Rphi  = |     0           1            0    |                 */
/*          |  sin(phi)       0        cos(phi) |                 */

/*          |    1            0           0     |                 */
/* Romega = |    0        cos(omega)  sin(omega)|                 */
/*          |    0       -sin(omega)  cos(omega)|                 */

{
double cp, sp, co, so, ck, sk;

   co = cos (omega);
   so = sin (omega);
   cp = cos (phi);
   sp = sin (phi);
   ck = cos (kappa);
   sk = sin (kappa);

   MOUT[0][0] =  cp * ck;
   MOUT[1][0] = -sk * cp;
   MOUT[2][0] =  sp;
   MOUT[0][1] =  so * sp * ck + co * sk;
   MOUT[1][1] = -so * sp * sk + co * ck;
   MOUT[2][1] = -cp * so;
   MOUT[0][2] = -sp * co * ck + so * sk;
   MOUT[1][2] =  sp * co * sk + so * ck;
   MOUT[2][2] =  co * cp;
}
/* ------------------------------------------------------------ */
void dlrkop2m (double kappa, double omega, double phi, double MOUT[3][3])
/* function calculates the matrix product: MOUT = Rkappa * Romega * Rphi */
/* where:  */
/*          | cos(kappa)  sin(kappa)      0     |                 */
/* Rkappa = |-sin(kappa)  cos(kappa)      0     |                 */
/*          |    0            0           1     |                 */

/*          |    1            0           0     |                 */
/* Romega = |    0        cos(omega)  sin(omega)|                 */
/*          |    0       -sin(omega)  cos(omega)|                 */

/*          |  cos(phi)       0       -sin(phi) |                 */
/*  Rphi  = |     0           1            0    |                 */
/*          |  sin(phi)       0        cos(phi) |                 */

{
double cp, sp, co, so, ck, sk;

   cp = cos (phi);
   sp = sin (phi);
   co = cos (omega);
   so = sin (omega);
   ck = cos (kappa);
   sk = sin (kappa);

   MOUT[0][0] =  sp * so * sk + cp * ck;
   MOUT[1][0] =  sp * so * ck - sk * cp;
   MOUT[2][0] =  sp * co;
   MOUT[0][1] =  co * sk;
   MOUT[1][1] =  co * ck;
   MOUT[2][1] = -so;
   MOUT[0][2] =  cp * so * sk - ck * sp;
   MOUT[1][2] =  cp * so * ck + sp * sk;
   MOUT[2][2] =  cp * co;
}
/* ------------------------------------------------------------ */
void dlrm2kop (double M[3][3], double *kappa, double *omega, double *phi)
/* function calculates phi omega kappa from the matrix M in that way that */
/* M = Rkappa * Romega * Rphi */
/* where:  */
/*          | cos(kappa)  sin(kappa)      0     |                 */
/* Rkappa = |-sin(kappa)  cos(kappa)      0     |                 */
/*          |    0            0           1     |                 */

/*          |    1            0           0     |                 */
/* Romega = |    0        cos(omega)  sin(omega)|                 */
/*          |    0       -sin(omega)  cos(omega)|                 */

/*          |  cos(phi)       0       -sin(phi) |                 */
/*  Rphi  = |     0           1            0    |                 */
/*          |  sin(phi)       0        cos(phi) |                 */

/* rotation matrix elements are defined for a rotation M = Rkappa * Romega * Rphi  by
   M[0][0] =  sp * so * sk + cp * ck
   M[1][0] =  sp * so * ck - sk * cp
   M[2][0] =  sp * co
   M[0][1] =  co * sk
   M[1][1] =  co * ck
   M[2][1] = -so
   M[0][2] =  cp * so * sk - ck * sp
   M[1][2] =  cp * so * ck + sp * sk
   M[2][2] =  cp * co

where
   cp = cos (phi)
   sp = sin (phi)
   co = cos (omega)
   so = sin (omega)
   ck = cos (kappa)
   sk = sin (kappa)
*/
{
double co, check_m[3][3];
int i, j, ok=0;

*omega = asin(-M[2][1]);
co = 1.0/cos(*omega);
*phi   = asin(M[2][0]*co);
*kappa = asin(M[0][1]*co);

while (1)
    {
    dlrkop2m (*kappa, *omega, *phi, check_m);
    ok=1;
    for (i=0;i<3;i++) 
       for (j=0;j<3;j++) 
    	    if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
    if (!ok) 
	{
	*kappa = PI - *kappa;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	if (!ok) *kappa = PI - *kappa;
	}
    else break;

    if (!ok) 
	{
	*phi = PI - *phi;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	if (!ok) *phi = PI - *phi;
	}
    else break;

    if (!ok) 
	{
	*omega = PI - *omega;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	}
    else break;

    if (!ok) 
	{
	*kappa = PI - *kappa;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	}
    else break;

    if (!ok) 
	{
	*phi = PI - *phi;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	}
    else break;

    if (!ok) 
	{
	*omega = PI - *omega;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	}
    else break;

    if (!ok) 
	{
	*omega = PI - *omega;
	*kappa = PI - *kappa;
	dlrkop2m (*kappa, *omega, *phi, check_m);
	ok=1;
	for (i=0;i<3;i++) 
	    for (j=0;j<3;j++) 
    		if (fabs(check_m[i][j] - M[i][j])>0.00001) ok=0;
	}
    else break;

    if (!ok)
	{
	printf ("\nerror in dlrm2kop !\n");
	exit(0);
	}
    }
    
while (*kappa > twoPI) *kappa -= twoPI;
while (*omega > twoPI) *omega -= twoPI;
while (*phi   > twoPI) *phi   -= twoPI;
}
/* ------------------------------------------------------------ */
void dlrkok2m (double kappa2, double omega, double kappa1, double MOUT[3][3])
/* function calculate the matrix product: M = Rkappa2 * Romega * Rkappa1 */
/* where:  */
/*           | cos(kappa2)  sin(kappa2)      0     |                 */
/* Rkappa2 = |-sin(kappa2)  cos(kappa2)      0     |                 */
/*           |    0             0            1     |                 */

/*           |    1             0            0     |                 */
/* Romega  = |    0         cos(omega)   sin(omega)|                 */
/*           |    0        -sin(omega)   cos(omega)|                 */

/*           | cos(kappa1)  sin(kappa1)      0     |                 */
/* Rkappa1 = |-sin(kappa1)  cos(kappa1)      0     |                 */
/*           |    0             0            1     |                 */
{
double ck1, sk1, co, so, ck2, sk2;

   ck1 = cos (kappa1);
   sk1 = sin (kappa1);
   co  = cos (omega);
   so  = sin (omega);
   ck2 = cos (kappa2);
   sk2 = sin (kappa2);

   MOUT[0][0] =  ck1 * ck2 - sk1 * sk2 * co;
   MOUT[1][0] = -ck1 * sk2 - sk1 * ck2 * co;
   MOUT[2][0] =  sk1 * so;
   MOUT[0][1] =  sk1 * ck2 + ck1 * sk2 * co;
   MOUT[1][1] = -sk1 * sk2 + ck1 * ck2 * co;
   MOUT[2][1] = -ck1 * so;
   MOUT[0][2] =  sk2 * so;
   MOUT[1][2] =  ck2 * so;
   MOUT[2][2] =  co;
}
/* ------------------------------------------------------------ */
void dlrvhat (double *V, double *VOUT)
/* function calculates V / |V| = VOUT (normalized vector) */
/* functions does not check for |V| == 0 , to be faster ! */
/* VOUT may overwrite V */
{
int    i;
double vmag;

vmag = dlrvnorm(V);
if (vmag!=0.0) 
    for (i=0;i<3;i++) VOUT[i] = V[i] / vmag;
else 
    for (i=0;i<3;i++) VOUT[i]=0.0;
}
/* ------------------------------------------------------------ */
double dlrvnorm (double *V)
/* function returns the norm of V  */
{
return (sqrt(V[0]*V[0]+V[1]*V[1]+V[2]*V[2]));
}
/* ------------------------------------------------------------ */
double dlrvdot (double *V1, double *V2)
/* function returns Vector dot product of V1 and V2  */
{
return (V1[0]*V2[0]+V1[1]*V2[1]+V1[2]*V2[2]);
}
/* ------------------------------------------------------------ */
void dlrvlcom (double A, double *V1, double B, double *V2, double *SUMOUT)
/* function calculates Vector linear combination of V1 and V2  */
/* SUMOUT[I] = A*V1[I] + B*V2[I]*/
{
int    i;
for (i=0;i<3;i++) SUMOUT[i]=A*V1[i] + B*V2[i];
}
/* ------------------------------------------------------------ */
void dlrreclat ( double *xyz, double *radius, double *lon, double *lat)
/* function calculates Rectangular to centric latitudinal coordinates  */
{
double 	x2, y2, x2_y2;
x2    = xyz[0]*xyz[0];
y2    = xyz[1]*xyz[1];
x2_y2 = x2+y2;

*radius = sqrt(x2_y2+xyz[2]*xyz[2]);
*lat    = atan2 (xyz[2], sqrt(x2_y2));

if ((xyz[0]!=0.0) || (xyz[1]!=0.0))
    *lon = atan2(xyz[1],xyz[0]);
else
    *lon = 0.0;
}
/* ------------------------------------------------------------ */
void dlrlatrec ( double radius, double lon, double lat, double *xyz)
/* function calculates centric latitudinal to Rectangular coordinates  */
{
double 	cla;

cla = cos(lat);

xyz[0] = radius * cos(lon) * cla;
xyz[1] = radius * sin(lon) * cla;
xyz[2] = radius * sin(lat);
}
/* ------------------------------------------------------------ */
void dlrrotate ( double ANGLE, int IAXIS, double MOUT[3][3])
/* function Generate a rotation matrix MOUT */
/* rotation around axis IAXIS (1,2 or 3) with the ANGLE */
/*   A rotation about the first, i.e. x-axis, is described by */
/*     |  1        0          0      | */
/*     |  0   cos(ANGLE) sin(ANGLE)  | */
/*     |  0  -sin(ANGLE) cos(ANGLE)  | */
/*     A rotation about the second, i.e. y-axis, is described by */
/*     |  cos(ANGLE)  0  -sin(ANGLE)  | */
/*     |      0       1        0      | */
/*     |  sin(ANGLE)  0   cos(ANGLE)  | */
/*     A rotation about the third, i.e. z-axis, is described by */
/*     |  cos(ANGLE) sin(ANGLE)   0   | */
/*     | -sin(ANGLE) cos(ANGLE)   0   | */
/*     |       0          0       1   | */

{
double 	s, c;

s = sin(ANGLE);
c = sin(ANGLE);

switch (IAXIS)
   {
   case 1:
   MOUT[0][0] =  1.0;
   MOUT[1][0] =  0.0;
   MOUT[2][0] =  0.0;
   MOUT[0][1] =  0.0;
   MOUT[1][1] =  c;
   MOUT[2][1] = -s;
   MOUT[0][2] =  0.0;
   MOUT[1][2] =  s;
   MOUT[2][2] =  c;
   break;
   case 2:
   MOUT[0][0] =  c;
   MOUT[1][0] =  0.0;
   MOUT[2][0] =  s;
   MOUT[0][1] =  0.0;
   MOUT[1][1] =  1.0;
   MOUT[2][1] =  0.0;
   MOUT[0][2] = -s;
   MOUT[1][2] =  0.0;
   MOUT[2][2] =  c;
   break;
   case 3:
   MOUT[0][0] =  c;
   MOUT[1][0] = -s;
   MOUT[2][0] =  0.0;
   MOUT[0][1] =  s;
   MOUT[1][1] =  c;
   MOUT[2][1] =  0.0;
   MOUT[0][2] =  0.0;
   MOUT[1][2] =  0.0;
   MOUT[2][2] =  1.0;
   break;
   }
}
/* ------------------------------------------------------------ */
double dlrdpr()
{
double value;
value = 180/PI;
return value;
}
/* ------------------------------------------------------------ */
double dlrrpd()
{
double value;
value = PI/180;
return value;
}

/* ------------------------------------------------------------ */
      void zhrscori (double position1[3], double position2[3], double rbp[3][3], float *scori)

/*     Subroutine calculates the viewing direction of
       the x-axis of the HRSC photogrammetry system,
	   which is also the y-axes of the HRSC camera system,,
	   in the prime meridian / equator frame and compares it
	   with the flight direction (whether it is +y of spacecraft (0.,1.,0.)
	   or -y of spacecraft (0.,-1.,0.)) */

/*      VARIABLE  I/O  DESCRIPTION
       --------  ---  --------------------------------------------------
       position1  I   SC position in prime meridian / equator frame 
                      at time t1 
       position2  I   SC position in prime meridian / equator frame
	                  at time t2 (t2 > t1) 
       RBP        I   Roation matrix from 
                      body system to photogrammetry system
       SCORI      O   SC orientation 
	                  (0.,1.,0.) : Flight direction is +Ysc 
	                  (0.,-1.,0.) : Flight direction is -Ysc 
*/
{
      double   vpoint [3], velvec [3], difvec [3], length;
	  int      i;
     
/*    use the +x-axis of the HRSC photogrammetry system */
      
      vpoint[0] = 1.;
      vpoint[1] = 0.;
      vpoint[2] = 0.;
      
/*    Transform it to the prime meridian / equator frame */
      dlrmtxv (rbp, vpoint, vpoint);
	  
/*    Compute the velocity vector */
      for (i=0;i<3;i++) velvec[i] = position2[i] - position1[i];

/*    normalize the velocity vector */
      dlrvhat (velvec, velvec);

/*    The difference of vpoint and velvec indicates the sc orientation */
      for (i=0;i<3;i++) difvec[i] = velvec[i] - vpoint[i];

/*    Calculate the length of this difference  */
	  length = 0.;
      for (i=0;i<3;i++) length += (difvec[i] * difvec[i]);
	  length = sqrt (length);
	  
/*    if the length of the difvec is less than sqrt(2) (xphot points forward)  
       then flight direction is -Ysc 
      if the length of the difvec is more than sqrt(2) (xphot points backward) 
       then flight direction is +Ysc */

	  scori[0] = scori[2] = 0.;
	  scori[1] = -1.;
	  if (length > sqrt(2.)) scori[1] = 1.;

}
/* ------------------------------------------------------------ */
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrspice.imake
/* IMAKE file for subroutine dlrspice */

#define SUBROUTINE dlrspice

#define MODULE_LIST dlrspice.c

#define HW_SUBLIB

#define USES_ANSI_C
$ Return
$!#############################################################################
