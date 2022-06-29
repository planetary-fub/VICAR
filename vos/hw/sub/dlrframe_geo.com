$!****************************************************************************
$!
$! Build proc for MIPL module dlrframe_geo
$! VPACK Version 1.9, Wednesday, November 30, 2005, 12:00:53
$!
$! Execute by entering:		$ @dlrframe_geo
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
$ write sys$output "*** module dlrframe_geo ***"
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
$ write sys$output "Invalid argument given to dlrframe_geo.com file -- ", primary
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
$   if F$SEARCH("dlrframe_geo.imake") .nes. ""
$   then
$      vimake dlrframe_geo
$      purge dlrframe_geo.bld
$   else
$      if F$SEARCH("dlrframe_geo.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrframe_geo
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrframe_geo.bld "STD"
$   else
$      @dlrframe_geo.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrframe_geo.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrframe_geo.com -mixed -
	-s dlrframe_geo.c dlrframe_getgeo_ikernel.c dlrframe_getgeo_xy.c -
	-i dlrframe_geo.imake -
	-t tstdlrframe_geo.c tstdlrframe_geo.imake tstdlrframe_geo.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrframe_geo.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include <stdio.h>
#include <string.h>

#include "SpiceUsr.h"
#include "dlrframe.h"
#define     WDSIZE            32  /* getfov */

/*     Written by Thomas Roatsch, DLR     28-May-1999 */


int dlrframe_getgeo (dlrframe_info dlrframe_info, FILE *adjuptr,
                     double *samp_x, double *samp_y, double *focal,
                     double positn[3], double omat [3][3])
{
int status;
double imat[3][3];

status = dlrframe_getgeo_cal(dlrframe_info, adjuptr,
                            samp_x, samp_y, focal,
                            imat);

if (status !=1) return (status);

status = dlrframe_getgeo_pr(dlrframe_info, adjuptr,
                            positn, imat, omat);

return (status);
}


int dlrframe_getgeo_cal (dlrframe_info dlrframe_info, FILE *adjuptr, 
                         double *samp_x, double *samp_y, double *focal,
                         double csmat [3][3])

{

int          status;
char         varname[50], ins_string[50];
int          mission_flag;
int          ihelp,ihelp1;
int          lauf_l, lauf_s;
double       pix_per_mm,l0,s0,alpha0;
float        fl, fs;
SpiceBoolean sp_found; 
SpiceInt     n;

/* read the I-kernel variables */
status = dlrframe_getgeo_ikernel (dlrframe_info,
                      &l0, &s0, &pix_per_mm,
                      &alpha0, focal);
if (status !=1) return (status);

/* calculate samp_x and samp_y */
  for (lauf_l = 1; lauf_l <= dlrframe_info.nl; lauf_l++)
      {
      ihelp1 = (lauf_l-1) * dlrframe_info.ns ;
      fl = (float) lauf_l;
      for (lauf_s = 1; lauf_s <= dlrframe_info.ns; lauf_s++)
          {
          fs = (float) lauf_s;
          ihelp = ihelp1 + lauf_s-1;
          dlrframe_getgeo_xy (dlrframe_info,
                              l0, s0, pix_per_mm,
                              alpha0,
                              fl, fs, &samp_x[ihelp], &samp_y[ihelp]);
          }
      }

if (adjuptr <= (FILE *)NULL)
   {
   status = dlrframe_getgeo_cal_cmat(dlrframe_info, csmat);
   if (status != 1) return (status);
   }
return (1);

}



int dlrframe_getgeo_cal_cmat(dlrframe_info dlrframe_info, 
                             double csmat[3][3])

{
int          status,found;
int          lauf_l, lauf_s;
double       helpmat[3][3];
double       cross,cone,rastr;
double       thetax,thetay,thetaz;
double       offset[3],axes[3];
char         varname[50], ins_string[50];
SpiceBoolean sp_found; 
SpiceInt     n;

/* let's check the ID */
found = 0;
if (dlrframe_info.spacecraft_id == Voyager_1)  found=1;
if (dlrframe_info.spacecraft_id == Voyager_2)  found=1;
if (dlrframe_info.spacecraft_id == Viking1)    found=1;
if (dlrframe_info.spacecraft_id == Viking2)    found=1;
if (dlrframe_info.spacecraft_id == Clementine) found=1;
if (dlrframe_info.spacecraft_id == Galileo)    found=1;
if (dlrframe_info.instrument_id == 1) 
   return 1; /* nothing to do for new missions */

if (found == 0) return (-2);

sprintf(ins_string,"INS%d",dlrframe_info.instrument_id);

   /* Voyager not implemented */
   if ((dlrframe_info.spacecraft_id == Voyager_1) || 
        (dlrframe_info.spacecraft_id == Voyager_2) ) ident_(csmat);

   /* Viking */
   if ((dlrframe_info.spacecraft_id == Viking1) || 
        (dlrframe_info.spacecraft_id == Viking2) ) 
      {
      strcpy(varname,ins_string);     
      strcat(varname,"_CROSS_CONE");
      gdpool_c(varname,0,1,&n,&cross,&sp_found);
      if (!sp_found) return (-211);
      strcpy(varname,ins_string);     
      strcat(varname,"_CONE");
      gdpool_c(varname,0,1,&n,&cone,&sp_found);
      if (!sp_found) return (-212);
      strcpy(varname,ins_string);     
      strcat(varname,"_RASTER_ORIENTATION");
      gdpool_c(varname,0,1,&n,&rastr,&sp_found);
      if (!sp_found) return (-213);
     /*  Copied from the Viking Instrument kernel,
     this gives camera to platform */
      cross *= rpd_c();
      cone  *= rpd_c();
      rastr *= rpd_c();
      rotate_c (-cross, 1, helpmat);
      rotmat_c (helpmat, cone, 2, helpmat);
      rotmat_c (helpmat, rastr, 3, helpmat);
      /* We need the transformation matrix from the camera system 
      to the platform system */
      for (lauf_s = 0; lauf_s < 3; lauf_s++)
         for (lauf_l = 0; lauf_l < 3; lauf_l++)
            csmat[lauf_l][lauf_s] = helpmat [lauf_s][lauf_l]; 
      } /* end of Viking */

   /* Clementine */
   if (dlrframe_info.spacecraft_id == Clementine)
      {
      strcpy(varname,ins_string);     
      strcat(varname,"_THETAX");
      gdpool_c(varname,0,1,&n,&thetax,&sp_found);
      if (!sp_found) return (-221);
      strcpy(varname,ins_string);     
      strcat(varname,"_THETAY");
      gdpool_c(varname,0,1,&n,&thetay,&sp_found);
      if (!sp_found) return (-222);
      strcpy(varname,ins_string);     
      strcat(varname,"_THETAZ");
      gdpool_c(varname,0,1,&n,&thetaz,&sp_found);
      if (!sp_found) return (-223);
      /* Calculate the transformation matrix from spacecraft system
     to camera system (see Instrument kernel) */
      eul2m_c (thetaz, thetay, thetax, 3, 2 ,1, helpmat);
      /* We need the transformation matrix from the camera system
     to the spacecraft system */
      for (lauf_s = 0; lauf_s < 3; lauf_s++)
         for (lauf_l = 0; lauf_l < 3; lauf_l++)
            csmat[lauf_l][lauf_s] = helpmat [lauf_s][lauf_l];
      } /* end of Clementine */      

   /* Galileo */
   if (dlrframe_info.spacecraft_id == Galileo)
      ident_(csmat);
      
return (1);
} 



int dlrframe_getgeo_pr (dlrframe_info dlrframe_info, FILE *adjuptr, 
                     double positn[3], 
                     double imat [3][3], double omat[3][3])
{

int    lauf3,lauf;
double et,iclkdp,clkout,lt;
double state[6],tipm[3][3],av[3];
double cmat[3][3],cjmat[3][3];
SpiceInt number;
SpiceBoolean sp_found;
double radius1,radius2,dhelp1,dhelp2;
double axes[3];
int    numberhelp;
double dangle_x, dangle_y, dangle_z;
double dpg;
int    found;
char   helpstring[120];
SpiceDouble dvec[]={0,0,1};
SpiceDouble spoint[3],dist,trgepc;
SpiceChar             bdyfxd [ WDSIZE ];
SpiceChar             frame  [ WDSIZE ];
SpiceChar             shape  [ WDSIZE ];
SpiceInt              room = 4;
SpiceDouble           bounds [4][3];
SpiceDouble           bsight [3];
SpiceInt              fov_n,det_id;
int                   srfxpt_found;

if (adjuptr <= (FILE *)NULL)
   {
   /* Convert the UTC to ephemeris time */
   str2et_c(dlrframe_info.utc, &et);
   if (failed_c() ) return (-501);

   if (dlrframe_info.instrument_id != 1)
      { /* the old missions */ 
      /* Convert the ephemeris time to encoded spacecraft clock time */
      sce2t_c (dlrframe_info.spacecraft_id, et, &iclkdp);
      if (failed_c() ) return (-502);

      /* Get the spaceraft position in J2000 */
      switch (dlrframe_info.target_id)
         {
         case 299: spkgeo_c (2, et, "j2000", 
                       dlrframe_info.spacecraft_id, state, &lt);
                   break;
         case 499: spkgeo_c (4, et, "j2000", 
                       dlrframe_info.spacecraft_id, state, &lt);
                   break;
         case 599: spkgeo_c (5, et, "j2000", 
                       dlrframe_info.spacecraft_id, state, &lt);
                   break;
         default:  spkgeo_c (dlrframe_info.target_id, et, "j2000", 
                       dlrframe_info.spacecraft_id, state, &lt);
         }
      if (failed_c() ) return (-503);

      /* SPKGEO returns the state vector as seen from the observer
         We need the position of the spacecraft as seen from the target */
      for (lauf3=0; lauf3 < 3; lauf3++)
          positn[lauf3] = - state[lauf3];

      /* Get the rotation matrix from J2000 to prime meridian /equator 
        frame */
      tipbod_c("J2000", dlrframe_info.target_id,et,tipm);
      if (failed_c() ) return (-504);

      /* Check if the distance from the target center is larger
         as 2 radii, than use LT correction */
      bodvar_c(dlrframe_info.target_id, "RADII", &number, axes);
      if (number < 3) return (-505);
      
      reclat_c(axes, &radius1, &dhelp1, &dhelp2);
      reclat_c(positn, &radius2, &dhelp1, &dhelp2);
      if ( radius2 > (2*radius1) )
         {
         switch (dlrframe_info.target_id)
            {
            case 299: spkez_c (2, et, "j2000", "LT",
                         dlrframe_info.spacecraft_id, state, &lt);
                      break;
            case 499: spkez_c (4, et, "j2000", "LT",
                         dlrframe_info.spacecraft_id, state, &lt);
                      break;
            case 599: spkez_c (5, et, "j2000", "LT",
                          dlrframe_info.spacecraft_id, state, &lt);
                      break;
            default:  spkez_c (dlrframe_info.target_id, et, "j2000", "LT",
                         dlrframe_info.spacecraft_id, state, &lt);
            }
         if (failed_c() ) return (-503);
            
         /* We need the position of the spacecraft as seen from the 
            target */
         for (lauf3=0; lauf3 < 3; lauf3++)
              positn[lauf3] = - state[lauf3];

         /* Get the rotation matrix from J2000 to prime meridian /equator
            frame at et-lt */
         tipbod_c("J2000", dlrframe_info.target_id,et-lt,tipm);
         if (failed_c() ) return (-504);
         } /*end of radius2 ... */

      if (dlrframe_info.spacecraft_id == Clementine)
         /* Special Clementine subroutine */
         ckgpav_c (dlrframe_info.ck_id, iclkdp, dlrframe_info.tol, 
                   "j2000", cmat, av, &clkout, &sp_found);
      else
         ckgp_c(dlrframe_info.ck_id, iclkdp, dlrframe_info.tol, 
               "j2000", cmat, &clkout, &sp_found);  
      if (!sp_found) return (-506);
   

      /* The transformation matrix from the camera system to J2000
         is the transposed C-Matrix multiplied by MAT */
      mtxm_c(cmat, imat, cjmat);
      
      /* Transform the spaecraft position to the 
      prime meridian / equator frame */
      mxv_c(tipm, positn, positn);
      
      /* The transformation matrix from the camera system to the 
      prime meridian / equator system is CJMAT multiplied by TIPM */
      mxm_c (tipm, cjmat, omat);
      } /* end of old missions */
   else
      { /* new missions, srfxpt ... */

      /* Get the spaceraft position in J2000 */
      sprintf(helpstring,"IAU_%s", dlrframe_info.target_name);
      /* let's try the center pixel */
      srfxpt_found=0;
      srfxpt_c("Ellipsoid", dlrframe_info.target_name, et,
               "LT+S", dlrframe_info.spacecraft_name,
               dlrframe_info.instrument_name, dvec,
               spoint, &dist, &trgepc, positn, &found);
      if ( failed_c() ) return (-505);
      if (found) 
         {
         lt=trgepc-et;
         srfxpt_found=1;
         }
      if (!found)
         {   /* now let's try the four corners */
         /* get the FOV */
         bodn2c_c(dlrframe_info.instrument_name, &det_id,&found);
         if (!found ) return -503;
         getfov_c ( det_id, room, WDSIZE, WDSIZE, shape, frame,
                    bsight, &fov_n, bounds );
         if (failed_c() ) return -504; 
         for (lauf=0; lauf<fov_n; lauf++)
            {
            srfxpt_c("Ellipsoid", dlrframe_info.target_name, et,
                     "LT+S", dlrframe_info.spacecraft_name,
                     dlrframe_info.instrument_name, bounds[lauf],
                     spoint, &dist, &trgepc, positn, &found);
            if (found)
               {
               srfxpt_found=1;
               lt=trgepc-et;
               break;
               }         
            }
         }
      if (srfxpt_found == 0)
         { /* we use light time to the center of the target */
         switch (dlrframe_info.target_id)
            {
            case 299: spkezr_c("VENUS BARYCENTER", et, helpstring, "LT",  
                         dlrframe_info.spacecraft_name, state, &lt);
                      break;
            case 499: spkezr_c("MARS BARYCENTER", et, helpstring, "LT",  
                         dlrframe_info.spacecraft_name, state, &lt);
                      break;
            case 599: spkezr_c("JUPITER BARYCENTER", et, helpstring, "LT",  
                         dlrframe_info.spacecraft_name, state, &lt);
                      break;
            default:  spkezr_c(dlrframe_info.target_name, et, helpstring, "LT",  
                         dlrframe_info.spacecraft_name, state, &lt);
            }
         vminus_c(state,positn);                
         }          
         /* The transformation matrix from the camera system to the 
            prime meridian / equator system */

         /* Instrument into J200 at et */
         pxform_c(dlrframe_info.instrument_name,"J2000",et, imat);
         if (failed_c()) return (-506);

         /* J2000 into body fixed system at light emitting time et-lt*/
         pxform_c("J2000",helpstring,trgepc, cmat);
         if (failed_c()) return (-506);
         /* Combine the two matrices */
         mxm_c(cmat, imat, omat);
         if (failed_c()) return (-506);
      }  /* end of new missions */
   } /* end of noadju */
else
   { /* read adjufile */
   found = 0;
   while ((feof(adjuptr)==0))
      {
      if (7 != fscanf(adjuptr, "%d %lf %lf %lf %lf %lf %lf", &numberhelp, 
            &positn[0], &positn[1], &positn[2],
            &dangle_y, &dangle_x, &dangle_z) ) 
            {
            rewind (adjuptr);
            return (-601);
            }
      if (numberhelp == -99) 
         {
         rewind (adjuptr);
         return (-602);
         }
      if (dlrframe_info.adju_id == numberhelp) 
         {
         found =1;
	 rewind (adjuptr);
         break;
         }
      }      
if (found != 1) return (-601);

/* position in adjufile in m, we need it in km */
      positn[0] = positn[0] / 1e3;
      positn[1] = positn[1] / 1e3;
      positn[2] = positn[2] / 1e3;

/* angles in gon, we need it in rad */
      dpg = 90.0 /100.0 ;
      dangle_y = dangle_y * dpg / dpr_c();   
      dangle_x = dangle_x * dpg / dpr_c();   
      dangle_z = dangle_z * dpg / dpr_c();   

/* get the transformation matrix from body to photogrammetry system
   (changed 27-Sep-1995, private communication by B. Giese */
      eul2m_c(dangle_z, dangle_x, dangle_y, 3, 1, 2, omat);
   
   }
   
return (1);

}
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create dlrframe_getgeo_ikernel.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "dlrframe.h"

int dlrframe_getgeo_ikernel (dlrframe_info dlrframe_info,
                      double *l0, double *s0, double *pix_per_mm,
                      double *alpha0, double *focal)

{
SpiceInt     cas;
char         varname[50], ins_string[50];
double       vinst[3];
double       k;
double       dhelp,dhelp2;
int          ihelp,ratio;
SpiceBoolean sp_found;
SpiceInt     n; 

if (dlrframe_info.instrument_id != 1) 
{ /* the old missions */
sprintf(ins_string,"INS%d",dlrframe_info.instrument_id);

strcpy(varname,ins_string);     
strcat(varname,"_FOCAL_LENGTH");
gdpool_c(varname,0,1,&n,focal,&sp_found);
if (!sp_found) return (-101);

strcpy(varname,ins_string);     
strcat(varname,"_K");
gdpool_c(varname,0,1,&n,pix_per_mm,&sp_found);
if (!sp_found) return (-102);

strcpy(varname,ins_string);     
strcat(varname,"_S0");
gdpool_c(varname,0,1,&n,s0,&sp_found);
if (!sp_found) return (-103);

strcpy(varname,ins_string);     
strcat(varname,"_L0");
gdpool_c(varname,0,1,&n,l0,&sp_found);
if (!sp_found) return (-104);

strcpy(varname,ins_string);     
strcat(varname,"_L_MAX");
gdpool_c(varname,0,1,&n,&dhelp,&sp_found);
if (!sp_found) return (-105);
ihelp  = (int) (dhelp + 0.2);
if (ihelp != dlrframe_info.nl) return (-106);

strcpy(varname,ins_string);     
strcat(varname,"_S_MAX");
gdpool_c(varname,0,1,&n,&dhelp,&sp_found);
if (!sp_found) return (-107);
ihelp  = (int) (dhelp + 0.2);
if (ihelp != dlrframe_info.ns) return (-108);

strcpy(varname,ins_string);     
strcat(varname,"_ALPHA0");
gdpool_c(varname,0,1,&n,alpha0,&sp_found);
if (!sp_found) return (-109);
} /* end of old missions*/
else
{ /* new missions, NAIF standard I-kernel */
bodn2c_c(dlrframe_info.instrument_name, &cas, &sp_found);
if (!sp_found) return (-110);
sprintf(ins_string,"INS%d",cas);

strcpy(varname,ins_string);     
strcat(varname,"_FOCAL_LENGTH");
gdpool_c(varname,0,1,&n,focal,&sp_found);
if (!sp_found) return (-101);

strcpy(varname,ins_string);     
strcat(varname,"_PIXEL_SIZE");
gdpool_c(varname,0,1,&n,&k,&sp_found);
if (!sp_found) return (-111);
*pix_per_mm = 1000 / k;  /* we need pixels / mm */

strcpy(varname,ins_string);     
strcat(varname,"_CCD_CENTER");
gdpool_c(varname,0,2,&n,vinst,&sp_found);
if (!sp_found) return (-112);
*s0 = vinst[0];
*l0 = vinst[1];

strcpy(varname,ins_string);     
strcat(varname,"_PIXEL_LINES");
gdpool_c(varname,0,1,&n,&dhelp,&sp_found);
if (!sp_found) return (-113);

strcpy(varname,ins_string);     
strcat(varname,"_PIXEL_SAMPLES");
gdpool_c(varname,0,1,&n,&dhelp2,&sp_found);
if (!sp_found) return (-114);

ratio=1;
if (  (strcmp(dlrframe_info.instrument_name,"MEX_HRSC_SRC"))
      && (!strstr(dlrframe_info.instrument_name,"VMC")) )
   { /* it is not SRC and also not VMC */
   ihelp  = (int) (dhelp + 0.2);
   if (ihelp != dlrframe_info.nl) 
       ratio = ihelp/dlrframe_info.nl;
   }
else
   { /* SRC with varaible pixel and line number */
   *s0 = *s0 - dlrframe_info.spacecraft_id +1;
   *l0 = *l0 - dlrframe_info.ck_id +1;
   }

if (ratio != 1)
   {
   *s0 = (*s0-0.5) / ratio + 0.5;
   *l0 = (*l0-0.5) / ratio + 0.5;
   *pix_per_mm = *pix_per_mm / ratio;
   }   
/* alpha not yet defined 
strcpy(varname,ins_string);     
strcat(varname,"_ALPHA0");
gdpool_c(varname,0,1,&n,&alpha0,&sp_found);
if (!sp_found) return (-109); */
*alpha0 = 0;
}

return (1);
}
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create dlrframe_getgeo_xy.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "dlrframe.h"

void dlrframe_getgeo_xy (dlrframe_info dlrframe_info,
                        double l0, double s0, double pix_per_mm,
                        double alpha0,
                        float line, float sample, double *x, double *y)

{
double       dline, dsample,dhelp;
double       fl = 1.0;   /* for Clementine routine ls2ins */
double       vinst[3];
SpiceBoolean sp_found;


dline   = (double) line;
dsample = (double) sample;
if (dlrframe_info.spacecraft_id == Clementine)
    {
    ls2ins_ (&l0, &s0, &alpha0, &pix_per_mm, &fl, 
             &dline, &dsample, vinst);
    *x = vinst[0];
    *y = vinst[1];
    }
else
    { /* we use the SSI model, see GLLSPICE_TI */
    dline   = (double) line;
    dline   = (dline - l0) / pix_per_mm;
    dsample = (double) sample;
    dsample = (dsample - s0) / pix_per_mm;
    dhelp   = 1 + alpha0 * (dline*dline + dsample*dsample); 
    *y      = dline * dhelp;
    *x      = dsample *dhelp;
    
/* Voyager and Cassini x =-x, y=-y */
    if ((dlrframe_info.spacecraft_id == Voyager_1) ||
        (dlrframe_info.spacecraft_id == Voyager_2) ||
        !strcmp(dlrframe_info.instrument_name,"CASSINI_ISS_NAC") ||
        !strcmp(dlrframe_info.instrument_name,"CASSINI_ISS_WAC") ||
        strstr(dlrframe_info.instrument_name,"VEX_VMC") ) 
	{
	*x = - (*x);
        *y = - (*y);
        }
        
    }

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrframe_geo.imake
/* Imake file for VICAR subroutine  dlrframe_geo */

#define SUBROUTINE   dlrframe_geo

#define MODULE_LIST  dlrframe_geo.c \
                     dlrframe_getgeo_ikernel.c \
                     dlrframe_getgeo_xy.c
                      

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE

$ Return
$!#############################################################################
$Test_File:
$ create tstdlrframe_geo.c
#include "vicmain_c"

#include "dlrframe.h"
#include "hwldker.h"

void main44()

{
int unit;
int status;
double *samp_x, *samp_y, focal;
double positn [3];
double mat[3][3];
char   adjufile[120];
char   error_message[DLRFRAME_ERROR_LENGTH];
int adjucount;
FILE   *adjuptr;
char   *getenv();
char   *value;
int    ihelp,line,lauf;

dlrframe_info dlrframe_info;
hwkernel_3 bsp;
hwkernel_6 bc;
hwkernel_6 tsc;
hwkernel_1 tpc;
hwkernel_1 bpc;
hwkernel_1 ti;
hwkernel_1 tf;
hwkernel_1 tls;

/* SPICE error action */
erract_c ("SET", SPICE_ERR_LENGTH, "REPORT");
errprt_c ("SET", SPICE_ERR_LENGTH, "NONE");

status = zvunit (&unit, "INP", 1, "");
status = zvopen(unit, "");
if (status != 1)  
   {
   zvmessage("error open input file","");
   zabend();
   } 

status = dlrframe_getinfo(unit,&dlrframe_info);

printf("status %d\n", status);
if (status != 1) 
   {
   status = dlrframe_error(status, "info", error_message);
   zvmessage("dlrframe_getinfo","");
   zvmessage(error_message,"");
   zabend();
   }
   
printf("%d %d %d %d %s\n",       dlrframe_info.spacecraft_id,
                                 dlrframe_info.instrument_id,
                                 dlrframe_info.target_id,
                                 dlrframe_info.adju_id,
                                 dlrframe_info.utc);

   
samp_x = (double *) 
       malloc(dlrframe_info.nl * dlrframe_info.ns * sizeof(double));
if (samp_x == NULL) 
   {
   zvmessage("not enough memory","");
   zabend();
   }

samp_y = (double *) 
       malloc(dlrframe_info.nl * dlrframe_info.ns * sizeof(double));
if (samp_y == NULL) 
   {
   zvmessage("not enough memory","");
   zabend();
   }


zvp("ADJUFILE", adjufile, &adjucount);
if (adjucount == 0)
   {
   adjuptr = NULL;
   if (dlrframe_info.target_id == 301)
      {/* bpcfile exists only for Moon */
      status = hwldker(1, "bpc",&bpc);
      if (status != 1)
         {
         zvmessage("HWLDKER problem","");
         printf("hwldker-status: %d\n",status);
         zabend();
         }
      }

   status = hwldker(5, "bsp", &bsp, "bc",  &bc, "tsc", &tsc, 
                   "tls", &tls, "tf", &tf); 
   if (status != 1)
      {
      zvmessage("HWLDKER problem","");
      printf("hwldker-status: %d\n",status);
      zabend();
      }
   }
else
   {
   value=getenv(adjufile);
   if (value != NULL) strcpy(adjufile,value);
   adjuptr=fopen(adjufile,"r");
   if (adjuptr <= (FILE *)NULL)
      {
      zvmessage ("could not open adjufile","");
      zabend();
      }    
   }   

/* we need these kernels always */
status = hwldker(2, "ti",&ti, "tpc", &tpc);
if (status != 1)
   {
   zvmessage("HWLDKER problem","");
   printf("hwldker-status: %d\n",status);
   zabend();
   }

status = dlrframe_getgeo(dlrframe_info, adjuptr,
                            samp_x, samp_y, &focal,
                            positn, mat);

printf("status %d\n", status);

/* we can also print the NAIF error message:
   getmsg_c ( "LONG", DLRFRAME_ERROR_LENGTH, error_message);
   zvmessage(error_message,""); */

if (status != 1) 
   {
   status = dlrframe_error(status, "geo", error_message);
   zvmessage("dlrframe_getgeo","");
   zvmessage(error_message,"");
   zabend();
   }
   
printf("Focal: %10.5f\n", focal);
zvp("LINE", &line, &status);
ihelp = (line-1)*dlrframe_info.ns;
for (lauf=0; lauf<dlrframe_info.ns; lauf++)
   printf("sample: %5d    x : %10.5f   y: %10.5f\n",
          lauf+1,samp_x[lauf+ihelp],samp_y[lauf+ihelp]);

printf("position: %lf %lf %lf\n", positn[0],positn[1],positn[2]);                            
printf("mat: %lf %lf %lf\n", mat[0][0],mat[0][1],mat[0][2]);                            
printf("mat: %lf %lf %lf\n", mat[1][0],mat[1][1],mat[1][2]);                            
printf("mat: %lf %lf %lf\n", mat[2][0],mat[2][1],mat[2][2]);                            
}

$!-----------------------------------------------------------------------------
$ create tstdlrframe_geo.imake
/* IMAKE file for test program TSTdlrframe_geo */

#define PROGRAM   tstdlrframe_geo  

#define MODULE_LIST  tstdlrframe_geo.c

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_P2SUB    /* for find_hist_key */
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create tstdlrframe_geo.pdf
Process help=*
PARM INP
PARM BSPFILE  TYPE=(STRING,120) COUNT=(0:3)     DEFAULT=--
PARM BCFILE   TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=--
PARM TSCFILE  TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=--
PARM TPCFILE  TYPE=(STRING,120)                 DEFAULT=CONSTANTS
PARM BPCFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=--
PARM TLSFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=LEAPSECONDS
PARM TIFILE   TYPE=(STRING,120)                 
PARM TFFILE   TYPE=(STRING,120)                 
PARM LINE     TYPE=INTEGER                      DEFAULT=1
PARM ADJUFILE                   COUNT=(0:1)     DEFAULT=--
END-PROC
.Title
 Test Program for dlrframe_geo
.HELP

WRITTEN BY:     Thomas Roatsch, DLR   25-May-1999

.LEVEL1
.VARI INP
Input image
.VARI BSPFILE
Binary SP-Kernel 
.VARI BCFILE
Binary C-Kernel
.VARI TSCFILE
Text Clock Kernel 
.VARI TPCFILE
Text Planetary 
Constants Kernel
.VARI BPCFILE
Binary Planetary 
Constants Kernel
.VARI TLSFILE
Text Leapseconds Kernel
.VARI TIFILE
Text Instrument Kernel
.VARI LINE
Line number
.VARI ADJUFILE
Name of Adjufile
.End

$ Return
$!#############################################################################
