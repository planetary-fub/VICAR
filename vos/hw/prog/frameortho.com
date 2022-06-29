$!****************************************************************************
$!
$! Build proc for MIPL module frameortho
$! VPACK Version 1.9, Thursday, March 03, 2005, 20:15:52
$!
$! Execute by entering:		$ @frameortho
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
$!   PDF         Only the PDF file is created.
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
$ write sys$output "*** module frameortho ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_PDF = ""
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
$ if primary .eqs. "PDF" then Create_PDF = "Y"
$ if primary .eqs. "TEST" then Create_Test = "Y"
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_PDF .or. Create_Test .or -
        Create_Imake .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to frameortho.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_PDF then gosub PDF_File
$ if Create_Test then gosub Test_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_PDF = "Y"
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
$   Create_PDF = "Y"
$ Return
$!
$ Set_All_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Do_Make = "Y"
$   Create_PDF = "Y"
$ Return
$!
$ Set_Sys_Options:
$   Create_Source = "Y"
$   Create_Imake = "Y"
$   Create_PDF = "Y"
$   Do_Make = "Y"
$ Return
$!
$Run_Make_File:
$   if F$SEARCH("frameortho.imake") .nes. ""
$   then
$      vimake frameortho
$      purge frameortho.bld
$   else
$      if F$SEARCH("frameortho.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake frameortho
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @frameortho.bld "STD"
$   else
$      @frameortho.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create frameortho.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack frameortho.com -mixed -
	-s frameortho.c frameortho.h -
	-i frameortho.imake -
	-p frameortho.pdf -
	-t tstframeortho.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create frameortho.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/* 
Based on frameortho
*/

#include <stdlib.h>
#include <stddef.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>  
#include <math.h> 
#include <errno.h> 

#if UNIX_OS
#include <malloc.h>	
#include <alloca.h>
#endif

#include "vicmain_c"
#include "dlrframe.h"
#include "dlrmapsub.h"
#include "dlrspice.h"
#include "mp_routines.h"
#include "dlrpho.h"
#include "hwldker.h"
#include "frameortho.h"
#include "dtm.h"
#include "hrgetstdscale.h"

/* private prototypes */

int frameortho_p (str_glob_TYPE *str_glob);
int fra_rip_get_scale (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, double *nom_scale);
int frameortho_getscale  (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, double *scale);
int frameorloc_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, int run);
int framegeorec_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, float *gv_out_buf);
int frametraidtm_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, 
			  int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, double *phoCorVal_vec, int loc_rec);
int frametraidtm_ripnew (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, 
			  int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, double *phoCorVal_vec, int loc_rec);
void rec2graphicll ( double *xyz, double *axes, double *llh);
void xyz2graphicllh ( double *xyz, double *llh, double *axes);
int hwintdtm_bi ( short int *gv_lo, short int *gv_ro, short int *gv_lu, short int *gv_ru,
			 double dv, double du, short int miss_gv, short int *gv );
void rec2centricll_radius ( double *xyz, double *llh, double *axes, double *radius, int naxes);
int hwintgv_bi ( float *gv_lo, float *gv_ro, float *gv_lu, float *gv_ru,
		 double dv, double du, float *gv );
int hwintgv_cc ( double dx, double dy, float *feld, float *result);
double	fct_hwintgv_cc ( double z);

int hwintpho_bi ( double phoCorVal_vec_ap1,double phoCorVal_vec_ap2,
		  double phoCorVal_vec_ap3,double phoCorVal_vec_ap4,
		  double dv, double du, int dV, int dU, double *phoCorVal );

int hwapppro (double x_inp, double y_inp, double inp_off[2], double out_off[2],
		      double *x_out, double *y_out, double *a);
int hwgetpro (double *in_u, double *in_v, double *in_x, double *in_y, double *a);
int framegetapt (dlrframe_info dlrframe_info, int l, int mid_of_l,
	       int *nof_le_p, int *nof_ri_p, int *s, int anchdist);
int hwsortap (int nof_up_le_p, int nof_up_ri_p, int *up_s, double *up_x, double *up_y, double *up_phoCorVal_vec, int *up_foundvec, int *up_signvec,
	      int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, double *lo_x, double *lo_y, double *lo_phoCorVal_vec, int *lo_foundvec, int *lo_signvec);
int hwgetapp (int nof_up_le_p, int nof_up_ri_p, int *up_s, double *up_x, double *up_y, double *up_phoCorVal_vec, int *up_foundvec, int *up_signvec,
	      int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, double *lo_x, double *lo_y, double *lo_phoCorVal_vec, int *lo_foundvec, int *lo_signvec,
	      int *nof_p, int *s_ap1, int *s_ap2, int *s_ap3, int *s_ap4,
	      double *phoCorVal_vec_ap1, double *phoCorVal_vec_ap2,
	      double *phoCorVal_vec_ap3, double *phoCorVal_vec_ap4,
	      double *x_ap1, double *x_ap2, double *x_ap3, double *x_ap4,
	      double *y_ap1, double *y_ap2, double *y_ap3, double *y_ap4, int *dtm_no_dtm);
double max (double w1, double w2, double w3, double w4);
int imax (int w1, int w2, int w3, int w4);
double min (double w1, double w2, double w3, double w4);
int imin (int w1, int w2, int w3, int w4);

void xyz2ll ( double *xyz, double *ll);
int check_quad ( double *line,  double *sample );
void check_size(str_glob_TYPE *str_glob);

int	stdproj_to_mapproj (str_glob_TYPE *str_glob, MP mp_obj, MP mp_stdobj, float *gv_inp_buf);
 
void main44()
 
/*############################################################	*/
/* FRAMEORTHO_NEW: Computes a geometrically corrected frame image 	*/
/*############################################################	*/
/* Calling	zveaction, zvunit, zvopen, zvget, zlget,
		zvmessage, zvabend, zvclose, zvsptr

		mpGetValues, mpSetValues		

		zbodvar

		hwldker, hwgetpar, zhwfailed, zcltgetrcs, cltgetgcl

    (private)   frameortho_p, frameorloc_rip, framegeorec_rip			*/
/*############################################################	*/
	{
   	hwkernel_3 bsp;
   	hwkernel_6 bc, tsc;
   	hwkernel_1 tpc, bpc, ti, tf, tls;
	
        char kernel[8][STRING_SIZE];
        char spice_file_id[100];
        int  lauf;
	
	PHO	   pho_obj;

    int        idum, nof_kernel;
	int	   save_proj, save_border,flag, i, j,  status, callfunc, scale_not_set, temp_l, temp_s, fit_unit, eins=1, 
		   instance, count, c_ptr[3], i_temp[3], cal_unit, nof_out_l_save, nof_out_s_save, nof_std_l, nof_std_s, 
		   oformat_save, oformat_size_save, mp_radius_set_from_fit=0;
    SpiceInt   n_axes, mp_n_axes;
        
	float	   r_temp, temp_float, *gv_out_buf, dummy_gv_out_buf[1];
	
	double     scale_resolution, d_val, cenlat_save, cenlon_save, d_temp, d_temp2,
		   lproff_save, sproff_save, lproff_std, sproff_std, spice_axes[3];

	char	   poslongdir[5], outstring[200], c_temp[120], c_temp3[360], c_temp32[32];
	char	   pool_item[80], ins_id_string[20], informat[5];
	char	   task_name[80], save_mptype[mpMAX_KEYWD_LENGTH+1];


	double centric_lat, centric_lon, temp_centric_cenlat, temp_centric_cenlon, los[3], pos[3], radius, dummy[3];
	
	MP 				mp_obj, mp_stdobj, mp_dtm_obj;
	str_glob_TYPE 	str_glob;
	dlrframe_info 	dlrframe_info;
	dtm 			dtmlabel;

	pho_obj=NULL;
	mp_obj=NULL;
	mp_stdobj=NULL;
	str_glob.limb=0;
	str_glob.found=0;
	str_glob.found_in_dtm=0;
	str_glob.min_longi=999.9; str_glob.max_longi=-999.9;
	str_glob.min_lati=999.9;  str_glob.max_lati=-999.9;
	str_glob.first_real_inp_l=1;

	str_glob.quad[0]=1;str_glob.quad[1]=1;str_glob.quad[2]=1;str_glob.quad[3]=1;

	str_glob.geom=1;
	str_glob.height=0.0;
	
/* ------------------------------------------    SPICE error action  */
	erract_c ("SET", SPICE_ERR_LENGTH, "REPORT");
	errprt_c ("SET", SPICE_ERR_LENGTH, "NONE");


/*----------------------------------------------------------------
	Get FRAMEORTHO_NEW-PPF-Parameters			
	----------------------------------------------------------*/	
		
	callfunc = frameortho_p (&str_glob);
/*-------------------------------------------------------------
	Open Input-file			
	----------------------------------------------------------*/	
			 
	callfunc = zvunit (&(str_glob.inunit), "INP", 1, 0);
	if(callfunc != 1)
		{
		zvmessage("Couldn't unit input-file", 0);
		zabend();
		}
		
	callfunc = zvopen (str_glob.inunit, "OP", "READ", "OPEN_ACT", " ",
			  "U_FORMAT", "REAL", "COND", "BINARY", 0);

	if (callfunc != 1) 
		{
		zvmessage("Error opening input-file in frameortho !","");
		zabend ();
		}
/*-------------------------------------------------------------
	Get Input-file Informations			
	------------------------------------------------------------*/	
	callfunc = dlrframe_getinfo(str_glob.inunit,&dlrframe_info);
	if (callfunc != 1) 
   		{
   		callfunc = dlrframe_error(callfunc, "info", outstring);
   		zvmessage("dlrframe_getinfo","");
   		zvmessage(outstring,"");
   		zabend();
   		}

dlrframe_info.trim_left += str_glob.user_trim_left;
dlrframe_info.trim_right += str_glob.user_trim_right;
dlrframe_info.trim_top += str_glob.user_trim_top;
dlrframe_info.trim_bottom += str_glob.user_trim_bottom;

/*---------------------------------------------------------------	
	Allocation for calibration				
	------------------------------------------------------	*/
		
	str_glob.xcal = (double *) malloc (dlrframe_info.ns*dlrframe_info.nl*sizeof(double));
	if (str_glob.xcal == (double *)NULL) 
		{    	
		sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
		sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
		zabend();
		}
	str_glob.ycal = (double *) malloc (dlrframe_info.ns*dlrframe_info.nl*sizeof(double));
	if (str_glob.ycal == (double *)NULL)
		{    	
		sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
		sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
		zabend();
		}

    nof_kernel = 0;
	strncpy (spice_file_id,"(",1);
/*----------------------------------------------------------------	
	Load kernels 					
    ----------------------------------------------------------------*/	
	callfunc = hwldker (2, "tpc", &tpc, "ti", &ti);
	status = hwldker_error (callfunc, c_temp);
  	if (status != -1)
             	{
         	zvmessage("HWLDKER problem","");
         	zvmessage(c_temp,"");
         	zabend();
         	}
	strcpy(kernel[nof_kernel++],tpc.filename);
	 strncat (spice_file_id,"PCK",3);
	strcpy(kernel[nof_kernel++],ti.filename);
	 strncat (spice_file_id,",IK",3);
	if (str_glob.adj_par == 0)
           { /* we need the FK */
           callfunc = hwldker (1, "tf", &tf);
           status = hwldker_error (callfunc, c_temp);
  	   if (status != -1)
             	{
         	zvmessage("HWLDKER problem","");
         	zvmessage(c_temp,"");
         	zabend();
         	}
          strcpy(kernel[nof_kernel++],tf.filename);
	  strncat (spice_file_id,",FK",3);
          }

/* Roatsch, 2-Jun-2003 bsp necessary for Photometry !!! */   	 
	if ((str_glob.phocorr == 1)||(str_glob.adj_par == 0)) 
		{
		callfunc = hwldker (2,"bsp", &bsp,  "tls", &tls);
		status = hwldker_error (callfunc, c_temp);
  		if (status != -1)
             		{
         		zvmessage("HWLDKER problem","");
         		zvmessage(c_temp,"");
         		zabend();
         		}
		strcpy(kernel[nof_kernel++],tls.filename);
	 	 strncat (spice_file_id,",LSK",4);
		strcpy(kernel[nof_kernel++],bsp.filename[0]);
	 	 strncat (spice_file_id,",SPK",4);
		if (bsp.count>1)
                   {
                   strcpy(kernel[nof_kernel++],bsp.filename[1]);
	 	   strncat (spice_file_id,",SPK",4);
                   if (bsp.count == 3)
                      {
                      strcpy(kernel[nof_kernel++],bsp.filename[2]);
	 	      strncat (spice_file_id,",SPK",4);
                      }
                   }   
		}

	if (str_glob.adj_par == 0) 
		{
	    callfunc = hwldker (2, "tsc", &tsc, "bc", &bc);
 		status = hwldker_error (callfunc, c_temp);
  		if (status != -1)
             	{
         		zvmessage("HWLDKER problem","");
         		zvmessage(c_temp,"");
         		zabend();
         		}
		strcpy(kernel[nof_kernel++],tsc.filename[0]);
	 	 strncat (spice_file_id,",SCLK",5);
		strcpy(kernel[nof_kernel++],bc.filename[0]);
	 	 strncat (spice_file_id,",CK",3);
	    }	

    if (dlrframe_info.target_id == 301)
	    {
							/* bpcfile exists only for Moon */
		callfunc = hwldker(1, "bpc",&bpc);
		status = hwldker_error (callfunc, c_temp);
  		if (status != -1)
             	{
         		zvmessage("HWLDKER problem","");
         		zvmessage(c_temp,"");
         		zabend();
         		}
		strcpy(kernel[nof_kernel++],bpc.filename);
	 	 strncat (spice_file_id,",SPK",4);
      	    }
	
     strncat (spice_file_id,")",1);

/* was in frameortho_p but target_id is unknown at this call and kernels 
   are not loaded */
	bodvar_c (dlrframe_info.target_id, "MEANRADIUS", &n_axes, spice_axes);
        if (failed_c() ) /* no MEANRADIUS */
           {
           reset_c();
           count=0;
           }
        else count=1;   
	if (count > 0) 
		{
		for (i=0;i<3;i++) str_glob.mp_axes[i]=spice_axes[0];
		}
	else 
		{
		for (i=0;i<3;i++) str_glob.mp_axes[i]=-1.0;
		}
/* end of  MEANRADIUS */

/*---------------------------------------------------------------	
  get geometric calibration information, position and pointing				
	------------------------------------------------------	*/
	if (str_glob.tol>0.) dlrframe_info.tol = str_glob.tol;
	callfunc = dlrframe_getgeo(dlrframe_info, str_glob.adjuptr,
                            str_glob.xcal, str_glob.ycal, &(str_glob.focal),
                            str_glob.positn, str_glob.cpmat);

	if (callfunc != 1) 
   		{
   		callfunc = dlrframe_error(callfunc, "geo", outstring);
   		zvmessage("dlrframe_getgeo","");
   		zvmessage(outstring,"");
   		zabend();
   		}
/*----------------------------------------------------------------	
  Fill Map Projection Data Object					
	-------------------------------------------------------	*/

	if (str_glob.fittofile==0)
		{
		callfunc = hwgetpar(&mp_obj, dlrframe_info.target_id);
		if (callfunc != 0) 
			{
			zvmessage("No map proj. object created  !","");
			zabend ();
			}
		if (str_glob.mp_axes[0] < 0.0)
			{
			for (i=0;i<3;i++) str_glob.mp_axes[i]=str_glob.axes[i];
			}
		else
			{
 			callfunc = mpSetValues (mp_obj, mpA_AXIS_RADIUS, str_glob.mp_axes[0], NULL);
 			callfunc = mpSetValues (mp_obj, mpB_AXIS_RADIUS, str_glob.mp_axes[1], NULL);
 			callfunc = mpSetValues (mp_obj, mpC_AXIS_RADIUS, str_glob.mp_axes[2], NULL);
			}
		}
	else
		{
		callfunc = zvunit (&fit_unit, "any",  1, "U_NAME", str_glob.fittofile_name, 0);
		if(callfunc != 1)
			{
		    	zvmessage("Couldn't unit FITTOIMAGE file", 0);
			zabend();
			}
		callfunc = zvopen (fit_unit, "OP", "READ", "OPEN_ACT",	" ", 0);
		if(callfunc != 1)
		    	{
		    	zvmessage("Couldn't open FITTOIMAGE file", 0);
			zabend();
		     	}
		callfunc = mpInit(&mp_obj);	

		callfunc = dlr_mpLabelRead(mp_obj, fit_unit, &(str_glob.prefs));	
		if (callfunc != mpSUCCESS) 
			{    	
			sprintf(outstring, "Error in dlr_mpLabelRead !!");
     			zvmessage(outstring,"");
			zabend();
			}
		 



			callfunc = mpGetValues ( mp_obj, mpA_AXIS_RADIUS, &str_glob.mp_axes[0], NULL); 
			callfunc = mpGetValues ( mp_obj, mpB_AXIS_RADIUS, &str_glob.mp_axes[1], NULL); 
			callfunc = mpGetValues ( mp_obj, mpC_AXIS_RADIUS, &str_glob.mp_axes[2], NULL); 

			callfunc = find_hist_key (fit_unit, "BODY_A_AXIS_RADIUS", TRUE, task_name, &instance);
			if (callfunc != 1)
				{
				for (i=0;i<3;i++) str_glob.axes[i]=str_glob.mp_axes[i];
				}
			else
				{
				callfunc = zlget (fit_unit, "HISTORY", 
				"BODY_A_AXIS_RADIUS", &r_temp,  "HIST", task_name, "INSTANCE", instance, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
				str_glob.axes[0] = (double)r_temp;
				callfunc = zlget (fit_unit, "HISTORY", 
				"BODY_B_AXIS_RADIUS", &r_temp,  "HIST", task_name, "INSTANCE", instance, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
				str_glob.axes[1] = (double)r_temp;
				callfunc = zlget (fit_unit, "HISTORY", 
				"BODY_C_AXIS_RADIUS", &r_temp,  "HIST", task_name, "INSTANCE", instance, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
				str_glob.axes[2] = (double)r_temp;
				mp_radius_set_from_fit = 1;
				}



		callfunc = zvget (fit_unit, "NL",  &(str_glob.nl), "NS",  &(str_glob.ns), 0);
		sprintf(c_temp, "OUT-File will fit to %s ...",str_glob.fittofile_name);
     		zvmessage(c_temp,"");
		}
	
/*--------------------------------------------------------------	*/
/* 	Check for set LINE/SAMPLE_PROJECTION_OFFSET				*/
/*--------------------------------------------------------------	*/
	str_glob.lineoffset_set=1;
	callfunc = mpGetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, &temp_float, NULL);
	if (callfunc!=0) 
	    {
	    callfunc = mpSetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, 0.0, NULL);
	    str_glob.lineoffset_set=0;
	    }
	str_glob.sampleoffset_set=1;
	callfunc = mpGetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, &temp_float, NULL);
	if (callfunc!=0) 
	    {
	    callfunc = mpSetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, 0.0, NULL);
	    str_glob.sampleoffset_set=0;
	    }


/*----------------------------------------------------------------	
	Check for user defined scale/resolution					
	-------------------------------------------------------	*/
	scale_not_set = 0;

	callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);

	if ((callfunc == mpKEYWORD_NOT_SET) ||
	    ((scale_resolution  > -0.00001) && (scale_resolution  < 0.00001)))
		{
		/*-----------------------------------------------------	
		no user defined scale or resolution					
		-------------------------------------------------------	*/
		scale_not_set = 1;
		}
	else
		{
		/*-----------------------------------------------------	
		Something was defined by the user.
		But it is not obvious whether scale and/or resolution
		was defined !! 
		Attention: The following call of mpSetValue is essential
		for the case that only MAP_RESOLUTION was defined by the user
		and no MAP_SCALE was defined.
		Then, the previous call of mpGetValues would have given back
		a value for MAP_SCALE although it is NOT within the mp_obj !!				
		But note: mp_routines (e.g. mpSphere) need MAP_SCALE
			  for its computations ! 
		
		Set scale value using mpSetValues
		to be sure that scale is stored in the mp_obj.
		-------------------------------------------------------	*/
		callfunc = mpSetValues ( mp_obj, mpMAP_SCALE, scale_resolution, NULL);
		}

/*----------------------------------------------------------------	
	Get POSITIVE_LONGITUDE_DIRECTION-interface (str_glob.poslongdir_fac)
	between dlrsurfpt's longitudes (allways positive EAST) and the 
	user defined or dtm POSITIVE_LONGITUDE_DIRECTION (may be positive WEST)					
	-------------------------------------------------------	*/
	str_glob.poslongdir_fac = 1.;
	callfunc = mpGetValues ( mp_obj, mpPOSITIVE_LONGITUDE_DIRECTION, poslongdir, NULL); 
	if (strcmp(poslongdir, "WEST")==0) str_glob.poslongdir_fac = -1.;


/*----------------------------------------------------------------	
	Fill PHO-Data Object					
	-------------------------------------------------------	*/
  	if (str_glob.phocorr != 0)
		{
  		callfunc = phoInit( &pho_obj);
  		callfunc = phoGetParms( pho_obj);
		}

	/*---------------------------------------------------------------
	Get Planetary Axes					
	------------------------------------------------------	*/
 
 	if ((str_glob.axes[0]<= 0.001)||(str_glob.axes[1]<= 0.001)||(str_glob.axes[2]<= 0.001))
		{
		/*----------------------------------------------------
		some Planetary Axes are not set by the user 
		. use bodvar to be consistent with mp_routines					
		------------------------------------------------------	*/
		bodvar_c (dlrframe_info.target_id, "RADII", &n_axes, spice_axes);
   		zhwfailed();
  	
		for (i=0;i<3;i++){if (str_glob.axes[i]<= 0.001) str_glob.axes[i]=spice_axes[i];}
		}
	for (i=0;i<3;i++){if (str_glob.mp_axes[i]<= 0.001) str_glob.mp_axes[i]=str_glob.axes[i];}
	
	if (fabs(str_glob.min_valid_lati)!=90.0) /* make it planetocentric */
		 str_glob.min_valid_lati = my_pi2deg*
					    (
					    atan (tan (str_glob.min_valid_lati*my_deg2pi)*str_glob.mp_axes[2]*str_glob.mp_axes[2]/(str_glob.mp_axes[0]*str_glob.mp_axes[0]))
					    );

	if (fabs(str_glob.max_valid_lati)!=90.0) /* make it planetocentric */
		 str_glob.max_valid_lati = my_pi2deg*
					    (
					    atan (tan (str_glob.max_valid_lati*my_deg2pi)*str_glob.mp_axes[2]*str_glob.mp_axes[2]/(str_glob.mp_axes[0]*str_glob.mp_axes[0]))
					    );
	/*---------------------------------------------------------------
	Get body_long_axis					
	------------------------------------------------------	*/
	if (fabs(str_glob.mp_axes[0]-str_glob.mp_axes[1]) > 0.001)
		/*---------------------------------------------------------------
		3-axial ellipsoid					
		------------------------------------------------------	*/
     		{
		if (str_glob.long_axis < -999.) 
		    {
 		    /*---------------------------------------------------------------
		    body_long_axis not set by the user, use value from SPICE				
		    ------------------------------------------------------	*/
		    bodvar_c(dlrframe_info.target_id,"LONG_AXIS", &mp_n_axes, &(str_glob.long_axis));
   		    
		    if (mp_n_axes==0) 
			{
 			/*---------------------------------------------------------------
			body_long_axis not in SPICE, use body_long_axis=0.0 					
			------------------------------------------------------	*/
			reset_c ();
      			str_glob.long_axis=0.0;
			}
			    
		    callfunc = mpSetValues (mp_obj, mpBODY_LONG_AXIS, str_glob.long_axis, NULL);
      		    }
		mp_n_axes=3;
		}
	else
		/*---------------------------------------------------------------
		1- or 2-axial ellipsoid					
		------------------------------------------------------	*/
		{
		mp_n_axes=1;
		if (fabs(str_glob.mp_axes[0]-str_glob.mp_axes[2]) > 0.001) mp_n_axes=2;
		if (str_glob.long_axis < -999.) str_glob.long_axis=0.0;
		callfunc = mpSetValues (mp_obj, mpBODY_LONG_AXIS, str_glob.long_axis, NULL);
		}
	str_glob.n_axes=mp_n_axes;
	
	if (fabs(str_glob.axes[0]-str_glob.axes[1]) > 0.001) n_axes=3;
	else
		{
		n_axes=1;
		if (fabs(str_glob.axes[0]-str_glob.axes[2]) > 0.001) n_axes=2;
		}
	str_glob.n_axes=n_axes;
	
/*--------------------------------------------------------------	*/
/* Check for set center_longitude and center_latitude 			*/
/*--------------------------------------------------------------	*/
	xyz2ll (str_glob.positn, str_glob.ll);			    /* ll centric radians */
	    
	if ((str_glob.ll[0]>(-PI/2.0+0.0000001))&&(str_glob.ll[0]<(PI/2.0-0.0000001)))	    
		str_glob.ll[0] = (atan (str_glob.axes[0]*str_glob.axes[0]/(str_glob.axes[2]*str_glob.axes[2])
		 *tan (str_glob.ll[0])));			    /* lat graphic radians */
	str_glob.ll[0]=str_glob.ll[0]*my_pi2deg;			    /* lat graphic degrees */   
	str_glob.ll[1]=str_glob.ll[1]*my_pi2deg*str_glob.poslongdir_fac;    /* lon graphic degrees */
	if (str_glob.ll[1]<0.0)str_glob.ll[1]+=360.0;

	if (str_glob.poslongdir_fac==-1) printf ("Sub-sc-lat (graphic) %lf Sub-sc-lon (pos.West) %lf \n",str_glob.ll[0],str_glob.ll[1]);	  
    	else printf ("Sub-sc-lat (graphic) %lf Sub-sc-lon (pos.East) %lf \n",str_glob.ll[0],str_glob.ll[1]);	  

	status = mpGetValues ( mp_obj, mpCENTER_LONGITUDE, &d_val, NULL);
	if (status == mpKEYWORD_NOT_SET)  
	    {
		if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")==0) /* SRC case: get standard scale */
			{
			callfunc = find_hist_key (str_glob.inunit, "EASTERN_LONGITUDE_AT_CENTER", TRUE, task_name, &instance);
			callfunc = zlget (str_glob.inunit, "HISTORY", "EASTERN_LONGITUDE_AT_CENTER", &r_temp, "HIST", task_name, "INSTANCE", instance,"FORMAT", "REAL", 0 );
			if (callfunc != 1)
	    		{
	    		zvmessage(" History item EASTERN_LONGITUDE_AT_CENTER missing ! Please set CENTER_LONGITUDE !!","");
	    		zabend();
	    		}
			str_glob.cenlong = (double)((int)(r_temp*str_glob.poslongdir_fac+0.5));
			if (str_glob.cenlong<0.0)str_glob.cenlong+=360.0;
			 
	    	callfunc = mpSetValues (mp_obj, mpCENTER_LONGITUDE, str_glob.cenlong, NULL);
			}
		else
			{
	    	callfunc = mpSetValues (mp_obj, mpCENTER_LONGITUDE, str_glob.ll[1], NULL);
	    	sprintf(outstring, "CENTER_LONGITUDE is set to sub-sc-lon !");
     	    zvmessage(outstring,"");
	    	str_glob.cenlong=str_glob.ll[1];
			}
	    }
	else str_glob.cenlong=d_val;
	
	status = mpGetValues ( mp_obj, mpCENTER_LATITUDE, &d_val, NULL);
	if (status == mpKEYWORD_NOT_SET)  
	    {
		if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")==0) /* SRC case: get standard scale */
			{
			callfunc = find_hist_key (str_glob.inunit, "CENTRIC_LATITUDE_AT_CENTER", TRUE, task_name, &instance);
			callfunc = zlget (str_glob.inunit, "HISTORY", "CENTRIC_LATITUDE_AT_CENTER", &r_temp, "HIST", task_name, "INSTANCE", instance,"FORMAT", "REAL", 0 );
			if (callfunc != 1)
	    		{
	    		zvmessage(" History item CENTRIC_LATITUDE_AT_CENTER missing ! Please set CENTER_LATITUDE !!","");
	    		zabend();
	    		}
			if (r_temp > 85.) 
				{
				str_glob.cenlat = 90.;
				strcpy (str_glob.mptype, "LAMBERT_AZIMUTHAL");
				}
			else if (r_temp < -85.) 
				{
				str_glob.cenlat = -90.;
				strcpy (str_glob.mptype, "LAMBERT_AZIMUTHAL");
				}
			else 
				{
				str_glob.cenlat = 0.;
				strcpy (str_glob.mptype, "SINUSOIDAL");
				}
	    	callfunc = mpSetValues (mp_obj, mpCENTER_LATITUDE, str_glob.cenlat, NULL);
	    	callfunc = mpSetValues (mp_obj, mpMAP_PROJECTION_TYPE, str_glob.mptype, NULL);
	    	sprintf(outstring, "You did not set CENTER_LATITUDE !", str_glob.mptype);
     	    zvmessage(outstring,"");
	    	sprintf(outstring, "CENTER_LATITUDE is set to %7.1lf !", str_glob.cenlat);
     	    zvmessage(outstring,"");
	    	sprintf(outstring, "and", str_glob.cenlat);
     	    zvmessage(outstring,"");
	    	sprintf(outstring, "MAP_PROJECTION_TYPE is set to %s !", str_glob.mptype);
     	    zvmessage(outstring,"");
	    	callfunc = mpSetValues (mp_obj, mpMAP_PROJECTION_TYPE, str_glob.mptype, NULL);
			}
		else
			{
	    	callfunc = mpSetValues (mp_obj, mpCENTER_LATITUDE, str_glob.ll[0], NULL);
	    	sprintf(outstring, "CENTER_LATITUDE is set to sub-sc-lat !");
     	    zvmessage(outstring,"");
	    	str_glob.cenlat=str_glob.ll[0];
			}
	    }
	else str_glob.cenlat=d_val;

/*----------------------------------------------------------------	
	Check for critical mpMAP_PROJECTION_TYPE					
	-------------------------------------------------------	*/
	callfunc = mpGetValues ( mp_obj, mpMAP_PROJECTION_TYPE, c_temp, NULL);
	strncpy (str_glob.mptype, c_temp, mpMAX_KEYWD_LENGTH);
	if (strcmp(c_temp, "ORTHOGRAPHIC")==0)		str_glob.critical_projection = -1;
	else if ((strcmp(c_temp, "LAMBERT_AZIMUTHAL")==0) ||
		 (strcmp(c_temp, "STEREOGRAPHIC")==0))	str_glob.critical_projection = 0;
	else if ((strcmp(c_temp, "SINUSOIDAL")==0) ||
		 (strcmp(c_temp, "EQUIDISTANT")==0) ||
		 (strcmp(c_temp, "MOLLWEIDE")==0) ||
		 (strcmp(c_temp, "CYLINDRICAL_EQUAL_AREA")==0))	str_glob.critical_projection = 1;
	else if  (strcmp(c_temp, "MERCATOR")==0) str_glob.critical_projection = 2;
	else str_glob.critical_projection = 99;

	if (str_glob.critical_projection == -1)
		{
		if ((str_glob.cenlat>(-90.0+0.0000001))&&(str_glob.cenlat<(90.0-0.0000001)))	    
		temp_centric_cenlat = (atan (str_glob.axes[2]*str_glob.axes[2]/(str_glob.axes[0]*str_glob.axes[0])
		    *tan (str_glob.cenlat*my_deg2pi)));
		else temp_centric_cenlat=str_glob.cenlat*my_deg2pi;
		temp_centric_cenlon = str_glob.cenlong*my_deg2pi*str_glob.poslongdir_fac;
		los[0]=cos(temp_centric_cenlon)*cos(temp_centric_cenlat);
		los[1]=sin(temp_centric_cenlon)*cos(temp_centric_cenlat);
		los[2]=sin(temp_centric_cenlat);
		pos[0]=pos[1]=pos[2]=0.0;
		dlrsurfptl_xyz (pos, los, str_glob.axes[0], str_glob.axes[1], str_glob.axes[2], str_glob.long_axis, dummy, &callfunc);
		radius = dlrvnorm (dummy);
		str_glob.xcen=radius*cos(temp_centric_cenlat)*cos(temp_centric_cenlon);
		str_glob.ycen=radius*cos(temp_centric_cenlat)*sin(temp_centric_cenlon);
		str_glob.zcen=radius*sin(temp_centric_cenlat);
		str_glob.d0=sqrt(str_glob.xcen*str_glob.xcen+str_glob.ycen*str_glob.ycen+str_glob.zcen*str_glob.zcen);	    
		str_glob.d02=str_glob.d0*str_glob.d0;	    
		}

	callfunc = dlr_earth_map_get_prefs (mp_obj, &(str_glob.prefs));
	if (callfunc != 1)
		{
		printf("Setting CENTER_LATITUDE = 0, process continues ...\n");
	    callfunc = mpSetValues (mp_obj, mpCENTER_LATITUDE, 0.0, NULL);
		}	
/*-------------------------------------------------------------
	Open dtm-file			
	----------------------------------------------------------*/	
	callfunc = zvunit (&(str_glob.dtmunit), "anything",  1, "U_NAME", str_glob.dtm_filename, 0);
	if(callfunc != 1)
		{
		zvmessage("Couldn't unit DTM file", 0);
		zabend();
		}

	callfunc = zvopen(str_glob.dtmunit, "OP", "READ", 0);
	if(callfunc != 1)
	    {
/*-------------------------------------------------------------
	    GEOM-Mode !!!			
	    ----------------------------------------------------------*/	
	    zvmessage("DTM-File could not be opened, trying GEOM-mode ...",0);
   	    callfunc = sscanf (str_glob.dtm_filename,"%lf",&(str_glob.height));
	    if (callfunc<1) str_glob.height=-999999.0;
	    
	    if (str_glob.fittofile==1)
			{
			callfunc = find_hist_key (fit_unit, "REFERENCE_HEIGHT", FALSE, task_name, &instance);
			if (callfunc != 1)
	    		{
	    		sprintf(outstring, "No Label item REFERENCE_HEIGHT in FITTOFILE %s !!",str_glob.fittofile_name);
     	    		zvmessage(outstring,"");
	    		sprintf(outstring, "REFERENCE_HEIGHT is set to 0.0, process continues ...\n");
     	    		zvmessage(outstring,"");
				str_glob.height = 0.0;
	    		}
			else 
				{
				callfunc = zlget (fit_unit, "HISTORY", 
				"REFERENCE_HEIGHT", &r_temp,  "HIST", task_name, "INSTANCE", instance, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
				if (callfunc != 1)
	    			{
	    			sprintf(outstring, "No Label item REFERENCE_HEIGHT in FITTOFILE %s !!",str_glob.fittofile_name);
     	    			zvmessage(outstring,"");
	    			sprintf(outstring, "REFERENCE_HEIGHT is set to 0.0, process continues ...\n");
     	    			zvmessage(outstring,"");
					str_glob.height = 0.0;
					}
				else str_glob.height = (double)r_temp;
	    		}
			}
    	 else
			{
	    	sprintf(outstring, "Using fix height: %lf m above target reference body ...", str_glob.height );
     	    	zvmessage(outstring,"");
	    		
			}
	     callfunc = mpGetValues ( mp_obj, mpA_AXIS_RADIUS, &str_glob.dtm_axes[0], NULL); 
	     callfunc = mpGetValues ( mp_obj, mpB_AXIS_RADIUS, &str_glob.dtm_axes[1], NULL); 
	     callfunc = mpGetValues ( mp_obj, mpC_AXIS_RADIUS, &str_glob.dtm_axes[2], NULL);
 	    }
	else 
	    {
/*-------------------------------------------------------------
	    Ortho-Mode !!!			
	    ----------------------------------------------------------*/	
 	    str_glob.geom=0;
	    sprintf(c_temp, "Using %s as DTM-file ...\n",str_glob.dtm_filename );
     	    zvmessage(c_temp,"");
	    
	    /* Initialize MP object */
	    callfunc = mpInit(&mp_dtm_obj);
	    if(callfunc != mpSUCCESS)
		{
		zvmessage("mpInit failed for dtm !!",0);
		zabend();
		}
	    /* Read DTM label */
	    callfunc = hwdtmrl(str_glob.dtmunit, &dtmlabel);
	    str_glob.min_h_in_dtm = ((double)dtmlabel.dtm_minimum_dn * dtmlabel.dtm_scaling_factor + (double)dtmlabel.dtm_offset);
	    str_glob.max_h_in_dtm = ((double)dtmlabel.dtm_maximum_dn * dtmlabel.dtm_scaling_factor + (double)dtmlabel.dtm_offset);
	    callfunc = dlr_mpLabelRead(mp_dtm_obj, str_glob.dtmunit, &(str_glob.prefs_dtm));				
	    callfunc = zvget (str_glob.dtmunit, "NL",  &(str_glob.nof_dtm_l), "NS",  &(str_glob.nof_dtm_s), 0); 

	    str_glob.ram_dtm=str_glob.nof_dtm_l*str_glob.nof_dtm_s*sizeof(short int);
	    str_glob.dtm_buf   = (short int *) malloc (str_glob.ram_dtm);
	    if (str_glob.dtm_buf == (short int *)NULL) 
		{
		sprintf(outstring, "Error during allocation of dtm data!!");
     		zvmessage(outstring,"");
		zabend();
		}
	    str_glob.dtm_tab_in   = (int *) malloc ((str_glob.nof_dtm_l)*sizeof(int));
	    if (str_glob.dtm_tab_in == (int *)NULL) 
		{
		sprintf(outstring, "Error during allocation of dtm_tab_in!!");
     		zvmessage(outstring,"");
		zabend();
		}
	    str_glob.dtm_tab_in[0]=0;
	    for (i=1; i<str_glob.nof_dtm_l; i++) { *(str_glob.dtm_tab_in+i) = *(str_glob.dtm_tab_in+i-1)+str_glob.nof_dtm_s; }
	    for (i=0;i<str_glob.nof_dtm_l;i++)
	    callfunc = zvread (str_glob.dtmunit, (str_glob.dtm_buf+str_glob.dtm_tab_in[i]),
				           "LINE", i, "SAMP", 1, "NSAMPS", str_glob.nof_dtm_s, 0);

	    callfunc = mpGetValues ( mp_dtm_obj, mpA_AXIS_RADIUS, &str_glob.dtm_axes_map[0], NULL); 
	    callfunc = mpGetValues ( mp_dtm_obj, mpB_AXIS_RADIUS, &str_glob.dtm_axes_map[1], NULL); 
	    callfunc = mpGetValues ( mp_dtm_obj, mpC_AXIS_RADIUS, &str_glob.dtm_axes_map[2], NULL);
	    callfunc = mpGetValues  ( mp_dtm_obj, mpMAP_SCALE, &str_glob.dtm_scale, NULL); 
	    str_glob.dtm_scale *= 1000.; 
 
	    str_glob.dtm_poslongdir_fac = 1.;
	    callfunc = mpGetValues ( mp_dtm_obj, mpPOSITIVE_LONGITUDE_DIRECTION, poslongdir, NULL); 
	    if (strcmp(poslongdir, "WEST")==0) str_glob.dtm_poslongdir_fac = -1.;
	    callfunc = dlr_earth_map_get_prefs (mp_dtm_obj, &(str_glob.prefs_dtm));
	    if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	
	    }

/*--------------------------------------------------------------	*/
/* Check for not set SCALE						*/
/*--------------------------------------------------------------	*/
	if (str_glob.geom==1) 	for (i=0;i<3;i++) str_glob.dtm_axes[i] = str_glob.axes[i];
	else 
		{
		str_glob.dtm_axes[0] = (double)(dtmlabel.dtm_a_axis_radius);
		str_glob.dtm_axes[1] = (double)(dtmlabel.dtm_b_axis_radius);
		str_glob.dtm_axes[2] = (double)(dtmlabel.dtm_c_axis_radius);
		}

	if (scale_not_set == TRUE) 
	    {
		if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")==0) /* SRC case: get standard scale */
			{
			callfunc = find_hist_key (str_glob.inunit, "BEST_GROUND_SAMPLING_DISTANCE", TRUE, task_name, &instance);
			callfunc = zlget (str_glob.inunit, "HISTORY", "BEST_GROUND_SAMPLING_DISTANCE", &r_temp, "HIST", task_name, "INSTANCE", instance,"FORMAT", "REAL", 0 );
			if (callfunc != 1)
	    		{
	    		zvmessage(" History item BEST_GROUND_SAMPLING_DISTANCE missing ! Please set MP_SCALE !!","");
	    		zabend();
	    		}
			d_temp = (double)r_temp;
			callfunc = hrgetstdscale ("MEX_HRSC_SRC", d_temp, &scale_resolution);
			if (callfunc != 1)
	    		{
				sprintf(outstring, "Error in hrgetstdscale: invalid DETECTOR_ID %s !", "MEX_HRSC_SRC");
     			zvmessage(outstring,"");
	    		zabend();
	    		}
			}
		else callfunc = fra_rip_get_scale (&str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, &scale_resolution);

	    callfunc = mpSetValues (mp_obj, mpMAP_SCALE, scale_resolution, NULL);
	    sprintf(outstring, "Scale set to %lf km ...\n", scale_resolution );
     	    zvmessage(outstring,"");
	    }

	if (!str_glob.geom)
		{
	        callfunc = mpGetValues ( mp_dtm_obj, mpMAP_SCALE, &str_glob.scale_ratio, NULL);
		str_glob.scale_ratio = scale_resolution/str_glob.scale_ratio;	
		}

	callfunc = dlr_earth_map_get_prefs (mp_obj, &(str_glob.prefs));
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	
/*--------------------------------------------------------------------	
	Computation of location and size of the new rectified image	
	-------------------------------------------------------------*/

	str_glob.pole=0;
	str_glob.two_or_three_d_limb=0;
	dlrframe_info.nl -= dlrframe_info.trim_bottom;
	callfunc = frameorloc_rip (&str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 1);
	if (callfunc == -998) 
		{
		sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
		sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
		callfunc = zvclose (str_glob.inunit, 0);
		zabend();
		}
	if ((str_glob.last_real_inp_l+5)<=dlrframe_info.nl) dlrframe_info.nl = str_glob.last_real_inp_l+5;
/*dlrframe_info.nl-=5;*/

	callfunc = dlr_earth_map_get_prefs (mp_obj, &(str_glob.prefs));
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	

/*--------------------------------------------------------------------
	Open Output-file 	
	-------------------------------------------------------------*/	

	callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);

	callfunc = zvget (str_glob.inunit, "FORMAT",  informat, 0);
	if (str_glob.oformat == 0)
		{
		if (strcmp(informat, "BYTE") == 0)
			{
			str_glob.oformat = 1;
			str_glob.oformat_size = 1;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "BYTE", 0);

		        callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);	
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "BYTE", 0);
			}
		else if (strcmp(informat, "HALF") == 0)
			{
			str_glob.oformat = 2;
			str_glob.oformat_size = 2;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "HALF", 0);

		        callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);	
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "HALF", 0);
			}
		else if (strcmp(informat, "FULL") == 0)
			{
			str_glob.oformat = 3;
			str_glob.oformat_size = 4;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "FULL", 0);

		        callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);	
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "FULL", 0);
			}
		else if (strcmp(informat, "REAL") == 0)
			{
			str_glob.oformat = 4;
			str_glob.oformat_size = 4;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "REAL", 0);

		        callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);	
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "REAL", 0);
			}
		}
	else 
		{
		if ((str_glob.oformat == -1)&&(strcmp(informat, "BYTE")==0))
		    {
		    str_glob.oformat = 1;
		    str_glob.oformat_size = 1;
		    check_size(&str_glob);
		    callfunc = zvopen (str_glob.outunit, 
		    "U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
		    "OP", "WRITE", "OPEN_ACT", "SA", "O_FORMAT", "BYTE", "U_FORMAT", "BYTE", 0);

		    callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);	
		    callfunc = zvclose (str_glob.outunit, 0);

		    callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
		    callfunc = zvopen (str_glob.outunit,
		    "U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
		    "OP", "UPDATE", "OPEN_ACT", "SA", "O_FORMAT", "BYTE", "U_FORMAT", "BYTE", 0);
		    }
		else
		    {
		    str_glob.oformat = 4;
		    str_glob.oformat_size = 4;
		    check_size(&str_glob);
		    callfunc = zvopen (str_glob.outunit, 
		    "U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
		    "OP", "WRITE", "OPEN_ACT", "SA", "O_FORMAT", "REAL", "U_FORMAT", "REAL", 0);

		    callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);		
		    callfunc = zvclose (str_glob.outunit, 0);

		    callfunc = zvunit (&(str_glob.outunit), "OUT", 1, 0);
		    callfunc = zvopen (str_glob.outunit,
		    "U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
		    "OP", "UPDATE", "OPEN_ACT", "SA", "O_FORMAT", "REAL", "U_FORMAT", "REAL", 0);
		    }
		}

	if (str_glob.match)
		{
		zvp ("OUT", str_glob.out_filename, &count);
		strcpy (c_temp,str_glob.out_filename);
		strncat (c_temp,"_l",2);
 		callfunc = zvunit (&(str_glob.match_x_unit), "none1", 1 ,"U_NAME", c_temp, 0);
		i=str_glob.oformat;
		str_glob.oformat = 4;
		check_size(&str_glob);
		str_glob.oformat = i;

		callfunc = zvopen (str_glob.match_x_unit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "O_FORMAT", "REAL","U_FORMAT", "REAL", 0);

		callfunc = zvclose (str_glob.match_x_unit, 0);

		callfunc = zvunit (&(str_glob.match_x_unit), "none1", 1 ,"U_NAME", c_temp, 0);
		callfunc = zvopen (str_glob.match_x_unit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "O_FORMAT", "REAL","U_FORMAT", "REAL", 0);
		strcpy (c_temp,str_glob.out_filename);
		strncat (c_temp,"_s",2);
 		callfunc = zvunit (&(str_glob.match_y_unit), "none2", 1 ,"U_NAME", c_temp, 0);
		i=str_glob.oformat;
		str_glob.oformat = 4;
		check_size(&str_glob);
		str_glob.oformat = i;

		callfunc = zvopen (str_glob.match_y_unit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "O_FORMAT", "REAL","U_FORMAT", "REAL", 0);

		callfunc = zvclose (str_glob.match_y_unit, 0);

		callfunc = zvunit (&(str_glob.match_y_unit), "none2", 1 ,"U_NAME", c_temp, 0);
		callfunc = zvopen (str_glob.match_y_unit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "O_FORMAT", "REAL","U_FORMAT", "REAL", 0);
		}

		
		
	if ((str_glob.limb==1)&&(str_glob.badlimb!=1))
	    {
	    if (n_axes>1) str_glob.two_or_three_d_limb=1;
	    callfunc = mpInit (&mp_stdobj);

	    callfunc = dlr_mpLabelRead(mp_stdobj, str_glob.outunit, &(str_glob.prefs_std));				
	    callfunc = mpSetValues (mp_stdobj, mpMAP_PROJECTION_TYPE, "ORTHOGRAPHIC", NULL);
	    if ((str_glob.ll[0]>(-90.0+0.0000001))&&(str_glob.ll[0]<(90.0-0.0000001)))	    
	    centric_lat = (atan (str_glob.axes[2]*str_glob.axes[2]/(str_glob.axes[0]*str_glob.axes[0])
			  *tan (str_glob.ll[0]*my_deg2pi))) * my_pi2deg;
	    else centric_lat = str_glob.ll[0];
		
	    if ((fabs(str_glob.ll[1])!=90.0)&&(fabs(str_glob.ll[1])!=270.0))	    
	    centric_lon = (atan (str_glob.axes[2]*str_glob.axes[2]/(str_glob.axes[1]*str_glob.axes[1])
			  *tan (str_glob.ll[1]*my_deg2pi))) * my_pi2deg;
	    else centric_lon = str_glob.ll[1];
	    if (centric_lon<0.0)centric_lon+=360.0;		
	    if (fabs(centric_lon-str_glob.ll[1])>100.0)centric_lon-=180.0;		
	    if (centric_lon<0.0)centric_lon+=360.0;		
		
	    callfunc = mpSetValues (mp_stdobj, mpCENTER_LATITUDE, centric_lat, NULL);
	    callfunc = mpSetValues (mp_stdobj, mpCENTER_LONGITUDE, centric_lon, NULL);
	    callfunc = mpSetValues (mp_stdobj, mpLINE_PROJECTION_OFFSET, 0.0, NULL);
	    callfunc = mpSetValues (mp_stdobj, mpSAMPLE_PROJECTION_OFFSET, 0.0, NULL);
	    if (str_glob.two_or_three_d_limb==1)
 		{
 		callfunc = mpSetValues (mp_stdobj, mpA_AXIS_RADIUS, str_glob.mp_axes[0], NULL);
 		callfunc = mpSetValues (mp_stdobj, mpB_AXIS_RADIUS, str_glob.mp_axes[0], NULL);
 		callfunc = mpSetValues (mp_stdobj, mpC_AXIS_RADIUS, str_glob.mp_axes[0], NULL);
 		}

	    nof_out_l_save=str_glob.nof_out_l;
	    nof_out_s_save=str_glob.nof_out_s;
	     
	    save_proj=str_glob.critical_projection;
	    str_glob.critical_projection = -1;

	    strncpy (save_mptype, str_glob.mptype, mpMAX_KEYWD_LENGTH);
	    strncpy (str_glob.mptype, "ORTHOGRAPHIC", mpMAX_KEYWD_LENGTH);

	    str_glob.cenlong=centric_lon;
	    str_glob.cenlat =centric_lat;
	    
	    if (str_glob.two_or_three_d_limb==1)
	    	{
	    	los[0]=cos(str_glob.cenlong*my_deg2pi*str_glob.poslongdir_fac)*cos(str_glob.cenlat*my_deg2pi);
	    	los[1]=sin(str_glob.cenlong*my_deg2pi*str_glob.poslongdir_fac)*cos(str_glob.cenlat*my_deg2pi);
	    	los[2]=sin(str_glob.cenlat*my_deg2pi);
	    	pos[0]=pos[1]=pos[2]=0.0;
	    	dlrsurfptl_xyz (pos, los, str_glob.axes[0], str_glob.axes[1], str_glob.axes[2], str_glob.long_axis, dummy, &callfunc);
		radius = dlrvnorm (dummy);
	    	}
	    else radius = str_glob.axes[0];

	    str_glob.xcen=radius*cos(str_glob.cenlat*my_deg2pi)*cos(str_glob.cenlong*my_deg2pi*str_glob.poslongdir_fac);
	    str_glob.ycen=radius*cos(str_glob.cenlat*my_deg2pi)*sin(str_glob.cenlong*my_deg2pi*str_glob.poslongdir_fac);
	    str_glob.zcen=radius*sin(str_glob.cenlat*my_deg2pi);
						/* now we have xyzcen (at sub-spacecraft-point) on the 1-3-axial ellipsoid) */

	    str_glob.d0=sqrt(str_glob.xcen*str_glob.xcen+str_glob.ycen*str_glob.ycen+str_glob.zcen*str_glob.zcen);	    
	    str_glob.d02=str_glob.d0*str_glob.d0;	    

	    
	    save_border=str_glob.border;
	    str_glob.border=20;

		callfunc = dlr_earth_map_get_prefs (mp_stdobj, &(str_glob.prefs_std));
	    callfunc = frameorloc_rip (&str_glob, dlrframe_info, mp_stdobj, mp_dtm_obj, dtmlabel, pho_obj, 2);
 	    if  (callfunc == -998) 
			{
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}

	    gv_out_buf = (float *) calloc (1,str_glob.nof_std_l*str_glob.nof_std_s*sizeof(float));
	    if ((gv_out_buf == (float *)NULL)||((str_glob.nof_std_l*str_glob.nof_std_s) > (3000*3000)))	    
			{ 
			callfunc = mpSetValues (mp_stdobj, mpLINE_PROJECTION_OFFSET, 0.0, NULL);
			callfunc = mpSetValues (mp_stdobj, mpSAMPLE_PROJECTION_OFFSET, 0.0, NULL);
			callfunc = mpGetValues (mp_stdobj, mpMAP_SCALE, &d_temp2, NULL);
			d_temp2*=(double)((str_glob.nof_std_l+str_glob.nof_std_s)/2)/1000.0;
			callfunc = mpSetValues (mp_stdobj, mpMAP_SCALE, d_temp2, NULL);
			callfunc = dlr_earth_map_get_prefs (mp_stdobj, &(str_glob.prefs_std));
			callfunc = frameorloc_rip (&str_glob, dlrframe_info, mp_stdobj, mp_dtm_obj, dtmlabel, pho_obj, 2);
 			if  (callfunc == -998) 
				{
				sprintf(outstring, "Allocation-error1 during call of malloc !!");
     			zvmessage(outstring,"");
		    	sprintf(outstring, "Not enough RAM available !!");
     		    zvmessage(outstring,"");
		    	callfunc = zvclose (str_glob.inunit, 0);
		    	zabend();
		    	}

			gv_out_buf = (float *) calloc (1,str_glob.nof_std_l*str_glob.nof_std_s*sizeof(float));
			}   	
	    if (gv_out_buf == (float *)NULL)	    
			{    	
			sprintf(outstring, "Allocation-error2 during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "No output file generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}
	    str_glob.nof_out_l=str_glob.nof_std_l;
	    str_glob.nof_out_s=str_glob.nof_std_s;
	    oformat_save = str_glob.oformat;	    
	    oformat_size_save = str_glob.oformat_size;	    
	    str_glob.oformat = 4;
	    str_glob.oformat_size = 4;
		callfunc = dlr_earth_map_get_prefs (mp_stdobj, &(str_glob.prefs_std));
	    callfunc = framegeorec_rip (&str_glob, dlrframe_info, mp_stdobj, mp_dtm_obj, dtmlabel, pho_obj, gv_out_buf);
	    if (callfunc == -997)
			{		
			sprintf(outstring, "ABORT !! FRAMEGEOM was not completed !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough memory");
     		zvmessage(outstring,"");
			sprintf(outstring, "Increase mp_sca or decrease mp_res !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "NOTE: The output file was generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			callfunc = zvclose (str_glob.outunit, 0);
			zabend();
			}
	    else if (callfunc == -998) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "No output file generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}
		
	    str_glob.nof_out_l=nof_out_l_save;
	    str_glob.nof_out_s=nof_out_s_save;
	    str_glob.oformat = oformat_save;	
	    str_glob.oformat_size = oformat_size_save;	    

	    strncpy (str_glob.mptype, save_mptype, mpMAX_KEYWD_LENGTH);

	    str_glob.critical_projection=save_proj;
	    str_glob.border=save_border;
    
	    callfunc = stdproj_to_mapproj (&str_glob, mp_obj, mp_stdobj, gv_out_buf);
	    if (callfunc == -998) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "No output file generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}
	    }
	else
	    {
/*--------------------------------------------------------------------
	    Computation of the new rectified image					
	    -------------------------------------------------------------*/
	    if (str_glob.limb==0) str_glob.badlimb=0;
	    str_glob.limb=0;		
	    callfunc = framegeorec_rip (&str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, dummy_gv_out_buf);
	    if (callfunc == -997)
			{		
			sprintf(outstring, "ABORT !! FRAMEORTHO was not completed !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough memory");
     		zvmessage(outstring,"");
			sprintf(outstring, "Increase mp_sca or decrease mp_res !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "NOTE: The output file was generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			callfunc = zvclose (str_glob.outunit, 0);
			zabend();
			}
	    else if (callfunc == -998) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "No output file generated !");
     		zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}
	    }

	if (!str_glob.geom) free(str_glob.dtm_buf);
/*--------------------------------------------------------------------	
	Add labels to output image								
	-------------------------------------------------------------*/

/*--------------------------------------------------------------------	
	PROPERTY label (PROPERTY MAP)								
	-------------------------------------------------------------*/
	callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", str_glob.prefs);				
	if (str_glob.match !=0 )
	    {
	    callfunc = dlr_mpLabelWrite(mp_obj, str_glob.match_x_unit, "PROPERTY", str_glob.prefs);				
	    callfunc = dlr_mpLabelWrite(mp_obj, str_glob.match_y_unit, "PROPERTY", str_glob.prefs);
	    }				

	bodvar_c (dlrframe_info.target_id, "MEANRADIUS", &n_axes, spice_axes);
        if (failed_c() ) /* no MEANRADIUS */
           {
           reset_c();
           count=0;
           }
        else count=1;  
/*
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"MP_RADIUS_SET", &count, "ERR_ACT", "S", "FORMAT", "INT", 0 );
*/
	if ((count > 0)||(mp_radius_set_from_fit))
		{
		r_temp= (float)str_glob.axes[0];
		callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"BODY_A_AXIS_RADIUS", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		r_temp= (float)str_glob.axes[1];
		callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"BODY_B_AXIS_RADIUS", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		r_temp= (float)str_glob.axes[2];
		callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"BODY_C_AXIS_RADIUS", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		}
/*--------------------------------------------------------------------	
	PROPERTY label (PROPERTY PHOT)								
	-------------------------------------------------------------*/
	callfunc = zvp("PHO_FUNC", c_temp32,  &count);

	callfunc = zladd (str_glob.outunit, "PROPERTY", "PHO_FUNC", c_temp32,
	    "ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "PHOT", 0 );
	    
/*--------------------------------------------------------------------	
	PROPERTY label (PROPERTY FILE)								
	-------------------------------------------------------------*/
	callfunc = zvp("OUT", c_temp,  &count);

	callfunc = zldel (str_glob.outunit, "PROPERTY", "FILE_NAME",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
	callfunc = zladd (str_glob.outunit, "PROPERTY", "FILE_NAME", c_temp,
	    	"ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "FILE", 0 );

	callfunc = zldel (str_glob.outunit, "PROPERTY", "PRODUCT_ID",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
	callfunc = zladd (str_glob.outunit, "PROPERTY", "PRODUCT_ID", c_temp,
	    	"ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "FILE", 0 );
		
	callfunc = zldel (str_glob.outunit, "PROPERTY", "PROCESSING_LEVEL_ID",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
/* must be changed later, can be 3 or 4, Roatsch */
        idum=3;                        
	callfunc = zladd (str_glob.outunit, "PROPERTY", "PROCESSING_LEVEL_ID", &idum,
	    	"ERR_ACT", "S", "FORMAT", "INT", "PROPERTY", "FILE", 0 );
	
/*--------------------------------------------------------------------	
	HISTORY label (general parameters)									
	-------------------------------------------------------------*/
	callfunc = zvp("INP", c_temp,  &count);
	
 	if (str_glob.geom)
		{
		r_temp= (float)str_glob.height;
		callfunc = zladd (str_glob.outunit, "HISTORY",
		"REFERENCE_HEIGHT", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		}
 	else
		callfunc = zladd (str_glob.outunit, "HISTORY",
		"DTM_FILE_NAME", str_glob.dtm_filename, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	
	if (str_glob.match !=0 )
	    {
	    callfunc = zladd (str_glob.match_x_unit, "HISTORY",
	    "START_INPUT_LINE", &eins, "ERR_ACT", "S", "FORMAT", "INT", 0 );
	    callfunc = zladd (str_glob.match_y_unit, "HISTORY",
	    "START_INPUT_LINE", &eins, "ERR_ACT", "S", "FORMAT", "INT", 0 );
 	    callfunc = zladd (str_glob.match_x_unit, "HISTORY",
	    "NUMBER_OF_INPUT_LINES", &(dlrframe_info.nl), "ERR_ACT", "S", "FORMAT", "INT", 0 );
 	    callfunc = zladd (str_glob.match_y_unit, "HISTORY",
	    "NUMBER_OF_INPUT_LINES", &(dlrframe_info.nl), "ERR_ACT", "S", "FORMAT", "INT", 0 );
	    callfunc = zladd (str_glob.match_x_unit, "HISTORY",
	    "START_INPUT_SAMPLE", &eins, "ERR_ACT", "S", "FORMAT", "INT", 0 );
	    callfunc = zladd (str_glob.match_y_unit, "HISTORY",
	    "START_INPUT_SAMPLE", &eins, "ERR_ACT", "S", "FORMAT", "INT", 0 );
 	    callfunc = zladd (str_glob.match_x_unit, "HISTORY",
	    "NUMBER_OF_INPUT_SAMPLES", &(dlrframe_info.ns), "ERR_ACT", "S", "FORMAT", "INT", 0 );
 	    callfunc = zladd (str_glob.match_y_unit, "HISTORY",
	    "NUMBER_OF_INPUT_SAMPLES", &(dlrframe_info.ns), "ERR_ACT", "S", "FORMAT", "INT", 0 );

	    callfunc = zladd (str_glob.match_x_unit, "HISTORY",
		"INPUT_FILE_NAME_1", c_temp, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    callfunc = zladd (str_glob.match_y_unit, "HISTORY",
		"INPUT_FILE_NAME_1", c_temp, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    }

	if (str_glob.interpol_type == 0)  
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "NEAREST_NEIGHBOUR", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    if (str_glob.match !=0 )
		{
		callfunc = zladd (str_glob.match_x_unit, "HISTORY",
		"INTERPOLATION_TYPE", "NEAREST_NEIGHBOUR", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		callfunc = zladd (str_glob.match_y_unit, "HISTORY",
		"INTERPOLATION_TYPE", "NEAREST_NEIGHBOUR", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		}
	    }
	if (str_glob.interpol_type == 1)
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "BILINEAR_INTERPOLATION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    if (str_glob.match !=0 )
		{
		callfunc = zladd (str_glob.match_x_unit, "HISTORY",
		"INTERPOLATION_TYPE", "BILINEAR_INTERPOLATION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		callfunc = zladd (str_glob.match_y_unit, "HISTORY",
		"INTERPOLATION_TYPE", "BILINEAR_INTERPOLATION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		}
	    }
	if (str_glob.interpol_type == 2)
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "CUBIC_CONVOLUTION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    if (str_glob.match !=0 )
		{
		callfunc = zladd (str_glob.match_x_unit, "HISTORY",
		"INTERPOLATION_TYPE", "CUBIC_CONVOLUTION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		callfunc = zladd (str_glob.match_y_unit, "HISTORY",
		"INTERPOLATION_TYPE", "CUBIC_CONVOLUTION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		}
	    }
		    
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "ANCHORPOINT_DISTANCE", &(str_glob.anchdist), "ERR_ACT", "S", "FORMAT", "INT", 0 );

/*--------------------------------------------------------------------	
	HISTORY label (SPICE parameters)								
	-------------------------------------------------------------*/

	if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")!=0) /* no SRC case */
		{
		r_temp= (float)str_glob.tol;
		callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"CLOCK_TOLERANCE", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		}


    for (lauf=0; lauf < nof_kernel; lauf++)
                    callfunc = zladd(str_glob.outunit,"HISTORY", 
                                     "SPICE_FILE_NAME", kernel[lauf], 
                                     "FORMAT","STRING", "MODE", "INSERT",
                                     "ELEMENT", lauf+1, "");
    callfunc = zladd(str_glob.outunit,"HISTORY", 
                                 "SPICE_FILE_ID", spice_file_id, 
                                 "FORMAT","STRING", "");

	if ( str_glob.adj_par == 1 )
		{
		callfunc = zladd (str_glob.outunit, "HISTORY",
		"ADJUSTED_POSITION_POINTING_FILE", str_glob.adjufile, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		}    
	
/*--------------------------------------------------------------------	
	free PHO-Data Object								
	-------------------------------------------------------------*/
 	if (str_glob.phocorr != 0)
		{
  		callfunc = phoFree (pho_obj);
		}

 	sprintf(outstring, "\nVICAR task FRAMEORTHO completed \n");
     	zvmessage(outstring,"");

	}

/*====================================================================*/
/*--------------------------------------------------------------------	
	Internal (private) functions used in FRAMEORTHO_NEW							
-------------------------------------------------------------*/

 

/*############################################################	*/
/* Get general FRAMEORTHO_NEW-parameters (private)			*/
/*############################################################	*/
/* Calls from	FRAMEORTHO_NEW					*/
/* Calling	zvp 						*/
/*############################################################	*/

	int frameortho_p (str_glob_TYPE *str_glob)
/*############################################################	*/
	{
	char  c_interpol_type[3];
   	int   i, count, callfunc;
	float float_val;
	char  c_temp32[32], *value;
	char   *getenv();
        SpiceDouble spice_axes[3];
        SpiceInt    n_axes;
/*--------------------------------------------------------------------	
	All general parameters (exept INP, OUT and MP_TYPE) 
*/

callfunc = zvp ( "INP", str_glob->dtm_filename, &count);
	callfunc = zvp ( "DTM", str_glob->dtm_filename, &count);

	str_glob->adj_par=0;
	callfunc = zvp ( "ADJUFILE", str_glob->adjufile, &count);
	if (count) 
		{
		str_glob->adj_par=1;
		value=getenv(str_glob->adjufile);
   		if (value != NULL) strcpy(str_glob->adjufile,value);
   		str_glob->adjuptr=fopen(str_glob->adjufile,"r");
 		if (str_glob->adjuptr == (FILE *)NULL)
      			{
      			zvmessage ("could not open adjufile","");
      			zabend();
      			}    
		str_glob->tol = -999.9;
		}
	else
		{
		str_glob->adjuptr = (FILE *)NULL;
		callfunc = zvp("TOL", &float_val,  &count);
		if (count>0) str_glob->tol = (double)float_val;
		else         str_glob->tol = -999.9;
		}
		
	callfunc = zvp("fittofile", str_glob->fittofile_name,  &(str_glob->fittofile));

	callfunc = zvp("NL_OUT", &(str_glob->nl),  &count);
	callfunc = zvp("NS_OUT", &(str_glob->ns),  &count);

	callfunc = zvp("IPOL", c_interpol_type,  &count);
	if (strcmp(c_interpol_type, "NN")==0)str_glob->interpol_type=0;
	else if (strcmp(c_interpol_type, "BI")==0)str_glob->interpol_type=1;
	else if (strcmp(c_interpol_type, "CC")==0)str_glob->interpol_type=2;

	callfunc = zvp("ANCHDIST", &(str_glob->anchdist),  &count);
/*if (str_glob->anchdist<2)str_glob->anchdist=2;*/

	callfunc = zvp("BORDER", &(str_glob->border),  &count);

	callfunc = zvp("trim_left", &str_glob->user_trim_left,  &count);
	callfunc = zvp("trim_right", &str_glob->user_trim_right,  &count);
	callfunc = zvp("trim_top", &str_glob->user_trim_top,  &count);
	callfunc = zvp("trim_bottom", &str_glob->user_trim_bottom,  &count);

	callfunc = zvp("REPORT", str_glob->report, &count);

	callfunc = zvp("OUTMAX", &float_val, &count);
	str_glob->max_sof_outfile = (double)float_val;
	
	callfunc = zvp("T_EMI_A", &float_val, &count);
	str_glob->TargViewAng = (double)float_val;
	
	callfunc = zvp("T_INC_A", &float_val, &count);
	str_glob->TargIncAng = (double)float_val;
	
	callfunc = zvp("T_AZI_A", &float_val, &count);
	str_glob->TargAzimAng = (double)float_val;

	callfunc = zvp("PHO_FUNC", c_temp32,  &count);
	str_glob->phocorr = 1;
	if (strcmp(c_temp32, "NONE") == 0) str_glob->phocorr = 0;

	if(!str_glob->phocorr) str_glob->oformat = 0;
	else
		{ 
		callfunc = zvp("O_FORMAT", c_temp32,  &count);
		if (count) str_glob->oformat = -1;
		else       str_glob->oformat = -4;
		}

	str_glob->axes[0]=0.0;
	callfunc = zvp("A_AXIS", &float_val,  &count);
	if (count > 0) str_glob->axes[0]=(double)float_val;
	str_glob->axes[1]=0.0;
	callfunc = zvp("B_AXIS", &float_val,  &count);
	if (count > 0) str_glob->axes[1]=(double)float_val;
	str_glob->axes[2]=0.0;
	callfunc = zvp("C_AXIS", &float_val,  &count);
	if (count > 0) str_glob->axes[2]=(double)float_val;

	for (i=0;i<3;i++) str_glob->mp_axes[i]=0.0;

	str_glob->long_axis=-999.9;
	callfunc = zvp("BOD_LONG", &float_val,  &count);
	if (count > 0) str_glob->long_axis=(double)float_val;

	callfunc = zvp("MATCH", c_temp32, &count);
	if ((strncmp(c_temp32, "MATCH",4)==0)||(strncmp(c_temp32, "match",4)==0))
	     str_glob->match=1;
	else str_glob->match=0;

	callfunc = zvp("LIMB", c_temp32, &count);
	if ((strncmp(c_temp32, "BAD",3)==0)||(strncmp(c_temp32, "bad",3)==0)||(str_glob->match==1))
	     str_glob->badlimb=1;
	else str_glob->badlimb=0;

	callfunc = zvp("MIN_LAT", &float_val,  &count);
	str_glob->min_valid_lati=(double)float_val;

	callfunc = zvp("MAX_LAT", &float_val,  &count);
	str_glob->max_valid_lati=(double)float_val;

	return (0);
	}
	

/*===================================================================*/
/*############################################################	*/
/* Get scale				*/
/*############################################################	*/
/* Calls from	FRAMEORTHO_NEW					*/
/* Calling	zlget 						*/
/*############################################################	*/

	int fra_rip_get_scale (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, double *nom_scale)
/*############################################################	*/

	{
	int	   callfunc;
	char	outstring[80];
	

	
	callfunc = frameortho_getscale  (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, nom_scale);
	if (callfunc != 0)
		    {
		    sprintf(outstring, "Imaged target too small for ");
     		    zvmessage(outstring,"");
		    sprintf(outstring, "automatic scale determination !");
     		    zvmessage(outstring,"");
		    sprintf(outstring, "=> Define scale by PDF !!");
     		    zvmessage(outstring,"");
		    zabend();
		    }
	
		
	return (0);
	}

/*===================================================================*/
	int frameortho_getscale  (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, double *scale)
	{
	float	ccd[2];
	double	x[2], y[2], dummy_vec[2];
	int foundvec[2],signvec[2], callfunc;
	PHO pho_obj=NULL;
	
	*scale = 0.01;
	callfunc = mpSetValues ( mp_obj, mpMAP_SCALE, *scale, NULL);
	
	callfunc = dlr_earth_map_get_prefs (mp_obj, &(str_glob->prefs));
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	

	ccd[0]   = (float)
		   (dlrframe_info.nl/2*dlrframe_info.ns + dlrframe_info.ns/2);
	ccd[1]   = ccd[0] + 1.0;
	
	callfunc = frametraidtm_rip 
		    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
		     2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
		     
	if ((foundvec[0]*foundvec[1])==0)
	    {	
	    ccd[0]   = (float) (dlrframe_info.ns/2);
	    ccd[1]   = ccd[0] + 1.0;
	
	    callfunc = frametraidtm_rip 
		    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
		     2, ccd, x, y, foundvec, signvec, dummy_vec, 0);

	    if ((foundvec[0]*foundvec[1])==0)
		{	
		ccd[0]   = (float)
			   ((dlrframe_info.nl-1)*dlrframe_info.ns + dlrframe_info.ns/2);
		ccd[1]   = ccd[0] + 1.0;
	
		callfunc = frametraidtm_rip 
		    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
		     2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
		     
		if ((foundvec[0]*foundvec[1])==0)
		    {	
		    ccd[0]   = (float)
			       (dlrframe_info.nl/2*dlrframe_info.ns + 1);
		    ccd[1]   = ccd[0] + 1.0;
	
		    callfunc = frametraidtm_rip 
		    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
		     2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
		
		    if ((foundvec[0]*foundvec[1])==0)
			{	
			ccd[0]   = (float)
			       (dlrframe_info.nl/2*dlrframe_info.ns - 1);
			ccd[1]   = ccd[0] + 1.0;
	
			callfunc = frametraidtm_rip 
			(str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
			2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
			
			if ((foundvec[0]*foundvec[1])==0)
			    {	
			    ccd[0]   = 1.0;
			    ccd[1]   = ccd[0] + 1.0;
	
			    callfunc = frametraidtm_rip 
			    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
			    2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
			    
			    if ((foundvec[0]*foundvec[1])==0)
				{	
				ccd[0]   = (float)(dlrframe_info.ns - 1);
				ccd[1]   = ccd[0] + 1.0;
	
				callfunc = frametraidtm_rip 
				(str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, 
				2, ccd, x, y, foundvec, signvec, dummy_vec, 0);

				if ((foundvec[0]*foundvec[1])==0)
				    {	
				    ccd[0]   = (float)
					       ((dlrframe_info.nl-1)*dlrframe_info.ns + 1);
				    ccd[1]   = ccd[0] + 1.0;
	
				    callfunc = frametraidtm_rip 
				    (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj,
				    2, ccd, x, y, foundvec, signvec, dummy_vec, 0);

				    if ((foundvec[0]*foundvec[1])==0)
					{	
					ccd[0]   = (float)
						   (dlrframe_info.nl*dlrframe_info.ns - 1);
					ccd[1]   = ccd[0] + 1.0;
	
					callfunc = frametraidtm_rip 
					(str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj,
					2, ccd, x, y, foundvec, signvec, dummy_vec, 0);
					
					if ((foundvec[0]*foundvec[1])==0)
					    {
					    return (-1);
					    }	
					}
				    }
				}
			    }
			}
		    }
		}
	    }
	*scale *= (int)(sqrt((x[1]-x[0])*(x[1]-x[0])+(y[1]-y[0])*(y[1]-y[0]))+0.5);


	return (0);
	}

/*===================================================================*/

	double max (double w1, double w2, double w3, double w4)
	{
	double	m;

	m=-99999999.;
	if (w1 > m) m=w1;
	if (w2 > m) m=w2;
	if (w3 > m) m=w3;
	if (w4 > m) m=w4;
	return(m);
	}

	int imax (int w1, int w2, int w3, int w4)
	{
	int	m;
	m=-99999999;
	if (w1 > m) m=w1;
	if (w2 > m) m=w2;
	if (w3 > m) m=w3;
	if (w4 > m) m=w4;
	return(m);
	}

	double min (double w1, double w2, double w3, double w4)
	{
	double	m;
	m=99999999.;
	if (w1 < m) m=w1;
	if (w2 < m) m=w2;
	if (w3 < m) m=w3;
	if (w4 < m) m=w4;
	return(m);
	}

	int imin (int w1, int w2, int w3, int w4)
	{
	int	m;
	m=99999999;
	if (w1 < m) m=w1;
	if (w2 < m) m=w2;
	if (w3 < m) m=w3;
	if (w4 < m) m=w4;
	return(m);
	}


/*==============================================================*/

/*############################################################	*/
/* Computation of location and size
	of the new rectified orthoimage	(private)	*/
/*############################################################	*/
/* Calls from	FRAMEORTHO_NEW						*/
/* Calling	mpGetValues, mpSetValues

		hrrdpref
		
     (private)	frametraidtm_rip				*/

/*############################################################	*/

	int frameorloc_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, int run)
	{
	double	*phoCorVal_vec,d_val;
	int	callfunc, callfunc1, callfunc2, j, k, l, first_real_image_l;
	int	nof_pix, *foundvec, *signvec, check_dist, found, last_image_l, end_of_file;
	int	*check_l, end_of_line;
	float	*check_s, *ccd, centerpixel;
	double 	max_x, max_y, min_x, min_y, x_off, y_off;
	double	*x, *y, scale_resolution, et;
	char	outstring[80];
	x=(double *)calloc(1,dlrframe_info.ns*sizeof(double));
	if (x == (double *)NULL)
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	y=(double *)calloc(1,dlrframe_info.ns*sizeof(double));
	if (y == (double *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	phoCorVal_vec=(double *)malloc(dlrframe_info.ns*sizeof(double));
	if (phoCorVal_vec == (double *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	foundvec=(int *)malloc(dlrframe_info.ns*sizeof(int));
	if (foundvec == (int *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	signvec=(int *)malloc(dlrframe_info.ns*sizeof(int));
	if (signvec == (int *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	check_l=(int *)malloc(dlrframe_info.nl*sizeof(int));
	if (check_l == (int *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	check_s=(float *)malloc(dlrframe_info.ns*sizeof(float));
	if (check_s == (float *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}
	ccd=(float *)malloc(dlrframe_info.ns*sizeof(float));
	if (ccd == (float *)NULL) 
		{ 
		sprintf(outstring, "Allocation Error in frameorloc");
     		zvmessage(outstring,"");
		zabend();
		}


	found=0;
	foundvec[0]=0;
	signvec[0]=0;
	phoCorVal_vec[0]=0.;
	x[0]=0.;
	y[0]=0.;

	min_x   = 9.9e20;
	min_y   = 9.9e20;
	max_x 	= -9.9e20;
	max_y 	= -9.9e20;
			
 	/*---------------------------------------------	*/
	/* if photometric correction is requested,
	   get sunposition for this et and this target	*/
	/*---------------------------------------------	*/
	if (str_glob->phocorr != 0) 
		{
		utc2et_c (dlrframe_info.utc,&et);
		callfunc = zhwgetsun (et, dlrframe_info.target_id, str_glob->MDirInc);
  		if (callfunc != 1)
             		{
         		zvmessage("zhwgetsun problem","");
         		printf("zhwgetsun-status: %d\n",callfunc);
         		zabend();
         		}
		}

/*--------------------------------------------------------------	*/
/* Handling each str_glob->anchdistth pixel on the image border	*/
/*--------------------------------------------------------------	*/

/*--------------------------------------------------------------	*/
/* preparing the following loop for all lines				*/
/*--------------------------------------------------------------	*/
	end_of_file = 0;

	check_dist = str_glob->anchdist;

	check_l [0] = 1;
	check_l [0] += dlrframe_info.trim_top;
	     
	j = 0;
	
	while (end_of_file != 1) 
		    /* loop of all lines with a distance of check_dist */
		{
		if ((check_l[j]+check_dist) >= dlrframe_info.nl)
		    {			
	            j++;
		    check_l [j] = dlrframe_info.nl;
		    end_of_file = 1;
		    }
			
		else
			{
			j++;
			check_l [j] = check_l [j-1] + check_dist;
			}
		}
/*--------------------------------------------------------------	*/
/* Loop of all check_lines						*/
/*--------------------------------------------------------------	*/
 
	first_real_image_l = 0;    		    
	for (l=0; l<=j; l++)	   
		{
		/*---------------------------------------------- */
		/* each "checkdist"th pixel has to be processed	 */
		/*---------------------------------------------- */
			
		check_s[0]= 1.0;
		check_s[0] += (float)dlrframe_info.trim_left;
			     
		ccd[0]   = (float)((check_l[l]-1)*dlrframe_info.ns)+check_s[0];
		k=1;
		end_of_line = 0;
		while (end_of_line != 1)
		    {
		    if (((int)(check_s[k-1]) + check_dist) >= (dlrframe_info.ns-dlrframe_info.trim_right))
			    {
			    check_s [k] = (float)(dlrframe_info.ns-dlrframe_info.trim_right);
			    end_of_line = 1;
			    }
		    else check_s [k] = check_s [k-1] + (float)check_dist;

		    ccd[k]   = (float) ((check_l[l]-1)*dlrframe_info.ns)+check_s[k];
		    k++;
		    }
		    
		nof_pix = k;

		callfunc = frametraidtm_rip ( str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj,nof_pix, ccd, x, y,
					    foundvec, signvec, phoCorVal_vec, 0);
		if (callfunc == -998) return (callfunc);	
		for (k=0;k<nof_pix;k++)
			{
			if ((x[k] < min_x)&&(foundvec[k] != 0)) {min_x = x[k];if (found == 0)str_glob->first_real_inp_l=check_l[l]-(check_dist+5);found=1;}
			if ((x[k] > max_x)&&(foundvec[k] != 0)) {max_x = x[k];if (found == 0)str_glob->first_real_inp_l=check_l[l]-(check_dist+5);found=1;}
			if ((y[k] < min_y)&&(foundvec[k] != 0)) {min_y = y[k];if (found == 0)str_glob->first_real_inp_l=check_l[l]-(check_dist+5);found=1;}
			if ((y[k] > max_y)&&(foundvec[k] != 0)) {max_y = y[k];if (found == 0)str_glob->first_real_inp_l=check_l[l]-(check_dist+5);found=1;}
			}

		for (k=0;k<nof_pix;k++)
			{
			if (foundvec[k] != 0) {str_glob->last_real_inp_l=check_l[l];break;}
			}
		}
	
	if (str_glob->found != 1)
	    {
	    zvmessage(" Error in frameorloc_rip ","");
	    zvmessage(" Input-Image does not ","");
 	    zvmessage(" contain the target !","");
	    zabend();
	    }
	if (str_glob->found_in_dtm != 1)
	    {
	    zvmessage(" Error in frameorloc_rip ","");
	    zvmessage(" The area covered by the image is not ","");
 	    zvmessage(" covered by the DTM !","");
	    zabend();
	    }
	if (found != 1)
	    {
	    zvmessage(" Error in frameorloc_rip ","");
	    zvmessage(" The area covered by the image can not ","");
 	    zvmessage(" be shown with this map projection parameters !","");
	    zabend();
	    }

	if (str_glob->first_real_inp_l<1)str_glob->first_real_inp_l=1;
/*--------------------------------------------------------------	*/
/* compute extreme x/y-coordinates of the output image			*/
/*--------------------------------------------------------------	*/
	
	callfunc1 = mpGetValues
		    ( mp_obj, mpLINE_PROJECTION_OFFSET, &x_off, NULL);
	if ((str_glob->lineoffset_set==0)||(run == 2)) 
		{
		min_x   -= (double)str_glob->border;
		max_x 	+= (double)str_glob->border;
		if (min_x < 0.0) min_x = min_x - 1.0;
		if (max_x < 0.0) max_x = max_x - 1.0;
		x_off	= -(double)((int)(min_x));
		if ((str_glob->pole==0)||
	            (str_glob->max_valid_lati < 90.0)||
	            (str_glob->min_valid_lati > -90.0)||
	            (str_glob->critical_projection <= 0)||
                    (str_glob->critical_projection == 2)
		   )
		    callfunc = mpSetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
		else
		    {
		    if (fabs(str_glob->max_lati)>=fabs(str_glob->min_lati))
			{
			if ((strcmp(str_glob->mptype, "SINUSOIDAL")==0)||
			    (strcmp(str_glob->mptype, "EQUIDISTANT")==0))
			    {
			    callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
			    x_off = (double)((int)(str_glob->mp_axes[0]*PI/2.0/scale_resolution + (double)str_glob->border));
			    }
			else if (strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
			    {
			    callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
			    x_off = (double)((int)(str_glob->mp_axes[0]/scale_resolution + (double)str_glob->border));
			    }
			else if (strcmp(str_glob->mptype, "MOLLWEIDE")==0)
			    {
			    callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
			    x_off = (double)((int)(sqrt(2.0)*str_glob->mp_axes[0]/scale_resolution + (double)str_glob->border));
			    }
/*			else if (str_glob->critical_projection == 2)
			    {
			    callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
			    x_off= (double)((int)(str_glob->mp_axes[0] * log(tan( PI/4.0 + 0.5 * 88.0*my_deg2pi)) /scale_resolution + (double)str_glob->border));
 			    }
*/			    
			callfunc = mpSetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
			}
		    else
			{
		    	callfunc = mpSetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
				
			callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
			
			if ((strcmp(str_glob->mptype, "SINUSOIDAL")==0)||
			    (strcmp(str_glob->mptype, "EQUIDISTANT")==0))
			    {max_x = str_glob->mp_axes[0]*PI/2.0/scale_resolution + (double)str_glob->border;}
			else if (strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
			    {max_x = str_glob->mp_axes[0]/scale_resolution + (double)str_glob->border;}
			else if (strcmp(str_glob->mptype, "MOLLWEIDE")==0)
			    {max_x = sqrt(2.0)*str_glob->mp_axes[0]/scale_resolution + (double)str_glob->border;}
/*			else if (str_glob->critical_projection == 2)
			    {max_x = str_glob->mp_axes[0] * log(tan( PI/4.0 + 0.5 * 88.0*my_deg2pi)) /scale_resolution + (double)str_glob->border;}
*/
			}
		    }

		/*-----------------------------------------------------	*/
		/* compute number of lines of the output image  */
		/*-----------------------------------------------------	*/
		if ((str_glob->nl == 0)||(run == 2)) 
			{
			if (run==1)str_glob->nof_out_l = (int)(max_x) + (int)(x_off) + 1;
			else	str_glob->nof_std_l = (int)(max_x) + (int)(x_off) + 1;
			}
		else
			{
			str_glob->nof_out_l = str_glob->nl;
			if ((str_glob->nl<(int)(max_x))&&(!str_glob->fittofile))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined NL !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		}
	else
		{
		if (min_x < 1.0)
			{
			if (max_x < 1.0)
				{
				zvmessage("There is no image information ","");
				zvmessage("beyond the user-defined ","");
				zvmessage("LINE_PROJECTION_OFFSET !!","");
				zabend();
				}
			else if (!str_glob->fittofile)
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined ","");
				zvmessage("LINE_PROJECTION_OFFSET !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		if ((str_glob->nl == 0)||(run == 2)) 
			{
			if (run==1)str_glob->nof_out_l = (int)(max_x)+str_glob->border;
			else	   str_glob->nof_std_l = (int)(max_x)+str_glob->border;
			}
		else
			{
			str_glob->nof_out_l = str_glob->nl;
			if ((str_glob->nl<(int)(max_x))&&(!str_glob->fittofile))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined NL !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		}

	callfunc2 = mpGetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, &y_off, NULL);

	if ((str_glob->sampleoffset_set==0)||(run == 2))  
		{
		if (
		(
		(str_glob->critical_projection == 2)
		||(strcmp(str_glob->mptype, "EQUIDISTANT")==0)
		||(strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
		)
		&&(str_glob->pole==1)
		)
		    {
		    callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &scale_resolution, NULL);
		    y_off	= (double)((int)(str_glob->mp_axes[0]*PI/scale_resolution + (double)str_glob->border));
		    max_y	= str_glob->mp_axes[0]*PI/scale_resolution + (double)str_glob->border;
		    callfunc = mpSetValues
				( mp_obj, mpSAMPLE_PROJECTION_OFFSET, y_off, NULL);
		    }
		else
		    {
		    min_y  	-= (double)str_glob->border;
		    max_y 	+= (double)str_glob->border; 
		    if (min_y < 0.0) min_y = min_y - 1.0;
		    if (max_y < 0.0) max_y = max_y - 1.0;
		    y_off	= -(double)((int)(min_y));
		    callfunc = mpSetValues
			   ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, y_off, NULL);
		    }
		/*-----------------------------------------------------	*/
		/* compute number of samples of the output image  */
		/*-----------------------------------------------------	*/
		if ((str_glob->ns == 0)||(run == 2)) 
			{
			if (run==1) str_glob->nof_out_s = (int)(max_y) + (int)(y_off) + 1;		
			else	    str_glob->nof_std_s = (int)(max_y) + (int)(y_off) + 1;		
			}
		else
			{
			str_glob->nof_out_s = str_glob->ns;
			if ((str_glob->ns<(int)(max_y))&&(!str_glob->fittofile))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined NS !!","");
				zvmessage("Processing continues ... ","");
				}
			}		
		}
	else
		{
		if (min_y < 1.0)
			{
			if (max_y < 1.0)
				{
				zvmessage("There is no image information ","");
				zvmessage("beyond the user-defined ","");
				zvmessage("SAMPLE_PROJECTION_OFFSET !!","");
				zabend();
				}
			else if (!str_glob->fittofile)
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined ","");
				zvmessage("SAMPLE_PROJECTION_OFFSET !!","");
				zvmessage("Processing continues ... ","");
				}
			}
					
		if ((str_glob->ns == 0)||(run == 2)) 
			{
			if (run==1)str_glob->nof_out_s = (int)(max_y)+str_glob->border;
			else	   str_glob->nof_std_s = (int)(max_y)+str_glob->border;
			}
		else
			{
			str_glob->nof_out_s = str_glob->ns;
			if ((str_glob->ns<(int)(max_y))&&(!str_glob->fittofile))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cutted ","");
				zvmessage("due to user-defined NS !!","");
				zvmessage("Processing continues ... ","");
				}
			}		
		}

	if ((strcmp(str_glob->report, "NO")!=0)&&(run==1))
		{
 		sprintf(outstring, "Lines of output-image %d", str_glob->nof_out_l);
     		zvmessage(outstring,"");
 		sprintf(outstring, "Samples of output-image %d", str_glob->nof_out_s);
     		zvmessage(outstring,"");

	   	if ((str_glob->lineoffset_set==0) || 
		    (str_glob->sampleoffset_set==0))
			{
 			sprintf(outstring, "LINE_PROJECTION_OFFSET %lf", x_off);
     			zvmessage(outstring,"");
			sprintf(outstring, "SAMPLE_PROJECTION_OFFSET %lf", y_off);
     			zvmessage(outstring,"");
			}
		}

	free(x);	
	free(y);	
	free(phoCorVal_vec);	
	free(foundvec);	
	free(signvec);	
	free(check_l);	
	free(check_s);	
	free(ccd);	

	return(0);
	}

/*======================================================================*/
/*##############################################################	*/
/* Geometric ortho-correction of a frame image
					(private)			*/
/*##############################################################	*/
/* Calls from	FRAMEORTHO_NEW						*/
/* Calling		zvunit, zvopen, zvclose, zvread, zvwrit

			mpLabelWrite		

			hrrdpref

	(private)	framegetapt, frametraidtm_rip,
			hwgetapp, hwsortap,
			hwintgv_bi, hwintgv_cc	*/
/*##############################################################	*/

	int framegeorec_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, float *gv_out_buf_for_limb)

	{
	int	ipol, callfunc, i, i_end, j, p, nof_pix, int_l, int_s;
	int	down, true_l1, true_l2, done, last_done;
	int	area, first_area, up_int_save, lo_int_save;
	int	nof_up_le_p, nof_up_ri_p, max_nof_read_out_l;
	int	nof_p, anch_l1, anch_l2, x_act, y_act;
	int	save_nof_le_p, save_nof_ri_p;
	int	p_up_down, p_start, p_end, x_start, x_end, y_start, y_end;
	int	first_read_out_l, first_ccd, first_s, mid_of_l;
	int	nof_lo_le_p, nof_lo_ri_p, out_buf_size;
	int	last_read_out_l, last_read_inp_l;
	int	out_buf_off, inp_buf_off;
	int	min_x_p, min_y_p, max_x_p, max_y_p;
	int	cont_inp_l, act_anchdist_l, act_anchdist_s;
	int	xcount, ycount;
	float   *ccd, *ccd2;
	double  l, s, initial_l, initial_s, d_l, d_s, d_first_s_p;
	double	lo_save, up_save, d_temp, phoCorVal;
	double	min_l_p, min_s_p, max_l_p, max_s_p;
	double	a[6], b[4], a3_min_x_p, b3_min_x_p; 	
	double	a3_min_y_p, b3_min_y_p, d, dmax;
			
	double   *up_x,    *up_y,    *up_phoCorVal_vec;
	double   *up_x2,   *up_y2,   *up_phoCorVal_vec2;
	double	 *lo_x,    *lo_y,    *lo_phoCorVal_vec;
	double	 *lo_x2,   *lo_y2,   *lo_phoCorVal_vec2;
	double	 *save_x, *save_y,  *save_phoCorVal_vec;
	double	 *phoCorVal_vec_ap1,   *phoCorVal_vec_ap2;
	double	 *phoCorVal_vec_ap3,   *phoCorVal_vec_ap4;
	double	 *x_ap1,   *x_ap2;
	double	 *x_ap3,   *x_ap4;
	double	 *y_ap1,   *y_ap2;
	double	 *y_ap3,   *y_ap4,  *phoCorVal_vec;

	int	*s_ap3, *s_ap4, *s_ap1, *s_ap2, *lo_s, *save_s, *up_s, *dtm_no_dtm, 
		*save_found_vec, *save_sign_vec, *foundvec, *foundvec2, *signvec, *signvec2;
		
	double	af_x_out[4], af_y_out[4], af_x_inp[4], af_y_inp[4], inp_off[2], out_off[2];

	char	outstring[80];
	float	*gv_inp_buf, *gv_out_buf_float, *gv, *gv_inp_lo, *gv_inp_ro,
		*gv_inp_lu, *gv_inp_ru, *gv_bicu, *match_x_buf_float, *match_y_buf_float;

	myBYTE	*gv_out_buf_byte, *tab_gv;
	short int *gv_out_buf_half;
	int	*gv_out_buf_full, *tab_in, *tab_out, nof_read_out_l;

 	s_ap1 = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	s_ap2 = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	s_ap3 = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	s_ap4 = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	lo_s = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	up_s = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	save_s = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	dtm_no_dtm = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	save_found_vec = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	save_sign_vec = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	foundvec = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	foundvec2 = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	signvec = (int *) malloc(dlrframe_info.ns*sizeof(int));
 	signvec2 = (int *) malloc(dlrframe_info.ns*sizeof(int));

	ccd  = (float *)malloc(dlrframe_info.ns*sizeof(float));
	ccd2 = (float *)malloc(dlrframe_info.ns*sizeof(float));

	up_x = (double *)malloc(dlrframe_info.ns*sizeof(double));
	up_y = (double *)malloc(dlrframe_info.ns*sizeof(double));
	up_x2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	up_y2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_x = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_x2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_y = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_y2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	up_phoCorVal_vec = (double *)malloc(dlrframe_info.ns*sizeof(double));
	up_phoCorVal_vec2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_phoCorVal_vec = (double *)malloc(dlrframe_info.ns*sizeof(double));
	lo_phoCorVal_vec2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	save_x = (double *)malloc(dlrframe_info.ns*sizeof(double));
	save_y = (double *)malloc(dlrframe_info.ns*sizeof(double));
	save_phoCorVal_vec = (double *)malloc(dlrframe_info.ns*sizeof(double));
	phoCorVal_vec     = (double *)malloc(dlrframe_info.ns*sizeof(double));
	phoCorVal_vec_ap1 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	phoCorVal_vec_ap2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	phoCorVal_vec_ap3 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	phoCorVal_vec_ap4 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	x_ap1 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	x_ap2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	x_ap3 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	x_ap4 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	y_ap1 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	y_ap2 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	y_ap3 = (double *)malloc(dlrframe_info.ns*sizeof(double));
	y_ap4 = (double *)malloc(dlrframe_info.ns*sizeof(double));

	gv_inp_lo   = (float *) malloc (sizeof(float));
		if (gv_inp_lo == (float *)NULL) return(-998); 

	gv_inp_ro   = (float *) malloc (sizeof(float));
		if (gv_inp_ro == (float *)NULL) return(-998); 

	gv_inp_lu   = (float *) malloc (sizeof(float));
		if (gv_inp_lu == (float *)NULL) return(-998); 

	gv_inp_ru   = (float *) malloc (sizeof(float));
		if (gv_inp_ru == (float *)NULL) return(-998); 

	gv	    = (float *) malloc (sizeof(float));
		if (gv == (float *)NULL) return(-998); 

	gv_bicu	   = (float *) malloc (16*sizeof(float));
		if (gv_bicu == (float *)NULL) return(-998); 

		
	*gv		= 0.;

	foundvec[0]=0;
	foundvec2[0]=0;
	signvec[0]=0;
	signvec2[0]=0;
	phoCorVal_vec[0]=0.;
	
	if (str_glob->limb==1)
	    {
	    if (str_glob->anchdist!=1)
		{
		sprintf(outstring, "Limb image ! Achor point distance is set to 1 !");
     		zvmessage(outstring,"");
		str_glob->anchdist=1;
		}
/*	    ipol=1;*/
	    } 
	ipol=str_glob->interpol_type;

 	gv_inp_buf = (float *) malloc (sizeof(float) * dlrframe_info.ns * 10*str_glob->anchdist);
		if (gv_inp_buf == (float *)NULL) return(-998); 
	*gv_inp_buf	= 0.;

/*--------------------------------------------------------------	*/
/*	Initialize output-image						*/
/*--------------------------------------------------------------	*/

	i=0;
 	out_buf_size =  str_glob->nof_out_s*str_glob->nof_out_l;
		
		if (str_glob->oformat == 4)
			{
			if (str_glob->limb==1)
			    {
			    str_glob->no_info_val = -1.0e32;
			    gv_out_buf_float=gv_out_buf_for_limb;
	    		    for (i=0;i<out_buf_size;i++) gv_out_buf_float[i]=str_glob->no_info_val;				
			    }
			else
			    {
 			    do
			    {
			    gv_out_buf_float= (float *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
			    if (str_glob->match) 
				{
				match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				}
			    i++;
			    } while ((gv_out_buf_float == (float *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

			    out_buf_size -= ((i-1)*4000000);
			    str_glob->no_info_val = -1.0e32;
	    		    for (i=0;i<out_buf_size;i++) gv_out_buf_float[i]=str_glob->no_info_val;				
			    }
			}
		else if (str_glob->oformat == 3)
			{
 			do
			{
			gv_out_buf_full= (int *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
			if (str_glob->match) 
				{
				match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				}
			i++;
			} while ((gv_out_buf_full == (int *)NULL)||(str_glob->match&&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

			out_buf_size -= ((i-1)*4000000);
			str_glob->no_info_val = -32768.;
	    		for (i=0;i<out_buf_size;i++) gv_out_buf_full[i]=(int)str_glob->no_info_val;				
			}
		else if (str_glob->oformat == 2)
			{
 			do
			{
			gv_out_buf_half= (short int *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
			if (str_glob->match) 
				{
				match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				}
			i++;
			} while ((gv_out_buf_half == (short int *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

			out_buf_size -= ((i-1)*4000000);
			str_glob->no_info_val = -32768.;
	    		for (i=0;i<out_buf_size;i++) gv_out_buf_half[i]=(short int)str_glob->no_info_val;				
			}
		else
			{
 			do
			{
			gv_out_buf_byte= (myBYTE *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
			if (str_glob->match) 
				{
				match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
				}
			i++;
			} while ((gv_out_buf_byte == (myBYTE *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

			out_buf_size -= ((i-1)*4000000);
			str_glob->no_info_val = 0.;
	    		for (i=0;i<out_buf_size;i++) gv_out_buf_byte[i]=(myBYTE)str_glob->no_info_val;				
			} 
 
/*--------------------------------------------------------------	*/

	if (str_glob->oformat == 4)
		{
		max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(float)));
		}
	else if (str_glob->oformat == 3)
		{
		max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(int)));
		}
	else if (str_glob->oformat == 2)
		{
		max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(short int)));
		}
	else
		{
		max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(myBYTE)));
		}

	 
	nof_read_out_l = max_nof_read_out_l;

	if (nof_read_out_l >= str_glob->nof_out_l) nof_read_out_l = str_glob->nof_out_l;
					
	else 
	    {
	    if (str_glob->limb==1)
		{
		sprintf(outstring, "Memory too low !");
     		zvmessage(outstring,"");
		zabend();
		}
	    for (i=1;i<=str_glob->nof_out_l;i++)				
		{
		if (str_glob->oformat == 4)
		    callfunc = zvwrit (str_glob->outunit,gv_out_buf_float, "LINE", i, "SAMP", 1, 0);
		else if (str_glob->oformat == 3)
		    callfunc = zvwrit (str_glob->outunit, gv_out_buf_full, "LINE", i, "SAMP", 1, 0);
		else if (str_glob->oformat == 2)
		    callfunc = zvwrit (str_glob->outunit, gv_out_buf_half, "LINE", i, "SAMP", 1, 0);
		else
		    callfunc = zvwrit (str_glob->outunit, gv_out_buf_byte, "LINE", i, "SAMP", 1, 0);
		if (str_glob->match)
			{
			callfunc = zvwrit (str_glob->match_x_unit, match_x_buf_float, "LINE", i, "SAMP", 1, 0);
			callfunc = zvwrit (str_glob->match_y_unit, match_y_buf_float, "LINE", i, "SAMP", 1, 0);
			}
		}
	    }

	first_read_out_l  = 1;
	last_read_out_l   = nof_read_out_l;

/*--------------------------------------------------------------	*/
/*	Initialize tables						*/
/*--------------------------------------------------------------	*/
	i_end = 2*str_glob->anchdist; 
	if (i_end < 20) i_end=20;
		
	tab_in   = (int *) malloc ((i_end+1)*sizeof(int));
		if (tab_in == (int *)NULL) return(-998); 
	*tab_in  = (int)0;

	for (i=1; i<i_end; i++) { *(tab_in+i) = *(tab_in+i-1)+dlrframe_info.ns; }

/*-------------------------------------------------------------	*/

	tab_out   = (int *) malloc ((nof_read_out_l+1)*sizeof(int));
		if (tab_out == (int *)NULL) return(-998); 
	*tab_out  = (int)0;
	i_end 	  = nof_read_out_l; 	

	for (i=1; i<i_end; i++)
		{ *(tab_out+i) = *(tab_out+i-1)+str_glob->nof_out_s; }

/*-------------------------------------------------------------	*/

	if (str_glob->oformat == 1)
		{
		tab_gv   = (myBYTE *) malloc (256*sizeof(myBYTE));
		if (tab_gv == (myBYTE *)NULL) return(-998); 
		*tab_gv  = (myBYTE)1;
		i_end 	  = 256; 	

		for (i=1; i<i_end; i++) { *(tab_gv+i) = (myBYTE)i; }
		}

/*-------------------------------------------------------------	*/
/*	Initialize anchorpoint lines				*/
/*-------------------------------------------------------------	*/

	mid_of_l = dlrframe_info.ns/2;

	last_read_inp_l = 0;
	cont_inp_l      = str_glob->first_real_inp_l;

	if (cont_inp_l<=dlrframe_info.trim_top)cont_inp_l = dlrframe_info.trim_top+1;

	first_area      = 0;
	area            = 0;
	down=0;

	if (strcmp(str_glob->report, "NO")!=0)
			{
			printf("Done (in percent): ");
			fflush(stdout);
			last_done=0;
			}

	while (cont_inp_l < dlrframe_info.nl)
		{
/*------------------------------------------------------------------	*/
/*	Read input grayvalues of this area between two anchorpoint-lines*/
/*	read the entire line, also for VIKING */
/*------------------------------------------------------------------	*/
		inp_buf_off = 0;     	

		if (str_glob->limb==1)
		    {
		    lo_save = 1.5;
		    up_save = 1.5;
		    lo_int_save = 2;
		    up_int_save = 2;
		    }
		else
		    {
		    lo_save = 0.5;
		    up_save = 0.5;
		    lo_int_save = 2;
		    up_int_save = 2;
		    }

		act_anchdist_l = str_glob->anchdist;
		if (dlrframe_info.nl - (cont_inp_l+act_anchdist_l) 
							<= (act_anchdist_l+1)/2)
		    {
		    act_anchdist_l = dlrframe_info.nl - cont_inp_l;
		    if (ipol==2) lo_save=-1.01;
		    else lo_save=-1.0;
		    lo_int_save = 0;
		    }

		anch_l1=cont_inp_l;
		
		first_ccd = 1;
		first_s = 0;


		true_l1 = cont_inp_l;
		true_l2 = cont_inp_l+act_anchdist_l;

		last_read_inp_l = true_l2;
	
		if ((cont_inp_l-up_int_save)<1)
			{
			if (ipol==2) d_temp=-1.0;
			else	     d_temp= 0.0;
				
			up_int_save = 0;
			up_save = d_temp;
			}

		for (j=cont_inp_l-up_int_save; j <= (cont_inp_l+act_anchdist_l+lo_int_save); j++)
			{
			callfunc = zvread (str_glob->inunit, (gv_inp_buf+inp_buf_off),
				           "LINE", j+dlrframe_info.nlb, "SAMP", 1+dlrframe_info.nbb,
				           "NSAMPS", dlrframe_info.ns, 0);
			inp_buf_off += dlrframe_info.ns;
			}

		done=100*(cont_inp_l-str_glob->first_real_inp_l+act_anchdist_l);
		done=((done/(dlrframe_info.nl-str_glob->first_real_inp_l + 1))/5)*5;
		if (strcmp(str_glob->report, "NO")!=0)
			{
			if (done>last_done)
			    {
			    printf("%2d ", done);
			    fflush (stdout);
			    last_done=done;
			    }
			}

		cont_inp_l = last_read_inp_l;

		if (area<=(first_area+1))
			{
			callfunc = framegetapt (dlrframe_info, anch_l1, mid_of_l,
				   &nof_up_le_p, &nof_up_ri_p, up_s, str_glob->anchdist);

			nof_pix  = nof_up_le_p + nof_up_ri_p + 1;
			for (j=0; j < nof_pix; j++)
				{ ccd[j]   = (float)((true_l1-1)*dlrframe_info.ns) + ((float)(up_s[j])-0.5)+0.5; }

			callfunc = frametraidtm_rip (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, nof_pix,
					      ccd, up_x, up_y, foundvec, signvec, up_phoCorVal_vec, 1);
			if ((str_glob->limb==1)&&(str_glob->badlimb==1))str_glob->limb=0;

			if (callfunc == -998) return (callfunc);	
			}
		else
			{
			nof_up_le_p  = save_nof_le_p;
			nof_up_ri_p = save_nof_ri_p;
			nof_pix  = nof_up_le_p + nof_up_ri_p + 1;
			for (j=0; j < nof_pix; j++)
				{
				up_s[j] = save_s[j];
				up_x[j]	= save_x[j];
				up_y[j]	= save_y[j];
				up_phoCorVal_vec[j] = save_phoCorVal_vec[j];
				foundvec[j] = save_found_vec[j];
				signvec[j] = save_sign_vec[j];
				}
			}

		anch_l2 = last_read_inp_l;

		callfunc= framegetapt (dlrframe_info, anch_l2, mid_of_l, &nof_lo_le_p, &nof_lo_ri_p, lo_s, str_glob->anchdist);

		nof_pix  = nof_lo_le_p + nof_lo_ri_p + 1;
		for (j=0; j < nof_pix; j++)
			{ ccd[j]   = (float)((true_l2-1)*dlrframe_info.ns) + ((float)(lo_s[j])-0.5)+0.5; }

		callfunc = frametraidtm_rip (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, nof_pix, ccd, lo_x, lo_y,
			   foundvec2, signvec2, lo_phoCorVal_vec, 1);
		if ((str_glob->limb==1)&&(str_glob->badlimb==1))str_glob->limb=0;

		if (callfunc == -998) return (callfunc);	
	
		/*----------------------------------------------------	*/
		/* save lower values of this area
				as upper values of next area	*/
		/*----------------------------------------------------	*/

		for (j=0; j < nof_pix; j++)
			{
			save_s[j] = lo_s[j];
			save_x[j] = lo_x[j];
			save_y[j] = lo_y[j];
			save_phoCorVal_vec[j] = lo_phoCorVal_vec[j];
			save_found_vec[j] = foundvec2[j];
			save_sign_vec[j] = signvec2[j];
			}
		save_nof_le_p = nof_lo_le_p;
		save_nof_ri_p = nof_lo_ri_p;

		callfunc = hwsortap (nof_up_le_p, nof_up_ri_p, up_s, up_x, up_y, up_phoCorVal_vec, foundvec, signvec,
			             nof_lo_le_p, nof_lo_ri_p, lo_s, lo_x, lo_y, lo_phoCorVal_vec, foundvec2, signvec2);

		callfunc = hwgetapp (nof_up_le_p, nof_up_ri_p, up_s, up_x, up_y, up_phoCorVal_vec, foundvec, signvec,
			  	     nof_lo_le_p, nof_lo_ri_p, lo_s, lo_x, lo_y, lo_phoCorVal_vec, foundvec2, signvec2,
			  	     &nof_p, s_ap1, s_ap2, s_ap3, s_ap4,
	 			     phoCorVal_vec_ap1, phoCorVal_vec_ap2,
	 			     phoCorVal_vec_ap3, phoCorVal_vec_ap4,
			  	      x_ap1, x_ap2, x_ap3, x_ap4,
			  	      y_ap1, y_ap2, y_ap3, y_ap4, dtm_no_dtm);
		/*----------------------------------------------------	*/
		/* Derive "working direction" of patches
		   so that it corresponds to down in output-image	*/
		/*----------------------------------------------------	*/

		if (x_ap2[0] > x_ap1[nof_p-1]) 
			{
			p_up_down = -1;
			p_start = nof_p-1;
			p_end	=  -1;
			}
		else
			{
			p_up_down = 1;
			p_start	= 0;
			p_end	= nof_p;
			}
		/*----------------------------------------------------	*/
		/* Loop of all anchorpoint-patches within this area
		   (patch = region between four anchorpoints)		*/
		/*----------------------------------------------------	*/

		for (p=p_start; p != p_end; p=p+p_up_down)
			{
			/*----------------------------------------------*/
			/* get projective transformation parameters
			   for this patch
			   (transformation from ortho- to input-image)	*/
			/*----------------------------------------------*/
			if (dtm_no_dtm[p] == 0) continue;
			
			af_y_inp[0] = y_ap1[p];
			af_x_inp[0] = x_ap1[p];
			af_y_inp[1] = y_ap2[p];
			af_x_inp[1] = x_ap2[p];
			af_y_inp[2] = y_ap3[p];
			af_x_inp[2] = x_ap3[p];
			af_y_inp[3] = y_ap4[p];
			af_x_inp[3] = x_ap4[p];
			af_x_out[0] = (double)anch_l1;
			af_y_out[0] = (double)(s_ap1[p]);
			af_x_out[1] = (double)anch_l1;
			af_y_out[1] = (double)(s_ap2[p]);
			af_x_out[2] = (double)anch_l2;
			af_y_out[2] = (double)(s_ap3[p]);
			af_x_out[3] = (double)anch_l2;
			af_y_out[3] = (double)(s_ap4[p]);

			inp_off[0]=af_x_inp[1];
			inp_off[1]=af_y_inp[1];		
			out_off[0]=af_x_out[1];
			out_off[1]=af_y_out[1];			

if ((str_glob->limb==1)||(str_glob->badlimb==1))	{
			callfunc = check_quad ( af_x_inp,  af_y_inp );
			if (callfunc==-1) continue;
			}
			callfunc = hwgetpro
				   (af_x_inp, af_y_inp, af_x_out, af_y_out, a);
			/*---------------------------------------------	*/
			/* extreme line/sample-coord. of this patch
			   in the input-buffer 				*/
			/*---------------------------------------------	*/

			min_l_p = 0.0 - up_save;
			max_l_p = (double)act_anchdist_l + lo_save;
			min_s_p = (double)(imin
				  (s_ap1[p], s_ap2[p], s_ap3[p], s_ap4[p]))-1.0-(up_save-0.001);
			max_s_p = (double)(imax
				  (s_ap1[p], s_ap2[p], s_ap3[p], s_ap4[p]))-1.0+(up_save-0.001);

			act_anchdist_s = (imax (s_ap1[p], s_ap2[p], s_ap3[p], s_ap4[p]))
					-(imin (s_ap1[p], s_ap2[p], s_ap3[p], s_ap4[p]));
			d_first_s_p = min_s_p+1.0+(up_save-0.001);

			switch (str_glob->interpol_type)
				{
				case 1:
/*---------------------------------------------------------------------	*/
/* 				bilinear*/
/*---------------------------------------------------------------------	*/
				if (max_s_p >= (double)(dlrframe_info.ns)-1.0)
					max_s_p = (double)(dlrframe_info.ns)-1.001;
						
				if (min_s_p < 0.0) min_s_p = 0.001;
						
				break;

				case 2:
/*----------------------------------------------------------------------	*/
/* 				cubic convolution	*/
/*----------------------------------------------------------------------	*/
				if (min_s_p < 1.0) min_s_p = 1.001;
				if (max_s_p >= (double)(dlrframe_info.ns)-2.0)
					max_s_p = (double)(dlrframe_info.ns)-2.001;
				break;
						
				default:
/*---------------------------------------------------------------------	*/
/* 				Nearest Neighbour*/
/*---------------------------------------------------------------------	*/
				break;
				}

			/*---------------------------------------------	*/
			/* extreme x/y-coord. of this patch
			   in the output image 				*/
			/*---------------------------------------------	*/

			min_x_p = (int) (min(af_x_inp[0], af_x_inp[1],
					     af_x_inp[2], af_x_inp[3])-3.0*up_save);
			max_x_p = (int) (max(af_x_inp[0], af_x_inp[1],
					     af_x_inp[2], af_x_inp[3])+3.0*up_save);
			min_y_p = (int) (min(af_y_inp[0], af_y_inp[1],
					     af_y_inp[2], af_y_inp[3])-3.0*up_save);
			max_y_p = (int) (max(af_y_inp[0], af_y_inp[1],
					     af_y_inp[2], af_y_inp[3])+3.0*up_save);

			if (max_x_p > 1 && max_y_p > 1 
			    && min_y_p < str_glob->nof_out_s && min_x_p < str_glob->nof_out_l)
			{
			if (min_x_p < 1) min_x_p = 1;
			if (min_y_p < 1) min_y_p = 1;
			if (max_x_p > str_glob->nof_out_l) max_x_p = str_glob->nof_out_l;
			if (max_y_p > str_glob->nof_out_s) max_y_p = str_glob->nof_out_s;
		
			if((area == first_area) && (af_x_inp[0]<af_x_inp[2])) down=1;

			if ((min_x_p < first_read_out_l) ||  (max_x_p > last_read_out_l))
				{
				if ((max_x_p-min_x_p) > max_nof_read_out_l) return(-997); 

					
				/*-------------------------------------	*/
				/* write and read output-grayvalues if
							 neccessary 	*/
				/*-------------------------------------	*/
				/*-------------------------------------	*/
				/* write				*/
				/*-------------------------------------	*/
				if(area != first_area) 
					{
					for (i=first_read_out_l;
					     i<first_read_out_l+nof_read_out_l;
					     i++)				
						{
						out_buf_off= (i-first_read_out_l) *str_glob->nof_out_s;

						if (str_glob->oformat == 4)
							{
							callfunc = zvwrit (str_glob->outunit,
							(gv_out_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							}
						else if (str_glob->oformat == 3)
							{
							callfunc = zvwrit (str_glob->outunit,
							(gv_out_buf_full+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							}
						else if (str_glob->oformat == 2)
							{
							callfunc = zvwrit (str_glob->outunit,
							(gv_out_buf_half+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							}
						else
							{
							callfunc = zvwrit (str_glob->outunit,
							(gv_out_buf_byte+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							}

						if (str_glob->match)
							{
							callfunc = zvwrit (str_glob->match_x_unit,
							(match_x_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							callfunc = zvwrit (str_glob->match_y_unit,
							(match_y_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
							}
						}

					i=0;
					if (str_glob->oformat == 4)
						{
						if (str_glob->limb==1)
			    			gv_out_buf_float=gv_out_buf_for_limb;
						else
			    			{
 			    			do
			    			{
			    			gv_out_buf_float= (float *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
			    			if (str_glob->match) 
							{
							match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							}
			    			i++;
			    			} while ((gv_out_buf_float == (float *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

			    			out_buf_size -= ((i-1)*4000000);
			    			*gv_out_buf_float = 0.;
			    			}
						}
					else if (str_glob->oformat == 3)
						{
 						do
						{
						gv_out_buf_full= (int *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
						if (str_glob->match) 
							{
							match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							}
						i++;
						} while ((gv_out_buf_full == (int *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

						out_buf_size -= ((i-1)*4000000);
						*gv_out_buf_full = 0;
						}
					else if (str_glob->oformat == 2)
						{
 						do
						{
						gv_out_buf_half= (short int *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
						if (str_glob->match) 
							{
							match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							}
						i++;
						} while ((gv_out_buf_half == (short int *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

						out_buf_size -= ((i-1)*4000000);
						*gv_out_buf_half = 0;
						}
					else
						{
 						do
						{
						gv_out_buf_byte= (myBYTE *) calloc (1,(out_buf_size*str_glob->oformat_size-i*4000000));
						if (str_glob->match) 
							{
							match_x_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							match_y_buf_float= (float *) calloc (1,(out_buf_size*sizeof(float)-i*4000000));
							}
						i++;
						} while ((gv_out_buf_byte == (myBYTE *)NULL)||(str_glob->match &&((match_x_buf_float == (float *)NULL)||(match_y_buf_float == (float *)NULL))));

						out_buf_size -= ((i-1)*4000000);
						*gv_out_buf_byte = 0;
						} 
					}
				if (str_glob->oformat == 4)
					{
					max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(float)));
					}
				else if (str_glob->oformat == 3)
					{
					max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(int)));
					}
				else if (str_glob->oformat == 2)
					{
					max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(short int)));
					}
				else
					{
					max_nof_read_out_l = (int) (out_buf_size*str_glob->oformat_size/(str_glob->nof_out_s*sizeof(myBYTE)));
					}

				/*----------------------------------	*/
				/* read					*/
				/*----------------------------------	*/

				if(down==1)
					{
					first_read_out_l = min_x_p-50;
					}
				else
					{
					first_read_out_l = 
						max_x_p-max_nof_read_out_l+50;
					}

				if (first_read_out_l<1)first_read_out_l=1;

				if ((first_read_out_l+max_nof_read_out_l-1)
				> str_glob->nof_out_l)
					{
					nof_read_out_l = 
					str_glob->nof_out_l-first_read_out_l+1;
					}
				else
					{
					nof_read_out_l = max_nof_read_out_l;
					} 


				for (i=first_read_out_l;
				     i<first_read_out_l+nof_read_out_l; i++)				
					{
					out_buf_off=(i-first_read_out_l)
							*str_glob->nof_out_s;
					if (str_glob->oformat == 4)
						{
						callfunc = zvread (str_glob->outunit,
							(gv_out_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						}
					else if (str_glob->oformat == 3)
						{
						callfunc = zvread (str_glob->outunit,
							(gv_out_buf_full+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						}
					else if (str_glob->oformat == 2)
						{
						callfunc = zvread (str_glob->outunit,
							(gv_out_buf_half+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						}
					else
						{
						callfunc = zvread (str_glob->outunit,
							(gv_out_buf_byte+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						}
					
					if (str_glob->match)
						{
						callfunc = zvread (str_glob->match_x_unit,
							(match_x_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						callfunc = zvread (str_glob->match_y_unit,
							(match_y_buf_float+out_buf_off),
							"LINE", i, "SAMP", 1, 0);
						}
					}
				last_read_out_l = 
				first_read_out_l+nof_read_out_l-1;
				}

/*-------------------------------------------------------------------	*/
/* 			initial application of the transformation	*/
/*			from out- to input image			*/
/*-------------------------------------------------------------------	*/

			callfunc = hwapppro
				   ((double)min_x_p, (double)min_y_p, inp_off, out_off,
				    &initial_l, &initial_s, a);

			initial_l -= (double)anch_l1;
			initial_s -= 1.0;
			

			x_start = min_x_p-first_read_out_l;
			x_end   = max_x_p-first_read_out_l;
 
			y_start = min_y_p-1;
			y_end   = max_y_p-1;
			

/*---------------------------------------------------------------------	*/
/* 			Loop of all positions in the output-image within*/
/*   			the extreme coordinates.			*/
/*   			For each position there is a test whether it is*/
/*   			within the actual patch in the input image	*/
/*---------------------------------------------------------------------	*/
			xcount=0;
			for (x_act=x_start; x_act<=x_end; x_act++)				
				{
/*---------------------------------------------------------------------	*/
/* 				loop of all lines			*/
/*---------------------------------------------------------------------	*/

				l = initial_l;
				s = initial_s;
 
				ycount=0;
				for (y_act=y_start;y_act<=y_end; y_act++)
					
					{
/*---------------------------------------------------------------------	*/
/* 					loop of all samples		*/
/*---------------------------------------------------------------------	*/

/*---------------------------------------------------------------------	*/
/* 					test: in/out of the input patch*/
/*---------------------------------------------------------------------	*/

					if (l >= min_l_p) 
					if (l <= max_l_p) 
					if (s >= min_s_p) 
					if (s <= max_s_p) 
						{
						if (l < 0.0)
							{
							int_l=-((int)(-l+1.0));				
							}
						else
							{
							int_l=(int)l;				
							} 
						int_s=(int)s;				
/*---------------------------------------------------------------------	*/
/* 						in:			*/
/*---------------------------------------------------------------------	*/
											
/*---------------------------------------------------------------------	*/
/* 						interpolate a grayvalue */
/*---------------------------------------------------------------------	*/
						switch (ipol)
							{
							case 1:
/*---------------------------------------------------------------------	*/
/* 							bilinear*/
/*---------------------------------------------------------------------	*/
						
							gv_inp_lo = gv_inp_buf
							 +(*(tab_in+int_l+up_int_save)+int_s);

							gv_inp_ro = gv_inp_buf
 							 +(*(tab_in+int_l+up_int_save)+int_s+1);

							gv_inp_lu = gv_inp_buf 
							 +(*(tab_in+int_l+1+up_int_save)+int_s);

							gv_inp_ru = gv_inp_buf 		
							 +(*(tab_in+int_l+1+up_int_save)+int_s+1);

							d_l = l - (double) (int_l);
							d_s = s - (double) (int_s);

							callfunc = hwintgv_bi
								   (gv_inp_lo,
								    gv_inp_ro,
							 	    gv_inp_lu,
								    gv_inp_ru,
								    d_l, d_s, gv); 

							break;

							case 2:
/*----------------------------------------------------------------------	*/
/* 							cubic convolution	*/
/*----------------------------------------------------------------------	*/
					
	
							*(gv_bicu+0) = *(gv_inp_buf
							 +(*(tab_in+int_l-1+up_int_save)+int_s-1));

							*(gv_bicu+1) = *(gv_inp_buf
							 +(*(tab_in+int_l-1+up_int_save)+int_s));

							*(gv_bicu+2) = *(gv_inp_buf
							 +(*(tab_in+int_l-1+up_int_save)+int_s+1));

							*(gv_bicu+3) = *(gv_inp_buf
							 +(*(tab_in+int_l-1+up_int_save)+int_s+2));

							*(gv_bicu+4) = *(gv_inp_buf
							 +(*(tab_in+int_l+up_int_save)+int_s-1));

							*(gv_bicu+5) = *(gv_inp_buf
							 +(*(tab_in+int_l+up_int_save)+int_s));

							*(gv_bicu+6) = *(gv_inp_buf
							 +(*(tab_in+int_l+up_int_save)+int_s+1));

							*(gv_bicu+7) = *(gv_inp_buf
							 +(*(tab_in+int_l+up_int_save)+int_s+2));

							*(gv_bicu+8) = *(gv_inp_buf
							 +(*(tab_in+int_l+1+up_int_save)+int_s-1));

							*(gv_bicu+9) = *(gv_inp_buf
							 +(*(tab_in+int_l+1+up_int_save)+int_s));

							*(gv_bicu+10) = *(gv_inp_buf
							 +(*(tab_in+int_l+1+up_int_save)+int_s+1));

							*(gv_bicu+11) = *(gv_inp_buf
							 +(*(tab_in+int_l+1+up_int_save)+int_s+2));

							*(gv_bicu+12) = *(gv_inp_buf
							 +(*(tab_in+int_l+2+up_int_save)+int_s-1));

							*(gv_bicu+13) = *(gv_inp_buf
							 +(*(tab_in+int_l+2+up_int_save)+int_s));

							*(gv_bicu+14) = *(gv_inp_buf
							 +(*(tab_in+int_l+2+up_int_save)+int_s+1));

							*(gv_bicu+15) = *(gv_inp_buf
							 +(*(tab_in+int_l+2+up_int_save)+int_s+2));


							d_l = l - (double) (int_l);
							d_s = s - (double) (int_s);

							callfunc = hwintgv_cc 
								   ( d_s, d_l, gv_bicu, gv);
							break;
						
							default:
/*---------------------------------------------------------------------	*/
/* 							Nearest Neighbour*/
/*---------------------------------------------------------------------	*/

							if ((l+0.5) < 0.0)
								{
								int_l=-1;				
								}
							else
								{
								int_l=(int)(l+0.5);
								} 

							inp_buf_off =
							(int)(s+0.5)+*(tab_in+int_l+up_int_save);

							*gv = *(gv_inp_buf
								      +inp_buf_off);

							}

						if (str_glob->phocorr != 0)
							{
							/*---------------------------*/
							/* computate a photometric
							   correction factor using
							   bilinear interpolation
							   between the phoCorValues
							   of the anchorpoints	     */
							/*---------------------------*/
							d_l = l ;
							d_s = s - d_first_s_p;
							
							callfunc = hwintpho_bi
								   (phoCorVal_vec_ap1[p],
								    phoCorVal_vec_ap2[p],
							 	    phoCorVal_vec_ap3[p],
								    phoCorVal_vec_ap4[p],
								    d_l, d_s, act_anchdist_l, act_anchdist_s,
								    &phoCorVal); 
							*gv = *gv * (float)phoCorVal;
							}

 						/*--------------------------------	*/
						/* put the new grayvalue
						   to the output matrix			*/
						/*--------------------------------	*/

						out_buf_off = y_act+*(tab_out+x_act);
						
						if (str_glob->oformat == 1)
							{
							if (*gv > 255.0) *gv = 255.0;
							else if (*gv < 0.0) *gv = 0.;
							*(gv_out_buf_byte + out_buf_off) = *(tab_gv + (int)(*gv + 0.5));
							}
						else if (str_glob->oformat == 2)
							{
							*(gv_out_buf_half + out_buf_off)=(short int)(*gv + 0.5);
							}
						else if (str_glob->oformat == 3)
							{
							*(gv_out_buf_full + out_buf_off) = (int)(*gv + 0.5);
							}
						else
							{
							*(gv_out_buf_float + out_buf_off) = *gv;
							}
							
						if (str_glob->match !=0)
						    {
						    *(match_x_buf_float + out_buf_off) = (float)(l + (double)anch_l1);
						    *(match_y_buf_float + out_buf_off) = (float)(s + 1.0);
						    }
						}
					ycount++;
					callfunc = hwapppro
				   	((double)(min_x_p+xcount), (double)(min_y_p+ycount), inp_off, out_off, &l, &s, a);
					l -= (double)anch_l1;
					s -= 1.0;
					}
				xcount++;
				callfunc = hwapppro
					((double)(min_x_p+xcount), (double)min_y_p, inp_off, out_off, &initial_l, &initial_s, a);
				initial_l -= (double)anch_l1;
				initial_s -= 1.0;
 				}
			}
			}
		/*----------------------------------------------------	*/
		/* free input buffer
		   for next area between two anchorpoint lines		*/
		/*----------------------------------------------------	*/

		free (gv_inp_buf);
		gv_inp_buf= (float *) calloc (1,sizeof(float) * dlrframe_info.ns * 10*str_glob->anchdist);
		if (gv_inp_buf == (float *)NULL) return(-998); 
		area++;
		} 

	free (gv_inp_buf);
	
	/*----------------------------------------------------	*/
	/* write output-grayvalues				*/
	/*----------------------------------------------------	*/
	if (str_glob->limb!=1)
	    {
	    for (i=first_read_out_l; i<first_read_out_l+nof_read_out_l; i++)				
		{
		out_buf_off=(i-first_read_out_l)*str_glob->nof_out_s;
		
		if (str_glob->oformat == 4)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_float+out_buf_off),
			"LINE", i, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 3)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_full+out_buf_off),
			"LINE", i, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 2)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_half+out_buf_off),
			"LINE", i, "SAMP", 1, 0);
			}
		else
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_byte+out_buf_off),
			"LINE", i, "SAMP", 1, 0);
			}

		if (str_glob->match)
			{
			callfunc = zvwrit (str_glob->match_x_unit,
				(match_x_buf_float+out_buf_off),
				"LINE", i, "SAMP", 1, 0);
			callfunc = zvwrit (str_glob->match_y_unit,
				(match_y_buf_float+out_buf_off),
				"LINE", i, "SAMP", 1, 0);
			}
		}

	    if ((str_glob->oformat == 4)&&(str_glob->limb==0)) free (gv_out_buf_float);
	    else if (str_glob->oformat == 3) free (gv_out_buf_full);
	    else if (str_glob->oformat == 2) free (gv_out_buf_half);
	    else	free (gv_out_buf_byte);
	    }
		
	if (str_glob->match !=0 )
	    {
    	    free (match_x_buf_float);
  	    free (match_y_buf_float);
	    }	

	return (0);
	}

/*==========================================================================*/
/*#############################################################	*/
/* Transformation of pixels at one ephemeris time
	from image plane via reference body to map projection	
						(private)	*/
/*#############################################################	*/
/* Calls from	frameorloc_rip, framegeorec_rip			*/
/* Calling	zcltviewpa, dlrsurfpt*, zhwcarto			*/
/*#############################################################	*/

	int frametraidtm_rip (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, 
			  int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, double *phoCorVal_vec, int loc_rec)
	/*#############################################################*/

	{
	int	lltype = 1;	/*   !!!!!!!!  1 = geocentric !!!!!!!!	*/
	int	forward = 0, callfunc, i, k, found_ell, shadow;

	double	*tempMDirView;
		/*	One line of sight vector in body fixed frame	*/
	double	positn[3];	/*	Position in body-fixed frame	*/
	double	lat=999.9, longi=999.9, latlong[3], intersection_point[3];
	double	a_ax, b_ax, c_ax, l_ax, last_l, last_s, help_londiff;

	double	DirEll[3], DirSurf[3], MDirView[3], phoCorVal;
	char	outstring[20];
	double	radius, dist2;
	int	all_quads, int_l, int_s;

	double	x1,y1,z1,d, last_h;
	double	last_add_h, delta_h;
	float	f_temp;
	short int short_temp;
	int	graphiclltype = 2;	
	int	above, int_hit_lin_act, int_hit_sam_act, found_ell_vec[2];
	short int  *dtm_lo, *dtm_ro, *dtm_lu, *dtm_ru, local_dn, hit_dn[2], short_miss;
	double	add_h[2], height, d_l, d_s, local_max_h, local_min_h;
	double  hit_dlin, hit_dsam,  hit_lin[2], hit_sam[2], hit_dist, hit_grad, hit_off, hit_lin_step, hit_sam_step, hit_lin_act,
	        hit_sam_act, hit_dn_step, hit_dn_act, act_l, act_s;
	int	hit_steps;
	
	if (1) /* new ray tracer */
		{
		callfunc = frametraidtm_ripnew (str_glob, dlrframe_info, mp_obj, mp_dtm_obj, dtmlabel, pho_obj, nof_pix,
		      ccd, x, y, foundvec, signvec, phoCorVal_vec, loc_rec);
		return (callfunc);
		}

	
	tempMDirView=(double *)calloc(1,nof_pix*3*sizeof(double));
	if (tempMDirView == (double *)NULL) return(-998); 


	a_ax=str_glob->axes[0];
	b_ax=str_glob->axes[1];
	c_ax=str_glob->axes[2];
	l_ax=str_glob->long_axis;

	/*---------------------------------------------------------
	  Compute line of sight vectors of all pixels and position of s/c
	  ---------------------------------------------------------	*/
	positn[0]=str_glob->positn[0];
	positn[1]=str_glob->positn[1];
	positn[2]=str_glob->positn[2];
	
	callfunc = dlrframe_getview (dlrframe_info, str_glob->adjuptr,
                     nof_pix, ccd, str_glob->cpmat,
                     str_glob->xcal, str_glob->ycal, str_glob->focal, tempMDirView);   

	for (k=0; k<nof_pix; k++)	/* loop of all pixels	*/
		{
		last_l=last_s=-9999999;
 		for (i=0; i<=2; i++) { MDirView [i] = *(tempMDirView+i+3*k);}
		
		/*----------------------------------------------------	
		  Intersection point of one line of sight with dtm / ref. body	
		  ----------------------------------------------------	*/
		if (!(str_glob->geom))
		{
		height = -999999.9;
		add_h[0]=str_glob->max_h_in_dtm;
		add_h[1]=str_glob->min_h_in_dtm;
		hit_dn[0]=(short int)((str_glob->max_h_in_dtm-(double)(dtmlabel.dtm_offset))/dtmlabel.dtm_scaling_factor);
		hit_dn[1]=(short int)((str_glob->min_h_in_dtm-(double)(dtmlabel.dtm_offset))/dtmlabel.dtm_scaling_factor);
/*
		local_max_h=str_glob->max_h_in_dtm;
		local_min_h=str_glob->min_h_in_dtm;
		last_h=(local_max_h+local_min_h)/2.0;
		delta_h = (double)(dtmlabel.dtm_scaling_factor); in m 
*/

		for (i=0;i<2;i++)
		    {
		    a_ax=str_glob->dtm_axes[0]+add_h[i]/1000.0; /* in km */
		    b_ax=str_glob->dtm_axes[1]+add_h[i]/1000.0; /* in km */
		    c_ax=str_glob->dtm_axes[2]+add_h[i]/1000.0; /* in km */
    
		    dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell_vec[i]);

		    rec2graphicll (intersection_point, str_glob->dtm_axes_map, latlong);
    
		    lat = latlong[0]*my_pi2deg;
		    longi = latlong[1]*my_pi2deg*str_glob->dtm_poslongdir_fac;
		    callfunc = zhwcarto (mp_dtm_obj, str_glob->prefs_dtm, &hit_lin[i], &hit_sam[i], &lat, &longi, graphiclltype, forward);
		    }

		if (found_ell_vec[0]!=1) continue;

		hit_dlin     = hit_lin[1]-hit_lin[0];
		hit_dsam     = hit_sam[1]-hit_sam[0];
		hit_dist     = sqrt(hit_dlin*hit_dlin+hit_dsam*hit_dsam);
		if (hit_dist<1.0)
		    {
		    if ((hit_lin[0]>=1.0)&&(hit_lin[0]<=(double)str_glob->nof_dtm_l)&&
			(hit_sam[0]>=1.0)&&(hit_sam[0]<=(double)str_glob->nof_dtm_s))
		    	{
		    	if (fix_height < -99999.0)
					{
					local_dn = *(str_glob->dtm_buf+(*(str_glob->dtm_tab_in+(int)(hit_lin[0]+0.5)-1)+(int)(hit_sam[0]+0.5)-1));
		    		if (local_dn != short_miss) 
					height = (double)(dtmlabel.dtm_scaling_factor * (double)local_dn + dtmlabel.dtm_offset); /* in m */
					if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")==0) /* SRC case (small image) */
						{
						fix_height = height;
						}
					}
				height = fix_height;
				}
		    }
		else
		    {
		    if (fix_height < -99999.0)
				{
		    	hit_lin_step = hit_dlin/hit_dist;
		    	hit_sam_step = hit_dsam/hit_dist;
		    	hit_dn_step  = (double)(hit_dn[0]-hit_dn[1])/hit_dist;
		    	hit_lin_act  = hit_lin[0]-hit_lin_step;
		    	hit_sam_act  = hit_sam[0]-hit_sam_step;
		    	hit_dn_act   = (double)hit_dn[0]+hit_dn_step;
		    	hit_steps    = (int)hit_dist+1;
		    	above = 0;
		    	for (i=0;i<=hit_steps;i++)
					{
		    		hit_lin_act += hit_lin_step;
		    		hit_sam_act += hit_sam_step;
		   			hit_dn_act  -= hit_dn_step;
		    		int_hit_lin_act = (int)hit_lin_act;
		    		int_hit_sam_act = (int)hit_sam_act;
		    		if((int_hit_lin_act<1)||(int_hit_lin_act>=str_glob->nof_dtm_l)
                  		||(int_hit_sam_act<1)||(int_hit_sam_act>=str_glob->nof_dtm_s)) {above = 0;continue;}
		    			callfunc = hwintdtm_bi (str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act-1),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act-1),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act),
                                        hit_lin_act-(double)int_hit_lin_act, 
                                        hit_sam_act-(double)int_hit_sam_act, 
                                        short_miss, &local_dn);
                	if (callfunc < 0) {above = 0;continue;}

		    		if (((double)local_dn > hit_dn_act)&& above) 
						{
                		height = (double)(dtmlabel.dtm_scaling_factor * (double)local_dn + dtmlabel.dtm_offset); /* in m */
						break;
						}
		    		else {above = 1;}
		    		}
				if (strcmp(dlrframe_info.spacecraft_name,"MARS EXPRESS")==0) /* SRC case (small image) */
					{
					fix_height = height;
					}
		    	}
			height = fix_height;
			}
			}
		else height=str_glob->height;
			
/*
		do  {

		    add_h = (local_max_h+local_min_h)/2.0; in m
		    a_ax=str_glob->dtm_axes[0]+add_h/1000.0; in km
		    b_ax=str_glob->dtm_axes[1]+add_h/1000.0; in km
		    c_ax=str_glob->dtm_axes[2]+add_h/1000.0; in km
    
		    dlrsurfptl_xyz (positn, MDirView, a_ax, b_ax, c_ax, l_ax, intersection_point, &found_ell);

 		    rec2centricll_radius (intersection_point, latlong, str_glob->dtm_axes, &radius, str_glob->mp_n_axes);
    
		    lat = latlong[0]*my_pi2deg;
		    longi = latlong[1]*my_pi2deg*str_glob->dtm_poslongdir_fac;
		    callfunc = zhwcarto (mp_dtm_obj, str_glob->prefs_dtm, &x[k], &y[k], &lat, &longi, lltype, forward);
		    int_l=(int)(x[k]+0.5);
		    int_s=(int)(y[k]+0.5);

		    if ((fabs(x[k]-last_l)+fabs(y[k]-last_s))<str_glob->scale_ratio) break;

		    if((int_l>0)&&(int_l<str_glob->nof_dtm_l)&&(int_s>0)&&(int_s<str_glob->nof_dtm_s))
			{
			if ((short_temp = *(str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_l-1)+int_s-1)))!=(short int)dtmlabel.dtm_missing_dn)
			    {

			    height = (double)(dtmlabel.dtm_scaling_factor * (float)short_temp + dtmlabel.dtm_offset); in m
			    if ((add_h-height)>delta_h)      local_max_h=add_h ;
			    else if ((add_h-height)<-delta_h) local_min_h=add_h ;
			    else 
				{
				break;
				}
			    last_h=height;
			    last_l = x[k];
			    last_s = y[k];

			    }
			else 
			    {
			    local_max_h=add_h;
			    height = -999999.9;
			    }
			}
		    else 
			{
			local_max_h=add_h;
			height = -999999.9;
			}
		    } while ((local_max_h-local_min_h)>delta_h);
		}
		else height=str_glob->height;
*/

		if (height < -999999.0) 
		    {
		    foundvec[k] = 0;
			if (loc_rec == 1) continue;
		    
			a_ax=str_glob->dtm_axes[0]; /* in km */
			b_ax=str_glob->dtm_axes[1]; /* in km */
			c_ax=str_glob->dtm_axes[2]; /* in km */
		    dlrsurfptl_xyz (positn, MDirView, a_ax, b_ax, c_ax, l_ax, intersection_point, &found_ell);
		    if (found_ell != 1) str_glob->limb=1;
		    else str_glob->found=1;
			continue;
		    }
		
		a_ax=str_glob->dtm_axes[0]+height/1000.0; /* in km */
		b_ax=str_glob->dtm_axes[1]+height/1000.0; /* in km */
		c_ax=str_glob->dtm_axes[2]+height/1000.0; /* in km */
		
		dlrsurfptl_xyz (positn, MDirView, a_ax, b_ax, c_ax, l_ax, intersection_point, &found_ell);
 		if (!found_ell) 
			{
		    	foundvec[k] = 0;
			str_glob->limb=1;
			continue;
			}

		str_glob->found=1;
		str_glob->found_in_dtm=1;

		rec2centricll_radius ( intersection_point, latlong, str_glob->mp_axes, &radius, str_glob->mp_n_axes); 

		if (str_glob->critical_projection == -1)
			{
			x1=radius*cos(latlong[0])*cos(latlong[1]);
			y1=radius*cos(latlong[0])*sin(latlong[1]);
			z1=radius*sin(latlong[0]);
			d=sqrt(x1*x1+y1*y1+z1*z1);
			dist2=(x1-str_glob->xcen)*(x1-str_glob->xcen)+(y1-str_glob->ycen)*(y1-str_glob->ycen)+(z1-str_glob->zcen)*(z1-str_glob->zcen);
			/* is this point visible for this special orthogr. projection ? */
			if (acos((dist2-str_glob->d02-d*d)/-2.0/str_glob->d0/d)>=my_halfpi){foundvec[k]=0;continue;}
			}

		lat = latlong[0]*my_pi2deg;
		longi = latlong[1]*my_pi2deg*str_glob->poslongdir_fac;
		if (longi < 0.0) longi += 360.0;

		if (lat < str_glob->min_lati) str_glob->min_lati = lat;
		if (lat > str_glob->max_lati) str_glob->max_lati = lat;

		if (lat > str_glob->max_valid_lati) {foundvec[k]=0;continue;}
		else if (lat < str_glob->min_valid_lati) {foundvec[k]=0;continue;}

		foundvec[k] = 1;

		if (longi < str_glob->min_longi) str_glob->min_longi = longi;
		if (longi > str_glob->max_longi) str_glob->max_longi = longi;

		if (str_glob->critical_projection > 0)
		    {
		    if (loc_rec == 1)
				{ 
				help_londiff = (longi-str_glob->cenlong)*my_deg2pi;

				if (str_glob->critical_projection > 1)
			    	{
			    	if (cos(help_londiff)>0.0)	        signvec[k] = 0;
			    	else if (sin(help_londiff)>0.0)     signvec[k] = 1;
			    	else				signvec[k] = -1;
			    	}
				else
			    	{
			    	if ((cos(help_londiff)>0.0)||
			    	((90.0-fabs(lat))<fabs(str_glob->cenlat)))	 signvec[k] = 0;
			    	else if (sin(help_londiff)>0.0)    		 signvec[k] = 1;
			    	else					 signvec[k] = -1;
			    	}
				}
		    else
				{
				if ((longi >= 0.0)&&(longi <= 90.0))   str_glob->quad[0]=0;
				if ((longi >= 90.0)&&(longi <= 180.0)) str_glob->quad[1]=0;
				if ((longi >= 180.0)&&(longi <= 270.0))str_glob->quad[2]=0;
				if ((longi >= 270.0)&&(longi <= 360.0))str_glob->quad[3]=0;
				}
		    }
		else signvec[k] = 0;
		/*----------------------------------------------------	
		 Transform one point from lat/long to a map projected x/y	
		 -----------------------------------------------------  */	

		callfunc = zhwcarto  (mp_obj, str_glob->prefs, &x[k], &y[k], &lat, &longi, lltype, forward);
		if (callfunc != mpSUCCESS)
			    {
			    if (callfunc==mpINVALID_PROJECTION)
				    printf("\n hwcarto returns INVALID_PROJECTION !!");
    			    else
				    printf("\n hwcarto returns %d !",callfunc);
 			    printf("\n VICAR task FRAMEGEOM aborted ");
			    zabend();
			    }

		if (loc_rec == 0) continue;

		if (str_glob->phocorr != 0)
			{
/*			shadow = hwshadow(dtm_rip_str,intersection_point, DirSurf, str_glob->MDirInc);*/
			zhwllnorm(latlong[0], latlong[1], str_glob->axes, l_ax, DirEll);

 			callfunc = hwphoeco(pho_obj, DirEll, str_glob->MDirInc, MDirView, str_glob->TargIncAng,
					    str_glob->TargViewAng, str_glob->TargAzimAng, &phoCorVal);
			phoCorVal_vec[k] = phoCorVal;		
 			}
		}
						
	free(tempMDirView);
	
	if (loc_rec == 0)
	    {
	    all_quads = str_glob->quad[0] + str_glob->quad[1] + str_glob->quad[2] + str_glob->quad[3];
	    if (((str_glob->max_longi-str_glob->min_longi)>180.0)&&(all_quads == 0))
		{str_glob->pole=1;}
	    }
	return(0);
	}

/*==========================================================================*/
/*#############################################################	*/
/* Transformation of pixels at one ephemeris time
	from image plane via reference body to map projection	
						(private)	*/
/*#############################################################	*/
/* Calls from	frameorloc_rip, framegeorec_rip			*/
/* Calling	zcltviewpa, dlrsurfpt*, zhwcarto			*/
/*#############################################################	*/

	int frametraidtm_ripnew (str_glob_TYPE *str_glob, dlrframe_info dlrframe_info, MP mp_obj, MP mp_dtm_obj, dtm dtmlabel, PHO pho_obj, 
			  int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, double *phoCorVal_vec, int loc_rec)
	/*#############################################################*/

	{
	int	lltype = 1;	/*   !!!!!!!!  1 = geocentric !!!!!!!!	*/
	int	forward = 0, callfunc, i, k, found_ell, shadow;

	double	*tempMDirView;
		/*	One line of sight vector in body fixed frame	*/
	double	positn[3];	/*	Position in body-fixed frame	*/
	double	lat=999.9, longi=999.9, latlong[3], intersection_point[3];
	double	a_ax, b_ax, c_ax, l_ax, last_l, last_s, help_londiff;

	double	DirEll[3], DirSurf[3], MDirView[3], phoCorVal;
	char	outstring[20];
	double	radius, dist2;
	int	all_quads, int_l, int_s;

	double	x1,y1,z1,d, last_h;
	double	last_add_h, delta_h;
	float	f_temp;
	short int short_temp;
	int	graphiclltype = 2;	
	int	above, int_hit_lin_act, int_hit_sam_act, found_ell_vec[2];
	short int  *dtm_lo, *dtm_ro, *dtm_lu, *dtm_ru, local_dn, hit_dn[2], short_miss;
	double	add_h[2], height, d_l, d_s, local_max_h, local_min_h;
	double  hit_dlin, hit_dsam,  hit_lin[2], hit_sam[2], hit_dist, hit_grad, hit_off, hit_lin_step[3], hit_sam_step, hit_lin_act,
	        hit_sam_act, hit_dn_step, hit_dn_act, act_l, act_s, latlongh[3], xx[3], yy[3], zz[3],stepwidth,saveaddh1, hit_dx, hit_dy, hit_dz, hit_xyz_act[3];
	int	hit_steps;
	
	
	tempMDirView=(double *)calloc(1,nof_pix*3*sizeof(double));
	if (tempMDirView == (double *)NULL) return(-998); 

	a_ax=str_glob->axes[0];
	b_ax=str_glob->axes[1];
	c_ax=str_glob->axes[2];
	l_ax=str_glob->long_axis;

	/*---------------------------------------------------------
	  Compute line of sight vectors of all pixels and position of s/c
	  ---------------------------------------------------------	*/
	positn[0]=str_glob->positn[0];
	positn[1]=str_glob->positn[1];
	positn[2]=str_glob->positn[2];
	
	callfunc = dlrframe_getview (dlrframe_info, str_glob->adjuptr,
                     nof_pix, ccd, str_glob->cpmat,
                     str_glob->xcal, str_glob->ycal, str_glob->focal, tempMDirView);   

	for (k=0; k<nof_pix; k++)	/* loop of all pixels	*/
		{
		last_l=last_s=-9999999;
 		for (i=0; i<=2; i++) { MDirView [i] = *(tempMDirView+i+3*k);}
		
		/*----------------------------------------------------	
		  Intersection point of one line of sight with dtm / ref. body	
		  ----------------------------------------------------	*/
		if (!(str_glob->geom))
		{
		height = -999999.9;
		add_h[0]=str_glob->max_h_in_dtm+(str_glob->max_h_in_dtm-str_glob->min_h_in_dtm)*0.01;
		add_h[1]=str_glob->min_h_in_dtm-(str_glob->max_h_in_dtm-str_glob->min_h_in_dtm)*0.01;

		for (i=0;i<2;i++)
		    {
		    a_ax=str_glob->dtm_axes[0]+add_h[i]/1000.0; /* in km */
		    b_ax=str_glob->dtm_axes[1]+add_h[i]/1000.0; /* in km */
		    c_ax=str_glob->dtm_axes[2]+add_h[i]/1000.0; /* in km */
    
		    dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell_vec[i]);
			if (found_ell_vec[0]!=1) break;

			xx[i] = intersection_point[0];
			yy[i] = intersection_point[1];
			zz[i] = intersection_point[2];

		    rec2graphicll (intersection_point, str_glob->dtm_axes_map, latlong);
    
		    lat = latlong[0]*my_pi2deg;
		    longi = latlong[1]*my_pi2deg*str_glob->dtm_poslongdir_fac;
		    callfunc = zhwcarto (mp_dtm_obj, str_glob->prefs_dtm, &hit_lin[i], &hit_sam[i], &lat, &longi, graphiclltype, forward);
		    }

		if (found_ell_vec[0]!=1) continue;

		if (found_ell_vec[1]!=1)
			{
			stepwidth = (add_h[0]-add_h[1])/2.;
			add_h[1] += stepwidth; 
			saveaddh1 = -999999.9;
			while (stepwidth>str_glob->dtm_scale)
				{
				a_ax=str_glob->dtm_axes[0]+add_h[1]/1000.0; /* in km */
		    	b_ax=str_glob->dtm_axes[1]+add_h[1]/1000.0; /* in km */
		    	c_ax=str_glob->dtm_axes[2]+add_h[1]/1000.0; /* in km */
    
		    	dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell_vec[1]);
				if (found_ell_vec[1]) saveaddh1 = add_h[1];

				stepwidth /= 2.;
				if (found_ell_vec[1]) add_h[1] -= stepwidth;
				else				  add_h[1] += stepwidth;
				}
			if (found_ell_vec[1]==1) add_h[1] += stepwidth;
			else 					 add_h[1]  = saveaddh1;
			if (add_h[1]<-999999.) continue;
		
			a_ax=str_glob->dtm_axes[0]+add_h[1]/1000.0; /* in km */
			b_ax=str_glob->dtm_axes[1]+add_h[1]/1000.0; /* in km */
			c_ax=str_glob->dtm_axes[2]+add_h[1]/1000.0; /* in km */
    
			dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell_vec[1]);
			xx[1] = intersection_point[0];
			yy[1] = intersection_point[1];
			zz[1] = intersection_point[2];

			rec2graphicll (intersection_point, str_glob->dtm_axes_map, latlong);
    
			lat = latlong[0]*my_pi2deg;
			longi = latlong[1]*my_pi2deg*str_glob->dtm_poslongdir_fac;
			callfunc = zhwcarto (mp_dtm_obj, str_glob->prefs_dtm, &hit_lin[1], &hit_sam[1], &lat, &longi, graphiclltype, forward);
			}

		hit_dx   = xx[1]-xx[0];
		hit_dy   = yy[1]-yy[0];
		hit_dz   = zz[1]-zz[0];
		hit_dist = sqrt((hit_lin[1]-hit_lin[0])*(hit_lin[1]-hit_lin[0])
					   +(hit_sam[1]-hit_sam[0])*(hit_sam[1]-hit_sam[0]));
		
		if (hit_dist<1.0)
		    {
		    if ((hit_lin[0]>=1.0)&&(hit_lin[0]<=(double)str_glob->nof_dtm_l)&&
			(hit_sam[0]>=1.0)&&(hit_sam[0]<=(double)str_glob->nof_dtm_s))
		    	{
		    	local_dn = *(str_glob->dtm_buf+(*(str_glob->dtm_tab_in+(int)(hit_lin[0]+0.5)-1)+(int)(hit_sam[0]+0.5)-1));
		    	if (local_dn != short_miss) 
				height = (double)(dtmlabel.dtm_scaling_factor * (double)local_dn + dtmlabel.dtm_offset); /* in m */
				}
		    }
		else
		    {
		    hit_lin_step[0] = hit_dx/hit_dist;
		    hit_lin_step[1] = hit_dy/hit_dist;
		    hit_lin_step[2] = hit_dz/hit_dist;
		    hit_xyz_act[0]  = xx[0]-hit_lin_step[0];
		    hit_xyz_act[1]  = yy[0]-hit_lin_step[1];
		    hit_xyz_act[2]  = zz[0]-hit_lin_step[2];
		    hit_steps    = (int)hit_dist+2;
		    above = 0; 
		    for (i=0;i<=hit_steps;i++)
				{
		    	hit_xyz_act[0] += hit_lin_step[0];
		    	hit_xyz_act[1] += hit_lin_step[1];
		    	hit_xyz_act[2] += hit_lin_step[2];
		    	xyz2graphicllh (hit_xyz_act, latlongh, str_glob->dtm_axes);
   
		    	lat = latlongh[0];
		    	longi = latlongh[1]*str_glob->dtm_poslongdir_fac;
		    	callfunc = zhwcarto (mp_dtm_obj, str_glob->prefs_dtm, &hit_lin[0], &hit_sam[0], &lat, &longi, graphiclltype, forward);

				int_hit_lin_act = (int)hit_lin[0];
				int_hit_sam_act = (int)hit_sam[0];
		    	if((int_hit_lin_act<1)||(int_hit_lin_act>=(str_glob->nof_dtm_l-1))
                  ||(int_hit_sam_act<1)||(int_hit_sam_act>=(str_glob->nof_dtm_s-1))) {above = 0;continue;}
		    	callfunc = hwintdtm_bi (str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act-1),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act-1),
                                        str_glob->dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act),
                                        hit_lin[0]-(double)int_hit_lin_act, 
                                        hit_sam[0]-(double)int_hit_sam_act, 
                                        short_miss, &local_dn);
                if (callfunc < 0) {above = 0;continue;}

		    	if (((double)(dtmlabel.dtm_scaling_factor * (double)local_dn 
				     + dtmlabel.dtm_offset) > latlongh[2]*1000.)&& above) 
					{
                	height = (double)(dtmlabel.dtm_scaling_factor * (double)local_dn + dtmlabel.dtm_offset); /* in m */
					break;
					}
		    	else {above = 1;}
		    	}
			}
		}
		else height=str_glob->height;
			
		if (height < -999999.0) 
		    {
		    foundvec[k] = 0;
			if (loc_rec == 1) continue;
		    
			a_ax=str_glob->dtm_axes[0]; /* in km */
			b_ax=str_glob->dtm_axes[1]; /* in km */
			c_ax=str_glob->dtm_axes[2]; /* in km */
		    dlrsurfptl_xyz (positn, MDirView, a_ax, b_ax, c_ax, l_ax, intersection_point, &found_ell);
		    if (found_ell != 1) str_glob->limb=1;
		    else str_glob->found=1;
			continue;
		    }
		
		a_ax=str_glob->dtm_axes[0]+height/1000.0; /* in km */
		b_ax=str_glob->dtm_axes[1]+height/1000.0; /* in km */
		c_ax=str_glob->dtm_axes[2]+height/1000.0; /* in km */
		
		dlrsurfptl_xyz (positn, MDirView, a_ax, b_ax, c_ax, l_ax, intersection_point, &found_ell);
 		if (!found_ell) 
			{
		    	foundvec[k] = 0;
			str_glob->limb=1;
			continue;
			}

		str_glob->found=1;
		str_glob->found_in_dtm=1;

		rec2centricll_radius ( intersection_point, latlong, str_glob->mp_axes, &radius, str_glob->mp_n_axes); 

		if (str_glob->critical_projection == -1)
			{
			x1=radius*cos(latlong[0])*cos(latlong[1]);
			y1=radius*cos(latlong[0])*sin(latlong[1]);
			z1=radius*sin(latlong[0]);
			d=sqrt(x1*x1+y1*y1+z1*z1);
			dist2=(x1-str_glob->xcen)*(x1-str_glob->xcen)+(y1-str_glob->ycen)*(y1-str_glob->ycen)+(z1-str_glob->zcen)*(z1-str_glob->zcen);
			/* is this point visible for this special orthogr. projection ? */
			if (acos((dist2-str_glob->d02-d*d)/-2.0/str_glob->d0/d)>=my_halfpi){foundvec[k]=0;continue;}
			}

		lat = latlong[0]*my_pi2deg;
		longi = latlong[1]*my_pi2deg*str_glob->poslongdir_fac;
		if (longi < 0.0) longi += 360.0;

		if (lat < str_glob->min_lati) str_glob->min_lati = lat;
		if (lat > str_glob->max_lati) str_glob->max_lati = lat;

		if (lat > str_glob->max_valid_lati) {foundvec[k]=0;continue;}
		else if (lat < str_glob->min_valid_lati) {foundvec[k]=0;continue;}

		foundvec[k] = 1;

		if (longi < str_glob->min_longi) str_glob->min_longi = longi;
		if (longi > str_glob->max_longi) str_glob->max_longi = longi;

		if (str_glob->critical_projection > 0)
		    {
		    if (loc_rec == 1)
				{ 
				help_londiff = (longi-str_glob->cenlong)*my_deg2pi;

				if (str_glob->critical_projection > 1)
			    	{
			    	if (cos(help_londiff)>0.0)	        signvec[k] = 0;
			    	else if (sin(help_londiff)>0.0)     signvec[k] = 1;
			    	else				signvec[k] = -1;
			    	}
				else
			    	{
			    	if ((cos(help_londiff)>0.0)||
			    	((90.0-fabs(lat))<fabs(str_glob->cenlat)))	 signvec[k] = 0;
			    	else if (sin(help_londiff)>0.0)    		 signvec[k] = 1;
			    	else					 signvec[k] = -1;
			    	}
				}
		    else
				{
				if ((longi >= 0.0)&&(longi <= 90.0))   str_glob->quad[0]=0;
				if ((longi >= 90.0)&&(longi <= 180.0)) str_glob->quad[1]=0;
				if ((longi >= 180.0)&&(longi <= 270.0))str_glob->quad[2]=0;
				if ((longi >= 270.0)&&(longi <= 360.0))str_glob->quad[3]=0;
				}
		    }
		else signvec[k] = 0;
		/*----------------------------------------------------	
		 Transform one point from lat/long to a map projected x/y	
		 -----------------------------------------------------  */	

		callfunc = zhwcarto  (mp_obj, str_glob->prefs, &x[k], &y[k], &lat, &longi, lltype, forward);
		if (callfunc != mpSUCCESS)
			    {
			    if (callfunc==mpINVALID_PROJECTION)
				    printf("\n hwcarto returns INVALID_PROJECTION !!");
    			    else
				    printf("\n hwcarto returns %d !",callfunc);
 			    printf("\n VICAR task FRAMEGEOM aborted ");
			    zabend();
			    }

		if (loc_rec == 0) continue;

		if (str_glob->phocorr != 0)
			{
/*			shadow = hwshadow(dtm_rip_str,intersection_point, DirSurf, str_glob->MDirInc);*/
			zhwllnorm(latlong[0], latlong[1], str_glob->axes, l_ax, DirEll);

 			callfunc = hwphoeco(pho_obj, DirEll, str_glob->MDirInc, MDirView, str_glob->TargIncAng,
					    str_glob->TargViewAng, str_glob->TargAzimAng, &phoCorVal);
			phoCorVal_vec[k] = phoCorVal;		
 			}
		}
						
	free(tempMDirView);
	
	if (loc_rec == 0)
	    {
	    all_quads = str_glob->quad[0] + str_glob->quad[1] + str_glob->quad[2] + str_glob->quad[3];
	    if (((str_glob->max_longi-str_glob->min_longi)>180.0)&&(all_quads == 0))
		{str_glob->pole=1;}
	    }
	return(0);
	}


/*==========================================================================*/
/*##############################################################	*/

void rec2graphicll ( double *xyz, double *axes, double *llh)
	{
	double 		temp, e, e2, theta, nkr, hilf, s;
	
	temp = sqrt(axes[0]*axes[0]-axes[2]*axes[2]);
	e = temp / axes[0];
	e2 = temp / axes[2];
	
	s = sqrt(xyz[0]*xyz[0]+xyz[1]*xyz[1]);
	
	theta = atan((xyz[2]*axes[0])/(s*axes[2]));
	
	temp = sin(theta);
	hilf = xyz[2]+e2*e2*axes[2]*temp*temp*temp;

	temp = cos(theta);
	llh[0] = atan(hilf/(s-e*e*axes[0]*temp*temp*temp));
	
	hilf = sin(llh[0]);
	nkr = axes[0]/sqrt(1-e*e*hilf*hilf);
	
	llh[1] = atan ( xyz[1]/xyz[0]);
	if ( (xyz[0] < 0.0 && xyz[1] > 0.0) || (xyz[0] < 0.0 && xyz[1] < 0.0))
	    llh[1] += PI;
	else if ( xyz[0] > 0.0 && xyz[1] < 0.0) llh[1] += (2 * PI);
	if ( llh[1] < 0.0) llh[1] += (2 * PI);
/* 	llh[0] = (atan (axes[2]*axes[2]/(axes[0]*axes[0])*tan (llh[0]))); make foot_lat centric */					    /* centric lat  */
	}

void xyz2graphicllh ( double *xyz, double *llh, double *axes)
	{
	double 		s, a2, b2, a2_b2, e2, es2;
	double		v, lat, lon, h, temp, theta, sin_lat;
	
	
	a2 = axes[0] * axes[0];
	b2 = axes[2] * axes[2];
	a2_b2 = a2 - b2;
	s = sqrt( xyz[0] * xyz[0] + xyz[1] * xyz[1]);
	e2 = a2_b2 / a2;
	es2 = a2_b2 / b2;
	theta = atan ( ( xyz[2] * axes[0]) / ( s * axes[2]));
	
	temp = sin ( theta);
	lat = xyz[2] + es2 * axes[2] * temp * temp * temp;
	temp = cos ( theta);
	lat = lat / ( s - e2 * axes[0] * temp * temp * temp);
	lat = atan ( lat);
	
	lon = atan ( xyz[1] / xyz[0]);
	
	sin_lat = sin ( lat);
	
	v = axes[0] / sqrt ( 1 - e2 * sin_lat * sin_lat);
	
	h = s / cos ( lat) - v;
	
	if ( (xyz[0] < 0.0 && xyz[1] > 0.0) || (xyz[0] < 0.0 && xyz[1] < 0.0))
	    lon += PI;
	else if ( xyz[0] > 0.0 && xyz[1] < 0.0)
	    lon += (2 * PI);
	
	if ( lon < 0.0)
	    lon += (2 * PI);
	
	llh[0] = lat * 180.0 / PI;
	llh[1] = lon * 180.0 / PI;
	llh[2] = h;
	}
/*==========================================================================*/
/*##############################################################	*/
/* Computation of grayvalue by Bilinear Interpolation 	(private)	*/
/*##############################################################	*/
/* Calls from	hwgeorec						*/
/* Calling	-							*/
/*##############################################################	*/

	int hwintdtm_bi ( short int *gv_lo, short int *gv_ro, short int *gv_lu, short int *gv_ru,
			 double dv, double du, short int miss_gv, short int *gv )
/*##############################################################	*/
	
	{
	double rm1, rn1, rpg;

	if ((*gv_lo == miss_gv)||(*gv_lu == miss_gv)||(*gv_ro == miss_gv)||(*gv_ru == miss_gv))  return(-1);

	rn1 = (double)(*gv_lo) + ((double)(*gv_lu) -(double)(*gv_lo))*dv;

	rm1 = (double)(*gv_ro) + ((double)(*gv_ru) -(double)(*gv_ro))*dv;

  	rpg = rn1 + (rm1 - rn1) * du;

	*gv = (short int) (rpg); 

	return(0);
	}
/*==========================================================================*/
/*##############################################################	*/

void rec2centricll_radius ( double *xyz, double *llh, double *axes, double *radius, int naxes)
	{
	double 		temp, e, e2, theta, nkr, hilf, s;
	
	
	if (naxes>1)
	{
	temp = sqrt(axes[0]*axes[0]-axes[2]*axes[2]);
	e = temp / axes[0];
	e2 = temp / axes[2];
	
	s = sqrt(xyz[0]*xyz[0]+xyz[1]*xyz[1]);
	
	theta = atan((xyz[2]*axes[0])/(s*axes[2]));
	
	temp = sin(theta);
	hilf = xyz[2]+e2*e2*axes[2]*temp*temp*temp;

	temp = cos(theta);
	llh[0] = atan(hilf/(s-e*e*axes[0]*temp*temp*temp));
	
	nkr = axes[0]/sqrt(1-e*e*sin(llh[0])*sin(llh[0]) );
	
/*	llh[2] = s / cos(llh[0])-nkr; */
	llh[1] = atan ( xyz[1]/xyz[0]);
	if ( (xyz[0] < 0.0 && xyz[1] > 0.0) || (xyz[0] < 0.0 && xyz[1] < 0.0))
	    llh[1] += PI;
	else if ( xyz[0] > 0.0 && xyz[1] < 0.0) llh[1] += (2 * PI);
	if ( llh[1] < 0.0) llh[1] += (2 * PI);
	llh[0] = (atan (axes[2]*axes[2]/(axes[0]*axes[0])*tan (llh[0])));					    /* centric lat  */
	*radius = sqrt(xyz[0]*xyz[0]+xyz[1]*xyz[1]+xyz[2]*xyz[2]) -  (s / cos(llh[0])-nkr); /* exact enough */
	}
	else
	{
	s = sqrt(xyz[0]*xyz[0]+xyz[1]*xyz[1]);
	llh[0] = atan ( xyz[2] / s );
	llh[1] = atan ( xyz[1] / xyz[0]);
	if ( (xyz[0] < 0.0 && xyz[1] > 0.0) || (xyz[0] < 0.0 && xyz[1] < 0.0))
	    llh[1] += PI;
	else if ( xyz[0] > 0.0 && xyz[1] < 0.0) llh[1] += (2 * PI);
	if ( llh[1] < 0.0) llh[1] += (2 * PI);
/*	llh[2] = s / cos ( llh[0]) - axes[0];*/
	*radius = axes[0];
	}
	}

/*==========================================================================*/
/*==========================================================================*/
/*##############################################################	*/
/* Computation of a projective transformation
					(private)			*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	-					*/
/*##############################################################	*/

	int hwgetpro  (double *in_u, double *in_v, double *in_x,
		       double *in_y, double *a)

	{
	double	c[41], u[4], v[4], x[4], y[4];
	double	small;
	small=0.0001;
	
	u[2]=in_u[0]-in_u[1]; 
	v[2]=in_v[0]-in_v[1];
	x[2]=in_x[0]-in_x[1];
	y[2]=in_y[0]-in_y[1];
	u[0]=in_u[2]-in_u[1];
	v[0]=in_v[2]-in_v[1];
	x[0]=in_x[2]-in_x[1];
	y[0]=in_y[2]-in_y[1];
	u[3]=in_u[3]-in_u[1];
	v[3]=in_v[3]-in_v[1];
	x[3]=in_x[3]-in_x[1];
	y[3]=in_y[3]-in_y[1];
	if (fabs(u[2])<small)u[2]=small;small+=0.0001; 
	if (fabs(v[2])<small)v[2]=small;small+=0.0001;
	if (fabs(x[2])<small)x[2]=small;small+=0.0001;
	if (fabs(y[2])<small)y[2]=small;small+=0.0001;
	if (fabs(u[0])<small)u[0]=small;small+=0.0001;
	if (fabs(v[0])<small)v[0]=small;small+=0.0001;
	if (fabs(x[0])<small)x[0]=small;small+=0.0001;
	if (fabs(y[0])<small)y[0]=small;small+=0.0001;
	if (fabs(u[3])<small)u[3]=small;small+=0.0001;
	if (fabs(v[3])<small)v[3]=small;small+=0.0001;
	if (fabs(x[3])<small)x[3]=small;small+=0.0001;
	if (fabs(y[3])<small)y[3]=small;small+=0.0001;
	
	c[1]=u[0]; c[2]=v[0];  c[3]=-x[0]*u[0];  c[4]=-x[0]*v[0]; 
	c[5]=u[2]; c[6]=v[2];  c[7]=-x[2]*u[2];  c[8]=-x[2]*v[2]; 
	c[9]=u[3]; c[10]=v[3]; c[11]=-x[3]*u[3]; c[12]=-x[3]*v[3]; 
		
	c[13]=-y[0]*u[0]; c[14]=-y[0]*v[0];
	c[15]=-y[2]*u[2]; c[16]=-y[2]*v[2];
	c[17]=-y[3]*u[3]; c[18]=-y[3]*v[3];

	c[19]=c[6]*c[9]-c[10]*c[5];
	c[20]=c[15]*c[9]-c[17]*c[5];
	c[21]=c[16]*c[9]-c[18]*c[5];
	c[22]=c[6]*c[1]-c[2]*c[5];
	c[23]=c[15]*c[1]-c[13]*c[5];
	c[24]=c[16]*c[1]-c[14]*c[5];
	c[25]=c[9]*y[2]-c[5]*y[3];
	c[26]=c[1]*y[2]-c[5]*y[0];

	c[27]=c[6]*c[1]-c[2]*c[5];
	c[28]=c[7]*c[1]-c[3]*c[5];
	c[29]=c[8]*c[1]-c[4]*c[5];
	c[31]=c[6]*c[9]-c[10]*c[5];
	c[32]=c[7]*c[9]-c[11]*c[5];
	c[33]=c[8]*c[9]-c[12]*c[5];
	c[30]=c[1]*x[2]-c[5]*x[0];
	c[34]=c[9]*x[2]-c[5]*x[3];

	c[35]=c[20]*c[22]-c[19]*c[23];
	c[36]=c[21]*c[22]-c[19]*c[24];
	c[37]=c[25]*c[22]-c[19]*c[26];

	c[38]=c[31]*c[28]-c[27]*c[32];
	c[39]=c[31]*c[29]-c[27]*c[33];
	c[40]=c[31]*c[30]-c[27]*c[34];

	a[5]=(c[37]*c[38]-c[40]*c[35])/(c[36]*c[38]-c[39]*c[35]);
	a[4]=(c[37]-c[36]*a[5])/c[35];
	a[3]=(c[26]-c[24]*a[5]-c[23]*a[4])/c[22];
	a[2]=(y[0]-c[14]*a[5]-c[13]*a[4]-c[2]*a[3])/c[1];
	a[1]=(c[30]-c[29]*a[5]-c[28]*a[4])/c[27];
	a[0]=(x[0]-c[4]*a[5]-c[3]*a[4]-c[2]*a[1])/c[1];
	
	return(4);
	}

/*==========================================================================*/
/*##############################################################	*/
/* Application off projective transformation from inp = rectified img
   to out = inputimg	given by a-coefficients 	(private)	*/
/*##############################################################	*/
/* Calls from	FRAMEGEOREC_RIP						*/
/* Calling	-							*/
/*##############################################################	*/

	int hwapppro (double x_inp, double y_inp, double inp_off[2], double out_off[2],
		      double *x_out, double *y_out, double *a)
	{
	double	xi,yi;

	xi = x_inp-inp_off[0];
	yi = y_inp-inp_off[1];
	*x_out = (a[0]*xi+a[1]*yi)/(a[4]*xi+a[5]*yi+1.0) + out_off[0];
	*y_out = (a[2]*xi+a[3]*yi)/(a[4]*xi+a[5]*yi+1.0) + out_off[1];
	return(0);
	}

/*=====================================================================*/
/*##############################################################	*/
/* Computation of photometric correction factor
			 by Bilinear Interpolation 	(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/

	int hwintpho_bi ( double phoCorVal_vec_ap1,double phoCorVal_vec_ap2,
			  double phoCorVal_vec_ap3,double phoCorVal_vec_ap4,
			  double dv, double du, int dV, int dU, double *phoCorVal )
/*##############################################################	*/
	
	{
	double rm1, rn1;

	rn1 = phoCorVal_vec_ap1 + (phoCorVal_vec_ap3 - phoCorVal_vec_ap1)*dv/(double)dV;

	rm1 = phoCorVal_vec_ap2 + (phoCorVal_vec_ap4 - phoCorVal_vec_ap2)*dv/(double)dV;

  	*phoCorVal = rn1 + (rm1 - rn1) * du/(double)(dU);

	return(0);
	}
	
/*=====================================================================*/
/*##############################################################	*/
/* Computation of grayvalue by Bilinear Interpolation 	(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/

	int hwintgv_bi ( float *gv_lo, float *gv_ro, float *gv_lu, float *gv_ru,
			 double dv, double du, float *gv )
/*##############################################################	*/
	
	{
	double rm1, rn1, rpg;

	rn1 = (double)(*gv_lo) + ((double)(*gv_lu) -(double)(*gv_lo))*dv;

	rm1 = (double)(*gv_ro) + ((double)(*gv_ru) -(double)(*gv_ro))*dv;

  	rpg = rn1 + (rm1 - rn1) * du;

	*gv = (float) (rpg); 

	return(0);
	}

/*=====================================================================*/
/*##############################################################	*/
/* Computation of a function value during Cubic Convolution (private)	*/
/*##############################################################	*/
/* Calls from	hwintgv_cc (private)					*/
/* Calling	-							*/
/*##############################################################	*/


	double	fct_hwintgv_cc ( double z)
	{
    	double 	b;

	
    	b = fabs (z);
	
    	if ( b < 1.0)
        	return ( b * b * b - 2.0 * b * b + 1.0);
	
    	if ( b < 2.0)
        	return ( -b * b * b + 5.0 * b * b - 8.0 * b + 4.0);
	
	return (0.0);
	}

/*=====================================================================*/
/*##############################################################	*/
/* Computation of grayvalue by Cubic Convolution 	(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip (private)					*/
/* Calling	fct_hwintgv_cc (private)					*/
/*##############################################################	*/

	int hwintgv_cc ( double dx, double dy, float *feld, float *result)	
	{
	double	a[4], fx[4];
		
	
	fx[0] = fct_hwintgv_cc ( dx + 1.0);
	fx[1] = fct_hwintgv_cc ( dx);
	fx[2] = fct_hwintgv_cc ( dx - 1.0);
	fx[3] = fct_hwintgv_cc ( dx - 2.0);
	
	a[0] = feld[0] * fx[0] + feld[1] * fx[1] + feld[2] * fx[2] + feld[3] * fx[3];
	a[1] = feld[4] * fx[0] + feld[5] * fx[1] + feld[6] * fx[2] + feld[7] * fx[3];
	a[2] = feld[8] * fx[0] + feld[9] * fx[1] + feld[10] * fx[2] + feld[11] * fx[3];
	a[3] = feld[12] * fx[0] + feld[13] * fx[1] + feld[14] * fx[2] + feld[15] * fx[3];

	*result = (float)( a[0] * fct_hwintgv_cc ( dy + 1.0) +
        	a[1] * fct_hwintgv_cc ( dy) +
       		a[2] * fct_hwintgv_cc ( dy - 1.0) +
     		a[3] * fct_hwintgv_cc ( dy - 2.0));
    
 
    	return 0;
	}



/*=====================================================================*/
/*##############################################################	*/
/* Computation of sample positions of all anchorpoints
	in this anchorpoint-line  			(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	hrrdpref						*/
/*##############################################################	*/


	int framegetapt (dlrframe_info dlrframe_info, int l, int mid_of_l,
		       int *nof_le_p, int *nof_ri_p, int *s, int anchdist)
	
/*##############################################################	*/
	
	{
	int	k, first_s, nof_s;
	int	le_part_of_l, ri_part_of_l; 
	
	first_s = 1;
	nof_s = dlrframe_info.ns;

	first_s  += dlrframe_info.trim_left;
	nof_s -= (dlrframe_info.trim_left+dlrframe_info.trim_right);

/*--------------------------------------------------------------	*/
/*	compute left anchorpoint-samples 				*/
/*--------------------------------------------------------------	*/
	le_part_of_l = mid_of_l - first_s;
	*nof_le_p =
		(le_part_of_l + anchdist/2)/anchdist;

/*--------------------------------------------------------------	*/
/*	mid anchorpoint-sample 						*/
/*--------------------------------------------------------------	*/
	s[*nof_le_p] = mid_of_l;

/*--------------------------------------------------------------	*/
/*	left anchorpoint-samples 					*/
/*--------------------------------------------------------------	*/
	for (k=1; k < *nof_le_p; k++)
		{ s[*nof_le_p-k] = s[*nof_le_p-k+1] - anchdist; }

/*--------------------------------------------------------------	*/
/*	first left anchorpoint-sample 					*/
/*--------------------------------------------------------------	*/
	s[0] = first_s;

/*--------------------------------------------------------------	*/
/*	now compute right anchorpoint-samples 				*/
/*--------------------------------------------------------------	*/
	ri_part_of_l = (first_s+nof_s-1)-mid_of_l;
	*nof_ri_p =
	      (ri_part_of_l + anchdist/2)/anchdist;

/*--------------------------------------------------------------	*/
/*	right anchorpoint-samples 					*/
/*--------------------------------------------------------------	*/
	for (k=*nof_le_p+1; k < *nof_le_p+*nof_ri_p; k++)
		{ s[k] = s[k-1] + anchdist; }

/*--------------------------------------------------------------	*/
/*	last right anchorpoint-sample 					*/
/*--------------------------------------------------------------	*/
	s[*nof_le_p+*nof_ri_p] = first_s + nof_s - 1;

	return(0);
	}


/*=====================================================================*/
/*##############################################################	*/
/* sorts anchorpoints		  			(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/


	int hwsortap 
	(int nof_up_le_p, int nof_up_ri_p, int *up_s, 
	 double *up_x, double *up_y, double *up_phoCorVal_vec, int *up_foundvec, int *up_signvec,
	 int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, 
	 double *lo_x, double *lo_y, double *lo_phoCorVal_vec, int *lo_foundvec, int *lo_signvec)
/*##############################################################	*/
	
	{
	int	le_diff, ri_diff, j, k;	
	le_diff=nof_up_le_p-nof_lo_le_p;
	if (le_diff < 0)
		{
		for (j=1; j <= nof_lo_le_p+nof_lo_ri_p-1; j++)
			{
			k = j+abs(le_diff)-1;
			lo_s[j] = lo_s[k];
			lo_x[j] = lo_x[k];
			lo_y[j] = lo_y[k];
			lo_phoCorVal_vec[j] = lo_phoCorVal_vec[k];
			lo_foundvec[j] = lo_foundvec[k];
			lo_signvec[j] = lo_signvec[k];
			}
		nof_lo_le_p -= abs(le_diff)-1;
		}
	else if (le_diff > 0)
		{
		for (j=1; j <= nof_up_le_p+nof_up_ri_p-1; j++)
			{
			k = j+abs(le_diff)-1;
			up_s[j] = up_s[k];
			up_x[j] = up_x[k];
			up_y[j] = up_y[k];
			up_phoCorVal_vec[j] = up_phoCorVal_vec[k];
			up_foundvec[j] = up_foundvec[k];
			up_signvec[j] = up_signvec[k];
			}
		nof_up_le_p -= abs(le_diff)-1;
		}
		
	ri_diff=nof_up_ri_p-nof_lo_ri_p;
	if (ri_diff < 0)
		{
		j = nof_lo_le_p+nof_lo_ri_p;
		k = j-abs(ri_diff)+1;
		lo_s[k]  = lo_s[j];
		lo_x[k]  = lo_x[j];
		lo_y[k]  = lo_y[j];
		lo_phoCorVal_vec[k]  = lo_phoCorVal_vec[j];
		lo_foundvec[k] = lo_foundvec[j];
		lo_signvec[k] = lo_signvec[j];

		nof_lo_ri_p -= abs(ri_diff)-1;
		}
	else if (ri_diff > 0)
		{
		j = nof_up_le_p+nof_up_ri_p;
		k = j-abs(ri_diff)+1;
		up_s[k]  = up_s[j];
		up_x[k]  = up_x[j];
		up_y[k]  = up_y[j];
		up_phoCorVal_vec[k]  = up_phoCorVal_vec[j];
		up_foundvec[k] = up_foundvec[j];
		up_signvec[k] = up_signvec[j];

		nof_up_ri_p -= abs(ri_diff)-1;
		}

	return (0);		
	}

/*=====================================================================*/
/*##############################################################	*/
/* gets anchorpoint patches 	  			(private)	*/
/*##############################################################	*/
/* Calls from	framegeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/


	int hwgetapp 
	(int nof_up_le_p, int nof_up_ri_p, int *up_s, 
	 double *up_x, double *up_y, double *up_phoCorVal_vec, int *up_foundvec, int *up_signvec,
	 int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, 
	 double *lo_x, double *lo_y, double *lo_phoCorVal_vec, int *lo_foundvec, int *lo_signvec,
	 int *nof_p, int *s_ap1, int *s_ap2, int *s_ap3, int *s_ap4,
	 double *phoCorVal_vec_ap1, double *phoCorVal_vec_ap2,
	 double *phoCorVal_vec_ap3, double *phoCorVal_vec_ap4,
	 double *x_ap1, double *x_ap2, double *x_ap3, double *x_ap4,
	 double *y_ap1, double *y_ap2, double *y_ap3, double *y_ap4, int *dtm_no_dtm)
	 	
/*##############################################################	*/
	
	{
	int	up_cont, lo_cont;
	int	nof_le_p, nof_ri_p, j, k;	

	if (nof_up_le_p > nof_lo_le_p)
		{
		if (((up_foundvec[0]*up_foundvec[1]*lo_foundvec[0]) == 0)
		||  ((abs(up_signvec[0]+up_signvec[1]+lo_signvec[0]) != 3)&&((up_signvec[0]*up_signvec[1]*lo_signvec[0]) != 0)))
			dtm_no_dtm[0]=0;
		else	dtm_no_dtm[0]=1;

		s_ap1[0] = up_s[0];
		s_ap2[0] = up_s[1];
		s_ap3[0] = lo_s[0];
		s_ap4[0] = -999.0;
		x_ap1[0] = up_x[0];
		x_ap2[0] = up_x[1];
		x_ap3[0] = lo_x[0];
		x_ap4[0] = -999.0;
		y_ap1[0] = up_y[0];
		y_ap2[0] = up_y[1];
		y_ap3[0] = lo_y[0];
		y_ap4[0] = -999.0;
		phoCorVal_vec_ap1[0] = up_phoCorVal_vec[0];
		phoCorVal_vec_ap2[0] = up_phoCorVal_vec[1];
		phoCorVal_vec_ap3[0] = lo_phoCorVal_vec[0];
		phoCorVal_vec_ap4[0] = phoCorVal_vec_ap3[0];
		up_cont  = 1;
		lo_cont  = 0;
		nof_le_p = nof_up_le_p;
		}
	else if (nof_up_le_p < nof_lo_le_p)
		{
		if (((up_foundvec[0]*lo_foundvec[1]*lo_foundvec[0]) == 0)
		||  ((abs(up_signvec[0]+lo_signvec[1]+lo_signvec[0]) != 3)&&((up_signvec[0]*lo_signvec[1]*lo_signvec[0]) != 0)))
			dtm_no_dtm[0]=0;
		else	dtm_no_dtm[0]=1;
		s_ap1[0] = -999.0;
		s_ap2[0] = up_s[0];
		s_ap3[0] = lo_s[0];
		s_ap4[0] = lo_s[1];
		x_ap1[0] = -999.0;
		x_ap2[0] = up_x[0];
		x_ap3[0] = lo_x[0];
		x_ap4[0] = lo_x[1];
		y_ap1[0] = -999.0;
		y_ap2[0] = up_y[0];
		y_ap3[0] = lo_y[0];
		y_ap4[0] = lo_y[1];
		phoCorVal_vec_ap2[0] = up_phoCorVal_vec[0];
		phoCorVal_vec_ap3[0] = lo_phoCorVal_vec[0];
		phoCorVal_vec_ap4[0] = lo_phoCorVal_vec[1];
		phoCorVal_vec_ap1[0] = phoCorVal_vec_ap3[0];
		up_cont  = 0;
		lo_cont  = 1;
		nof_le_p = nof_lo_le_p;
		}
	else
		{
		if (((up_foundvec[0]*up_foundvec[1]*lo_foundvec[0]*lo_foundvec[1]) == 0)
		||  ((abs(up_signvec[0]+up_signvec[1]+lo_signvec[0]+lo_signvec[1]) != 4)&&((up_signvec[0]*up_signvec[1]*lo_signvec[0]*lo_signvec[1]) != 0))) 
			dtm_no_dtm[0]=0;
		else	dtm_no_dtm[0]=1;
		s_ap1[0] = up_s[0];
		s_ap2[0] = up_s[1];
		s_ap3[0] = lo_s[0];
		s_ap4[0] = lo_s[1];
		x_ap1[0] = up_x[0];
		x_ap2[0] = up_x[1];
		x_ap3[0] = lo_x[0];
		x_ap4[0] = lo_x[1];
		y_ap1[0] = up_y[0];
		y_ap2[0] = up_y[1];
		y_ap3[0] = lo_y[0];
		y_ap4[0] = lo_y[1];
		phoCorVal_vec_ap1[0] = up_phoCorVal_vec[0];
		phoCorVal_vec_ap2[0] = up_phoCorVal_vec[1];
		phoCorVal_vec_ap3[0] = lo_phoCorVal_vec[0];
		phoCorVal_vec_ap4[0] = lo_phoCorVal_vec[1];
		up_cont  = 1;
		lo_cont  = 1;
		nof_le_p = nof_lo_le_p;
		}
	
	if (nof_up_ri_p > nof_lo_ri_p)
		{
		nof_ri_p = nof_up_ri_p;
		for (j=1; j <= nof_le_p + nof_lo_ri_p - 1; j++)
			{
			if (((up_foundvec[up_cont+j-1]*up_foundvec[up_cont+j]*
			     lo_foundvec[lo_cont+j-1]*lo_foundvec[lo_cont+j]) == 0)
			||  ((abs(up_signvec[up_cont+j-1]+up_signvec[up_cont+j]+
			     lo_signvec[lo_cont+j-1]+lo_signvec[lo_cont+j]) != 4)&&((up_signvec[up_cont+j-1]*up_signvec[up_cont+j]*
			     lo_signvec[lo_cont+j-1]*lo_signvec[lo_cont+j]) != 0))) dtm_no_dtm[j]=0;
			else							   dtm_no_dtm[j]=1;
			s_ap1[j] = up_s[up_cont+j-1];
			s_ap2[j] = up_s[up_cont+j];
			s_ap3[j] = lo_s[lo_cont+j-1];
			s_ap4[j] = lo_s[lo_cont+j];
			x_ap1[j] = up_x[up_cont+j-1];
			x_ap2[j] = up_x[up_cont+j];
			x_ap3[j] = lo_x[lo_cont+j-1];
			x_ap4[j] = lo_x[lo_cont+j];
			y_ap1[j] = up_y[up_cont+j-1];
			y_ap2[j] = up_y[up_cont+j];
			y_ap3[j] = lo_y[lo_cont+j-1];
			y_ap4[j] = lo_y[lo_cont+j];
			phoCorVal_vec_ap1[j] = up_phoCorVal_vec[up_cont+j-1];
			phoCorVal_vec_ap2[j] = up_phoCorVal_vec[up_cont+j];
			phoCorVal_vec_ap3[j] = lo_phoCorVal_vec[lo_cont+j-1];
			phoCorVal_vec_ap4[j] = lo_phoCorVal_vec[lo_cont+j];
			}
		j = nof_le_p+nof_lo_ri_p;
		k = nof_le_p+nof_ri_p - 1;
		if (((up_foundvec[up_cont+j-1]*up_foundvec[up_cont+j]*
		     lo_foundvec[lo_cont+j-1]) == 0)
		||  ((abs(up_signvec[up_cont+j-1]+up_signvec[up_cont+j]+
		     lo_signvec[lo_cont+j-1]) != 3)&&((up_signvec[up_cont+j-1]*up_signvec[up_cont+j]*
		     lo_signvec[lo_cont+j-1]) != 0)))dtm_no_dtm[k]=0;
		else				    dtm_no_dtm[k]=1;
		s_ap1[k] =  up_s[up_cont+j-1];
		s_ap2[k] =  up_s[up_cont+j];
		s_ap3[k] =  lo_s[lo_cont+j-1];
		s_ap4[k] =  -999.0;
		x_ap1[k] =  up_x[up_cont+j-1];
		x_ap2[k] =  up_x[up_cont+j];
		x_ap3[k] =  lo_x[lo_cont+j-1];
		x_ap4[k] =  -999.0;
		y_ap1[k] =  up_y[up_cont+j-1];
		y_ap2[k] =  up_y[up_cont+j];
		y_ap3[k] =  lo_y[lo_cont+j-1];
		y_ap4[k] =  -999.0;
		phoCorVal_vec_ap1[k] =  up_phoCorVal_vec[up_cont+j-1];
		phoCorVal_vec_ap2[k] =  up_phoCorVal_vec[up_cont+j];
		phoCorVal_vec_ap3[k] =  lo_phoCorVal_vec[lo_cont+j-1];
		phoCorVal_vec_ap4[k] =  phoCorVal_vec_ap3[k];
		}
	else 
		{
		nof_ri_p = nof_lo_ri_p;
		for (j=1; j <= nof_le_p + nof_up_ri_p - 1; j++)
			{
			if (((up_foundvec[up_cont+j-1]*up_foundvec[up_cont+j]*
			     lo_foundvec[lo_cont+j-1]*lo_foundvec[lo_cont+j]) == 0)
			|| ((abs(up_signvec[up_cont+j-1]+up_signvec[up_cont+j]+
			     lo_signvec[lo_cont+j-1]+lo_signvec[lo_cont+j]) != 4)&&((up_signvec[up_cont+j-1]*up_signvec[up_cont+j]*
			     lo_signvec[lo_cont+j-1]*lo_signvec[lo_cont+j]) != 0))) dtm_no_dtm[j]=0;
			else							   dtm_no_dtm[j]=1;
			s_ap1[j] = up_s[up_cont+j-1];
			s_ap2[j] = up_s[up_cont+j];
			s_ap3[j] = lo_s[lo_cont+j-1];
			s_ap4[j] = lo_s[lo_cont+j];
			x_ap1[j] = up_x[up_cont+j-1];
			x_ap2[j] = up_x[up_cont+j];
			x_ap3[j] = lo_x[lo_cont+j-1];
			x_ap4[j] = lo_x[lo_cont+j];
			y_ap1[j] = up_y[up_cont+j-1];
			y_ap2[j] = up_y[up_cont+j];
			y_ap3[j] = lo_y[lo_cont+j-1];
			y_ap4[j] = lo_y[lo_cont+j];
			phoCorVal_vec_ap1[j] = up_phoCorVal_vec[up_cont+j-1];
			phoCorVal_vec_ap2[j] = up_phoCorVal_vec[up_cont+j];
			phoCorVal_vec_ap3[j] = lo_phoCorVal_vec[lo_cont+j-1];
			phoCorVal_vec_ap4[j] = lo_phoCorVal_vec[lo_cont+j];
			}
		if (nof_up_ri_p < nof_lo_ri_p)
			{
			j = nof_le_p+nof_up_ri_p;
			k = nof_le_p+nof_ri_p - 1;
			if (((up_foundvec[up_cont+j-1]*
			     lo_foundvec[lo_cont+j-1]*lo_foundvec[lo_cont+j]) == 0)
			||  ((abs(up_signvec[up_cont+j-1]+
			     lo_signvec[lo_cont+j-1]+lo_signvec[lo_cont+j]) != 3)&&((up_signvec[up_cont+j-1]*
			     lo_signvec[lo_cont+j-1]*lo_signvec[lo_cont+j]) != 0))) dtm_no_dtm[k]=0;
			else							   dtm_no_dtm[k]=1;
			s_ap1[k] =  -999.0;
			s_ap2[k] =  up_s[up_cont+j-1];
			s_ap3[k] =  lo_s[lo_cont+j-1];
			s_ap4[k] =  lo_s[lo_cont+j];
			x_ap1[k] =  -999.0;
			x_ap2[k] =  up_x[up_cont+j-1];
			x_ap3[k] =  lo_x[lo_cont+j-1];
			x_ap4[k] =  lo_x[lo_cont+j];
			y_ap1[k] =  -999.0;
			y_ap2[k] =  up_y[up_cont+j-1];
			y_ap3[k] =  lo_y[lo_cont+j-1];
			y_ap4[k] =  lo_y[lo_cont+j];
			phoCorVal_vec_ap2[k] =  up_phoCorVal_vec[up_cont+j-1];
			phoCorVal_vec_ap3[k] =  lo_phoCorVal_vec[lo_cont+j-1];
			phoCorVal_vec_ap4[k] =  lo_phoCorVal_vec[lo_cont+j];
			phoCorVal_vec_ap1[k] =  phoCorVal_vec_ap3[k];
			}
		}	

	*nof_p = nof_le_p + nof_ri_p;
	
	return (0);
	}

	
		
void xyz2ll ( double *xyz, double *ll)
	{
	double 		e, e2, theta, nkr, hilf, s;
	
	s = sqrt(xyz[0]*xyz[0]+xyz[1]*xyz[1]);
	ll[0] = atan ( xyz[2] / s );
	ll[1] = atan ( xyz[1] / xyz[0]);
	if ( (xyz[0] < 0.0 && xyz[1] > 0.0) || (xyz[0] < 0.0 && xyz[1] < 0.0))
	    ll[1] += PI;
	else if ( xyz[0] > 0.0 && xyz[1] < 0.0) ll[1] += (2 * PI);
	if ( ll[1] < 0.0) ll[1] += (2 * PI);
	}


int check_quad ( double *line,  double *sample )
{
   double  a, b, c, d, e, f, h, i, k, l, m, n, o, temp1, temp2, temp3, temp4;
   f = sample[1]-sample[0];
   h = line[0]-line[1];
   i = sample[2]-sample[0];
   k = line[0]-line[2];
   l = sample[3]-sample[1];
   m = line[1]-line[3];
   n = sample[2]-sample[3];
   o = line[3]-line[2];
   
   a = atan2 (f, h);
   if (a<0.0)a+=my_twopi;
   temp1=a+PI;
   d = atan2 (i, k);
   if (d<0.0)d+=my_twopi;
   temp2=d+PI;
   e = d-a;  if (e<0.0) e+=my_twopi; if (e>=my_justpi) {return (-1);}
   
   a = atan2 (l, m);
   if (a<0.0)a+=my_twopi;
   temp3=a+PI;
   d = temp1;
   if (d<0.0)d+=my_twopi;
   if (d>my_twopi)d-=my_twopi;
   e = d-a;  if (e<0.0) e+=my_twopi; if (e>=my_justpi) {return (-1);}
   
   a = atan2 (n, o);
   if (a<0.0)a+=my_twopi;
   temp4 = a+PI;
   d = temp3;
   if (d<0.0)d+=my_twopi;
   if (d>my_twopi)d-=my_twopi;
   e = d-a;  if (e<0.0) e+=my_twopi; if (e>=my_justpi) {return (-1);}
   
   a = temp2;
   if (a<0.0)a+=my_twopi;
   if (a>my_twopi)a-=my_twopi;
   d = temp4;
   if (d<0.0)d+=my_twopi;
   if (d>my_twopi)d-=my_twopi;
   e = d-a;  if (e<0.0) e+=my_twopi; if (e>=my_justpi) {return (-1);}
   
    return (1);   
}

int	stdproj_to_mapproj (str_glob_TYPE *str_glob, MP mp_obj, MP mp_stdobj, float *gv_inp_buf)
    {
    int	    i, line, samp, callfunc, min_samp, max_samp, min_line, max_line, *tab_in, done, last_done;
    int	    forward = 0, backward=1, int_l, int_s;
    double  d_l, d_s, dou_l, dou_s, lat, longi, x[2], y[2], dist2, radius_cos_lat,
	    std_line, std_samp, x1, y1, z1, d, longi_rad, lat_rad;
    float	*gv_out_buf_float, *gv, *gv_inp_lo, *gv_inp_ro,
		*gv_inp_lu, *gv_inp_ru, *gv_bicu;
    int	*gv_out_buf_full, inp_buf_off, line_start, line_end, samp_start, samp_end, iipol;
    short int	*gv_out_buf_half;
    myBYTE   *gv_out_buf_byte;
double pos[3], los[3], radius, latlong[3];
int found;
	printf ("\nMaking a nice limb (set limb=bad or -bad for no limb improvement), please wait ...\n");
 
/*	iipol = str_glob->interpol_type;
*/
	iipol = 0; /* NN */
	
	gv_inp_lo   = (float *) malloc (sizeof(float));
		if (gv_inp_lo == (float*)NULL) return(-998); 

	gv_inp_ro   = (float *) malloc (sizeof(float));
		if (gv_inp_ro == (float *)NULL) return(-998); 

	gv_inp_lu   = (float *) malloc (sizeof(float));
		if (gv_inp_lu == (float *)NULL) return(-998); 

	gv_inp_ru   = (float *) malloc (sizeof(float));
		if (gv_inp_ru == (float *)NULL) return(-998); 

	gv	    = (float *) malloc (sizeof(float));
		if (gv == (float *)NULL) return(-998); 

	gv_bicu	   = (float *) malloc (16*sizeof(float));
		if (gv_bicu == (float *)NULL) return(-998); 

		
	*gv		= 0.;


	tab_in   = (int *) malloc (str_glob->nof_std_l*sizeof(int));
		if (tab_in == (int *)NULL) return(-998); 
	*tab_in  = (int)0;
	for (i=1; i<str_glob->nof_std_l; i++) { *(tab_in+i) = *(tab_in+i-1)+str_glob->nof_std_s; }

	if (str_glob->oformat == 4)
			{
			str_glob->no_info_val = -1.0e32;
			gv_out_buf_float= (float *) calloc (1,str_glob->nof_out_s*sizeof(float));
			if (gv_out_buf_float == (float *)NULL) return(-998); 
	    		for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_float[i]=str_glob->no_info_val;				
			}
	else if (str_glob->oformat == 3)
			{
			str_glob->no_info_val = -32768.;
			gv_out_buf_full= (int *) calloc (1,str_glob->nof_out_s*sizeof(int));
			if (gv_out_buf_full == (int *)NULL) return(-998); 
	    		for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_full[i]=(int)str_glob->no_info_val;				
			}
	else if (str_glob->oformat == 2)
			{
			str_glob->no_info_val = -32768.;
			gv_out_buf_half= (short int *) calloc (1,str_glob->nof_out_s*sizeof(short int));
			if (gv_out_buf_half == (short int *)NULL) return(-998); 
	    		for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_half[i]=(short int)str_glob->no_info_val;				
			}
	else
			{
			str_glob->no_info_val = 0;
			gv_out_buf_byte= (myBYTE *) calloc (1,str_glob->nof_out_s*sizeof(myBYTE));
			if (gv_out_buf_byte == (myBYTE *)NULL) return(-998); 
	    		for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_byte[i]=(myBYTE )str_glob->no_info_val;				
			}


    switch (iipol)
	{
	case 1:
/*-----------------	*/
/* 	bilinear	*/
/*---------------	*/
	min_line = 1;				
	max_line = str_glob->nof_std_l - 1;				
	min_samp = 1;				
	max_samp = str_glob->nof_std_s - 1;				
	break;

	case 2:
/*------------------	*/
/*	cubic convolution */
/*------------------	*/
	min_line = 2;				
	max_line = str_glob->nof_std_l - 2;				
	min_samp = 2;				
	max_samp = str_glob->nof_std_s - 2;				
	break;
						
	default:
/*--------------	*/
/*	Nearest Neighbour */
/*---------------------	*/
	min_line = 1;				
	max_line = str_glob->nof_std_l;				
	min_samp = 1;				
	max_samp = str_glob->nof_std_s;				
	}

	line_start=1;
	line_end=str_glob->nof_out_l;
	samp_start=1;
	samp_end=str_glob->nof_out_s;

    for (line=1;line<line_start;line++)
		{
		if (str_glob->oformat == 4)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_float,
			"LINE", line, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 3)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_full,
			"LINE", line, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 2)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_half,
			"LINE", line, "SAMP", 1, 0);
			}
		else
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_byte,
			"LINE", line, "SAMP", 1, 0);
			}
		}
	
 	for (line=line_end+1;line<=str_glob->nof_out_l;line++)
		{
		if (str_glob->oformat == 4)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_float,
			"LINE", line, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 3)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_full,
			"LINE", line, "SAMP", 1, 0);
			}
		else if (str_glob->oformat == 2)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_half,
			"LINE", line, "SAMP", 1, 0);
			}
		else
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_byte,
			"LINE", line, "SAMP", 1, 0);
			}
		}
	
	if (strcmp(str_glob->report, "NO")!=0)
		{
		printf("Done (in percent): ");
		fflush(stdout);
		last_done=0;
		}

    for (line=line_start;line<=line_end;line++)
	{
	for (samp=samp_start;samp<=samp_end;samp++)
	    {
	    dou_l=(double)line;
	    dou_s=(double)samp;
	    callfunc = zhwcarto (mp_obj, str_glob->prefs, &dou_l, &dou_s, &lat, &longi, 1, backward);
	    if (callfunc!=0)continue;
	    lat_rad=lat*my_deg2pi;
	    longi_rad=longi*my_deg2pi;
	    
	    radius = str_glob->axes[0];
	    radius_cos_lat=radius*cos(lat_rad);
	    x1=radius_cos_lat*cos(longi_rad*str_glob->poslongdir_fac);
	    y1=radius_cos_lat*sin(longi_rad*str_glob->poslongdir_fac);
	    z1=radius*sin(lat_rad);
	    d=sqrt(x1*x1+y1*y1+z1*z1);
	    dist2=(x1-str_glob->xcen)*(x1-str_glob->xcen)+(y1-str_glob->ycen)*(y1-str_glob->ycen)+(z1-str_glob->zcen)*(z1-str_glob->zcen);
	    /* is this point visible for the intermediate orthogr. projection ? */
	    if (acos((dist2-str_glob->d02-d*d)/-2.0/str_glob->d0/d)>=my_halfpi)continue;

	    callfunc = zhwcarto (mp_stdobj, str_glob->prefs, &std_line, &std_samp, &lat, &longi, 1, forward);
	    if (callfunc!=0)continue;

	    if ((std_line<(double)min_line)||(std_line>(double)max_line)||(std_samp<(double)min_samp)||(std_samp>(double)max_samp)) continue;

	    int_l = (int)std_line;
	    int_s = (int)std_samp;
	    
/*	    if ((int_l<min_line)||(int_l>max_line)||(int_s<min_samp)||(int_s>max_samp)) continue;
*/
		
	    d_l = std_line - (double) (int_l);
	    d_s = std_samp - (double) (int_s);

	    int_l--;int_s--;		
		
	    switch (iipol)
							{
							case 1:
/*---------------------------------------------------------------------	*/
/* 							bilinear*/
/*---------------------------------------------------------------------	*/
						
							gv_inp_lo = gv_inp_buf
							 +(*(tab_in+int_l)+int_s);

							gv_inp_ro = gv_inp_buf
 							 +(*(tab_in+int_l)+int_s+1);

							gv_inp_lu = gv_inp_buf 
							 +(*(tab_in+int_l+1)+int_s);

							gv_inp_ru = gv_inp_buf 		
							 +(*(tab_in+int_l+1)+int_s+1);

							callfunc = hwintgv_bi
								   (gv_inp_lo,
								    gv_inp_ro,
							 	    gv_inp_lu,
								    gv_inp_ru,
								    d_l, d_s, gv); 
							break;

							case 2:
/*----------------------------------------------------------------------	*/
/* 							cubic convolution	*/
/*----------------------------------------------------------------------	*/
					
	
							*(gv_bicu+0) = *(gv_inp_buf
							 +(*(tab_in+int_l-1)+int_s-1));

							*(gv_bicu+1) = *(gv_inp_buf
							 +(*(tab_in+int_l-1)+int_s));

							*(gv_bicu+2) = *(gv_inp_buf
							 +(*(tab_in+int_l-1)+int_s+1));

							*(gv_bicu+3) = *(gv_inp_buf
							 +(*(tab_in+int_l-1)+int_s+2));

							*(gv_bicu+4) = *(gv_inp_buf
							 +(*(tab_in+int_l)+int_s-1));

							*(gv_bicu+5) = *(gv_inp_buf
							 +(*(tab_in+int_l)+int_s));

							*(gv_bicu+6) = *(gv_inp_buf
							 +(*(tab_in+int_l)+int_s+1));

							*(gv_bicu+7) = *(gv_inp_buf
							 +(*(tab_in+int_l)+int_s+2));

							*(gv_bicu+8) = *(gv_inp_buf
							 +(*(tab_in+int_l+1)+int_s-1));

							*(gv_bicu+9) = *(gv_inp_buf
							 +(*(tab_in+int_l+1)+int_s));

							*(gv_bicu+10) = *(gv_inp_buf
							 +(*(tab_in+int_l+1)+int_s+1));

							*(gv_bicu+11) = *(gv_inp_buf
							 +(*(tab_in+int_l+1)+int_s+2));

							*(gv_bicu+12) = *(gv_inp_buf
							 +(*(tab_in+int_l+2)+int_s-1));

							*(gv_bicu+13) = *(gv_inp_buf
							 +(*(tab_in+int_l+2)+int_s));

							*(gv_bicu+14) = *(gv_inp_buf
							 +(*(tab_in+int_l+2)+int_s+1));

							*(gv_bicu+15) = *(gv_inp_buf
							 +(*(tab_in+int_l+2)+int_s+2));

							callfunc = hwintgv_cc 
								   ( d_s, d_l, gv_bicu, gv);
							break;
						
							default:
/*---------------------------------------------------------------------	*/
/* 							Nearest Neighbour*/
/*---------------------------------------------------------------------	*/

							int_l = (int)(std_line+0.5); 

							inp_buf_off = (int)(std_samp+0.5)-1+*(tab_in+int_l);

							*gv = *(gv_inp_buf + inp_buf_off);
							}

	    if (str_glob->oformat == 4)
		*(gv_out_buf_float+samp-1)= *gv;
	    else if (str_glob->oformat == 3)
		*(gv_out_buf_full+samp-1)=(int)(*gv + 0.5);
	    else if (str_glob->oformat == 2)
		*(gv_out_buf_half+samp-1)=(short int)(*gv + 0.5);
	    else	
			{
			if (*gv<0.0)*gv=0.0;if (*gv>255.0)*gv=255.0;
			*(gv_out_buf_byte+samp-1)=(myBYTE)(*gv + 0.5);
			}

	    }

	done=100*(line-line_start);
	done=((done/(line_end-line_start + 1))/5)*5;
	if (strcmp(str_glob->report, "NO")!=0)
		{
		if (done>last_done)
			{
			printf("%2d ", done);
			fflush (stdout);
			last_done=done;
			}
		}

	if (str_glob->oformat == 4)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_float,
			"LINE", line, "SAMP", 1, 0);
	    	for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_float[i]=str_glob->no_info_val;				
			}
	else if (str_glob->oformat == 3)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_full,
			"LINE", line, "SAMP", 1, 0);
	    	for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_full[i]=(int)str_glob->no_info_val;				
			}
	else if (str_glob->oformat == 2)
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_half,
			"LINE", line, "SAMP", 1, 0);
	    	for (i=0;i<str_glob->nof_out_s;i++) gv_out_buf_half[i]=(short int)str_glob->no_info_val;				
			}
	else
			{
			callfunc = zvwrit (str_glob->outunit, gv_out_buf_byte,
			"LINE", line, "SAMP", 1, 0);
			free (gv_out_buf_byte);
			gv_out_buf_byte= (myBYTE *) calloc (1,str_glob->nof_out_s*sizeof(myBYTE));
			if (gv_out_buf_byte == (myBYTE *)NULL) return(-998); 
			}
	}
    return (0);
    }
	
	
    void check_size(str_glob_TYPE *str_glob)
	{
	double outsize;
	char	outstring[120];
	
	    outsize = (double)str_glob->nof_out_l;
	    outsize = outsize * (double)(str_glob->nof_out_s/1024./1024.);
	    if (str_glob->oformat == 2) outsize = outsize * 2.0; 
	    if (str_glob->oformat == 3) outsize = outsize * 4.0; 
	    if (str_glob->oformat == 4) outsize = outsize * 4.0; 
	
	    if (outsize > str_glob->max_sof_outfile)
		{
 		sprintf(outstring, "Size of output-image would be: ");
     		zvmessage(outstring,"");
		sprintf(outstring, "%ld MegaByte", (long)(outsize));
     		zvmessage(outstring,"");
		sprintf(outstring, "This is more than the maximum size");
     		zvmessage(outstring,"");
		sprintf(outstring, "allowed by the user (%ld MegaByte) => ABORT !! "
							, (long)(str_glob->max_sof_outfile));
     		zvmessage(outstring,"");
		zabend();
		}
	}
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create frameortho.h
$ DECK/DOLLARS="$ VOKAGLEVE"
typedef unsigned char myBYTE;

#define o_format1 "myBYTE"
#define o_format2 "HALF"
#define o_format3 "FULL"
#define o_format4 "REAL"

#define STRING_SIZE 120

typedef struct	{int	inunit;
	 char	adjufile[120];
	 char	x_cal_filename[120];
	 char	y_cal_filename[120];
	 int	first_real_inp_l;
	 int	last_real_inp_l;
	 int	dtmunit;
	 int	nof_dtm_l;
	 int	nof_dtm_s;
	 int	outunit;
	 int	nof_out_l;
	 int	nof_out_s;
	 int	nof_std_l;
	 int	nof_std_s;
	 int	oformat;
	 int	oformat_size;
	 double	max_sof_outfile;
	 double	et;
	 int	interpol_type;
	 int	nl;
	 int	ns;
	 char	report[4];
	 int	phocorr;
	 int	anchdist;
	 int	border;
	 int	adj_par;
	 FILE   *adjuptr;
	 int	pole;
	 int	limb;
	 int	found;
	 int	found_in_dtm;
	 int	n_axes;
	 int	mp_n_axes;
	 char	mptype[mpMAX_KEYWD_LENGTH+1];
	 double	cenlat;
	 double	cenlong;
	 double	xcen;
	 double	ycen;
	 double	zcen;
	 double	x0;
	 double	y0;
	 double	z0;
	 double	d0;
	 double	d02;
	 double	ll[2];
	 double	min_valid_lati;
	 double	max_valid_lati;
	 double	min_lati;
	 double	min_longi;
	 double	max_lati;
	 double	max_longi;
	 int	critical_projection;
	 int	two_or_three_d_limb;
	 int	lineoffset_set;
	 int	sampleoffset_set;
	 int	quad[4];
	 double poslongdir_fac;
	 double dtm_poslongdir_fac;
	 double TargIncAng;
	 double TargViewAng;
	 double TargAzimAng;
	 double MDirInc[3];
	 double axes[3];
	 double mp_axes[3];
	 double dtm_scale;
	 double dtm_axes[3];
	 double dtm_axes_map[3];
	 double long_axis;
	 int	instrument_id;
	 char	instrument_name[120];
	 char	mission_name[120];
	 int	mission_id;
	 double	positn[3];
	 double	cpmat[3][3];
	 double	*xcal;
	 double	*ycal;
	 double	focal;
	 double	tol;
	 int	geom;
	 double height;
	 int fittofile;
	 Earth_prefs prefs;
	 Earth_prefs prefs_dtm;
	 Earth_prefs prefs_std;
	 char	fittofile_name[120];
	 char	dtm_filename[120];
	 char	out_filename[120];
	 double min_h_in_dtm;
	 double max_h_in_dtm;
	 long ram_dtm;
	 int *dtm_tab_in;
	 short int *dtm_buf;
	 int match;
	 int match_x_unit;
	 int match_y_unit;
	 double scale_ratio;
	 int user_trim_left;	 
	 int user_trim_right;	 
	 int user_trim_top;	 
	 int user_trim_bottom;	 
	 int badlimb;
	 float no_info_val;
	 } str_glob_TYPE;

double my_pi2deg=(180.0/PI);
double my_deg2pi=(PI/180.0);
double my_halfpi=(PI/2.0);
double my_twopi=(2.0*PI);
double my_justpi=(PI-0.05);

double fix_height = -99999.9;

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create frameortho.imake
#define PROGRAM frameortho

#define MODULE_LIST frameortho.c 
#define INCLUDE_LIST frameortho.h 

#define MAIN_LANG_C

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB
#define LIB_CSPICE
#define LIB_HWSUB

$ Return
$!#############################################################################
$PDF_File:
$ create frameortho.pdf

process help=*

	parm inp	type=(string,120) count=1   default=frameortho.inp
	parm out	type=(string,120) count=1   default=frameortho.out

	PARM NL_OUT     TYPE=int          COUNT=0:1 DEFAULT=0
	PARM NS_OUT     TYPE=int          COUNT=0:1 DEFAULT=0
	PARM OUTMAX     TYPE=real         COUNT=1   DEFAULT=100.
	parm dtm	type=(string,120) count=1   default=0.0
	parm fittofile	type=(string,120) count=0:1 default=--

	PARM IPOL       TYPE=KEYWORD      COUNT=1   VALID=(NN,BI,CC) DEFAULT=BI
	PARM ANCHDIST   TYPE=int 	  COUNT=1   VALID=(1:1000)    DEFAULT=5
	PARM BORDER     TYPE=int 	  COUNT=1   VALID=(0:500)    DEFAULT=20
	PARM REPORT     TYPE=KEYWORD      COUNT=1   VALID=(YES,NO)   DEFAULT=NO

	PARM MATCH      TYPE=KEYWORD      COUNT=0:1 VALID=MATCH      DEFAULT=--

	PARM LIMB       TYPE=KEYWORD      COUNT=1 VALID=(BADLIMB,NICELIMB)      DEFAULT=NICELIMB

	PARM MIN_LAT    TYPE=REAL         COUNT=1    VALID=(-90:90)   DEFAULT=-90.
	PARM MAX_LAT    TYPE=REAL         COUNT=1    VALID=(-90:90)   DEFAULT=90.


	parm adjufile	type=(string,120) count=0:1	default=--
 	PARM BSPFILE    TYPE=(STRING,120) COUNT=0:3     DEFAULT =(HWSPICE_BSP,SUNKER)
 	PARM BCFILE     TYPE=(STRING,120) COUNT=0:6     DEFAULT = HWSPICE_BC
	parm TSCFILE	type=(string,120) count=0:6	default = HWSPICE_TSC
	parm TIFILE	type=(string,120) count=1       default = HWSPICE_TI
    parm TFFILE	type=(string,120) count=1       default = HWSPICE_TF
	parm TPCFILE	type=(string,120) count=1	default = CONSTANTS
	parm BPCFILE	type=(string,120) count=0:1	default = ""
	parm TLSFILE	type=(string,120) count=0:1	default = LEAPSECONDS

	parm MP_TYPE	type=(string,40) count=1	default=SINUSOIDAL +
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
			PERSPECTIVE,					+
			CORRECTION,					+
			GAUSS_KRUEGER,					+
			UTM,						+
			BMN28,						+
			BMN31,						+
			BMN34,						+
			SOLDNER) 	

	! SPICE parameter
	
	parm A_AXIS	type=(real)	 count=0:1	default=--
	parm B_AXIS	type=(real) 	 count=0:1	default=--
	parm C_AXIS	type=(real) 	 count=0:1	default=--
	parm BOD_LONG	type=(real) 	 count=0:1	default=--

	! Map projection parameter

	parm MP_RES	type=real	count=0:1	default=--
	parm MP_SCALE 	type=real	count=0:1	default=--
	parm POS_DIR	type=keyword	count=1		default=WEST +
							valid=(EAST,WEST)	
	parm CEN_LAT	type=real	count=0:1	default=--
	parm CEN_LONG	type=real	count=0:1	default=--
	parm SPHER_AZ	type=real	count=1		default=0.0
	parm L_PR_OFF	type=real	count=0:1	default=--
	parm S_PR_OFF	type=real	count=0:1	default=--
	parm CART_AZ	type=real	count=1		default=0.0
	parm F_ST_PAR	type=real	count=0:1	default=--
	parm S_ST_PAR	type=real	count=0:1	default=--

	parm USEMP 	type=keyword	count=0:1	default=-- valid=(USEMP)
	
	parm o_format	type=keyword 	  count=0:1 default=-- valid=(BYTE)
	PARM TRIM_LEFT     TYPE=int 	  COUNT=1   DEFAULT=0
	PARM TRIM_RIGHT     TYPE=int 	  COUNT=1   DEFAULT=0
	PARM TRIM_TOP     TYPE=int 	  COUNT=1   DEFAULT=0
	PARM TRIM_BOTTOM     TYPE=int 	  COUNT=1   DEFAULT=0

  ! all following parameters are only for current DLR developments (not yet supported):
    
	PARM TOL        TYPE=REAL         COUNT=0:1       DEFAULT=--

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

	! photometric parameters:

	parm PHO_FUNC	type=(string,32) count=1	default=NONE +
		valid=( NONE,						+
			LAMBERT,					+
			MINNAERT,					+
			IRVINE,						+
			VEVERKA,					+
			BURATTI1,					+
			BURATTI2,					+
			BURATTI3,					+
			MOSHER,						+
			LUMME_BOWEL_HG1,				+
			HAPKE_81_LE2,					+
			HAPKE_81_COOK,					+
			HAPKE_86_HG1,					+
			HAPKE_86_HG2,					+
			HAPKE_03_HG2,					+
			HAPKE_86_LE2,					+
			HAPKE_HG1_DOM,					+
			REGNER_HAPKE_HG1, 				+
			ATMO_CORR_REGNER)
			
    PARM T_EMI_A  TYPE=real     COUNT=1  VALID=(0.:90.) DEFAULT=0.
    PARM T_INC_A  TYPE=real     COUNT=1  VALID=(0.:90.) DEFAULT=30.
    PARM T_AZI_A  TYPE=real     COUNT=1  VALID=(0.:360.) DEFAULT=180.
    parm PHO_PAR_FILE type=string  count=0:1 	default=--

	parm ALBEDO 	type=real 	count=0:1	default=--
	parm EXPONENT 	type=real	count=0:1	default=-- valid=(0:1)
	parm A_VEVERKA 	type=real	count=0:1	default=--
	parm B_VEVERKA 	type=real	count=0:1	default=--
	parm C_VEVERKA 	type=real	count=0:1	default=--
	parm D_VEVERKA 	type=real	count=0:1	default=--
	parm MO_EXP1 	type=real	count=0:1	default=--
	parm MO_EXP2 	type=real	count=0:1	default=--
	parm E_BURATTI 	type=real	count=0:1	default=--
	parm DEN_SOIL 	type=real	count=0:1	default=--
	parm W_SOIL 	type=real	count=0:1	default=0.21 valid=(0:1)
	parm HG1_SOIL 	type=real	count=0:1	default=--
	parm HG2_SOIL 	type=real	count=0:1	default=--
	parm HG_ASY_SOIL type=real	count=0:1	default=--
	parm LE1_SOIL 	type=real	count=0:1	default=0.29
	parm LE2_SOIL 	type=real	count=0:1	default=0.39
	parm H_SHOE 	type=real	count=0:1	default=0.07
	parm B_SHOE 	type=real	count=0:1	default=2.012
	parm H_CBOE 	type=real	count=0:1	default=--
	parm B_CBOE 	type=real	count=0:1	default=--
	parm THETA 	type=real	count=0:1	default=20.0
	parm COOK 	type=real	count=0:1	default=--
	parm TAU_ATM 	type=real	count=0:1	default=--
	parm W_ATM 	type=real	count=0:1	default=-- valid=(0:1)
	parm HG1_ATM 	type=real	count=0:1	default=--
	parm IRV_EXP1 	type=real	count=0:1	default=--
	parm IRV_EXP2 	type=real	count=0:1	default=--

end-proc

.title
VICAR program FRAMEORTHO

.help
PURPOSE:
Geometric orthoimaging of frame images 

.page
FRAMEORTHO is a program created for geometric 
(ortho)-correction of frame images.

.page

Programmer:
Frank Scholten
DLR


.level1

.var inp
Input file

.var dtm
DTM file or fix height

.var out
Output image

.var adjufile
File containing adjusted position
and pointing (if set, no SPICE is used)

.var fittofile
File to which output has to fit

.var o_format
Output format (valid=BYTE) default=--
Only effective, if PHO_FUNC != NONE and
fileformat of input file is BYTE
frameortho will cut grayvalues > 255 to 255

.var MP_TYPE
map projection type

.var PHO_FUNC
Photometric function type

.var IPOL
Interpolation type
.var NL_OUT
Number of lines of the output image
.var NS_OUT
Number of samples of the output image

.var ANCHDIST
Anchorpoint distance

.var BORDER
Width of black image border

.var LIMB       
setting to BADLIMB does not make
a (time consuming) nicelimb

.var MIN_LAT       
Minimum latitude of image data
allowed in output file
(def.: -90.0)

.var MAX_LAT       
Maximum latitude of image data
allowed in output file
(def.: 90.0)

.var TRIM_LEFT
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_RIGHT
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_TOP
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_BOTTOM
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var REPORT
Monitor output request buttom

.var OUTMAX
Sizelimit for output image

.var MATCH
Match request parameter

.var T_EMI_A
Target emission angle

.var T_INC_A
Target incidence angle

.var T_AZI_A
Target azimuth angle

.var TOL
Clock tolerance of pointing requests

.var  BSPFILE
Binary SP-Kernel 

.var  BCFILE
Binary C-Kernel

.var  TSCFILE
Clock, SCLK-kernels

.var  TIFILE
Instrument data, I-kernel

.var  TPCFILE
Planetary constants, PC-kernels

.var  BPCFILE
Binary Planetary constants, PC-kernels.  Default = --

.var  TLSFILE
Leapseconds, LS-kernel

.VARI A_AXIS
Semimajor axis of target body.

.VARI B_AXIS
Semiminor axis of target body.

.VARI C_AXIS
Polar axis of target body.

.VARI BOD_LONG
The target body's longitude at which the semimajor equatorial axis is
measured.

.var MP_RES
scale of a map in pixels per 
degree, Attention! 
it is a nessary parameter, 
if MP_SCALE is not defined
.var MP_SCALE
scale of a map in kilometers per
pixel, Attention! 
it is a nessary parameter, 
if MP_RES is not defined
.var POS_DIR
the direction of longitude 
(e.g. EAST, WEST) for a planet
.var CEN_LAT
center_latitude, measured in 
degrees with a valid range of 
(-90.0, 90.0)
.var CEN_LONG
center_longitude, measured in 
degrees with a valid range of 
(0,360)
.var SPHER_AZ
spherical_azimuth, measured in 
degrees with a valid range of 
(0,360)
.var L_PR_OFF
line offset value of the origin 
from the pixel line and sample 
1,1
.var S_PR_OFF
sample offset value of the 
origin from the pixel line and 
sample 1,1
.var CART_AZ
cartesian_azimuth is the angle 
of the clockwise rotation of 
the map in degrees
.var F_ST_PAR
first standard parallel, 
measured in degrees with a 
valid range of (-90.0, 90.0)
.var S_ST_PAR
second standard parallel, 
measured in degrees with a 
valid range of (-90.0, 90.0)
.var FOC_LEN
Focal Length
.var FOC_SCAL
Focal Plane Scale
.var NORTH_AN
North Angle
.var INTERC_L
optical axis interception 
line
.var INTERC_S
optical axis interception 
sample
.var PL_CEN_L
planet center line
.var PL_CEN_S
planet center sample
.var SUB_LAT
subspacecraft latitude
.var SUB_LONG
subspacecraft longitude
.var SPC_DIST
Spacecraft Distance

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

.level2

.var inp
Input file
(has to be frame image)

.var dtm
DTM file of fix height in m
above target body
(default= 0m,
i.e. the reference ellipsoid)

.var out
Output VICAR-image with complete label information

.var adjufile
File containing adjusted position
and pointing (if set, no SPICE is used)

.var fittofile
File to which output has to fit

.var o_format
Output format (valid=BYTE) default=--
Only effective, if PHO_FUNC != NONE and
fileformat of input file is BYTE
frameortho will cut grayvalues > 255 to 255

.var MP_TYPE
Identifies the type of cartographic projection characteristic of 
a given map.  These names or types are derived from names used in 
USGS Professional Paper 1395. (default: SINUSOIDAL)

.var PHO_FUNC
Photometric function type (default: NONE)

This parameter selects the menu point for input the photometry task:
   1. to run the program without using a photometric function, you have 
      to select "NONE"'
   3. to run the program without using a photometric correction you have to 
      select the desired photometric function.

Note for the tutor mode :
  When returning to the highest level of the menu program you will
  see that the fourth selection point has been changed according to your input 
  of PHO_FUNC in the first menu point.

.var IPOL
Interpolation type: NN = Nearest Neighbor
                    BI = Bilinear Interpolation (default)
                    CC = Cubic Convolution
.var NL_OUT
Number of lines of the output image
.var NS_OUT
Number of samples of the output image

.var ANCHDIST
Distance between the points that define the 
anchorpoint grid: valid is a value between 1 and 1000

.var LIMB       
setting to BADLIMB does not make
a (time consuming) nicelimb
default and in MATCH-Mode: NICELIMB

.var MIN_LAT       
Minimum latitude of image data (wrt. MP_RADIUS if set)
allowed in output file
(should be set by user, e.g. if south pole is in image)
(def.: -90.0)

.var MAX_LAT       
Maximum latitude of image data (wrt. MP_RADIUS if set)
allowed in output file
(should be set by user, e.g. if north pole is in image)
(def.: 90.0)

.var BORDER
This is the width of a black border region with a
grayvalue of 0 which is generated all arround the
output image. If a special projection offset is given by
the user the border will only be generated at the bottom and
right side of the output image. Default for BORDER = 20

Note, that BORDER does not allways define the width exact.
It might vary due to real-to-integer-conversion of
offsets by +/- 1 pixel and due to interpolation limitations
at the image border (e.g. using Cubic Convolution or 
Bilinear Interpolation) by additional +/- 1 pixel.
This does not affect the correctness of offsets.

.var TRIM_LEFT
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_RIGHT
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_TOP
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var TRIM_BOTTOM
user-defined border of the input image,
which will be ignored; additional to 
VOYAGER: TOP/BOTTOM/LEFT/RIGHT 50
VIKING:  TOP 25 BOTTOM 20 LEFT/RIGHT 30

.var REPORT
Monitor output request buttom.
YES = The monitor output of
      - Output image dimensions (lines, samples)
      - Location within the map projection
	(Line and Sample Projection Offset)
      - progress in processing 
      is requested.
NO  = No monitor output is requested (default)

.var OUTMAX
Sizelimit for output image [in MegaByte]
default: 100.

.var MATCH
Match request parameter,
may be set to MATCH=MATCH,
if program should generate 
OUT_l and OUT_s files with information
about the history of each pixel in OUT
NOTE: These files will have together
a size of 8 times the OUT size !
default: --

.var T_EMI_A
Target emission angle (in degrees) for the photometric correction from the 
nativ illumination condition to target artficial ons.

The emission angle element provides the value of the angle between the surface 
normal vector at the interception point and a vector from the intercept point 
to the viewer (artificial spacecraft). The emission angle varies 
from 0 degrees when the viewer is looking perpendicular to the local surface 
(nadir viewing) to 90 degrees when the intercept is tangent to the surface 
of the target body. 

.var T_INC_A
Target incidence angle (in degrees) for the photometric correction from the 
nativ illumination condition to target artficial ons.

The target incidence angle element provides a measure of the target artificial 
lighting condition at the intercept point. The target incidence angle is the 
angle between the surface normal vector at the intercept point (at the surface) 
and a vector from the intercept point to the artificial "sun". The incidence 
angle varies from 0 degrees when the "solar" direction is perpendicular to the 
local surface to 90 degrees when the intercept is tangent to the surface of the 
target body. 

.var T_AZI_A
Target azimuth angle (in degrees) for the photometric correction from the 
nativ illumination condition to target artficial ons.

The target phase angle element provides a measure of the relationship between 
the target viewing direction (corrected to desired ons) and incidence 
artificial "solar" light direction. Phase angle is defined as the angle between 
a vector from the intercept point to the "sun" and a vector from the intercept 
point to the viewer. Phase angle varies from 0 degrees, when the "sun" is 
directly behind the viewer, to 180 degrees, when the "sun" is opposite the 
viewer.

.var A_AXIS
The a-axis measure provides the value of the a-axis of a solar 
system body.  This element provides the semimajor equatorial 
radius measured perpendicular to the spin axis. In the case of 
a spherical or oblate spherical body, the a-axis and b-axis 
measures have the same value. A_AXIS_RADIUS is measured in kilometers.

.var B_AXIS
The b-axis measure provides the value of the b-axis of a solar 
system body.  This element provides the semiminor equatorial 
radius measured perpendicular to the spin axis. In the case of 
a spherical or oblate spherical body, the a-axis and b-axis 
measures have the same value. B_AXIS_RADIUS is measured in kilometers.

.var C_AXIS
The C axis measure provides the value of the c-axis of a solar 
system body.  This element provides the polar radius as measured 
along the spin axis. C_AXIS_RADIUS is measured in kilometers.

.var BOD_LONG
The longitude of the semimajor (longest) axis of a triaxial 
ellipsoid.  Some bodies, like Mars, have the prime meridian 
defined at a longitude which does not correspond to the 
equatorial semimajor axis, if the equatorial plane is modeled 
as an ellipse.

.var TOL
Clock tolerance of pointing requests

.var  BSPFILE
Binary SP-Kernel. Default = EPHEMERIS 

.var  BCFILE
Binary C-Kernel. Default = POINTING

.var  TSCFILE
Clock, SCLK-kernel.  Default = SCLK

.var  TIFILE
Instrument data, I-kernel.  Default = INSTRUMENT

.var  TPCFILE
Planetary constants, PC-kernels.  Default = CONSTANTS

.var  BPCFILE
Binary Planetary constants, PC-kernels.  Default = --

.var  TLSFILE
Leapseconds, LS-kernel.  Default = LEAPSECONDS

.var MP_RES
Identifies the scale of a given map in pixels per degree.  Please refer
to the definition for map scale for a more complete definition. Note 
that map resolution and map scale both define the scale of a map except 
that they are expressed in different units. Map scale is measured in 
kilometers per pixel.

.var MP_SCALE
Map scale is defined as the ratio of the actual distance between two 
points on the surface of the target body to the distance between the
corresponding points on the map.  The map scale references the scale 
of a map at a certain reference point or line, measured in kilometers 
per pixel.  Certain map projections vary in scale throughout the map. 
In general, the map scale usually refers to the scale of the map at 
the center latitude and center longitude. An exception are the Conic 
projections; the map scale refers to the scale at the standard 
parallels for these projections.  The relationship between map 
scale and the map resolution element is that they both define 
the scale of a given map, except they are expressed in different 
units.  Map resolution is in pixels per degree.

.var POS_DIR
Identifies the direction of longitude (e.g. EAST, WEST) for a planet. 
The IAU definition for direction of positive longitude is adopted.  
Typically, for planets with prograde rotations, positive longitude 
direction is to the west. For planets with retrograde rotations, positive
longitude direction is to the east.

.var CEN_LAT
The center_latitude element provides a reference latitude for certain 
map projections, measured in degrees with a valid range of (-90.0, 90.0). 
In many projections, the center_latitude along with the center_longitude 
defines the point or tangency between the sphere of the planet and the 
plane of the projection.  For spherical projections, the center_latitude 
is formally defined in terms of Euler angles (please refer to the definition 
for spherical_azimuth for a more complete explanation).  The map_scale 
(or map_resolution) is typically defined at the center_latitude and
center_longitude.

.var CEN_LONG
The center_longitude element provides a reference longitude for certain 
map projections, measured in degrees with a valid range of (0,360).  In 
many projections, the center_longitude along with the center_latitude 
defines the point or tangency between the sphere of the planet and the 
plane of the projection.  For spherical projections, the center_longitude 
is formally defined in terms of Euler angles (please refer to the definition 
for spherical_azimuth for a more complete explanation).  The map_scale 
(or map_resolution) is typically defined at the center latitude and 
longitude.

.var SPHER_AZ
For the spherical body model, a clockwise rotation of that body about 
an imaginary axis through a specified center latitude and longitude 
(MIPS-PDS keywords CENTER_LATITUDE, CENTER_LONGITUDE) allows for a 
reorientation prior to map projection of the surface to the image space. 
The measure of this clockwise rotation in degrees is the spherical 
azimuth.
More specifically, the spherical body model is first rotated about its 
polar axis until the specified center longitude lies at the projection 
center. Then the body model is rotated about an axis perpendicular to 
the specified center longitude until the center latitude lies at the 
projection center. Finally, the body model is rotated clockwise about 
the radius vector from the center of the sphere to the center latitude 
and longitude point to complete the pre-mapping body reorientation.

.var L_PR_OFF
Provides the line offset value of the map projection origin position 
from the center of the pixel line and sample {1,1} (line and sample 
1,1 is considered the upper left corner of the digital array). Note 
that the positive direction is to the right and down.

.var S_PR_OFF
The sample offset value of the map projection origin position from the 
center of the pixel line and sample 1,1 (line and sample 1,1 is 
considered the upper left corner of the digital array). Note that the 
positive direction is to the right and down.

.var CART_AZ
After points have been projected to image space (x,y or line,sample), 
a clockwise rotation, in degrees, of the line and sample coordinates 
can be made with respect to the map projection origin - specified by
line and sample projection offset. This clockwise rotation in degrees 
is the Cartesian azimuth. This parameter is used to indicate where 'up' 
is in the projection.

.var F_ST_PAR
Standard parallels are used in certain projections, e.g. Lambert Conic 
and Albers, to mark selected latitudes for defining components of a map
projection.  If a Conic projection has a single standard parallel, then 
the first standard parallel is the point of tangency between the sphere 
of the planet and the cone of the projection. If there are two standard
parallels, both first and second parallels, these are the intersection 
lines between the sphere of the planet and the cone of the projection. 
For respective map projections, map scale is defined at the standard 
parallels.

.var S_ST_PAR
Standard parallels are used in certain projections, e.g. Lambert Conic 
and Albers, to mark selected latitudes for defining components of a map
projection.  If a Conic projection has a single standard parallel, then 
the first standard parallel is the point of tangency between the sphere 
of the planet and the cone of the projection. If there are two standard
parallels, both first and second parallels, these are the intersection 
lines between the sphere of the planet and the cone of the projection. 
For respective map projections, map scale is defined at the standard 
parallels.

.var FOC_LEN
The camera focal length measured in millimeters.

.var FOC_SCAL
The scale in the camera focal plane in pixels per millimeter. The 
scale is measured on the geometrically corrected image.

.var NORTH_AN
The angle in degrees measured clockwise from up, where up is 
defined in the direction of the planet spin axis, projected onto 
the image plane.

.var INTERC_L
The image line which intersects the optical axis in the camera focal 
plane after distortion correction.

.var INTERC_S
The image sample which intersects the optical axis in the camera focal 
plane after distortion correction. Sample increases to the right.

.var PL_CEN_L
The picture line coincident with the center of the planet. This line 
is measured on the geometrically corrected image.

.var PL_CEN_S
The picture sample coincident with the center of the planet. This sample 
is measured on the geometrically corrected image.

.var SUB_LAT
The planetocentric latitude of the intersection of a vector drawn from 
the planet center to the spacecraft with the surface of the planet.

.var SUB_LONG
The  west longitude of the intersection of a vector drawn from the planet
 center to the spacecraft with the surface of the planet.

.var SPC_DIST
Distance in kilometers between the planet center and the spacecraft 
at the time the image was obtained.

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

.end
$ Return
$!#############################################################################
$Test_File:
$ create tstframeortho.pdf
procedure
refgbl $echo
refgbl $syschar
body
let _onfail="continue"
!
!*******************************************************
!     THIS IS A TEST FILE FOR THE PROGRAM FRAMEORTHO_NEW
!*******************************************************
!
write "Remarks for Testing of FRAMEORTHO_NEW:"
write "FRAMEORTHO_NEW is a program created for geometric correction of "
write "frame images. To perform a test of FRAMEORTHO_NEW"
write "just enter:          frameortho inp=(A,DTM) out=B "
write "at the command line of VICAR or from shell"
write "where A is an appropriate input image,"
write "DTM is a 16-bit-DTM of this region"
write "and B the output file !! "

end-proc

$ Return
$!#############################################################################
