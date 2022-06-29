$!****************************************************************************
$!
$! Build proc for MIPL module hrortho
$! VPACK Version 1.9, Friday, October 21, 2005, 17:50:38
$!
$! Execute by entering:		$ @hrortho
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
$ write sys$output "*** module hrortho ***"
$!
$ Create_Source = ""
$ Create_Repack =""
$ Create_PDF = ""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_PDF .or. Create_Imake .or -
        Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hrortho.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_PDF then gosub PDF_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
$   Create_PDF = "Y"
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
$   if F$SEARCH("hrortho.imake") .nes. ""
$   then
$      vimake hrortho
$      purge hrortho.bld
$   else
$      if F$SEARCH("hrortho.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrortho
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrortho.bld "STD"
$   else
$      @hrortho.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrortho.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrortho.com -mixed -
	-s hrortho.c hrortho.h -
	-i hrortho.imake -
	-p hrortho.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrortho.c
$ DECK/DOLLARS="$ VOKAGLEVE"

#include "hrortho.h"

void main44()


/*############################################################	*/
/* hrortho: Computes a geometrically corrected hw image 	*/
/*############################################################	*/
/* Calling	zveaction, zvunit, zvopen, zvget, zlget,
		zvmessage, zvabend, zvclose, zvsptr

		mpGetValues, mpSetValues		

		hwldker, hwgetpar,  zcltgetrcs, cltgetgcl

    (private)   hrortho_p, hworloc, hwgeorec			*/
/*############################################################	*/

	{
   	hwkernel_3 bsp;
   	hwkernel_6 bc, tsc;
   	hwkernel_1 tpc, bpc, ti, tf, tls, sunker;

    char kernel[9][STRING_SIZE];
    char spice_file_id[60];
    int  lauf;

	short int  *dtm_buf;	

	int	   n_rows, fit_unit, ib_unit,  n_IBIS_rows, flag, i, j, n_axes, callfunc, count, 
		   c_ptr[2], i_temp[2], cal_unit, dtmunit, eins=1, instance, nof_kernel;

	float	   r_temp, vari[6], covari[6], temp_float;
	
	char	   pok[4], poslongdir[5], tp_dir[80], outstring[200],utc_string[80], outname[120], 
	           c_string[200],c_temp[120], c_temp2[240], c_temp32[32], c2_temp[2], extorifile[120];
	char	   pool_item[80], informat[5], start_time[120], stop_time[120], task_name[120], fittosensor[3];
	double	   dou, cart_az, ll_start[2], ll_end[2], tempMDirView[3], positn[3], GON2PI=PI/200.0, d_temp;

	MP mp_obj;
	Earth_prefs	prefs, prefs_dtm;
	
	int		def_count ,count1, count2, count3, status, checkl;
	char		project[STRING_SIZE];
	char		c_strip[3], sensor[3];
	int		strip, reduced_ram;
	myBYTE	*gv_out_buf_byte;
	short int *gv_out_buf_half;
	int	*gv_out_buf_full;
	float	*gv_out_buf_float, *match_x_buf, *match_y_buf, ccd;
	double	red_fac, out_buf_size, match_buf_size, check_out_buf_size, xxx[3][3];

	char   outdir[120];
	char   *value, dum_detec[10];
    int idum, dum_macro, dum_first,  dum_sl_inp, dum_nof_inp_l, preliminary;
	
	double	*dum_time, *dum_xyz0, *dum_xyz1, *dum_xyz2, *dum_phi, *dum_omega, *dum_kappa, cpmat[3][3];
	dtm	fitto_dtmlabel;
	hrpref_typ HR_Prefix;

	str_glob_type str_glob;


	preliminary = 1;

	if ((preliminary-1) != 0)
		{
		callfunc = extori_or("its-preliminary", &ib_unit, &n_rows, pok, vari, covari, start_time, stop_time, &dum_macro, dum_detec, &dum_first);
		if (callfunc !=1) 
			{
			sprintf(c_temp, "could not open the IBIS extori file (%d) !!", callfunc);
     		zvmessage(c_temp,"");
  	    	zabend();
			}
		callfunc = extori_re(ib_unit, dum_sl_inp, dum_nof_inp_l, 
		   dum_time, dum_xyz0, dum_xyz1, dum_xyz2, dum_phi, dum_omega, dum_kappa);
		if (callfunc !=1)  
			{
			sprintf(c_temp, "could not read the IBIS extori file  !!");
     		zvmessage(c_temp,"");
  	    	zabend();
			}
		callfunc = extori_cl(ib_unit);
		}


	for (i=0;i<MAX_PIXEL_PER_LINE;i++)str_glob.phoCorVal_vec[i]=1.0;
	
	zvp ( "project", project, &count1);
	zvp ( "strip", &strip, &count2);
	if (count2>0) sprintf (c_strip,"%02d",strip);
	zvp ( "sensor", sensor, &count3);
	def_count = count1 * count2 * count3;

	mp_obj=NULL;

	str_glob.first_used_l = 1;
	str_glob.first_georec=1;
	str_glob.first_io=1;
	str_glob.fillp=0;
	str_glob.found=0;
	str_glob.found_in_dtm=0;
	str_glob.min_longi=999.9; str_glob.max_longi=-999.9;
	str_glob.min_lati =999.9; str_glob.max_lati =-999.9;

	str_glob.quad[0]=1;str_glob.quad[1]=1;str_glob.quad[2]=1;str_glob.quad[3]=1;
	str_glob.pho_calc_done=1;	
/*-------------------------------------------------------------
	Standard error action for VICAR I/O 
	----------------------------------------------------------*/	

/*	callfunc = zveaction("sa","");	!!!! has to be included 
			     when mp_routines are corrected !!!!! */
			
/*-------------------------------------------------------------
	Get hrortho-PPF-Parameters and store it in structures

	(Spice-kernel-name-parameters
	which are used in hwldker, cltviewpa, 
	are get NOT here but within the routine hwldker)			
	----------------------------------------------------------*/	
		
	callfunc = hrortho_p (&str_glob);

/*-------------------------------------------------------------
	Get Input-file name			
	----------------------------------------------------------*/	
	callfunc = zvp("INP", str_glob.inp_filename,  &count);
	if ( count != 1)
	    {
	    if (def_count!=0)
		{
		strcpy (str_glob.inp_filename,project);
		strncat(str_glob.inp_filename,"/",strlen("/"));
		strncat(str_glob.inp_filename,c_strip,2);
		strncat(str_glob.inp_filename,"/",strlen("/"));
		strncat(str_glob.inp_filename,"img",strlen("img"));
		strncat(str_glob.inp_filename,"/",strlen("/"));
		strncat(str_glob.inp_filename,sensor,2);
		strncat(str_glob.inp_filename,".l2",strlen(".l2"));
		}
	    else 
	    	{
		sprintf(c_string, "Error opening INP-file  !!");
     		zvmessage(c_string,"");
			
  	    	zabend();
		}
	    }
	sprintf(c_string, "Using %s as INP-file ...\n",str_glob.inp_filename );
     	zvmessage(c_string,"");

/*-------------------------------------------------------------
	Open Input-file			
	----------------------------------------------------------*/	
			 
	callfunc = zvunit (&(str_glob.inunit), "anything2",  1, "U_NAME", str_glob.inp_filename, 0);
	zvselpiu(str_glob.inunit);
	callfunc = zvopen (str_glob.inunit,
		"OP",		"READ",
		"OPEN_ACT",	"AUS",
		"OPEN_MES",	"Error opening input-file in hrortho",
		"COND", 	"BINARY",
		"U_FORMAT",	"REAL", 0);

/*-------------------------------------------------------------
	Get Input-File Informations			
	------------------------------------------------------------*/	
	callfunc = hw_get_label_info (&str_glob);
	if (callfunc != 0)
	    {
	    printf("Error reading Input Label !! (Error Key: %d)\n", callfunc);
	    zabend();
	    }
	
	str_glob.ignore_min = (double)
         		((double)(str_glob.fp-str_glob.non_active_pixel_start-1) + 
			0.01 * str_glob.ignore * (double)(str_glob.nof_inp_s*str_glob.macro) * 0.5);
	str_glob.ignore_max = (double)
         		((double)(str_glob.fp-str_glob.non_active_pixel_start-1) + 
			(double)(str_glob.nof_inp_s*str_glob.macro) - (str_glob.ignore_min-(str_glob.fp-str_glob.non_active_pixel_start-1)));


	/*-------------------------------------------------------------
	Get Property M94_ORBIT (spice_target_id)			
	------------------------------------------------------------*/	
	callfunc = hw_get_target(&str_glob);
	if (callfunc != 0)
	    {
	    sprintf(outstring, "No target found!!");
     	    zvmessage(outstring,"");
	    zabend();
	    }

 
/*-------------------------------------------------------------
	Get dtm-file name			
	----------------------------------------------------------*/	
	callfunc = zvp("DTM", str_glob.dtm_filename,  &count);
	if ( count != 1)
	    {
	    if (def_count!=0)
		{
		strcpy (str_glob.dtm_filename,project);
		strncat(str_glob.dtm_filename,"/",strlen("/"));
		strncat(str_glob.dtm_filename,"dtm",strlen("dtm"));
		strncat(str_glob.dtm_filename,"/",strlen("/"));
		strncat(str_glob.dtm_filename,"dtm",strlen("dtm"));
		}
	    else 
	    	{
		sprintf(c_string, "Error opening DTM-file  !!");
     		zvmessage(c_string,"");
			
  	    	zabend();
		}
	    }
/*-------------------------------------------------------------
	Open dtm-file			
	----------------------------------------------------------*/	
	callfunc = zvunit (&dtmunit, "anything",  1, "U_NAME", str_glob.dtm_filename, 0);
	if(callfunc != 1)
		{
		zvmessage("Couldn't unit DTM file", 0);
		zabend();
		}

	str_glob.geom=0;
	str_glob.height=0.0;
	callfunc = zvopen(dtmunit, "OP", "READ", 0);
	if(callfunc != 1)
	    {
 	    str_glob.geom=1;
   	    callfunc = sscanf (str_glob.dtm_filename,"%lf",&(str_glob.height));
	    if ((callfunc==(int)EOF)||(callfunc<1)) 
		{
	    	printf ("DTM-File %s could not be opened !!\n",str_glob.dtm_filename);
		zabend();
		}

	    printf ("DTM-File %s could not be opened, using GEOM-mode with fix height %lf meter ...\n",str_glob.dtm_filename, str_glob.height);
	    str_glob.ram_dtm=0;
	    }
	else 
	    {
	    sprintf(c_string, "Using %s as DTM-file ...\n",str_glob.dtm_filename );
     	    zvmessage(c_string,"");
	    
	    /* Initialize MP object */
	    callfunc = mpInit(&(str_glob.mp_dtm_obj));
	    if(callfunc != mpSUCCESS)
		{
		zvmessage("mpInit failed for dtm !!",0);
		zabend();
		}
	    /* Read DTM label */
	    callfunc = hwdtmrl(dtmunit, &(str_glob.dtmlabel));
	    str_glob.min_h_in_dtm = ((double)str_glob.dtmlabel.dtm_minimum_dn * str_glob.dtmlabel.dtm_scaling_factor + (double)str_glob.dtmlabel.dtm_offset);
	    str_glob.max_h_in_dtm = ((double)str_glob.dtmlabel.dtm_maximum_dn * str_glob.dtmlabel.dtm_scaling_factor + (double)str_glob.dtmlabel.dtm_offset);
	    callfunc = dlr_mpLabelRead(str_glob.mp_dtm_obj, dtmunit, &prefs_dtm);				
	    callfunc = zvget (dtmunit, "NL",  &(str_glob.nof_dtm_l), 
			       "NS",  &(str_glob.nof_dtm_s), 0); 
	    if (((double)str_glob.nof_dtm_l*(double)str_glob.nof_dtm_s*(double)(sizeof(short int)))
		> 1024.*1024.*1024.*2.)	
		{
		zvmessage("DTM is larger than 2 GByte !! There are problems due to max_value of int ",0);
		zabend();
		}
	    str_glob.ram_dtm=str_glob.nof_dtm_l*str_glob.nof_dtm_s*sizeof(short int);
	    dtm_buf   = (short int *) malloc (str_glob.ram_dtm);
	    if (dtm_buf == (short int *)NULL) 
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
	    callfunc = zvread (dtmunit, (dtm_buf+str_glob.dtm_tab_in[i]),
				           "LINE", i, "SAMP", 1, "NSAMPS", str_glob.nof_dtm_s, 0);
	    callfunc = mpGetValues  ( str_glob.mp_dtm_obj, mpA_AXIS_RADIUS, &str_glob.dtm_axes_map[0], NULL); 
	    callfunc = mpGetValues  ( str_glob.mp_dtm_obj, mpB_AXIS_RADIUS, &str_glob.dtm_axes_map[1], NULL); 
	    callfunc = mpGetValues  ( str_glob.mp_dtm_obj, mpC_AXIS_RADIUS, &str_glob.dtm_axes_map[2], NULL); 
	    callfunc = mpGetValues  ( str_glob.mp_dtm_obj, mpMAP_SCALE, &str_glob.dtm_scale, NULL); 
	    str_glob.dtm_scale *= 1000.; 
	    str_glob.dtm_poslongdir_fac = 1.;
	    callfunc = mpGetValues
		  ( str_glob.mp_dtm_obj, mpPOSITIVE_LONGITUDE_DIRECTION, poslongdir, NULL); 
	    if (strcmp(poslongdir, "WEST")==0) str_glob.dtm_poslongdir_fac = -1.;
	    
	    callfunc = dlr_earth_map_get_prefs (str_glob.mp_dtm_obj, &prefs_dtm);
	    if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	
	    }


/*--------------------------------------------------------------------
	Get Output-file name 	
	-------------------------------------------------------------*/	

	callfunc = zvp("OUT", str_glob.out_filename,  &count);
	if ( count != 1)
	    {
	    if (def_count!=0)
			{
			if (str_glob.geom==1)
		    	{
		    	if (str_glob.match==1)
					{
					strcpy (str_glob.out_filename,project);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,c_strip,2);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,"mat",strlen("mat"));
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,sensor,2);
					strncat(str_glob.out_filename,".mat",strlen(".mat"));
					}
		    	else
					{
					strcpy (str_glob.out_filename,project);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,c_strip,2);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,"geo",strlen("geo"));
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,sensor,2);
					strncat(str_glob.out_filename,".l3",strlen(".l3"));
					}
		    	}
			else
		    	{
		    	if (str_glob.match==1)
					{
					strcpy (str_glob.out_filename,project);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,c_strip,2);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,"mat",strlen("mat"));
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,sensor,2);
					strncat(str_glob.out_filename,".mat",strlen(".mat"));
					}
		    	else
					{
					strcpy (str_glob.out_filename,project);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,c_strip,2);
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,"ort",strlen("ort"));
					strncat(str_glob.out_filename,"/",strlen("/"));
					strncat(str_glob.out_filename,sensor,2);
					strncat(str_glob.out_filename,".l4",strlen(".l4"));
					}
		    	}
			}
	    else 
	    	{
			strcpy (str_glob.out_filename,str_glob.inp_filename);
			if (str_glob.geom==1)
				strncat(str_glob.out_filename,".l3",strlen(".l3"));
			else
				strncat(str_glob.out_filename,".l4",strlen(".l3"));
			zvp ("DIR_OUT", outdir, &count);
			if (count>0) 
				{
				strncat(outdir,"/",strlen("/"));
				hwnopath(str_glob.out_filename);
				strcat(outdir,str_glob.out_filename);
				}
			}
	    }

 
	if (str_glob.use_extori)
		{

		/*-------------------------------------------------------------
		Get extori-file name			
		----------------------------------------------------------*/	
		callfunc = zvp("EXTORIFILE", extorifile,  &count);
		if ( count != 1)
	    	{
			sprintf(c_string, "Error opening extorifile  !!");
     		zvmessage(c_string,"");
			
  	    	zabend();
	    	}
		/*-------------------------------------------------------------
		Get position and rotation matrix from body fixed to camera system
		----------------------------------------------------------*/	

 		/* open the extori file for read */
		callfunc = extori_or(extorifile, &ib_unit, &n_rows, pok, vari, covari, start_time, stop_time, &dum_macro, dum_detec, &dum_first);

		if (callfunc !=1) 
			{
			sprintf(c_temp, "could not open the IBIS extori file (%d) !!", callfunc);
     		zvmessage(c_temp,"");
  	    	zabend();
			}
		if (n_rows > str_glob.nof_inp_l) 
			{
			sprintf(c_temp, "IBIS extori file contains more lines than image file,");
     		zvmessage(c_temp,"");
			sprintf(c_temp, "process continues assuming extori-line1 = image-line1 ...");
     		zvmessage(c_temp,"");
 			}
		else if (n_rows < str_glob.nof_inp_l) 
			{
			sprintf(c_temp, "IBIS extori file contains less lines than image file !!");
     		zvmessage(c_temp,"");
  	    	zabend();
 			}

		str_glob.time   = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.time == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.xyz0 = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.xyz0 == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.xyz1 = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.xyz1 == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.xyz2 = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.xyz2 == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.phi    = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.phi == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.omega  = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.omega == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}
		str_glob.kappa  = (double *)malloc(n_rows*sizeof(double));
		if (str_glob.kappa == (double *)NULL) 
			{    	
			sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
			zabend();
			}

		/* read n_rows rows */
		callfunc = extori_re(ib_unit, 1, n_rows, 
		   str_glob.time, str_glob.xyz0, str_glob.xyz1, str_glob.xyz2, str_glob.phi, str_glob.omega, str_glob.kappa);

		if (callfunc !=1) 
			{
			sprintf(c_temp, "could not read the IBIS extori file  !!");
     		zvmessage(c_temp,"");
  	    	zabend();
			}

		/* close the extori file */
		callfunc = extori_cl(ib_unit);
		if (callfunc !=1)
			{
			sprintf(c_temp, "could not close the IBIS extori file  !!");
     		zvmessage(c_temp,"");
  	    	zabend();
			}


		/*----------------------------------------------------------------	
		load kernels 					
  		----------------------------------------------------------------*/	
    	callfunc = hwldker(1, "tpc", &tpc);
		status = hwldker_error (callfunc, c_temp);
		if (status != -1)
       		{
       		zvmessage("HWLDKER problem","");
       		zvmessage(c_temp,"");
       		zabend();
       		}
    	strcpy(kernel[0],tpc.filename);

		nof_kernel = 1;

  		if (str_glob.phocorr != 0)
			{
    		strcpy(kernel[1],bsp.filename[0]);  	
    		strcpy(kernel[2],bsp.filename[1]);  	
    		strcpy(kernel[3],bsp.filename[2]);  	
			nof_kernel += 3;
			strcpy (spice_file_id, "(PCK,SPK,SPK,SUNKER)");
			}
		else strcpy (spice_file_id, "PCK");
		}	    
	else
		{
		/*----------------------------------------------------------------	
		load kernels 					
  		----------------------------------------------------------------*/	
    	callfunc = hwldker(7, "bsp", &bsp, "bc",  &bc, "tsc", &tsc,
            			  "tls", &tls, "tpc", &tpc, "ti", &ti,
                    	  "tf", &tf);
		status = hwldker_error (callfunc, c_temp);
		if (status != -1)
       		{
       		zvmessage("HWLDKER problem","");
       		zvmessage(c_temp,"");
       		zabend();
       		}
    	strcpy(kernel[0],bsp.filename[0]);
    	strcpy(kernel[1],bsp.filename[1]);
    	strcpy(kernel[2],bc.filename[0]);
    	strcpy(kernel[3],tsc.filename[0]);
    	strcpy(kernel[4],tls.filename);
    	strcpy(kernel[5],tpc.filename);
    	strcpy(kernel[6],ti.filename);
    	strcpy(kernel[7],tf.filename);
 
		nof_kernel = 8;

  		if (str_glob.phocorr != 0)
			{
    		strcpy(kernel[8],bsp.filename[2]);  	
			nof_kernel++;
    		strcpy (spice_file_id, "(SPK,SPK,CK,SCLK,LSK,PCK,IK,FK,SUNKER)");
			}
		else
			{
    		strcpy (spice_file_id, "(SPK,SPK,CK,SCLK,LSK,PCK,IK,FK)");
			}

		}


/*----------------------------------------------------------------	
	Fill Map Projection Data Object					
	-------------------------------------------------------	*/
	callfunc = zvp("fittofile", str_glob.fittofile_name,  &(str_glob.fittofile));

	if (str_glob.fittofile==0)
		    {
		    callfunc = hwgetpar(&mp_obj, str_glob.target_id);
		    if (callfunc != 0) 
				{
				zvmessage("No map proj. object created in hrortho !","");
				zabend ();
				}

			callfunc = mpGetValues ( mp_obj, mpA_AXIS_RADIUS, &str_glob.axes[0], NULL); 
			callfunc = mpGetValues ( mp_obj, mpB_AXIS_RADIUS, &str_glob.axes[1], NULL); 
			callfunc = mpGetValues ( mp_obj, mpC_AXIS_RADIUS, &str_glob.axes[2], NULL); 

			if (!(str_glob.mp_radius_set))
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
		    count = zvopen (fit_unit, "OP", "READ", "OPEN_ACT",	" ", 0);
		    if(count != 1)
		     {
		     callfunc = which_sensor(str_glob.fittofile_name,fittosensor);

		     if (callfunc!=0)
			{
			if (def_count==0)
			    {
			    zvmessage("No map FITTOIMAGE-file could be referenced !","");
			    zabend ();
			    }
			if(str_glob.geom==1)
			    {
			    if (str_glob.match==0)
				    {
				    strcpy (str_glob.fittofile_name,project);
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,c_strip,2);
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,"geo",strlen("geo"));
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,fittosensor,2);
				    strncat(str_glob.fittofile_name,".l3",strlen(".l3"));
				    }
			    else
				    {
				    strcpy (str_glob.fittofile_name,project);
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,c_strip,2);
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,"mat",strlen("mat"));
				    strncat(str_glob.fittofile_name,"/",strlen("/"));
				    strncat(str_glob.fittofile_name,fittosensor,2);
				    strncat(str_glob.fittofile_name,".mat",strlen(".mat"));
				    }
			    }
			else
			    {
			    if (str_glob.match==0)
				{
				strcpy (str_glob.fittofile_name,project);
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,c_strip,2);
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,"ort",strlen("ort"));
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,fittosensor,2);
				strncat(str_glob.fittofile_name,".l4",strlen(".l4"));
				}
			    else
				{
				strcpy (str_glob.fittofile_name,project);
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,c_strip,2);
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,"mat",strlen("mat"));
				strncat(str_glob.fittofile_name,"/",strlen("/"));
				strncat(str_glob.fittofile_name,fittosensor,2);
				strncat(str_glob.fittofile_name,".mat",strlen(".mat"));
				}
			    }
			}
		     callfunc = zvunit (&fit_unit, "any",  1, "U_NAME", str_glob.fittofile_name, 0);
		     if(callfunc != 1)
			{
		    	zvmessage("Couldn't unit FITTOIMAGE file", 0);
			zabend();
			}
		     count = zvopen (fit_unit, "OP", "READ", "OPEN_ACT", " ", 0);
		     }

		    if(count != 1)
			{
		    	zvmessage("Couldn't open FITTOIMAGE file", 0);
			zabend();
			}

		    callfunc = mpInit(&mp_obj);	

		    callfunc = dlr_mpLabelRead(mp_obj, fit_unit, &prefs);	
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
				}

		 
		    callfunc = zvget (fit_unit, "NL",  &(str_glob.nl), "NS",  &(str_glob.ns), 0);
		    sprintf(c_string, "OUT-File will fit to %s ...",str_glob.fittofile_name);
     		    zvmessage(c_string,"");
		    }

    str_glob.long_axis=0.;

/*---------------------------------------------------------------	
	Allocation for geometric calibration information				
	------------------------------------------------------	*/
		
	str_glob.xcal = (double *) malloc (MAX_PIXEL_PER_LINE*sizeof(double));
	if (str_glob.xcal == (double *)NULL) 
		{    	
		sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
		sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
		zabend();
		}
	str_glob.ycal = (double *) malloc (MAX_PIXEL_PER_LINE*sizeof(double));
	if (str_glob.ycal == (double *)NULL)
		{    	
		sprintf(outstring, "Allocation-error during call of malloc !!");
     		zvmessage(outstring,"");
		sprintf(outstring, "Not enough RAM available !!");
     		zvmessage(outstring,"");
		zabend();
		}

	/*-------------------------------------------------------------
	Open, read and close gcal-files			
	----------------------------------------------------------*/	
	hrorcgcl ( str_glob.geocal_dir, str_glob.h_geocal_version, 
		   str_glob.spacecraft_name, 
		   str_glob.ins_id,     str_glob.det_id,           str_glob.gcal_filename,
		   str_glob.xcal,       str_glob.ycal,		   &(str_glob.focal),		   &(str_glob.non_active_pixel_start)); 


	str_glob.ignore_min = (double)
         		((double)(str_glob.fp-str_glob.non_active_pixel_start-1) + 
			0.01 * str_glob.ignore * (double)(str_glob.nof_inp_s*str_glob.macro) * 0.5);
	str_glob.ignore_max = (double)
         		((double)(str_glob.fp-str_glob.non_active_pixel_start-1) + 
			(double)(str_glob.nof_inp_s*str_glob.macro) - (str_glob.ignore_min-(str_glob.fp-str_glob.non_active_pixel_start-1)));


	str_glob.nof_inp_l -= (str_glob.sl_inp-1);
	if (str_glob.nl_inp != 0) str_glob.nof_inp_l=str_glob.nl_inp;

	hrrdpref( str_glob.inunit, str_glob.sl_inp - 1 + str_glob.nof_inp_l/2, &HR_Prefix);
	temp_float	=	(float)(str_glob.nof_inp_s/2);
	ccd  		= 	hwpixnum(temp_float, str_glob.macro, str_glob.fp, 1); 
	pixnum2ccd (&str_glob, &ccd);

	if (str_glob.use_extori)
		{
		checkl = str_glob.sl_inp - 1 + str_glob.nof_inp_l/2;
		while (checkl >= str_glob.sl_inp - 1)
			{
			if (fabs (str_glob.kappa[checkl]) <= 400.) break;
			checkl--;
			}
		if (checkl < (str_glob.sl_inp - 1))
			{
			checkl = str_glob.sl_inp - 1 + str_glob.nof_inp_l/2;
			while (checkl < (str_glob.sl_inp - 1 + str_glob.nof_inp_l))
				{
				if (fabs (str_glob.kappa[checkl]) <= 400.) break;
				checkl++;
				}
			if (checkl >= (str_glob.sl_inp - 1 + str_glob.nof_inp_l))
				{    	
				sprintf(outstring, "Not even one proper extori-line !!");
     			zvmessage(outstring,"");
				zabend();
				}
			}
		
		positn[0]=str_glob.xyz0[checkl]/1000.0;
		positn[1]=str_glob.xyz1[checkl]/1000.0;
		positn[2]=str_glob.xyz2[checkl]/1000.0;
		}
	else
		{
		callfunc = hrviewpa 	(str_glob.target_name, str_glob.spacecraft_name, str_glob.ins_name, 
				HR_Prefix.EphTime, 1, &ccd, str_glob.xcal, str_glob.ycal, str_glob.focal, positn, tempMDirView);
		if (callfunc != 1)
			{
			printf ("ERROR %d in hrviewpa !\n", callfunc);
			zabend();
			}	
		}
	xyz2ll_centric (positn, str_glob.ll);			    /* ll centric radians */
	    
/*----------------------------------------------------------------	
	Get POSITIVE_LONGITUDE_DIRECTION-interface (str_glob.poslongdir_fac)
	between dlrsurfpt's longitudes (allways positive EAST) and the 
	user defined POSITIVE_LONGITUDE_DIRECTION (may be positive WEST)					
	-------------------------------------------------------	*/
	str_glob.poslongdir_fac = 1.;
	callfunc = mpGetValues ( mp_obj, mpPOSITIVE_LONGITUDE_DIRECTION, poslongdir, NULL); 
	if (strcmp(poslongdir, "WEST")==0) str_glob.poslongdir_fac = -1.;

	    
	if ((str_glob.ll[0]>(-PI/2.0+0.0000001))&&(str_glob.ll[0]<(PI/2.0-0.0000001)))	    
	str_glob.ll[0] = (atan (str_glob.axes[0]*str_glob.axes[0]/(str_glob.axes[2]*str_glob.axes[2])
		 *tan (str_glob.ll[0])));			    /* lat graphic radians */
	str_glob.ll[0]=str_glob.ll[0]*my_pi2deg;			    /* lat graphic degrees */   
	str_glob.ll[1]=str_glob.ll[1]*my_pi2deg*str_glob.poslongdir_fac;    /* lon graphic degrees */
	if (str_glob.ll[1]<0.0)str_glob.ll[1]+=360.0;

    	if (str_glob.poslongdir_fac==-1) 
		{
		printf ("Image center (nadir-point) at %lf (graphic)  latitude  and\n",str_glob.ll[0]);
		printf ("                           at %lf (pos.East) longitude  \n",360.0-str_glob.ll[1]);
		}
    	else 
		{
		printf ("Image center (nadir-point) at %lf (graphic)  latitude  and\n",str_glob.ll[0]);
		printf ("                           at %lf (pos.East) longitude  \n",str_glob.ll[1]);
		}

	callfunc = mpGetValues ( mp_obj, mpMAP_PROJECTION_TYPE, c_temp, NULL);
	strncpy (str_glob.mptype, c_temp, mpMAX_KEYWD_LENGTH);

/*--------------------------------------------------------------	*/
/* Check for set center_longitude and center_latitude		*/
/*--------------------------------------------------------------	*/
	callfunc = mpGetValues ( mp_obj, mpCENTER_LATITUDE, &(str_glob.cenlat), NULL);
	if (callfunc == mpKEYWORD_NOT_SET)  
	    {
		if (strcmp(str_glob.spacecraft_name,"MGS")) /* HRSC standard case: check for ><+-85 deg */
			{
			callfunc = find_hist_key (str_glob.inunit, "CENTRIC_LATITUDE_AT_CENTER", TRUE, task_name, &instance);
			callfunc = zlget (str_glob.inunit, "HISTORY", "CENTRIC_LATITUDE_AT_CENTER", &r_temp, "HIST", task_name, "INSTANCE", instance,  "FORMAT", "REAL", 0 );
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
	    	str_glob.cenlat=(double)((int)(str_glob.ll[0]*10.0+0.5))/10.0;
	    	callfunc = mpSetValues (mp_obj, mpCENTER_LATITUDE, str_glob.cenlat, NULL);
	    	sprintf(outstring, "CENTER_LATITUDE is set to %7.1lf by HRORTHO !", str_glob.cenlat);
     	    zvmessage(outstring,"");
			}
	    }
	callfunc = mpGetValues ( mp_obj, mpCENTER_LONGITUDE, &(str_glob.cenlong), NULL);
	if (callfunc == mpKEYWORD_NOT_SET)  
	    {
		if (strcmp(str_glob.spacecraft_name,"MGS")) /* HRSC standard case: use label entry */
			{
			if (fabs(str_glob.cenlat) > 89.) 
				{
	    		str_glob.cenlong=0.0;
	   	 		callfunc = mpSetValues (mp_obj, mpCENTER_LONGITUDE, str_glob.cenlong, NULL);
	    		sprintf(outstring, "CENTER_LONGITUDE is set to %7.1lf !", str_glob.cenlong);
     	    	zvmessage(outstring,"");
				}
			else
				{
				callfunc = find_hist_key (str_glob.inunit, "EASTERN_LONGITUDE_AT_CENTER", TRUE, task_name, &instance);
				callfunc = zlget (str_glob.inunit, "HISTORY", "EASTERN_LONGITUDE_AT_CENTER", &r_temp, "HIST", task_name, "INSTANCE", instance,"FORMAT", "REAL", 0 );
				if (callfunc != 1)
	    			{
	    			zvmessage(" History item EASTERN_LONGITUDE_AT_CENTER missing ! Please set CENTER_LONGITUDE !!","");
	    			zabend();
	    			}
				str_glob.cenlong = (double)((int)(r_temp * str_glob.poslongdir_fac + 0.5));
				if (str_glob.cenlong<0.0)str_glob.cenlong+=360.0;
	   	 		callfunc = mpSetValues (mp_obj, mpCENTER_LONGITUDE, str_glob.cenlong, NULL);
	    		sprintf(outstring, "CENTER_LONGITUDE is set to %7.1lf !", str_glob.cenlong);
     	    	zvmessage(outstring,"");
				}
			}
		else
			{
	    	str_glob.cenlong=(double)((int)(str_glob.ll[1]*10.0+0.5))/10.0;
	   	 	callfunc = mpSetValues (mp_obj, mpCENTER_LONGITUDE, str_glob.cenlong, NULL);
	    	sprintf(outstring, "CENTER_LONGITUDE is set to %7.1lf !", str_glob.cenlong);
     	    zvmessage(outstring,"");
			}
	    }

	if (strcmp(str_glob.mptype, "ORTHOGRAPHIC")==0)		str_glob.critical_projection = -1;
	else if ((strcmp(str_glob.mptype, "LAMBERT_AZIMUTHAL")==0) ||
		 (strcmp(str_glob.mptype, "STEREOGRAPHIC")==0))	str_glob.critical_projection = 0;
	else if ((strcmp(str_glob.mptype, "SINUSOIDAL")==0) ||
		 (strcmp(str_glob.mptype, "EQUIDISTANT")==0) ||
		 (strcmp(str_glob.mptype, "CYLINDRICAL_EQUAL_AREA")==0))	str_glob.critical_projection = 1;
	else if  (strcmp(str_glob.mptype, "MERCATOR")==0) str_glob.critical_projection = 2;
	else str_glob.critical_projection = 99;

	callfunc = dlr_earth_map_get_prefs (mp_obj, &prefs);
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	
/*----------------------------------------------------------------	
	Fill PHO-Data Object					
	-------------------------------------------------------	*/
  	if (str_glob.phocorr != 0)
		{
  		callfunc = phoInit( &(str_glob.pho_obj));
  		callfunc = phoGetParms( str_glob.pho_obj);
		}

/*----------------------------------------------------------------	
	Check for user defined scale/resolution					
	-------------------------------------------------------	*/
	if (str_glob.geom==1) 	for (i=0;i<3;i++) str_glob.dtm_axes[i] = str_glob.axes[i];
	else 
		{
		str_glob.dtm_axes[0] = (double)(str_glob.dtmlabel.dtm_a_axis_radius);
		str_glob.dtm_axes[1] = (double)(str_glob.dtmlabel.dtm_b_axis_radius);
		str_glob.dtm_axes[2] = (double)(str_glob.dtmlabel.dtm_c_axis_radius);
		}

	str_glob.scale_not_set = 0;

	callfunc = mpGetValues ( mp_obj, mpMAP_SCALE, &(str_glob.scale_resolution), NULL);

	if ((callfunc == mpKEYWORD_NOT_SET) ||
	    ((str_glob.scale_resolution  > -0.000001) && (str_glob.scale_resolution  < 0.000001)))
		{
		/*-----------------------------------------------------	
		no user defined scale or resolution					
		-------------------------------------------------------	*/
		if (strcmp(str_glob.spacecraft_name,"MGS")) /* HRSC case: use standard scale */
			{
			callfunc = find_hist_key (str_glob.inunit, "BEST_GROUND_SAMPLING_DISTANCE", TRUE, task_name, &instance);
			callfunc = zlget (str_glob.inunit, "HISTORY", "BEST_GROUND_SAMPLING_DISTANCE", &r_temp, "HIST", task_name, "INSTANCE", instance, "FORMAT", "REAL", 0 );
			if (callfunc != 1)
	    		{
	    		zvmessage(" History item BEST_GROUND_SAMPLING_DISTANCE missing ! Please set MP_SCALE !!","");
	    		zabend();
	    		}
			d_temp = (double)r_temp;
			callfunc = hrgetstdscale (str_glob.det_id, d_temp, &(str_glob.scale_resolution));
			if (callfunc != 1)
	    		{
				sprintf(outstring, "Error in hrgetstdscale: invalid DETECTOR_ID %s !", str_glob.det_id);
     			zvmessage(outstring,"");
	    		zabend();
	    		}
			}
		else callfunc = hw_rip_get_scale (&str_glob, mp_obj, prefs, prefs_dtm, dtmunit, &(str_glob.scale_resolution), dtm_buf);
		
	    if (strcmp(str_glob.spacecraft_name,"MGS") && (str_glob.match==1)) /* for HRSC matching (first file without fitto, e.g. nd */
			{
		 	str_glob.scale_resolution *= 2./(double)(str_glob.macro);
			} 

		callfunc = mpSetValues ( mp_obj, mpMAP_SCALE, str_glob.scale_resolution, NULL);
	    sprintf(outstring, "MAP_SCALE is set to %lf !", str_glob.scale_resolution);
     	zvmessage(outstring,"");
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
		Then, the previous call of mpGetValues whould have given back
		a value for MAP_SCALE although it is NOT within the mp_obj !!				
		But note: mp_routines (e.g. mpSphere) need MAP_SCALE
			  for its computations ! 
		
		Set scale value using mpSetValues
		to be sure that scale is stored in the mp_obj.
		-------------------------------------------------------	*/
		callfunc = mpSetValues ( mp_obj, mpMAP_SCALE, str_glob.scale_resolution, NULL);
		}


	callfunc = dlr_earth_map_get_prefs (mp_obj, &prefs);
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	



	if (str_glob.geom) 
    		{
    		if (str_glob.fittofile==1)
			{
			callfunc = find_hist_key (fit_unit, "REFERENCE_HEIGHT", TRUE, task_name, &instance);
			callfunc = zlget (fit_unit, "HISTORY", 
				"REFERENCE_HEIGHT", &r_temp,  "HIST", task_name, "INSTANCE", instance, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
			if (callfunc != 1)
	    			{
	    			sprintf(outstring, "No Label item REFERENCE_HEIGHT in FITTOFILE %s !!",str_glob.fittofile_name);
     	    			zvmessage(outstring,"");
	    			sprintf(outstring, "=> checking FITTOFILE as a DTM-File ...");
     	    			zvmessage(outstring,"");
	    			callfunc = hwdtmrl(fit_unit, &(fitto_dtmlabel));
	    			if (callfunc != 1)
	    				{
	    				sprintf(outstring, "No DTM-file !!");
     	    				zvmessage(outstring,"");
	    				zabend();
	    				}
	   			str_glob.height = ((double)fitto_dtmlabel.dtm_minimum_dn * fitto_dtmlabel.dtm_scaling_factor + (double)fitto_dtmlabel.dtm_offset);
	    			}
			else	str_glob.height = (double)r_temp;
 
			printf ("used from FITTOFILE: fix height %6.1lf meter above ellipsoid ...\n",str_glob.height);
			}
    		else
			{
			if (str_glob.height<-999990.0)
	    			{
	    			sprintf(outstring, "No fix height above sea level defined by DTM-Parameter !!");
     	    			zvmessage(outstring,"");
	    			zabend();
	    			}
			printf ("=> given by DTM-Parameter: fix height %6.1lf meter above ellipsoid is used ...\n",str_glob.height);
			}
    		}
		
 	callfunc = mpGetValues ( mp_obj, mpCARTESIAN_AZIMUTH, &cart_az, NULL); 
    	if (str_glob.fittofile==0)
		{
		if 	(
           		(((int)(cart_az+0.01)-999)==0)
           		||
	   		((str_glob.match==1)&&(callfunc == mpKEYWORD_NOT_SET))
           		)  
			{

			hrrdpref( str_glob.inunit, str_glob.sl_inp, &HR_Prefix);
			temp_float	=	(float)(str_glob.nof_inp_s/2);
			ccd  		= 	hwpixnum(temp_float, str_glob.macro, str_glob.fp, 1); 
			pixnum2ccd (&str_glob, &ccd);

			if (str_glob.use_extori)
				{
				checkl = str_glob.sl_inp - 1;
				while (checkl < (str_glob.sl_inp - 1 + str_glob.nof_inp_l))
					{
					if (fabs (str_glob.kappa[checkl]) <= 400.) break;
					checkl++;
					}
				if (checkl >= (str_glob.sl_inp - 1 + str_glob.nof_inp_l))
					{
					sprintf(outstring, "Not even one proper extori-line !!");
     				zvmessage(outstring,"");
					zabend();
					}

				positn[0]=str_glob.xyz0[checkl]/1000.0;
				positn[1]=str_glob.xyz1[checkl]/1000.0;
				positn[2]=str_glob.xyz2[checkl]/1000.0;
				}
			else
				{
				callfunc = hrviewpa 	(str_glob.target_name, str_glob.spacecraft_name, str_glob.ins_name, 
						HR_Prefix.EphTime, 1, &ccd, str_glob.xcal, str_glob.ycal, str_glob.focal, positn, tempMDirView);
				if (callfunc != 1)
					{
					printf ("ERROR %d in hrviewpa !\n", callfunc);
					zabend();
					}	
				}
	
			xyz2ll_centric (positn, ll_start);			    /* ll centric radians */
	    
			if ((ll_start[0]>(-PI/2.0+0.0000001))&&(ll_start[0]<(PI/2.0-0.0000001)))	    
			ll_start[0] = (atan (str_glob.axes[0]*str_glob.axes[0]/(str_glob.axes[2]*str_glob.axes[2])
		 		*tan (ll_start[0])));			    /* lat graphic radians */
			ll_start[0]=ll_start[0];			    /* lat graphic degrees */   
			ll_start[1]=ll_start[1];    /* lon graphic east degrees */
			if (ll_start[1]<0.0)ll_start[1]+=2.0*PI;

			hrrdpref( str_glob.inunit, str_glob.sl_inp + str_glob.nof_inp_l - 1, &HR_Prefix);
			temp_float	=	(float)(str_glob.nof_inp_s/2);
			ccd  		= 	hwpixnum(temp_float, str_glob.macro, str_glob.fp, 1); 
			pixnum2ccd (&str_glob, &ccd);

			if (str_glob.use_extori)
				{
				checkl = str_glob.sl_inp + str_glob.nof_inp_l - 1 - 1;
				while (checkl >= (str_glob.sl_inp - 1))
					{
					if (fabs (str_glob.kappa[checkl]) <= 400.) break;
					checkl--;
					}
				if (checkl < (str_glob.sl_inp - 1))
					{
					sprintf(outstring, "Not even one proper extori-line !!");
     				zvmessage(outstring,"");
					zabend();
					}

				positn[0]=str_glob.xyz0[checkl]/1000.0;
				positn[1]=str_glob.xyz1[checkl]/1000.0;
				positn[2]=str_glob.xyz2[checkl]/1000.0;
				}
			else
				{
				callfunc = hrviewpa 	(str_glob.target_name, str_glob.spacecraft_name, str_glob.ins_name, 
						HR_Prefix.EphTime, 1, &ccd, str_glob.xcal, str_glob.ycal, str_glob.focal, positn, tempMDirView);
				if (callfunc != 1)
					{
					printf ("ERROR %d in hrviewpa !\n", callfunc);
					zabend();
					}	
				}
	
			xyz2ll_centric (positn, ll_end);			    /* ll centric radians */
	    
			if ((ll_end[0]>(-PI/2.0+0.0000001))&&(ll_end[0]<(PI/2.0-0.0000001)))	    
			ll_end[0] = (atan (str_glob.axes[0]*str_glob.axes[0]/(str_glob.axes[2]*str_glob.axes[2])
		 		*tan (ll_end[0])));			    /* lat graphic radians */
			ll_end[0]=ll_end[0];			    /* lat graphic degrees */   
			ll_end[1]=ll_end[1];    /* lon graphic east degrees */
			if (ll_end[1]<0.0)ll_end[1]+=2.0*PI;
			cart_az = 180.0- atan2 	(
			       			ll_end[1]-ll_start[1],
			       			log ( tan (PI/4.0 + ll_end[0]/2.0))
			        		- log ( tan (PI/4.0 + ll_start[0]/2.0))
			       			)*my_pi2deg;
			cart_az = (double)((int)(cart_az*1000.0))/1000.0;
			callfunc = mpSetValues ( mp_obj, mpCARTESIAN_AZIMUTH, cart_az, NULL); 
			}
		}

	sprintf(outstring, "CARTESIAN_AZIMUTH is set to %10.3lf !", cart_az);
     	zvmessage(outstring,"");
	str_glob.border=0;
/*--------------------------------------------------------------------	
	Computation of location and size of the new rectified image	
	-------------------------------------------------------------*/

/*POLE	str_glob.pole=0;*/

	str_glob.first_inp_l_part = str_glob.sl_inp-1 + 1;
	str_glob.nof_inp_l_part = str_glob.nof_inp_l;
	str_glob.parts = 0;	

	str_glob.nof_out_s = str_glob.ns;
	str_glob.nof_out_l = str_glob.nl;

	callfunc = hworloc_rip (&str_glob, mp_obj, prefs, prefs_dtm, dtmunit, dtm_buf);
 	if  (callfunc == -998) 
			{
			sprintf(outstring, "Allocation-error during call of malloc !!");
     			zvmessage(outstring,"");
			sprintf(outstring, "Not enough RAM available !!");
     			zvmessage(outstring,"");
			callfunc = zvclose (str_glob.inunit, 0);
			zabend();
			}
	str_glob.parts = 1;	

	if (str_glob.phocorr != 0) 
	    {
	    zhwgetsun (HR_Prefix.EphTime, str_glob.target_id, str_glob.MDirInc);
	    zhwllnorm(str_glob.ll[0]/my_pi2deg, str_glob.ll[1]/my_pi2deg, str_glob.axes, str_glob.long_axis, str_glob.DirEll);
	    str_glob.pho_calc_done=0;
	    }
	else str_glob.pho_calc_done=1;


	callfunc = dlr_earth_map_get_prefs (mp_obj, &prefs);
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	

/*--------------------------------------------------------------------
	Open Output-file 	
	-------------------------------------------------------------*/	
	callfunc = zvunit (&(str_glob.outunit), "anything3",  1, "U_NAME", str_glob.out_filename, 0);

	callfunc = zvget (str_glob.inunit, "FORMAT",  informat, 0);
	if (strcmp(informat, "BYTE") == 0)
			{
			str_glob.oformat = 1;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "BYTE", 0);

			/*--------------------------------------------------------------------	
			PROPERTY label (PROPERTY MAP)								
			-------------------------------------------------------------*/
			callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", prefs);				
			if (callfunc != mpSUCCESS) 
				{    	
				sprintf(outstring, "Error in dlr_mpLabelWrite !!");
     				zvmessage(outstring,"");
				zabend();
				}
				
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "anything3",  1, "U_NAME", str_glob.out_filename, 0);

			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "BYTE", 0);

			}
	else if (strcmp(informat, "HALF") == 0)
			{
			str_glob.oformat = 2;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "HALF", 0);

			/*--------------------------------------------------------------------	
			PROPERTY label (PROPERTY MAP)								
			-------------------------------------------------------------*/
			callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", prefs);				
			if (callfunc != mpSUCCESS) 
				{    	
				sprintf(outstring, "Error in dlr_mpLabelWrite !!");
     				zvmessage(outstring,"");
				zabend();
				}
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "anything3",  1, "U_NAME", str_glob.out_filename, 0);

			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "HALF", 0);
			}
	else if (strcmp(informat, "FULL") == 0)
			{
			str_glob.oformat = 3;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "FULL", 0);

			/*--------------------------------------------------------------------	
			PROPERTY label (PROPERTY MAP)								
			-------------------------------------------------------------*/
			callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", prefs);				
			if (callfunc != mpSUCCESS) 
				{    	
				sprintf(outstring, "Error in dlr_mpLabelWrite !!");
     				zvmessage(outstring,"");
				zabend();
				}
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "anything3",  1, "U_NAME", str_glob.out_filename, 0);

			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "FULL", 0);
			}
	else if (strcmp(informat, "REAL") == 0)
			{
			str_glob.oformat = 4;
			check_size(&str_glob);
			callfunc = zvopen (str_glob.outunit, 
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "WRITE", "OPEN_ACT", "SA", "U_FORMAT", "REAL", 0);

			/*--------------------------------------------------------------------	
			PROPERTY label (PROPERTY MAP)								
			-------------------------------------------------------------*/
			callfunc = dlr_mpLabelWrite(mp_obj, str_glob.outunit, "PROPERTY", prefs);				
			if (callfunc != mpSUCCESS) 
				{    	
				sprintf(outstring, "Error in dlr_mpLabelWrite !!");
     				zvmessage(outstring,"");
				zabend();
				}
			callfunc = zvclose (str_glob.outunit, 0);

			callfunc = zvunit (&(str_glob.outunit), "anything3",  1, "U_NAME", str_glob.out_filename, 0);

			callfunc = zvopen (str_glob.outunit,
			"U_NL", str_glob.nof_out_l, "U_NS", str_glob.nof_out_s,
			"OP", "UPDATE", "OPEN_ACT", "SA", "U_FORMAT", "REAL", 0);
			}

			if (str_glob.mp_radius_set)
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
	Open Match-files if requested 	
	-------------------------------------------------------------*/	
	if (str_glob.match !=0)
	    {
	    strcpy (c_temp,str_glob.out_filename);
	    strncat (c_temp,"_l",2);
	    strcpy (c_temp2,str_glob.out_filename);
	    strncat (c_temp2,"_s",2);

		str_glob.index_x = (long *) calloc (str_glob.nof_out_l, sizeof(long));
		if (str_glob.index_x == (long *)NULL)
			{
			sprintf(outstring, "Error during allocation of index for new_match_x_buf!!");
     			zvmessage(outstring,"");
			zabend();
			}
		str_glob.new_match_x_unit = fopen (c_temp,"w+b");
		if (str_glob.new_match_x_unit==(FILE *)NULL)
			{
			sprintf(outstring, "Error during creation of new_match_x_buf-file!!");
     			zvmessage(outstring,"");
			zabend();
			}
		callfunc =  init_reffile_for_creation (str_glob.new_match_x_unit, str_glob.nof_out_l, str_glob.nof_out_s, str_glob.index_x);
		if (callfunc < 0)
			{
			printf ("init_reffile_for_creation error: %d !\n",callfunc);
			zabend();
			}

		str_glob.index_y = (long *) calloc (str_glob.nof_out_l, sizeof(long));
		if (str_glob.index_y == (long *)NULL)
			{
			sprintf(outstring, "Error during allocation of index for new_match_y_buf!!");
     			zvmessage(outstring,"");
			zabend();
			}
		str_glob.new_match_y_unit = fopen (c_temp2,"w+b");
		if (str_glob.new_match_y_unit==(FILE *)NULL)
			{
			sprintf(outstring, "Error during creation of new_match_y_buf-file!!");
     			zvmessage(outstring,"");
			zabend();
			}
		callfunc =  init_reffile_for_creation (str_glob.new_match_y_unit, str_glob.nof_out_l, str_glob.nof_out_s, str_glob.index_y);
		if (callfunc < 0)
			{
			printf ("init_reffile_for_creation error: %d !\n",callfunc);
			zabend();
			}
	    }

/*--------------------------------------------------------------	*/
/*	Initialize output-image						*/
/*--------------------------------------------------------------	*/
  	printf ("\nInitializing total output file ... \n");

	if (str_glob.oformat == 1)
			{
	    		gv_out_buf_byte = (myBYTE *) calloc (1,str_glob.nof_out_s*sizeof(myBYTE));
			str_glob.no_info_val = 0.;
			for (i=1;i<=str_glob.nof_out_l;i++)
				callfunc = zvwrit (str_glob.outunit, gv_out_buf_byte,
					"LINE", i, "SAMP", 1, 0);
			free (gv_out_buf_byte);
			}
	else if (str_glob.oformat == 2)
			{
	    		gv_out_buf_half = (short int *) calloc (1,str_glob.nof_out_s*sizeof(short int));
			str_glob.no_info_val = -32768.;
			for (i=0;i<str_glob.nof_out_s;i++) 
				gv_out_buf_half[i] = (short int)str_glob.no_info_val;
			for (i=1;i<=str_glob.nof_out_l;i++)
				callfunc = zvwrit (str_glob.outunit, gv_out_buf_half,
					"LINE", i, "SAMP", 1, 0);
			free (gv_out_buf_half);
			}
	else if (str_glob.oformat == 3)
			{
	    		gv_out_buf_full = (int *) calloc (1,str_glob.nof_out_s*sizeof(int));
			str_glob.no_info_val = -32768.;
			for (i=0;i<str_glob.nof_out_s;i++) 
				gv_out_buf_full[i] = (int)str_glob.no_info_val;
			for (i=1;i<=str_glob.nof_out_l;i++)
				callfunc = zvwrit (str_glob.outunit, gv_out_buf_full,
					"LINE", i, "SAMP", 1, 0);
			free (gv_out_buf_full);
			}
	else if (str_glob.oformat == 4)
			{
	    		gv_out_buf_float = (float *) calloc (1,str_glob.nof_out_s*sizeof(float));
			str_glob.no_info_val = -99999.9;
			for (i=0;i<str_glob.nof_out_s;i++) 
				gv_out_buf_float[i] = str_glob.no_info_val;
			for (i=1;i<=str_glob.nof_out_l;i++)
				callfunc = zvwrit (str_glob.outunit, gv_out_buf_float,
					"LINE", i, "SAMP", 1, 0);
			free (gv_out_buf_float);
			}

/*--------------------------------------------------------------	*/
/*	Partitions of output-image					*/
/*--------------------------------------------------------------	*/

	if (str_glob.oformat == 1)      out_buf_size=(double)str_glob.nof_out_s*(double)str_glob.nof_out_l*(double)sizeof(myBYTE);
	else if (str_glob.oformat == 2) out_buf_size=(double)str_glob.nof_out_s*(double)str_glob.nof_out_l*(double)sizeof(short int);
	else if (str_glob.oformat == 3) out_buf_size=(double)str_glob.nof_out_s*(double)str_glob.nof_out_l*(double)sizeof(int);
	else if (str_glob.oformat == 4) out_buf_size=(double)str_glob.nof_out_s*(double)str_glob.nof_out_l*(double)sizeof(float);

	if (str_glob.match != 0) 
		match_buf_size = (double)str_glob.nof_out_s*(double)str_glob.nof_out_l*(double)sizeof(float);
	else	
		match_buf_size = 0.;
	
	red_fac = 1.0;
	reduced_ram = 0;
	if (out_buf_size > 1024.*1024.*1024.) 
		{
		red_fac = 1024.*1024.*1024. / out_buf_size;
		reduced_ram=1;
		}
	if (match_buf_size*red_fac > 1024.*1024.*1024.) 
		{
		red_fac *= (1024.*1024.*1024. / match_buf_size);
		reduced_ram=1;
		}

	check_out_buf_size = (out_buf_size + match_buf_size*2.)*red_fac;

	if (str_glob.ram_set && (check_out_buf_size>(str_glob.ram_use*1024.*1024.))) 
		{
		red_fac *= (str_glob.ram_use*1024.*1024.)/check_out_buf_size;
		check_out_buf_size *= red_fac;
		reduced_ram=1;
		}

	i=0;
 	do
	  {
	  gv_out_buf_float= (float *) malloc (((int)check_out_buf_size-i*4*1024*1024));
	  i++;
	  } while (gv_out_buf_float == (float *)NULL);
	free (gv_out_buf_float);

	if (i!=1) 
		{
		red_fac *= (check_out_buf_size-(double)((i-1)*4*1024*1024))/check_out_buf_size;
		reduced_ram=1;
		}

	if (reduced_ram)
	    {
	    str_glob.nof_parts = (int)(1.0/red_fac)+1;
            str_glob.first_inp_l_part  = str_glob.first_used_l;
            str_glob.nof_inp_l_part = (str_glob.last_used_l - str_glob.first_used_l + 1)/str_glob.nof_parts + 2*str_glob.anchdist;
	    printf ("\nNot Enough RAM for allocation of total output file !\n");
	    printf ("Output file will be calculated in  %d  parts ...\n", str_glob.nof_parts);
	    }		
	else     
	    {
	    printf ("\nEnough RAM for allocation of total output file !\n");
	    str_glob.nof_parts         = 1;
            str_glob.first_inp_l_part  = str_glob.first_used_l;
            str_glob.nof_inp_l_part    = str_glob.last_used_l - str_glob.first_used_l + 1;
	    str_glob.first_out_l_part  = 1;
	    str_glob.first_out_s_part  = 1;
	    str_glob.nof_out_l_part   = str_glob.nof_out_l;
	    str_glob.nof_out_s_part   = str_glob.nof_out_s;
	    }
	
/*--------------------------------------------------------------------
	Computation of the new rectified image					
	-------------------------------------------------------------*/

	printf ("\nGenerating output data ... \n\n");
	for (i=1;i<=str_glob.nof_parts;i++)
		{
		if (str_glob.nof_parts>1) 
			{
			if ((str_glob.first_inp_l_part + str_glob.nof_inp_l_part - 1) > str_glob.last_used_l)
				str_glob.nof_inp_l_part = str_glob.last_used_l - str_glob.first_inp_l_part + 1;

			printf ("\nPart %d:\n", i);
 			printf ("(Input lines %d to %d of total %d)\n", 
				str_glob.first_inp_l_part,str_glob.first_inp_l_part+str_glob.nof_inp_l_part-1, str_glob.last_used_l);

			callfunc = hworloc_rip (&str_glob, mp_obj, prefs, prefs_dtm, dtmunit, dtm_buf);

			if (
			   ((int)(str_glob.minx)>str_glob.nof_out_l) ||
			   ((int)(str_glob.maxx)<1) ||
			   ((int)(str_glob.miny)>str_glob.nof_out_s) ||
			   ((int)(str_glob.maxy)<1) 
			   ) {
			     printf ("not in Output-File !\n");
			     str_glob.first_inp_l_part += (str_glob.nof_inp_l_part-2*str_glob.anchdist);
			     continue;
			     }
		
			str_glob.first_out_s_part = (int)(str_glob.miny);
 			str_glob.first_out_l_part = (int)(str_glob.minx);
			if ((str_glob.first_out_s_part<1) || (str_glob.new_match_type))
 				str_glob.first_out_s_part=1;
			if (str_glob.first_out_l_part<1) str_glob.first_out_l_part=1;

			str_glob.nof_out_s_part = (int)(str_glob.maxy+0.5) - str_glob.first_out_s_part + 1;
 			str_glob.nof_out_l_part = (int)(str_glob.maxx+0.5) - str_glob.first_out_l_part + 1;
			if (((str_glob.first_out_s_part + str_glob.nof_out_s_part - 1)>str_glob.nof_out_s) || (str_glob.new_match_type))  
				str_glob.nof_out_s_part=str_glob.nof_out_s-str_glob.first_out_s_part+1;
			if ((str_glob.first_out_l_part + str_glob.nof_out_l_part - 1)>str_glob.nof_out_l)  
				str_glob.nof_out_l_part=str_glob.nof_out_l-str_glob.first_out_l_part+1;
			}

  		callfunc = hwgeorec_rip (&str_glob, mp_obj, prefs, prefs_dtm, dtmunit, dtm_buf);
	
		if (callfunc == -997)
			{		
			sprintf(outstring, "ABORT !! hrortho was not completed !!");
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
			callfunc = zvclose (str_glob.inunit, 0);
			callfunc = zvclose (str_glob.outunit, 0);
			zabend();
			}
		str_glob.first_inp_l_part += (str_glob.nof_inp_l_part-2*str_glob.anchdist);
		}

	if (str_glob.phocorr != 0) 
	  {
	  printf ("\nPhotometric correction values:\n");
	  for (i=0;i<str_glob.nof_inp_s;i=i+400) 
	    {
	    printf ("%6d ",i);
	    }
	  printf ("\n");
	  for (i=0;i<str_glob.nof_inp_s;i=i+400) 
	    {
	    printf ("%6.4lf ",str_glob.phoCorVal_vec[i/str_glob.anchdist]);
	    }
	  }

/*--------------------------------------------------------------------	
	Close dtm file								
	-------------------------------------------------------------*/

	if (!(str_glob.geom)) callfunc = zvclose (dtmunit, 0);

/*--------------------------------------------------------------------	
	Add labels to output image								
	-------------------------------------------------------------*/

/*--------------------------------------------------------------------	
	PROPERTY label (PROPERTY FILE)								
	-------------------------------------------------------------*/
	callfunc = zldel (str_glob.outunit, "PROPERTY", "FILE_NAME",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
	callfunc = zladd (str_glob.outunit, "PROPERTY", "FILE_NAME", str_glob.out_filename,
	    	"ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "FILE", 0 );
		
	callfunc = zldel (str_glob.outunit, "PROPERTY", "PRODUCT_ID",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
	callfunc = zladd (str_glob.outunit, "PROPERTY", "PRODUCT_ID", str_glob.out_filename,
	    	"ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "FILE", 0 );

	callfunc = zldel (str_glob.outunit, "PROPERTY", "PROCESSING_LEVEL_ID",
				"PROPERTY", "FILE", "ERR_ACT", " ", 0 );
        idum=3;                        
	callfunc = zladd (str_glob.outunit, "PROPERTY", "PROCESSING_LEVEL_ID", &idum,
	    	"ERR_ACT", "S", "FORMAT", "INT", "PROPERTY", "FILE", 0 );
	
/*--------------------------------------------------------------------	
	PROPERTY label (PROPERTY PHOT)								
	-------------------------------------------------------------*/
	callfunc = zvp("PHO_FUNC", c_temp32,  &count);

	callfunc = zladd (str_glob.outunit, "PROPERTY", "PHO_FUNC", c_temp32,
	    "ERR_ACT", "S", "FORMAT", "STRING", "PROPERTY", "PHOT", 0 );
/*--------------------------------------------------------------------	
	HISTORY label (general parameters)									
	-------------------------------------------------------------*/
/*
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INPUT_FILE_NAME_1", str_glob.inp_filename, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INPUT_FILE_TYPE_1", "IMAGE", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
*/

 	if (str_glob.geom)
		{
		r_temp= (float)str_glob.height;
		callfunc = zladd (str_glob.outunit, "HISTORY",
		"REFERENCE_HEIGHT", &r_temp, "ERR_ACT", "S", "FORMAT", "REAL", 0 );
		}
	else
		{
 		callfunc = zladd (str_glob.outunit, "HISTORY",
	    	"DTM_NAME", str_glob.dtm_filename, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
		}
	    
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "START_INPUT_LINE", &(str_glob.sl_inp), "ERR_ACT", "S", "FORMAT", "INT", 0 );
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "NUMBER_OF_INPUT_LINES", &(str_glob.nof_inp_l), "ERR_ACT", "S", "FORMAT", "INT", 0 );

	callfunc = zvget (str_glob.inunit, "NL",  &(str_glob.nof_inp_l), 
			       "NS",  &(str_glob.nof_inp_s), 0); 

	if (str_glob.match !=0 )
	    {
		callfunc = prepare_reffile_for_initclose (str_glob.new_match_x_unit, str_glob.nof_out_l, str_glob.index_x, 
					      str_glob.sl_inp, str_glob.nof_inp_l, eins, str_glob.nof_inp_s, str_glob.inp_filename);
		if (callfunc < 0)
			{
			printf ("prepare_reffile_for_initclose error: %d !\n",callfunc);
			zabend();
			}
		callfunc = prepare_reffile_for_initclose (str_glob.new_match_y_unit, str_glob.nof_out_l, str_glob.index_y, 
					      str_glob.sl_inp, str_glob.nof_inp_l, eins, str_glob.nof_inp_s, str_glob.inp_filename);
		if (callfunc < 0)
			{
			printf ("prepare_reffile_for_initclose error: %d !\n",callfunc);
			zabend();
			}
	    }

/*
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "MINIMUM_LONGITUDE", &str_glob.min_longi, "ERR_ACT", "S", "FORMAT", "DOUB", 0 );
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "MAXIMUM_LONGITUDE", &str_glob.max_longi, "ERR_ACT", "S", "FORMAT", "DOUB", 0 );
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "MINIMUM_LATITUDE", &str_glob.min_lati, "ERR_ACT", "S", "FORMAT", "DOUB", 0 );
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "MAXIMUM_LATITUDE", &str_glob.max_lati, "ERR_ACT", "S", "FORMAT", "DOUB", 0 );
*/

	if (str_glob.interpol_type == 0)  
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "NEAREST_NEIGHBOUR", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    }
	else if (str_glob.interpol_type == 1)
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "BILINEAR_INTERPOLATION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    }
	else if (str_glob.interpol_type == 2)
	    {
	    callfunc = zladd (str_glob.outunit, "HISTORY",
	    "INTERPOLATION_TYPE", "CUBIC_CONVOLUTION", "ERR_ACT", "S", "FORMAT", "STRING", 0 );
	    }
	    
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "ANCHORPOINT_DISTANCE", &(str_glob.anchdist), "ERR_ACT", "S", "FORMAT", "INT", 0 );

/*--------------------------------------------------------------------	
	HISTORY label (SPICE parameters)								
	-------------------------------------------------------------*/

 	if (str_glob.use_extori)
		{
		callfunc = zladd(str_glob.outunit,"HISTORY", 
                                 "EXTORI_FILE_NAME", extorifile, "FORMAT","STRING", "");
		}

/*
	callfunc = zladd (str_glob.outunit, "HISTORY",
	    "TARGET", str_glob.target_name, "ERR_ACT", "S", "FORMAT", "STRING", 0 );
*/

 	for (lauf=0; lauf <nof_kernel; lauf++)
                    callfunc = zladd(str_glob.outunit,"HISTORY", 
                                     "SPICE_FILE_NAME", kernel[lauf], 
                                     "FORMAT","STRING", "MODE", "INSERT",
                                     "ELEMENT", lauf+1, "");
 	
	callfunc = zladd(str_glob.outunit,"HISTORY", 
                                 "SPICE_FILE_ID", spice_file_id, 
                                 "FORMAT","STRING", "");
								 
    if (strcmp(str_glob.spacecraft_name,"MGS"))
		{
		callfunc = zladd(str_glob.outunit,"HISTORY", 
                                 "GEOMETRIC_CALIB_FILE_NAME", str_glob.gcal_filename, 
                                 "FORMAT","STRING", "");
		}
/*--------------------------------------------------------------------	
	free PHO-Data Object								
	-------------------------------------------------------------*/
 	if (str_glob.phocorr != 0)
		{
  		callfunc = phoFree (str_glob.pho_obj);
		}

/*--------------------------------------------------------------------	
	Close input file								
	-------------------------------------------------------------*/

	callfunc = zvclose (str_glob.inunit, 0);
/*--------------------------------------------------------------------	
	Close output file								
	-------------------------------------------------------------*/

	callfunc = zvclose (str_glob.outunit, 0);
	if (str_glob.match !=0 )
		{
		callfunc = fclose (str_glob.new_match_x_unit);
	    if (callfunc < 0)
				printf ("Error closing match_x_file: %d !!\n",callfunc);
		callfunc = fclose (str_glob.new_match_y_unit);
	    if (callfunc < 0)
				printf ("Error closing match_y_file: %d !!\n",callfunc);
		}

 	sprintf(outstring, "\nVICAR task hrortho completed ");
     	zvmessage(outstring,"");

	}

/*====================================================================*/
/* ---------------------------------------------------------------------------	*/
int which_sensor(char *name,char *sensor)
{
if      ((int)NULL==strcmp(name,"nd")) {strncpy(sensor,"nd",2); return 1;}
else if ((int)NULL==strcmp(name,"s1")) {strncpy(sensor,"s1",2); return 1;}
else if ((int)NULL==strcmp(name,"s2")) {strncpy(sensor,"s2",2); return 1;}
else if ((int)NULL==strcmp(name,"p1")) {strncpy(sensor,"p1",2); return 1;}
else if ((int)NULL==strcmp(name,"p2")) {strncpy(sensor,"p2",2); return 1;}
else if ((int)NULL==strcmp(name,"re")) {strncpy(sensor,"re",2); return 1;}
else if ((int)NULL==strcmp(name,"gr")) {strncpy(sensor,"gr",2); return 1;}
else if ((int)NULL==strcmp(name,"bl")) {strncpy(sensor,"bl",2); return 1;}
else if ((int)NULL==strcmp(name,"ir")) {strncpy(sensor,"ir",2); return 1;}
return 0;
}
/*--------------------------------------------------------------------	
	Internal (private) functions used in hrortho							
-------------------------------------------------------------*/

 

/*############################################################	*/
/* Get general hrortho-parameters (private)			*/
/*############################################################	*/
/* Calls from	hrortho					*/
/* Calling	zvp 						*/
/*############################################################	*/

	int hrortho_p (str_glob_type *str_glob)
/*############################################################	*/
	{
	char  c_interpol_type[3], outstring[120];
   	int   count, callfunc, i, j;
	float float_val;
	char  temp[2][120], c_temp32[32], *value, c_temp[2];

/*--------------------------------------------------------------------	
	All general parameters (exept INP, OUT and MP_TYPE)
	are read using the VICAR-RTL routine zvp
	Count gives the number of parameters which are got from TAE								
	-------------------------------------------------------------*/

	callfunc = zvp("MATCH", c_temp32, &count);
	if ((strncmp(c_temp32, "MATCH",4)==0)||(strncmp(c_temp32, "match",4)==0))
	    {
		str_glob->match=1;
		str_glob->new_match_type = 1;
		callfunc = zvp("PREC", &float_val, &count);
		str_glob->match_prec = (double)float_val;
		}
	else str_glob->match=0;
 

	callfunc = zvp("NL_OUT", &(str_glob->nl),  &count);
	callfunc = zvp("NS_OUT", &(str_glob->ns),  &count);
	callfunc = zvp("SL_INP", &(str_glob->sl_inp),  &count);
	callfunc = zvp("NL_INP", &(str_glob->nl_inp),  &count);

	callfunc = zvp("SWATH", &float_val,  &count);
	str_glob->ignore = 100. - (double)float_val;

	callfunc = zvp("IPOL", c_interpol_type,  &count);
	if (strcmp(c_interpol_type, "NN")==0)str_glob->interpol_type=0;
	if (strcmp(c_interpol_type, "BI")==0)str_glob->interpol_type=1;
	if (strcmp(c_interpol_type, "CC")==0)str_glob->interpol_type=2;

	callfunc = zvp("ANCHDIST", &(str_glob->anchdist),  &count);
	if (count<1)str_glob->anchdist=0;
	
	callfunc = zvp("BORDER", &(str_glob->border),  &count);

	callfunc = zvp("REPORT", str_glob->report, &count);

	callfunc = zvp("OUTMAX", &float_val, &count);
	str_glob->max_sof_outfile = (double)float_val;

	str_glob->ram_set=0;
	callfunc = zvp("RAM", &float_val, &count);
	if (count==1) {str_glob->ram_use = (double)float_val;str_glob->ram_set=1;}
	
	callfunc = zvp("PHO_FUNC", c_temp32,  &count);
	if (strcmp(c_temp32, "NONE") == 0) str_glob->phocorr = 0;
	else str_glob->phocorr = 1;

	callfunc = zvp("T_EMI_A", &float_val, &count);
	str_glob->TargViewAng = (double)float_val;
	
	callfunc = zvp("T_INC_A", &float_val, &count);
	str_glob->TargIncAng = (double)float_val;
	
	callfunc = zvp("T_AZI_A", &float_val, &count);
	str_glob->TargAzimAng = (double)float_val;

	str_glob->oformat = 0;
	
	callfunc = zvp("gcaldir", str_glob->geocal_dir, &count);
	if (count == 0) str_glob->geocal_dir[0]='\0';

	callfunc = zvp("ORI", c_temp32, &count);
	
	str_glob->use_extori = 1;
	if ((strncmp(c_temp32,"S",1)==0)||(strncmp(c_temp32,"s",1)==0))
		str_glob->use_extori = 0;  /* SPICE case */

	for (i=0;i<3;i++) str_glob->mp_axes[i]=0.0;
	callfunc = zvp("MP_RADIUS", &float_val,  &count);
	if (count > 0) 
		{
		for (i=0;i<3;i++) str_glob->mp_axes[i]=(double)float_val;
		str_glob->mp_radius_set = 1;
		}
	else 
		{
		for (i=0;i<3;i++) str_glob->mp_axes[i]=-1.0;
		str_glob->mp_radius_set = 0;
		}

	return (0);
	}
	
/*===================================================================*/
/*############################################################	*/
/* Get mission name and instrument id				*/
/*############################################################	*/
/* Calls from	hrortho					*/
/* Calling	zlget 						*/
/*############################################################	*/

	int hw_get_label_info (str_glob_type *str_glob)
/*############################################################	*/

	{
	int	   instance, callfunc, camera_number, itemp;
	char	   task_name[80], tmp_string[80], start_time[100];
	
	callfunc = zvget  (str_glob->inunit, "NL",  &(str_glob->nof_inp_l), 
			       "NS",  &(str_glob->nof_inp_s), "NBB",  &(str_glob->nbb), 0); 
	if (callfunc != 1) return (-1);

	callfunc = zlget  (str_glob->inunit, "PROPERTY", "INSTRUMENT_HOST_NAME", str_glob->spacecraft_name,
			  "PROPERTY","M94_INSTRUMENT", 0);
	if (callfunc != 1) 
		{
		callfunc = zlget  (str_glob->inunit, "PROPERTY", "SPACECRAFT_NAME", str_glob->spacecraft_name,
			  "PROPERTY","M94_INSTRUMENT", 0);
		if (callfunc != 1) return (-2);
		}
	
	if (strcmp(str_glob->spacecraft_name,"MARS EXPRESS")==0) strcpy(str_glob->spacecraft_name,"MARS_EXPRESS");

	if ((strcmp(str_glob->spacecraft_name,"MARS_EXPRESS")!=0)&&(strcmp(str_glob->spacecraft_name,"MGS")!=0))
		{
           printf("Unsupported Camera !\n");
           zabend();
 		}
/*	sprintf (str_glob->sig_chain_id,"%05d",itemp);*/


	if (strcmp(str_glob->spacecraft_name,"MGS")!=0) /* HRSC - case */
		{
		callfunc = zlget  (str_glob->inunit, "PROPERTY", "PROCESSING_LEVEL_ID", &itemp,
			  "PROPERTY","FILE", 0);
		if (callfunc != 1) return (-3);
        if (itemp != 2) 
           {
           printf("PROCESSING_LEVEL of input file must be 2, it is %d\n", itemp);
           zabend();
           }
		}

	callfunc = zlget  (str_glob->inunit, "PROPERTY", "INSTRUMENT_NAME", str_glob->ins_name,
			  "PROPERTY","M94_INSTRUMENT", 0);
	if (callfunc != 1) return (-4);

	if (strcmp(str_glob->ins_name,"HIGH RESOLUTION STEREO CAMERA")==0) strcpy(str_glob->ins_name,"HIGH_RESOLUTION_STEREO_CAMERA");
	
	callfunc = zlget  (str_glob->inunit, "PROPERTY", "SAMPLE_FIRST_PIXEL", &(str_glob->fp),
			  "PROPERTY","M94_CAMERAS", 0);
	if (callfunc != 1)
		{
		callfunc = zlget  (str_glob->inunit, "PROPERTY", "FIRST_PIXEL", &(str_glob->fp),
			  "PROPERTY","M94_CAMERAS", 0);
		if (callfunc != 1) return (-5);
		}
		
	if (strcmp(str_glob->spacecraft_name,"MGS")!=0)
		{
/*		callfunc = zlget  (str_glob->inunit, "PROPERTY", "FIRST_ACTIVE_PIXEL", &(str_glob->fap),
			  "PROPERTY","M94_CAMERAS", 0);
		if (callfunc != 1) return (-1); */
                str_glob->fap = 0;
		}
	else str_glob->fap= 0;

	callfunc = zlget  (str_glob->inunit, "PROPERTY", "MACROPIXEL_SIZE", &(str_glob->macro),
			  "PROPERTY","M94_CAMERAS", 0);
	if (callfunc != 1) 
		callfunc = zlget  (str_glob->inunit, "PROPERTY", "MACROPIXEL_FORMAT", &(str_glob->macro),
			  "PROPERTY","M94_CAMERAS", 0);

	if (callfunc != 1) return (-6);

/*	callfunc = zlget  (str_glob->inunit, "PROPERTY", "NUMBER_OF_ACTIVE_PIXELS", &(str_glob->nap),
			  "PROPERTY","M94_CAMERAS", 0);
	if (callfunc != 1) return (-1);
*/	
	if (strcmp(str_glob->spacecraft_name,"MGS"))
   		strcpy(str_glob->ins_id,"FM2");
	else   
  		{
 		callfunc = zlget  (str_glob->inunit, "PROPERTY", "INSTRUMENT_ID", str_glob->ins_id,
			  "PROPERTY","M94_INSTRUMENT", 0);
	   	if (callfunc != 1) return (-7);
		}

	if (strcmp(str_glob->spacecraft_name,"MGS")==0)
		{
		if (strcmp(str_glob->ins_id,"WA")==0)
			{
			callfunc = zlget  (str_glob->inunit, "PROPERTY", "DETECTOR_ID", str_glob->det_id,
			  "PROPERTY","M94_INSTRUMENT", 0);
			if (callfunc != 1) return (-8);
			strncat (str_glob->ins_name, "_WA_", 4);
            if (!strncmp(str_glob->det_id,"RED",3))
                strcat (str_glob->ins_name, "RED");
            else
                strcat (str_glob->ins_name, "BLUE");
			}
		else 	strncat (str_glob->ins_name, "_NA", 3);

		}
    else
        {
	   	callfunc = zlget  (str_glob->inunit, "PROPERTY", "DETECTOR_ID", str_glob->det_id,
				"PROPERTY","M94_INSTRUMENT", 0);
       	if (callfunc != 1) return (-9);
        }
   
	callfunc = zlget  (str_glob->inunit, "PROPERTY", "START_TIME", start_time,
                           "PROPERTY","M94_ORBIT", 0);
    if (callfunc != 1) return (-10);
 	if (strcmp(str_glob->spacecraft_name,"MGS")==0)
    	strcpy (str_glob->h_geocal_version,"NO_VERSION_FOR_MGS");
	else
    	callfunc=hrgetversion("geo",start_time,str_glob->det_id,str_glob->h_geocal_version);
    if (callfunc != 1) return (-11);

	return (0);
	}

/*===================================================================*/
/*############################################################	*/
/* Get target							*/
/*############################################################	*/
/* Calls from	hrortho					*/
/* Calling	zlget 						*/
/*############################################################	*/

	int hw_get_target(str_glob_type *str_glob)
/*############################################################	*/

	{
   	int   count, callfunc, i, j;
	char  c_temp[2];
	SpiceBoolean found_spb;
        SpiceInt     sptargetid;
        
	if (strcmp(str_glob->spacecraft_name,"MGS")==0)
		{
 		callfunc = zvp ( "TARGET", str_glob->target_name, &count);

		for (i=0;i<strlen(str_glob->target_name);i++)
	    		{
	    		strncpy (c_temp,str_glob->target_name+i,1);
	    		j=(int)(c_temp[0]);
	    		c_temp[1]=(char)(toupper(j));
	    		strncpy (c_temp,c_temp+1,1);
	    		strncpy (str_glob->target_name+i,c_temp,1);
	    		}
		}
	else
		{
		callfunc = zlget  (str_glob->inunit, "PROPERTY", "TARGET_NAME", str_glob->target_name,
			   "PROPERTY","MAP", 0);
		if (callfunc != 1) return (-1);
		}

	bodn2c_c(str_glob->target_name, &sptargetid, &found_spb);
        str_glob->target_id = sptargetid;
	return (0);	
	}	

/*===================================================================*/
/*############################################################	*/
/* Get scale				*/
/*############################################################	*/
/* Calls from	hrortho					*/
/* Calling	zlget 						*/
/*############################################################	*/

	int hw_rip_get_scale (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, double *scale, short int *dtm_buf)
/*############################################################	*/
	{
	float	temp_float,ccd[2];
	double	x[2], y[2], dummy_vec[2];
	int foundvec[2],signvec[2], callfunc;
	
	*scale = 0.01;
	callfunc = mpSetValues ( mp_obj, mpMAP_SCALE, *scale, NULL);

	callfunc = dlr_earth_map_get_prefs (mp_obj, &prefs);
	if (callfunc != 1)
		{
		printf("Error in dlr_earth_map_get_prefs !");
     		zabend();
		}	
	temp_float = (float)(str_glob->nof_inp_s/2);
	ccd[0]= hwpixnum(temp_float, str_glob->macro, str_glob->fp, 1); 
	pixnum2ccd(str_glob, &ccd[0]);     
	     
	temp_float = temp_float + 1.0;
	ccd[1]= hwpixnum(temp_float, str_glob->macro, str_glob->fp, 1); 
	pixnum2ccd(str_glob, &ccd[1]);     
	callfunc = hwtraidtm_rip (str_glob, mp_obj, prefs, prefs_dtm, dtmunit, str_glob->sl_inp-1 + str_glob->nof_inp_l/2, 2, 
	    ccd, x, y, foundvec, signvec, 0, dtm_buf);
		     
	*scale *= sqrt((x[1]-x[0])*(x[1]-x[0])+(y[1]-y[0])*(y[1]-y[0]));

	return (1);
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
	of the new rectified image	(private)	*/
/*############################################################	*/
/* Calls from	hrortho						*/
/* Calling	mpGetValues, mpSetValues

		hrrdpref
		
     (private)	hwtraip				*/

/*############################################################	*/

	int hworloc_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, short int *dtm_buf)
	{
	double	outsize, d_val1, d_val2, d_temp;
	int	callfunc, callfunc1, callfunc2, j, k, l, centerlon, last_check_line;
	int	nof_pix, foundvec[MAX_PIXEL_PER_LINE], signvec[MAX_PIXEL_PER_LINE], check_dist, found=0;
	int	*check_l, end_of_line;
	float	check_s[MAX_PIXEL_PER_LINE], ccd[MAX_PIXEL_PER_LINE], centerpixel, r_temp;
	double 	max_x, max_y, min_x, min_y, x_off, y_off;
	double	x[MAX_PIXEL_PER_LINE], y[MAX_PIXEL_PER_LINE];
	char	outstring[80];
	 	
	double	   temp_centric_cenlat, temp_centric_cenlon, dummy3[3],dummy[2], los[3], pos[3], radius;
	
	foundvec[0]=0;
/*SIGN	signvec[0]=0;SIGN*/
	x[0]=0.;
	y[0]=0.;

	min_x   = 9.9e20;
	min_y   = 9.9e20;
	max_x 	= -9.9e20;
	max_y 	= -9.9e20;

	if ((!str_glob->fittofile)&&(!str_glob->parts))
		{
		callfunc1 = mpGetValues ( mp_obj, mpLINE_PROJECTION_OFFSET, &x_off, NULL);
		callfunc2 = mpGetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, &y_off, NULL);
		if ((callfunc1 != mpKEYWORD_NOT_SET)&&(callfunc2 != mpKEYWORD_NOT_SET) &&
		    (str_glob->nof_out_l!=0)&&(str_glob->nof_out_s!=0)) str_glob->fittofile = 1;
		}

			
/*--------------------------------------------------------------	*/
/* Handling each str_glob->anchdistth pixel on the image border				*/
/*--------------------------------------------------------------	*/

/*--------------------------------------------------------------	*/
/* preparing the following loop for all lines				*/
/*--------------------------------------------------------------	*/
	check_dist = str_glob->anchdist;

	check_l = (int *) malloc ((str_glob->nof_inp_l_part/check_dist + 10) * sizeof(int));
	check_l [0] = str_glob->first_inp_l_part;
		
	j = 0;

	while (1) 
		    /* loop of all lines with a distance of check_dist */
		{
		if ((check_l[j]+check_dist) >= (str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1))
		    {			
		    j++;
		    check_l [j] = (str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1);
/* wg. moeglichem Fehler im letzten Prefix */  check_l [j] = check_l [j] - 1;
		    break;
		    }
			
		else
			{
			j++;
			check_l [j] = check_l [j-1] + check_dist;
			}
		}
last_check_line=j;



/*SINU
	if (str_glob->critical_projection == -1)
		{
		if ((str_glob->cenlat>(-90.0+0.0000001))&&(str_glob->cenlat<(90.0-0.0000001)))	    
		temp_centric_cenlat = (atan (str_glob->axes[2]*str_glob->axes[2]/(str_glob->axes[0]*str_glob->axes[0])
		    *tan (str_glob->cenlat*my_deg2pi)));
		else temp_centric_cenlat=str_glob->cenlat*my_deg2pi;
		temp_centric_cenlon = str_glob->cenlong*my_deg2pi;
los[0]=cos(temp_centric_cenlon)*cos(temp_centric_cenlat);
los[1]=sin(temp_centric_cenlon)*cos(temp_centric_cenlat);
los[2]=sin(temp_centric_cenlat);
pos[0]=pos[1]=pos[2]=0.0;
		dlrsurfpt (pos, los, str_glob->axes[0], str_glob->axes[1], str_glob->axes[2], dummy3, &callfunc);
		radius = dlrvnorm (dummy3)
		str_glob->xcen=radius*cos(temp_centric_cenlat)*cos(temp_centric_cenlon);
		str_glob->ycen=radius*cos(temp_centric_cenlat)*sin(temp_centric_cenlon);
		str_glob->zcen=radius*sin(temp_centric_cenlat);
		str_glob->d0=sqrt(str_glob->xcen*str_glob->xcen+str_glob->ycen*str_glob->ycen+str_glob->zcen*str_glob->zcen);	    
		str_glob->d02=str_glob->d0*str_glob->d0;	    
		}
SINU*/


	/*---------------------------------------------- */
	/* each "checkdist"th pixel has to be processed	 */
	/*---------------------------------------------- */
			
	check_s[0] = 1.0;
	ccd[0]= hwpixnum(check_s[0], str_glob->macro, str_glob->fp, 1); 
	pixnum2ccd(str_glob, &ccd[0]);     
		     
	k=1;
	end_of_line = 0;
	while (end_of_line != 1 && (k<MAX_PIXEL_PER_LINE))
		    {
		    if (((int)(check_s[k-1]) + check_dist) > str_glob->nof_inp_s)
			    {
			    check_s [k] = (float)(str_glob->nof_inp_s);
			    end_of_line = 1;
			    }

		    else	check_s [k] = check_s [k-1] + (float)check_dist;
			

		    ccd[k]= hwpixnum(check_s[k], str_glob->macro, str_glob->fp, 1); 
		    pixnum2ccd(str_glob, &ccd[k]);     
		    k++;
		    }
		    
	nof_pix = k;
/*--------------------------------------------------------------	*/
/* Loop of all check_lines						*/
/*--------------------------------------------------------------	*/
 
	for (l=0; l<=last_check_line; l++)	    
		{
		callfunc = hwtraidtm_rip (str_glob, mp_obj, prefs, prefs_dtm, dtmunit, check_l[l],
			   nof_pix, ccd, x, y, foundvec, signvec, 0, dtm_buf);
		if (callfunc == -998) return (callfunc);	

		for (k=0;k<nof_pix;k++)
			{
			if (foundvec[k] != 0)
				{
				if (x[k] < min_x) {min_x = x[k];found=1;}
				if (x[k] > max_x) {max_x = x[k];found=1;}
				if (y[k] < min_y) {min_y = y[k];found=1;}
				if (y[k] > max_y) {max_y = y[k];found=1;}
				if ((str_glob->fittofile)&&(!str_glob->parts)) 
					{
					if ((x[k] <= str_glob->nof_out_l) && 
					    (x[k] >= 1.0) &&
					    (y[k] <= str_glob->nof_out_s) &&
					    (y[k] >= 1.0)) 
						{
						if (str_glob->first_used_l == 0) 
							{
							str_glob->first_used_l = check_l[l] - check_dist;
							if (str_glob->first_used_l<1) str_glob->first_used_l = 1;
							}
						str_glob->last_used_l = check_l[l] + check_dist;
						if (str_glob->last_used_l>(str_glob->sl_inp-1 + str_glob->nof_inp_l)) 
							str_glob->last_used_l=str_glob->sl_inp-1 + str_glob->nof_inp_l;
						}
					}
				}			
			}
		}
				
	if (str_glob->found != 1)
	    {
	    zvmessage(" Error in hworloc ","");
	    zvmessage(" Input-Image does not ","");
 	    zvmessage(" contain the target !","");
	    zabend();
	    }
	if (str_glob->found_in_dtm != 1)
	    {
	    zvmessage(" Error in hworloc_rip ","");
	    zvmessage(" The area covered by the image is not ","");
 	    zvmessage(" covered by the DTM !","");
	    zabend();
	    }
	if (found != 1)
	    {
	    zvmessage(" Error in hworloc_rip ","");
	    zvmessage(" The area covered by the image can not ","");
 	    zvmessage(" be shown with this map projection parameters !","");
	    zabend();
	    }

/*--------------------------------------------------------------	*/
/* compute extreme x/y-coordinates of the output image			*/
/*--------------------------------------------------------------	*/
	
	callfunc1 = mpGetValues
		    ( mp_obj, mpLINE_PROJECTION_OFFSET, &x_off, NULL);
	if (callfunc1 == mpKEYWORD_NOT_SET) 
	 	{
		min_x   -= (double)str_glob->border;
		max_x 	+= (double)str_glob->border;
		if (min_x < 0.0) min_x = min_x - 1.0;
		if (max_x < 0.0) max_x = max_x - 1.0;
		x_off	= -(double)((int)(min_x));
/*POLE		if ((str_glob->pole==0)||(str_glob->critical_projection <= 0)) POLE*/
		    callfunc = mpSetValues
			   ( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
/*POLE		else
		    {
		    if (fabs(str_glob->max_lati)>fabs(str_glob->min_lati))
			{
			if ((strcmp(str_glob->mptype, "SINUSOIDAL")==0)||
			    (strcmp(str_glob->mptype, "EQUIDISTANT")==0))
			    {
			    x_off = (double)((int)(str_glob->mp_axes[0]*PI/2.0/str_glob->scale_resolution + (double)str_glob->border));
			    }
			else if (strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
			    { 
			    x_off = (double)((int)(str_glob->mp_axes[0]/str_glob->scale_resolution + (double)str_glob->border));
			    }
			else if (str_glob->critical_projection == 2)
			    {
			    x_off= (double)((int)(str_glob->mp_axes[0] * log(tan( PI/4.0 + 0.5 * 88.0*my_deg2pi)) /str_glob->scale_resolution + (double)str_glob->border));
 			    }
			callfunc = mpSetValues
				( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
			}
		    else 
			{
		    	callfunc = mpSetValues
				( mp_obj, mpLINE_PROJECTION_OFFSET, x_off, NULL);
				
			if ((strcmp(str_glob->mptype, "SINUSOIDAL")==0)||
			    (strcmp(str_glob->mptype, "EQUIDISTANT")==0))
			    {
			    max_x = str_glob->mp_axes[0]*PI/2.0/str_glob->scale_resolution + (double)str_glob->border;
			    }
			else if (strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
			    {max_x = str_glob->mp_axes[0]/str_glob->scale_resolution + (double)str_glob->border;}
			else if (str_glob->critical_projection == 2)
			    {max_x = str_glob->mp_axes[0] * log(tan( PI/4.0 + 0.5 * 88.0*my_deg2pi)) /str_glob->scale_resolution + (double)str_glob->border;}
			}
		    } POLE*/

		/*-----------------------------------------------------	*/
		/* compute number of lines of the output image  */
		/*-----------------------------------------------------	*/
		if (str_glob->nl == 0) 
			str_glob->nof_out_l = (int)(max_x) + (int)(x_off) + 1;
		else
			{
			if ((str_glob->nof_out_l<(int)(max_x))&&(str_glob->fittofile==0))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined NL !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		}
	else if (!str_glob->parts)
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
			else if (str_glob->fittofile==0)
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined ","");
				zvmessage("LINE_PROJECTION_OFFSET !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		if (str_glob->nl == 0)
			{
			str_glob->nof_out_l = (int)(max_x)+str_glob->border;
			}
		else
			{
			if ((str_glob->nof_out_l<(int)(max_x))&&(str_glob->fittofile==0))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined NL !!","");
				zvmessage("Processing continues ... ","");
				}
			}
		}

	callfunc2 = mpGetValues ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, &y_off, NULL);

	if (callfunc2 == mpKEYWORD_NOT_SET) 
		{
/*POLE		if (
		(
		(str_glob->critical_projection == 2)
		||(strcmp(str_glob->mptype, "EQUIDISTANT")==0)
		||(strcmp(str_glob->mptype, "CYLINDRICAL_EQUAL_AREA")==0)
		)
		&&(str_glob->pole==1)
		)
		    {
		    y_off	= (double)((int)(str_glob->mp_axes[0]*PI/str_glob->scale_resolution + (double)str_glob->border));
		    max_y	= str_glob->mp_axes[0]*PI/str_glob->scale_resolution + (double)str_glob->border;
		    callfunc = mpSetValues
				( mp_obj, mpSAMPLE_PROJECTION_OFFSET, y_off, NULL);
		    }
		else
		    {
POLE*/
		    min_y  	-= (double)str_glob->border;
		    max_y 	+= (double)str_glob->border; 
		    if (min_y < 0.0) min_y = min_y - 1.0;
		    if (max_y < 0.0) max_y = max_y - 1.0;
		    y_off	= -(double)((int)(min_y));
		    callfunc = mpSetValues
			   ( mp_obj, mpSAMPLE_PROJECTION_OFFSET, y_off, NULL);
/*POLE		    } POLE*/
		/*-----------------------------------------------------	*/
		/* compute number of samples of the output image  */
		/*-----------------------------------------------------	*/
		if (str_glob->nof_out_s == 0) 
			{
			str_glob->nof_out_s = (int)(max_y) + (int)(y_off) + 1;		
			}
		else
			{
			if ((str_glob->nof_out_s<(int)(max_y))&&(str_glob->fittofile==0))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined NS !!","");
				zvmessage("Processing continues ... ","");
				}
			}		
		}
	else if (!str_glob->parts)
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
			else if (str_glob->fittofile==0)
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined ","");
				zvmessage("SAMPLE_PROJECTION_OFFSET !!","");
				zvmessage("Processing continues ... ","");
				}
			}
					
		if (str_glob->nof_out_s == 0)
			{
			str_glob->nof_out_s = (int)(max_y)+str_glob->border;
			}
		else
			{
			if ((str_glob->nof_out_s<(int)(max_y))&&(str_glob->fittofile==0))
				{
				zvmessage("Attention:","");
				zvmessage("The outfile will be cut ","");
				zvmessage("due to user-defined NS !!","");
				zvmessage("Processing continues ... ","");
				}
			}		
		}

	if ((strcmp(str_glob->report, "NO")!=0) && (!str_glob->parts))
		{
 		sprintf(outstring, "Lines of output-image %d", str_glob->nof_out_l);
     		zvmessage(outstring,"");
 		sprintf(outstring, "Samples of output-image %d", str_glob->nof_out_s);
     		zvmessage(outstring,"");

	   	if ((callfunc1 == mpKEYWORD_NOT_SET) || 
		    (callfunc2 == mpKEYWORD_NOT_SET))
			{
 			sprintf(outstring, "LINE_PROJECTION_OFFSET %lf", x_off);
     			zvmessage(outstring,"");
			sprintf(outstring, "SAMPLE_PROJECTION_OFFSET %lf", y_off);
     			zvmessage(outstring,"");
			}
		}

	if (str_glob->parts)
			{
			str_glob->minx = min_x;
			str_glob->maxx = max_x;
			str_glob->miny = min_y;
			str_glob->maxy = max_y;
			}

	if ((!str_glob->fittofile)&&(!str_glob->parts)) 
		{
		str_glob->first_used_l = str_glob->sl_inp-1 + 1;
		str_glob->last_used_l = str_glob->sl_inp-1 + str_glob->nof_inp_l;
		}

	free (check_l);

	return(0);
	}

/*======================================================================*/
/*##############################################################	*/
/* Geometric correction of a hw image 
					(private)			*/
/*##############################################################	*/
/* Calls from	hrortho						*/
/* Calling		zvunit, zvopen, zvclose, zvread, zvwrit

			mpLabelWrite		

			hrrdpref

	(private)	hwgetapt, hwtraip,
			hwgetapp, hwsortap,
			hwintgv_bi, hwintgv_cc	*/
/*##############################################################	*/

	int hwgeorec_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, short int *dtm_buf)

	{
	int	callfunc, i, i_end, j, p, nof_pix, int_l, int_s, nof_read_inp_lines;
	int	down, done, last_done;
	int	save_found_vec[MAX_PIXEL_PER_LINE], save_sign_vec[MAX_PIXEL_PER_LINE], 
		foundvec[MAX_PIXEL_PER_LINE],foundvec2[MAX_PIXEL_PER_LINE], signvec[MAX_PIXEL_PER_LINE],signvec2[MAX_PIXEL_PER_LINE], 
		area, first_area, up_int_save, lo_int_save;
	int	on_target[MAX_PIXEL_PER_LINE];
	int	nof_up_le_p, nof_up_ri_p;
	int	nof_p, anch_l1, anch_l2, x_act, y_act;
	int	save_nof_le_p, save_nof_ri_p;
	int	p_up_down, p_start, p_end, x_start, x_end, y_start, y_end;
	int	mid_of_l;
	int	nof_lo_le_p, nof_lo_ri_p, out_buf_size ;
	int	save_s[MAX_PIXEL_PER_LINE], up_s[MAX_PIXEL_PER_LINE];
	int	lo_s[MAX_PIXEL_PER_LINE], out_buf_off, inp_buf_off;
	int	min_x_p, min_y_p, max_x_p, max_y_p;
	int	cont_inp_l, act_anchdist_l, act_anchdist_s;
	int	s_ap1[MAX_PIXEL_PER_LINE], s_ap2[MAX_PIXEL_PER_LINE];
	int	s_ap3[MAX_PIXEL_PER_LINE], s_ap4[MAX_PIXEL_PER_LINE], xcount, ycount, prefix_off;
	float   ccd[MAX_PIXEL_PER_LINE], ccd2[MAX_PIXEL_PER_LINE];
	double  l, s, initial_l, initial_s, d_l, d_s, d_first_s_p;
	double	lo_save, up_save, d_temp;
	double	min_l_p, min_s_p, max_l_p, max_s_p;
	double	a[6];			
	double  up_x[MAX_PIXEL_PER_LINE],   up_y[MAX_PIXEL_PER_LINE];
	double  up_x2[MAX_PIXEL_PER_LINE],  up_y2[MAX_PIXEL_PER_LINE];
	double	lo_x[MAX_PIXEL_PER_LINE],   lo_y[MAX_PIXEL_PER_LINE];
	double	lo_x2[MAX_PIXEL_PER_LINE],  lo_y2[MAX_PIXEL_PER_LINE];
	double	save_x[MAX_PIXEL_PER_LINE], save_y[MAX_PIXEL_PER_LINE];
	double	x_ap1[MAX_PIXEL_PER_LINE],  x_ap2[MAX_PIXEL_PER_LINE];
	double	x_ap3[MAX_PIXEL_PER_LINE],  x_ap4[MAX_PIXEL_PER_LINE];
	double	y_ap1[MAX_PIXEL_PER_LINE],  y_ap2[MAX_PIXEL_PER_LINE], d, dmax;
	double	y_ap3[MAX_PIXEL_PER_LINE],  y_ap4[MAX_PIXEL_PER_LINE], test_l, test_s;
	int	dtm_no_dtm[MAX_PIXEL_PER_LINE];
	double	af_x_out[4], af_y_out[4], af_x_inp[4], af_y_inp[4], inp_off[2], out_off[2];
	 
	int	act_macro, match_buf_size;
		
	char	outstring[200], temp_string[200], temp_string2[200];
	float	*gv_inp_buf, *gv_out_buf_float, *gv, *gv_inp_lo, *gv_inp_ro,
		*gv_inp_lu, *gv_inp_ru, *gv_bicu, *match_x_buf, *match_y_buf;

	myBYTE	*gv_out_buf_byte, *tab_gv;
	short int *gv_out_buf_half;
	int	*gv_out_buf_full, *tab_in, *tab_out;

	char	line_of_asciifile[MAXLINESIZE];
	int	i_file, nof_files, i_point, nof_points;
	double	lin, samp;
	float	   vari[6], covari[6], r_temp;
	char	   start_time[120], stop_time[120];
	hrpref_typ HR_Prefix;
	int	*time_gaps;
	double	*ephtime, *exptime;
	
	time_gaps	    = (int *) malloc ((str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1)*sizeof(int));
	if (time_gaps  == (int *) NULL) return(-998); 
	ephtime	    = (double *) malloc ((str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1)*sizeof(double));
	if (ephtime  == (double *) NULL) return(-998); 
	exptime	    = (double *) malloc ((str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1)*sizeof(double));
	if (exptime  == (double *) NULL) return(-998); 

	for (i=str_glob->first_inp_l_part-1;i<(str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1);i++)
		{
		hrrdpref( str_glob->inunit, i+1, &HR_Prefix);
		ephtime[i]=HR_Prefix.EphTime;
		exptime[i]=HR_Prefix.Exposure/1000.;
		time_gaps[i]=0;
		}
	for (i=str_glob->first_inp_l_part;i<(str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1);i++)
		{
		if ((ephtime[i]-ephtime[i-1]-exptime[i-1])>0.001) 
			{
			time_gaps[i]=1; 
			printf ("#W: Time gap of %.3lf s at line %d filled by interpolation ...\n",(ephtime[i]-ephtime[i-1]-exptime[i-1]), i);
			}
		}

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

	lo_int_save = 2;
	up_int_save = 2;
  	gv_inp_buf = (float *) malloc (sizeof(float) * str_glob->nof_inp_s *
				       (str_glob->anchdist+str_glob->anchdist/2+10+lo_int_save+up_int_save));
	if (gv_inp_buf == (float *)NULL) return(-998); 
		
	*gv		= 0.;
	*gv_inp_buf	= 0.;

	foundvec[0]=0;
	foundvec2[0]=0;
/*SIGN	signvec[0]=0;
	signvec2[0]=0;
SIGN*/

/*--------------------------------------------------------------	*/
/*	Initialize output-image						*/
/*--------------------------------------------------------------	*/
	out_buf_size=str_glob->nof_out_s_part*str_glob->nof_out_l_part;
	if (str_glob->oformat == 1)     out_buf_size*=sizeof(myBYTE);
	else if (str_glob->oformat == 2)out_buf_size*=sizeof(short int);
	else if (str_glob->oformat == 3)out_buf_size*=sizeof(int);
	else if (str_glob->oformat == 4)out_buf_size*=sizeof(float);

	if (str_glob->match != 0) match_buf_size = str_glob->nof_out_s_part*str_glob->nof_out_l_part*sizeof(float);
	else  match_buf_size = 0;

	if (str_glob->match !=0 )
		{
		match_x_buf = (float *) calloc (1,match_buf_size);
	    	if (match_x_buf == (float *)NULL) 
			{
			sprintf(outstring, "Error during allocation of match_x_buf!!");
     			zvmessage(outstring,"");
			zabend();
			}
		*match_x_buf = 0.;
		match_y_buf = (float *) calloc (1,match_buf_size);
	    	if (match_y_buf == (float *)NULL) 
			{
			sprintf(outstring, "Error during allocation of match_y_buf!!");
     			zvmessage(outstring,"");
			zabend();
			}
		*match_y_buf = 0.;
		}
	if (str_glob->oformat == 1)
			{
			gv_out_buf_byte = (myBYTE *) calloc (1,out_buf_size);
	    		if (gv_out_buf_byte == (myBYTE *)NULL) 
				{
				sprintf(outstring, "Error during allocation of gv_out_buf_byte !!");
     				zvmessage(outstring,"");
				zabend();
				}
			*gv_out_buf_byte = 0;
			}
	else if (str_glob->oformat == 2)
			{
			gv_out_buf_half = (short int *) calloc (1,out_buf_size);
	    		if (gv_out_buf_half == (short int *)NULL) 
				{
				sprintf(outstring, "Error during allocation of gv_out_buf_half !!");
     				zvmessage(outstring,"");
				zabend();
				}
			*gv_out_buf_half = 0;
			}
	else if (str_glob->oformat == 3)
			{
			gv_out_buf_full = (int *) calloc (1,out_buf_size);
	    		if (gv_out_buf_full == (int *)NULL) 
				{
				sprintf(outstring, "Error during allocation of gv_out_buf_full !!");
     				zvmessage(outstring,"");
				zabend();
				}
			*gv_out_buf_full = 0;
			}
	else if (str_glob->oformat == 4)
			{
			gv_out_buf_float = (float *) calloc (1,out_buf_size);
	    		if (gv_out_buf_float == (float *)NULL) 
				{
				sprintf(outstring, "Error during allocation of gv_out_buf_float !!");
     				zvmessage(outstring,"");
				zabend();
				}
			*gv_out_buf_float = 0.;
			}

	prefix_off = str_glob->nbb;
		
/*--------------------------------------------------------------	*/
/*	Initialize tables						*/
/*--------------------------------------------------------------	*/
	i_end = 2*str_glob->anchdist; 
	if (i_end < 20) i_end=20;
		
	tab_in   = (int *) malloc ((i_end+1)*sizeof(int));
		if (tab_in == (int *)NULL) return(-998); 
	*tab_in  = (int)0;

	for (i=1; i<i_end; i++) { *(tab_in+i) = *(tab_in+i-1)+str_glob->nof_inp_s; }

/*-------------------------------------------------------------	*/
	
	tab_out   = (int *) malloc ((str_glob->nof_out_l_part+1)*sizeof(int));
	if (tab_out == (int *)NULL) return(-998); 
	*tab_out  = (int)0;
	i_end 	  = str_glob->nof_out_l_part; 	

	for (i=1; i<i_end; i++) { *(tab_out+i) = *(tab_out+i-1)+str_glob->nof_out_s_part; }

/*-------------------------------------------------------------	*/

	if (str_glob->oformat == 1)
		{
		tab_gv   = (myBYTE *) malloc (256*sizeof(myBYTE));
		if (tab_gv == (myBYTE *)NULL) return(-998); 
		*tab_gv  = (myBYTE)1;
		i_end 	  = 256; 	

		for (i=1; i<i_end; i++) { *(tab_gv+i) = (myBYTE)i; }
		}
 
	/*----------------------------------------------------	*/
	/* read output-grayvalues				*/
	/*----------------------------------------------------	*/
	if (!str_glob->first_io)
	{
	for (i=str_glob->first_out_l_part; i<str_glob->first_out_l_part+str_glob->nof_out_l_part; i++)				
		{
		out_buf_off=(i-str_glob->first_out_l_part)*str_glob->nof_out_s_part;
		if (str_glob->match !=0 )
			{
				callfunc = decode_refline 
					  (match_x_buf+out_buf_off, str_glob->nof_out_s_part, str_glob->new_match_x_unit, i, str_glob->index_x);
				if (callfunc < 0)
					{
					printf ("Decode error: %d !\n",callfunc);
					zabend();
					}
				callfunc = decode_refline 
					  (match_y_buf+out_buf_off, str_glob->nof_out_s_part, str_glob->new_match_y_unit, i, str_glob->index_y);
				if (callfunc < 0)
					{
					printf ("Decode error: %d !\n",callfunc);
					zabend();
					}
			}

		if (str_glob->oformat == 1)
			{
			callfunc = zvread (str_glob->outunit, (gv_out_buf_byte+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 2)
			{
			callfunc = zvread (str_glob->outunit, (gv_out_buf_half+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 3)
			{
			callfunc = zvread (str_glob->outunit, (gv_out_buf_full+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 4)
			{
			callfunc = zvread (str_glob->outunit, (gv_out_buf_float+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		}
	}
	else
	{
	if (str_glob->oformat == 1) 
			{;}
	else if (str_glob->oformat == 2) 
			for (i=0; i<str_glob->nof_out_s_part*str_glob->nof_out_l_part; i++) gv_out_buf_half[i] = (short int)str_glob->no_info_val;
	else if (str_glob->oformat == 3)
			for (i=0; i<str_glob->nof_out_s_part*str_glob->nof_out_l_part; i++) gv_out_buf_full[i] = (int)str_glob->no_info_val;
	else if (str_glob->oformat == 4)
			for (i=0; i<str_glob->nof_out_s_part*str_glob->nof_out_l_part; i++) gv_out_buf_float[i] = (float)str_glob->no_info_val;
	}

	str_glob->first_io=0;
/*-------------------------------------------------------------	*/
/*	Initialize anchorpoint lines				*/
/*-------------------------------------------------------------	*/

	mid_of_l = str_glob->nof_inp_s/2;

	cont_inp_l      = str_glob->first_inp_l_part;

	first_area      = 0;
	area            = 0;
	down=0;

	if (strcmp(str_glob->report, "NO")!=0)
			{
			printf("Done (in percent): ");
			fflush(stdout);
			last_done=0;
			}
	while (cont_inp_l < (str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1))
		{
/*------------------------------------------------------------------	*/
/*	Read input grayvalues of this area between two anchorpoint-lines*/
/*------------------------------------------------------------------	*/
		inp_buf_off = 0;     	

		lo_save = 0.5;
		up_save = 0.5;
		lo_int_save = 2;
		up_int_save = 2;
		
		act_anchdist_l = 1;
		while(act_anchdist_l<str_glob->anchdist) 
			{
			if (time_gaps[cont_inp_l-1+act_anchdist_l]) break;
			act_anchdist_l++;
			}
		if (act_anchdist_l<str_glob->anchdist && act_anchdist_l>1) act_anchdist_l--;


		
		if ((str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1) - (cont_inp_l+act_anchdist_l) 
							<= (act_anchdist_l+1)/2)
			{
			act_anchdist_l = (str_glob->first_inp_l_part+str_glob->nof_inp_l_part-1) - cont_inp_l;
			if (str_glob->interpol_type==2) 
				{
				lo_save=-1.01;
				}
			else
				{
				lo_save=-1.0;
				}

			lo_int_save = 0;
			}

		anch_l1=cont_inp_l;
		
		if (area<=(first_area+1))
			{
			if (str_glob->interpol_type==2) { d_temp=-1.0; }
			else { d_temp=0.0; }
				
			if (area==first_area)
				{
				up_int_save = 0;
				up_save = d_temp;
				}
			else
				{
				if (act_anchdist_l==1)
					{
					up_int_save = 0;
					up_save = d_temp;
					}
				}
			}

		    
		for (j=cont_inp_l-up_int_save; j <= (cont_inp_l+act_anchdist_l+lo_int_save); j++)
			{
			callfunc = zvread (str_glob->inunit, (gv_inp_buf+inp_buf_off),
				           "LINE", j, "SAMP", 1+prefix_off,
				           "NSAMPS", str_glob->nof_inp_s, 0);
			inp_buf_off += str_glob->nof_inp_s;
			}
		nof_read_inp_lines = act_anchdist_l+lo_int_save+up_int_save+1;

		done=100*(cont_inp_l - str_glob->first_used_l + act_anchdist_l);
		done=((done/(str_glob->last_used_l - str_glob->first_used_l + 1))/5)*5;
		if (strcmp(str_glob->report, "NO")!=0)
			{
			if (done>last_done)
			    {
			    printf("%2d ", done);
			    fflush (stdout);
			    last_done=done;
			    }
			}

		cont_inp_l = cont_inp_l+act_anchdist_l;

			callfunc = hwgetapt (str_glob, anch_l1, mid_of_l, str_glob->fillp+str_glob->fap+1, 
				   &nof_up_le_p, &nof_up_ri_p, up_s);
	     
			nof_pix  = nof_up_le_p + nof_up_ri_p + 1;
			for (j=0; j < nof_pix; j++)
			    {
			    ccd[j]= hwpixnum((float)(up_s[j])-(float)(str_glob->fillp), str_glob->macro, str_glob->fp, 1); 
			    pixnum2ccd(str_glob, &ccd[j]);     
			    }

			callfunc = hwtraidtm_rip (str_glob, mp_obj, prefs, prefs_dtm, dtmunit, anch_l1, nof_pix,
					    ccd, up_x, up_y, foundvec, signvec, 1, dtm_buf);

			str_glob->pho_calc_done=1;
			if (callfunc == -998) return (callfunc);	

		anch_l2 = cont_inp_l;

		callfunc= hwgetapt (str_glob, anch_l2, mid_of_l, str_glob->fillp+str_glob->fap+1, &nof_lo_le_p, &nof_lo_ri_p, lo_s);

		nof_pix  = nof_lo_le_p + nof_lo_ri_p + 1;
		for (j=0; j < nof_pix; j++)
		    {
		    ccd[j]= hwpixnum((float)(lo_s[j])-(float)(str_glob->fillp), str_glob->macro, str_glob->fp, 1); 
		    pixnum2ccd(str_glob, &ccd[j]);     
		    }

		callfunc = hwtraidtm_rip (str_glob, mp_obj, prefs, prefs_dtm, dtmunit, anch_l2, nof_pix,
				    ccd, lo_x, lo_y, foundvec2, signvec2, 1, dtm_buf);

		if (callfunc == -998) return (callfunc);	
	
		callfunc = hwsortap (nof_up_le_p, nof_up_ri_p, up_s, up_x, up_y, foundvec, signvec,
			             nof_lo_le_p, nof_lo_ri_p, lo_s, lo_x, lo_y, foundvec2, signvec2);

		callfunc = hwgetapp (nof_up_le_p, nof_up_ri_p, up_s, up_x, up_y, foundvec, signvec,
			  	     nof_lo_le_p, nof_lo_ri_p, lo_s, lo_x, lo_y, foundvec2, signvec2,
			  	     &nof_p, s_ap1, s_ap2, s_ap3, s_ap4,
			  	      x_ap1, x_ap2, x_ap3, x_ap4,
			  	      y_ap1, y_ap2, y_ap3, y_ap4,  dtm_no_dtm);
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
			   (transformation from output- to input-image)	*/
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
/*if (strcmp(str_glob->spacecraft_name, "MGS")!=0)
	callfunc = check_quad ( af_x_inp,  af_y_inp );
else
	callfunc = check_quad_gespiegelt ( af_x_inp,  af_y_inp );
*/
callfunc = check_quad ( af_x_inp,  af_y_inp );
if (callfunc == -1) callfunc = check_quad_gespiegelt ( af_x_inp,  af_y_inp );

if (callfunc==-1) {continue;}

			inp_off[0]=af_x_inp[1];
			inp_off[1]=af_y_inp[1];		
			out_off[0]=af_x_out[1];
			out_off[1]=af_y_out[1];			

			callfunc = hwgetpro (af_x_inp, af_y_inp, af_x_out, af_y_out, a);
			
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
				if (max_s_p >= (double)(str_glob->nof_inp_s)-1.0)
					max_s_p = (double)(str_glob->nof_inp_s)-1.001;
						
				if (min_s_p < 0.0) min_s_p = 0.001;
						
				break;

				case 2:
/*----------------------------------------------------------------------	*/
/* 				cubic convolution	*/
/*----------------------------------------------------------------------	*/
				if (min_s_p < 1.0) min_s_p = 1.001;
				if (max_s_p >= (double)(str_glob->nof_inp_s)-2.0)
					max_s_p = (double)(str_glob->nof_inp_s)-2.001;
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
					     af_x_inp[2], af_x_inp[3])-1.);
			max_x_p = (int) (max(af_x_inp[0], af_x_inp[1],
					     af_x_inp[2], af_x_inp[3])+1.);
			min_y_p = (int) (min(af_y_inp[0], af_y_inp[1],
					     af_y_inp[2], af_y_inp[3])-1.);
			max_y_p = (int) (max(af_y_inp[0], af_y_inp[1],
					     af_y_inp[2], af_y_inp[3])+1.);
			if (max_x_p > str_glob->first_out_l_part && max_y_p > str_glob->first_out_s_part 
			    && min_y_p < (str_glob->first_out_s_part+str_glob->nof_out_s_part-1)
			    && min_x_p < (str_glob->first_out_l_part+str_glob->nof_out_l_part-1))
			{
			if (min_x_p < str_glob->first_out_l_part) min_x_p = str_glob->first_out_l_part;
			if (min_y_p < str_glob->first_out_s_part) min_y_p = str_glob->first_out_s_part;
			if (max_x_p > (str_glob->first_out_l_part+str_glob->nof_out_l_part-1)) 
				max_x_p = str_glob->first_out_l_part+str_glob->nof_out_l_part-1;
			if (max_y_p > (str_glob->first_out_s_part+str_glob->nof_out_s_part-1)) 
				max_y_p = str_glob->first_out_s_part+str_glob->nof_out_s_part-1;
		
			if((area == first_area) && (af_x_inp[0]<af_x_inp[2])) down=1;

/*-------------------------------------------------------------------	*/
/* 			initial application of the transformation	*/
/*			from out- to input image			*/
/*-------------------------------------------------------------------	*/

			callfunc = hwapppro ((double)min_x_p, (double)min_y_p, inp_off, out_off,
				    &initial_l, &initial_s, a);

			initial_l -= (double)anch_l1;
			initial_s -= 1.0;
			
			x_start = min_x_p-str_glob->first_out_l_part;
			x_end   = max_x_p-str_glob->first_out_l_part;
 
			y_start = min_y_p-str_glob->first_out_s_part;
			y_end   = max_y_p-str_glob->first_out_s_part;
			
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
							if (up_int_save<-int_l)continue;
							}
						else
							{
							int_l=(int)l;				
							if ((int_l+1)>=nof_read_inp_lines)continue;		
							} 
						int_s=(int)s;				
/*---------------------------------------------------------------------	*/
/* 						in:			*/
/*---------------------------------------------------------------------	*/
											
/*---------------------------------------------------------------------	*/
/* 						interpolate a grayvalue */
/*---------------------------------------------------------------------	*/
						switch (str_glob->interpol_type)
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
							*gv *= str_glob->phoCorVal_vec[p];
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
							*gv *= str_glob->phoCorVal_vec[p];
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

							*gv = *(gv_inp_buf+inp_buf_off)*str_glob->phoCorVal_vec[p];
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
							*(gv_out_buf_byte + out_buf_off) = *(tab_gv + (int)*gv);
							}
						else if (str_glob->oformat == 2)
							{
							*(gv_out_buf_half + out_buf_off) = (short int)(*gv);
						
							}
						else if (str_glob->oformat == 3)
							{
							*(gv_out_buf_full + out_buf_off) = (int)(*gv);
							}
						else
							{
							*(gv_out_buf_float + out_buf_off) = *gv;
							}
						
						if (str_glob->match !=0)
						    {
						    *(match_x_buf + out_buf_off) = (float)(l + (double)anch_l1);
						    *(match_y_buf + out_buf_off) = (float)(s + 1.0);
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

		area++;
		} 

	free (gv_inp_buf);

	/*----------------------------------------------------	*/
	/* write output-grayvalues				*/
	/*----------------------------------------------------	*/
	for (i=str_glob->first_out_l_part; i<str_glob->first_out_l_part+str_glob->nof_out_l_part; i++)				
		{
		out_buf_off=(i-str_glob->first_out_l_part)*str_glob->nof_out_s_part;
		if (str_glob->match !=0 )
			{
				callfunc = encode_refline 
					  (match_x_buf+out_buf_off, str_glob->nof_out_s_part, str_glob->new_match_x_unit, str_glob->match_prec, i, str_glob->index_x);
				if (callfunc < 0)
					{
					printf ("Encode error: %d !\n",callfunc);
					zabend();
					}
				callfunc = encode_refline 
					  (match_y_buf+out_buf_off, str_glob->nof_out_s_part, str_glob->new_match_y_unit, str_glob->match_prec, i, str_glob->index_y);
				if (callfunc < 0)
					{
					printf ("Encode error: %d !\n",callfunc);
					zabend();
					}
			}

		if (str_glob->oformat == 1)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_byte+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 2)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_half+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 3)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_full+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		else if (str_glob->oformat == 4)
			{
			callfunc = zvwrit (str_glob->outunit, (gv_out_buf_float+out_buf_off),
			"LINE", i, "SAMP", str_glob->first_out_s_part, "NSAMPS", str_glob->nof_out_s_part, 0);
			}
		}

	if (str_glob->oformat == 1) free (gv_out_buf_byte);
	else if (str_glob->oformat == 2) free (gv_out_buf_half);
	else if (str_glob->oformat == 3) free (gv_out_buf_full);
	else if (str_glob->oformat == 4) free (gv_out_buf_float);
		
	if (str_glob->match !=0 )
	    {
    	    free (match_x_buf);
  	    free (match_y_buf);
	    }	

	return (0);
	}

/*==========================================================================*/
/*#############################################################	*/
/* Transformation of up to MAX_PIXEL_PER_LINE pixels at one ephemeris time
	from image plane via reference body to map projection	
						(private)	*/
/*#############################################################	*/
/* Calls from	hworloc, hwgeorec				*/
/* Calling	zfladjuview, dlrsurfpt, zhwcarto			*/
/*#############################################################	*/

	int hwtraidtm_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, int line, int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, int loc_rec, short int *dtm_buf)
	/*#############################################################*/
 
	{
	int	centriclltype = 1;	
	int	graphiclltype = 2;	
	int	forward = 0, callfunc, i, j, k, above;

	double	*tempMDirView, GON2PI=PI/200.0;
		/*	One line of sight vector in body fixed hw	*/
	double	intersection_point[3], shifted_intersection_point[3], positn[3];	/*	Position in body-fixed hw	*/
	double	lat=999.9, longi=999.9, latlong[3];
	double	a_ax, b_ax, c_ax, l_ax, dist2, radius;

	double	temp_mat[3][3], DirSurf[3], MDirView[3];
	char	outstring[20];
	int	all_quads, found_ell, found_ell_vec[2], int_l, int_s, int_hit_lin_act, int_hit_sam_act, centerlongitude;
	short int  *dtm_lo, *dtm_ro, *dtm_lu, *dtm_ru, local_dn, hit_dn[2], short_miss;
	double	add_h[2], height, d_l, d_s, local_max_h, local_min_h;
	float	f_temp;
	double  hit_dlin, hit_dsam,  hit_lin[2], hit_sam[2], hit_dist, hit_grad, hit_off, hit_lin_step, hit_sam_step, hit_lin_act,
	        hit_sam_act, hit_dn_step, hit_dn_act, act_l, act_s;
	int	hit_steps;

	double phoCorVal, cpmat[3][3];
	double	x1,y1,z1,d,temp_centric_cenlat,temp_centric_cenlon;
	hrpref_typ HR_Prefix;

	if (str_glob->use_extori && fabs (str_glob->kappa[line-1]) > 400.)
		{
		for (k=0; k<nof_pix; k++) foundvec[k] = 0;
		return (1);
		}

	if ((str_glob->dtm_axes[0] < 1000.) && (!(str_glob->geom))) 
		{
		callfunc = hwtraidtm_ripnew (str_glob, mp_obj, prefs, prefs_dtm, dtmunit, line, nof_pix,
		      ccd, x, y, foundvec, signvec, loc_rec, dtm_buf);
		return (callfunc);
		}

	tempMDirView=(double *)calloc(1,nof_pix*3*sizeof(double));
		if (tempMDirView == (double *)NULL) return(-998); 

	l_ax=str_glob->long_axis;
 	short_miss = (short int)str_glob->dtmlabel.dtm_missing_dn;
	/*---------------------------------------------------------
	  Compute line of sight vectors of all pixels and position of s/c
	  ---------------------------------------------------------	*/

	hrrdpref( str_glob->inunit, line, &HR_Prefix);

	if (str_glob->use_extori)
		{
		positn[0]=str_glob->xyz0[line-1]/1000.0;
		positn[1]=str_glob->xyz1[line-1]/1000.0;
		positn[2]=str_glob->xyz2[line-1]/1000.0;
		dlrkop2m(str_glob->kappa[line-1]*GON2PI, str_glob->omega[line-1]*GON2PI, str_glob->phi[line-1]*GON2PI, cpmat);

		dlrmtxm (phot2cam,cpmat,cpmat);
		zfladjuview (nof_pix, ccd, cpmat, str_glob->xcal, str_glob->ycal, -str_glob->focal, tempMDirView);
		}
	else
		{
		callfunc = hrviewpa 	(str_glob->target_name, str_glob->spacecraft_name, str_glob->ins_name, 
				HR_Prefix.EphTime, nof_pix, ccd, str_glob->xcal, str_glob->ycal, str_glob->focal, positn, tempMDirView);

		if (callfunc != 1)
			{
			printf ("ERROR %d in hrviewpa !\n", callfunc);
			zabend();
			}	
		}
	
	for (k=0; k<nof_pix; k++)	/* loop of all pixels	*/
		{

		foundvec[k] = 0;
		
		if (((double)(ccd[k])>str_glob->ignore_max)||((double)(ccd[k])<str_glob->ignore_min))
		    {
		    continue;
		    }

		for (i=0; i<=2; i++) { MDirView [i] = *(tempMDirView+3*k+i);}
		
	 	if(str_glob->pho_calc_done!=1)
		    {
		    callfunc = hwphoeco(str_glob->pho_obj, str_glob->DirEll, str_glob->MDirInc, MDirView,
			str_glob->TargIncAng, str_glob->TargViewAng, str_glob->TargAzimAng, 
			&phoCorVal);
		    str_glob->phoCorVal_vec[k] = phoCorVal;
		    }
		/*----------------------------------------------------	
		  Intersection point of one line of sight with dtm / ref. body	
		  ----------------------------------------------------	*/
		if (!(str_glob->geom))
		{
		height = -999999.9;
		add_h[0]=str_glob->max_h_in_dtm;
		add_h[1]=str_glob->min_h_in_dtm;
		hit_dn[0]=(short int)((str_glob->max_h_in_dtm-(double)(str_glob->dtmlabel.dtm_offset))/str_glob->dtmlabel.dtm_scaling_factor);
		hit_dn[1]=(short int)((str_glob->min_h_in_dtm-(double)(str_glob->dtmlabel.dtm_offset))/str_glob->dtmlabel.dtm_scaling_factor);

		for (i=0;i<2;i++)
		    {
		    a_ax=str_glob->dtm_axes[0]+add_h[i]/1000.0; /* in km */
		    b_ax=str_glob->dtm_axes[1]+add_h[i]/1000.0; /* in km */
		    c_ax=str_glob->dtm_axes[2]+add_h[i]/1000.0; /* in km */
    
		    dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell_vec[i]);
			if (found_ell_vec[0]!=1) break;

		    rec2graphicll (intersection_point, str_glob->dtm_axes_map, latlong);
    
		    lat = latlong[0]*my_pi2deg;
		    longi = latlong[1]*my_pi2deg*str_glob->dtm_poslongdir_fac;
		    callfunc = zhwcarto (str_glob->mp_dtm_obj, prefs_dtm, &hit_lin[i], &hit_sam[i], &lat, &longi, graphiclltype, forward);
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
		    	local_dn = *(dtm_buf+(*(str_glob->dtm_tab_in+(int)(hit_lin[0]+0.5)-1)+(int)(hit_sam[0]+0.5)-1));
		    	if (local_dn != short_miss) 
				height = (double)(str_glob->dtmlabel.dtm_scaling_factor * (double)local_dn + str_glob->dtmlabel.dtm_offset); /* in m */
			}
		    }
		else
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
		    	callfunc = hwintdtm_bi (dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act-1),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act-1),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act),
                                        hit_lin_act-(double)int_hit_lin_act, 
                                        hit_sam_act-(double)int_hit_sam_act, 
                                        short_miss, &local_dn);
                if (callfunc < 0) {above = 0;continue;}

		    	if (((double)local_dn > hit_dn_act)&& above) 
				{
                height = (double)(str_glob->dtmlabel.dtm_scaling_factor * (double)local_dn + str_glob->dtmlabel.dtm_offset); /* in m */
				break;
				}
		    	else {above = 1;}
		    	}
		    }

		if (height < -999999.0)
		    {
		    foundvec[k] = 0;
		    continue;
		    }
		}
		else height=str_glob->height;

		a_ax=str_glob->dtm_axes[0]+height*0.001; /* in km */
		b_ax=str_glob->dtm_axes[1]+height*0.001; /* in km */
		c_ax=str_glob->dtm_axes[2]+height*0.001; /* in km */
    
		dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell);
		if (found_ell!=1) continue;

		foundvec[k] = 1;
		str_glob->found = 1;
		str_glob->found_in_dtm = 1;

		rec2graphicll (intersection_point, str_glob->mp_axes, latlong);
   
		lat = latlong[0]*my_pi2deg;
		longi = latlong[1]*my_pi2deg*str_glob->poslongdir_fac;

/*SIGN		signvec[k] = 0; SIGN*/
		/*----------------------------------------------------	
		 Transform one point from lat/long to a map projected x/y	
		 -----------------------------------------------------  */	
		callfunc = zhwcarto (mp_obj, prefs, &x[k], &y[k], &lat, &longi, graphiclltype, forward);
		if (callfunc != mpSUCCESS)
			    {
 			    printf("\n hwcarto returns %d !",callfunc);
    			    zabend();
			    }
		if (longi < str_glob->min_longi) str_glob->min_longi = longi;
		if (longi > str_glob->max_longi) str_glob->max_longi = longi;
		if (lat < str_glob->min_lati) str_glob->min_lati = lat;
		if (lat > str_glob->max_lati) str_glob->max_lati = lat;

		if (loc_rec == 0) continue;
		}
					
	free(tempMDirView);

/*POLE	if (loc_rec == 0)
	    {
	    all_quads = str_glob->quad[0] + str_glob->quad[1] + str_glob->quad[2] + str_glob->quad[3];
	    if (((str_glob->max_longi-str_glob->min_longi)>340.0)&&(all_quads == 0))
		{str_glob->pole=1;}
	    }
POLE*/
	centerlongitude=(int)(longi);
if ((nof_pix==1)&&(loc_rec==0))x[0]=(double)((int)(lat)); /* rough approximation of requested center_latitude */

	return(centerlongitude);
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
/* Computation of a projective transformation
					(private)			*/
/*##############################################################	*/
/* Calls from	hwgeorec						*/
/* Calling	--				*/
/*##############################################################	*/

	int hwgetpro  (double *in_u, double *in_v, double *in_x,
		       double *in_y, double *a)

	{
	double	c[41], u[4], v[4], x[4], y[4];

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
	
	return(0);
	}

/*##############################################################	*/
/* Application off projective transformation from inp = rectified img
   to out = inputimg	given by a-, b-coefficients 	(private)	*/
/*##############################################################	*/
/* Calls from	FRAMEGEOREC						*/
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

/*=====================================================================*/
/*##############################################################	*/
/* Computation of grayvalue by Bilinear Interpolation 	(private)	*/
/*##############################################################	*/
/* Calls from	hwgeorec						*/
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
	
	return 0.0;
	}

/*=====================================================================*/
/*##############################################################	*/
/* Computation of grayvalue by Cubic Convolution 	(private)	*/
/*##############################################################	*/
/* Calls from	hwgeorec (private)					*/
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
/* Calls from	hwgeorec						*/
/* Calling	hrrdpref						*/
/*##############################################################	*/


	int hwgetapt (str_glob_type *str_glob, int l, int mid_of_l, int first_s,
		       int *nof_le_p, int *nof_ri_p, int *s)
	
/*##############################################################	*/
	
	{
	int	k;
	int	le_part_of_l, ri_part_of_l; 
	
/*--------------------------------------------------------------	*/
/*	compute left anchorpoint-samples 				*/
/*--------------------------------------------------------------	*/
	le_part_of_l = mid_of_l - first_s;
	*nof_le_p = (le_part_of_l + str_glob->anchdist/2)/str_glob->anchdist;
	if (*nof_le_p < 0) *nof_le_p = 0;
/*--------------------------------------------------------------	*/
/*	mid anchorpoint-sample 						*/
/*--------------------------------------------------------------	*/
	s[*nof_le_p] = mid_of_l;

/*--------------------------------------------------------------	*/
/*	left anchorpoint-samples 					*/
/*--------------------------------------------------------------	*/
	for (k=1; k < *nof_le_p; k++)
		{ s[*nof_le_p-k] = s[*nof_le_p-k+1] - str_glob->anchdist; }

/*--------------------------------------------------------------	*/
/*	first left anchorpoint-sample 					*/
/*--------------------------------------------------------------	*/
	s[0] = first_s;

/*--------------------------------------------------------------	*/
/*	now compute right anchorpoint-samples 				*/
/*--------------------------------------------------------------	*/
	ri_part_of_l = (first_s+str_glob->nof_inp_s-1)-mid_of_l;
	*nof_ri_p = (ri_part_of_l + str_glob->anchdist/2)/str_glob->anchdist;
	if (*nof_ri_p < 0) *nof_ri_p = 0;
/*--------------------------------------------------------------	*/
/*	right anchorpoint-samples 					*/
/*--------------------------------------------------------------	*/
	for (k=*nof_le_p+1; k < *nof_le_p+*nof_ri_p; k++)
		{ s[k] = s[k-1] + str_glob->anchdist; }

/*--------------------------------------------------------------	*/
/*	last right anchorpoint-sample 					*/
/*--------------------------------------------------------------	*/
	if (*nof_ri_p > 0) s[*nof_le_p+*nof_ri_p] = first_s + str_glob->nof_inp_s - 1;

	return(0);
	}


/*=====================================================================*/
/*##############################################################	*/
/* sorts anchorpoints		  			(private)	*/
/*##############################################################	*/
/* Calls from	hwgeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/


	int hwsortap 
	(int nof_up_le_p, int nof_up_ri_p, int *up_s, 
	 double *up_x, double *up_y, int *up_foundvec, int *up_signvec,
	 int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, 
	 double *lo_x, double *lo_y, int *lo_foundvec, int *lo_signvec)
/*##############################################################	*/
	
	{
	int	le_diff, ri_diff, j, k;	
	
	le_diff=nof_up_le_p-nof_lo_le_p;
	if (le_diff < 0)
		{
		for (j=0; j <= nof_lo_le_p+nof_lo_ri_p+le_diff; j++)
			{
			k = j-le_diff;
			lo_s[j] = lo_s[k];
			lo_x[j] = lo_x[k];
			lo_y[j] = lo_y[k];
			lo_foundvec[j] = lo_foundvec[k];
/*SIGN			lo_signvec[j] = lo_signvec[k];SIGN*/
			}
		nof_lo_le_p += le_diff;
		}
	else if (le_diff > 0)
		{
		for (j=0; j <= nof_up_le_p+nof_up_ri_p-le_diff; j++)
			{
			k = j+le_diff;
			up_s[j] = up_s[k];
			up_x[j] = up_x[k];
			up_y[j] = up_y[k];
			up_foundvec[j] = up_foundvec[k];
/*SIGN			up_signvec[j] = up_signvec[k];SIGN*/
			}
		nof_up_le_p -= le_diff;
		}
		
	ri_diff=nof_up_ri_p-nof_lo_ri_p;
	
	if	(ri_diff < 0) nof_lo_ri_p += ri_diff;
	else if (ri_diff > 0) nof_up_ri_p -= ri_diff;
		

	return (0);		
	}

/*=====================================================================*/
/*##############################################################	*/
/* gets anchorpoint patches 	  			(private)	*/
/*##############################################################	*/
/* Calls from	hwgeorec_rip						*/
/* Calling	-							*/
/*##############################################################	*/


	int hwgetapp 
	(int nof_up_le_p, int nof_up_ri_p, int *up_s, 
	 double *up_x, double *up_y, int *up_foundvec, int *up_signvec,
	 int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, 
	 double *lo_x, double *lo_y, int *lo_foundvec, int *lo_signvec,
	 int *nof_p, int *s_ap1, int *s_ap2, int *s_ap3, int *s_ap4,
	 double *x_ap1, double *x_ap2, double *x_ap3, double *x_ap4,
	 double *y_ap1, double *y_ap2, double *y_ap3, double *y_ap4, int *dtm_no_dtm)
	 	
/*##############################################################	*/
	
	{
	int	j;	

	for (j=0; j <= nof_up_le_p + nof_up_ri_p - 1; j++)
		{
		if (((up_foundvec[j]*up_foundvec[j+1]*
			     lo_foundvec[j]*lo_foundvec[j+1]) == 0)
/*SIGN		|| ((abs(up_signvec[j]+up_signvec[j+1]+
			     lo_signvec[j]+lo_signvec[j+1]) != 4)&&((up_signvec[j]*up_signvec[j+1]*
			     lo_signvec[j]*lo_signvec[j+1]) != 0))
SIGN*/
			     ) dtm_no_dtm[j]=0;
		else							   dtm_no_dtm[j]=1;
		s_ap1[j] = up_s[j];
		s_ap2[j] = up_s[j+1];
		s_ap3[j] = lo_s[j];
		s_ap4[j] = lo_s[j+1];
		x_ap1[j] = up_x[j];
		x_ap2[j] = up_x[j+1];
		x_ap3[j] = lo_x[j];
		x_ap4[j] = lo_x[j+1];
		y_ap1[j] = up_y[j];
		y_ap2[j] = up_y[j+1];
		y_ap3[j] = lo_y[j];
		y_ap4[j] = lo_y[j+1];
		}	

	*nof_p = nof_lo_le_p + nof_lo_ri_p;
	
	return (0);
	}
		
/*#############################################################*/
    void check_size(str_glob_type *str_glob)
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
		sprintf(outstring, "allowed by parameter OUTMAX (%ld MegaByte) => ABORT !! "
							, (long)(str_glob ->max_sof_outfile));
     		zvmessage(outstring,"");
		zabend();
		}
	}
/*#############################################################*/
void pixnum2ccd (str_glob_type *str_glob, float *ccd)
	{
	*ccd += (float)str_glob->fap;
	*ccd -= (float)(str_glob->non_active_pixel_start);
	}
void xyz2ll_centric ( double *xyz, double *ll)
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
int check_quad_gespiegelt ( double *line,  double *sample )
{
   double  a, b, c, d, e, f, h, i, k, l, m, n, o, temp1, temp2, temp3, temp4;
   double my_twopi=(2.0*PI);
   double my_justpi=(PI-0.001);

   f = sample[0]-sample[1];
   h = line[1]-line[0];
   i = sample[3]-sample[1];
   k = line[1]-line[3];
   l = sample[2]-sample[0];
   m = line[0]-line[2];
   n = sample[3]-sample[2];
   o = line[2]-line[3];
   
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
int check_quad ( double *line,  double *sample )
{
   double  a, b, c, d, e, f, h, i, k, l, m, n, o, temp1, temp2, temp3, temp4;
   double my_twopi=(2.0*PI);
   double my_justpi=(PI-0.001);

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

int init_reffile_for_creation (FILE *fp, int nof_lines, int nof_samples, long *index)
	{
	if (0         != fseek (fp, 0, SEEK_SET)) return (-1);	
	if (1         != fwrite(&nof_lines, sizeof(int), 1, fp)) return (-2);
	if (1         != fwrite(&nof_samples, sizeof(int), 1, fp)) return (-3);

	if (nof_lines != fwrite(index, sizeof(long), nof_lines, fp)) return (-4);

	return (1);
	}

int prepare_reffile_for_initclose (FILE *fp, int nof_lines, long *index, int sl, int nl, int ss, int ns, char *filename)
	{
	int name_len, i;

	if (0         != fseek (fp, (long)(2*sizeof(int)), SEEK_SET)) return (-1);	
	if (nof_lines != fwrite(index, sizeof(long), nof_lines, fp)) return (-2);

	if (0         != fseek (fp, 0, SEEK_END)) return (-3);	
	name_len = strlen(filename);
	if (1         != fwrite(filename, name_len, 1, fp)) return (-4);
	if (1         != fwrite(&name_len, sizeof(int), 1, fp)) return (-5);
	if (1         != fwrite(&sl, sizeof(int), 1, fp)) return (-6);
	if (1         != fwrite(&nl, sizeof(int), 1, fp)) return (-7);
	if (1         != fwrite(&ss, sizeof(int), 1, fp)) return (-8);
	if (1         != fwrite(&ns, sizeof(int), 1, fp)) return (-9);

	return (1);
	}


int encode_refline (float *line, int length_line, FILE *fp, double prec, int line_number, long *index)
	{
	int 	start_s, end_s, nof_s, i, n;
	float	ds;
	unsigned char temp, uc_val_255=255;	

	if (0 != fseek (fp, 0, SEEK_END)) return (-1);	
	index[line_number-1] = ftell (fp);
	start_s = 0;
	while (line[start_s] < 1.0) if (start_s++ == length_line) break;
	
	end_s = length_line - 1;
 	while (line[end_s] < 1.0) if (end_s-- < start_s) break;

	nof_s = end_s - start_s + 1;

	if (1 != fwrite (&nof_s, sizeof(int), 1, fp)) return (-2);
	if (nof_s == 0) return (1);

	if (1 != fwrite (&start_s, sizeof(int), 1, fp)) return (-3);
	if (1 != fwrite (&line[start_s], sizeof(float), 1, fp)) return (-4);
	i = start_s;

	while (i < end_s)
		{
		n = 1;
		ds = line[i+n] - line[i];
		if (1 != fwrite (&ds, sizeof(float), 1, fp)) return (-5);

		while (fabs((double)(line[i+n] - line[i] - (float)n*ds)) < prec)
			if ((i+ (++n)) > end_s) break;

		i += --n;

		if (1 != fwrite (&line[i], sizeof(float), 1, fp)) return (-6);

		while (n >= 255)
			{
			if (1 != fwrite (&uc_val_255, sizeof(unsigned char), 1, fp)) return (-7);
			n -= 255;
			}

		temp = (unsigned char)n;
		if (1 != fwrite (&temp, sizeof(unsigned char), 1, fp)) return (-8);		
		}
	return (1);
	}

int decode_refline (float *line, int length_line, FILE *fp, int line_number, long *index)
	{
	int 	start_s, end_s, nof_s, i, actpos, nsum;
	float	last, val_start_s, ds;
	unsigned char n;	

	if (index[line_number-1] == (long)0) 
		{
		for (i=0;i<length_line;i++) line[i] = 0.0;
		return (1);

		}
	if (0 != fseek (fp, index[line_number-1], SEEK_SET)) return (-1);	

	if (1 != fread (&nof_s, sizeof(int), 1, fp)) return (-2);
	if (nof_s == 0) 
		{
		for (i=0;i<length_line;i++) line[i] = 0.0;
		return (1);
		}
	if (1 != fread (&start_s, sizeof(int), 1, fp)) return (-3);
	if (1 != fread (&val_start_s, sizeof(float), 1, fp)) return (-4);

	actpos = 0;
	end_s = start_s + nof_s - 1;

	for (i=0;i<start_s; i++) line[i]=0.0;

	actpos += start_s;

	line[actpos] = val_start_s;
	actpos++;

	while (actpos <= end_s)
		{
		if (1 != fread (&ds, sizeof(float), 1, fp)) return (-5);
		if (1 != fread (&last, sizeof(float), 1, fp)) return (-6);
		if (1 != fread (&n, sizeof(unsigned char), 1, fp)) return (-7);

		nsum = (int)n;
		while (n==255) 
			{
			if (1 != fread (&n, sizeof(unsigned char), 1, fp)) return (-8);
			nsum += (int)n;
			}

		for (i=actpos;i<actpos+nsum;i++) line[i] = line[actpos-1] + (float)(i-actpos+1)*ds;
	
		actpos += nsum;

		line[actpos-1] = last;
		}
	for (i=end_s+1;i<length_line; i++) line[i]=0.0;
	return (1);
	}

	int hwtraidtm_ripnew (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, int line, int nof_pix,
		      float *ccd, double *x, double *y,
		      int *foundvec, int *signvec, int loc_rec, short int *dtm_buf)
	/*#############################################################*/
 
	{
	int	centriclltype = 1;	
	int	graphiclltype = 2;	
	int	forward = 0, callfunc, i, j, k, above;

	double	*tempMDirView, GON2PI=PI/200.0;
		/*	One line of sight vector in body fixed hw	*/
	double	intersection_point[3], shifted_intersection_point[3], positn[3];	/*	Position in body-fixed hw	*/
	double	lat=999.9, longi=999.9, latlong[3], centerlongitude;
	double	a_ax, b_ax, c_ax, l_ax, dist2, radius;

	double	temp_mat[3][3], DirSurf[3], MDirView[3];
	char	outstring[20];
	int	all_quads, found_ell, found_ell_vec[2], int_l, int_s, int_hit_lin_act, int_hit_sam_act;
	short int  *dtm_lo, *dtm_ro, *dtm_lu, *dtm_ru, local_dn, short_miss;
	double	add_h[2], height, d_l, d_s, local_max_h, local_min_h;
	float	f_temp;
	double  hit_dlin, hit_dsam,  hit_lin[2], hit_sam[2], hit_dist, hit_grad, hit_off, hit_xyz_act[3],
			hit_lin_step[3], hit_sam_step, hit_lin_act[3],
	        hit_sam_act,  act_l, act_s, hit_dx, hit_dy, hit_dz;
	int	hit_steps;

	double phoCorVal, cpmat[3][3], latlongh[3], xx[3], yy[3], zz[3];
	double	x1,y1,z1,d,temp_centric_cenlat,temp_centric_cenlon,stepwidth,saveaddh1;
	hrpref_typ HR_Prefix;
	
	tempMDirView=(double *)calloc(1,nof_pix*3*sizeof(double));
		if (tempMDirView == (double *)NULL) return(-998); 

	l_ax=str_glob->long_axis;
 	short_miss = (short int)str_glob->dtmlabel.dtm_missing_dn;
	/*---------------------------------------------------------
	  Compute line of sight vectors of all pixels and position of s/c
	  ---------------------------------------------------------	*/

	hrrdpref( str_glob->inunit, line, &HR_Prefix);

	if (str_glob->use_extori)
		{
		positn[0]=str_glob->xyz0[line-1]/1000.0;
		positn[1]=str_glob->xyz1[line-1]/1000.0;
		positn[2]=str_glob->xyz2[line-1]/1000.0;
		dlrkop2m(str_glob->kappa[line-1]*GON2PI, str_glob->omega[line-1]*GON2PI, str_glob->phi[line-1]*GON2PI, cpmat);

		dlrmtxm (phot2cam,cpmat,cpmat);
		zfladjuview (nof_pix, ccd, cpmat, str_glob->xcal, str_glob->ycal, -str_glob->focal, tempMDirView);
		}
	else
		{
		callfunc = hrviewpa 	(str_glob->target_name, str_glob->spacecraft_name, str_glob->ins_name, 
				HR_Prefix.EphTime, nof_pix, ccd, str_glob->xcal, str_glob->ycal, str_glob->focal, positn, tempMDirView);
		if (callfunc != 1)
			{
			printf ("ERROR %d in hrviewpa !\n", callfunc);
			zabend();
			}	
		}
	
	for (k=0; k<nof_pix; k++)	/* loop of all pixels	*/
		{

		foundvec[k] = 0;
		
		if (((double)(ccd[k])>str_glob->ignore_max)||((double)(ccd[k])<str_glob->ignore_min))
		    {
		    continue;
		    }

		for (i=0; i<=2; i++) { MDirView [i] = *(tempMDirView+3*k+i);}
		
	 	if(str_glob->pho_calc_done!=1)
		    {
		    callfunc = hwphoeco(str_glob->pho_obj, str_glob->DirEll, str_glob->MDirInc, MDirView,
			str_glob->TargIncAng, str_glob->TargViewAng, str_glob->TargAzimAng, 
			&phoCorVal);
		    str_glob->phoCorVal_vec[k] = phoCorVal;
		    }
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
		    callfunc = zhwcarto (str_glob->mp_dtm_obj, prefs_dtm, &hit_lin[i], &hit_sam[i], &lat, &longi, graphiclltype, forward);
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
			callfunc = zhwcarto (str_glob->mp_dtm_obj, prefs_dtm, &hit_lin[1], &hit_sam[1], &lat, &longi, graphiclltype, forward);
			}
			
		hit_dx   = xx[1]-xx[0];
		hit_dy   = yy[1]-yy[0];
		hit_dz   = zz[1]-zz[0];
		hit_dist = sqrt((hit_lin[1]-hit_lin[0])*(hit_lin[1]-hit_lin[0])
					   +(hit_sam[1]-hit_sam[0])*(hit_sam[1]-hit_sam[0]));
		
		if (hit_dist<1.)
		    {
		    if ((hit_lin[0]>=1.0)&&(hit_lin[0]<=(double)str_glob->nof_dtm_l)&&
			(hit_sam[0]>=1.0)&&(hit_sam[0]<=(double)str_glob->nof_dtm_s))
		    	{
		    	local_dn = *(dtm_buf+(*(str_glob->dtm_tab_in+(int)(hit_lin[0]+0.5)-1)+(int)(hit_sam[0]+0.5)-1));
		    	if (local_dn != short_miss) 
				height = (double)(str_glob->dtmlabel.dtm_scaling_factor * (double)local_dn + str_glob->dtmlabel.dtm_offset); /* in m */
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
		    	callfunc = zhwcarto (str_glob->mp_dtm_obj, prefs_dtm, &hit_lin[0], &hit_sam[0], &lat, &longi, graphiclltype, forward);

				int_hit_lin_act = (int)hit_lin[0];
				int_hit_sam_act = (int)hit_sam[0];
		    	if((int_hit_lin_act<1)||(int_hit_lin_act>=(str_glob->nof_dtm_l-1))
                  ||(int_hit_sam_act<1)||(int_hit_sam_act>=(str_glob->nof_dtm_s-1))) {above = 0;continue;}
		    	callfunc = hwintdtm_bi (dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act-1),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act-1)+int_hit_sam_act),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act-1),
                                        dtm_buf+(*(str_glob->dtm_tab_in+int_hit_lin_act)+int_hit_sam_act),
                                        hit_lin[0]-(double)int_hit_lin_act, 
                                        hit_sam[0]-(double)int_hit_sam_act, 
                                        short_miss, &local_dn);
                if (callfunc < 0) {above = 0;continue;}

		    	if (((double)(str_glob->dtmlabel.dtm_scaling_factor * (double)local_dn 
				     + str_glob->dtmlabel.dtm_offset) > latlongh[2]*1000.)&& above) 
					{
                	height = (double)(str_glob->dtmlabel.dtm_scaling_factor * (double)local_dn + str_glob->dtmlabel.dtm_offset); /* in m */
					break;
					}
		    	else {above = 1;}
		    	}
		    }

		if (height < -999999.0)
		    {
		    foundvec[k] = 0;
		    continue;
		    }
		}
		else height=str_glob->height;
	

		a_ax=str_glob->dtm_axes[0]+height*0.001; /* in km */
		b_ax=str_glob->dtm_axes[1]+height*0.001; /* in km */
		c_ax=str_glob->dtm_axes[2]+height*0.001; /* in km */
    
		dlrsurfpt (positn, MDirView, a_ax, b_ax, c_ax, intersection_point, &found_ell);
		if (found_ell!=1) continue;

		foundvec[k] = 1;
		str_glob->found = 1;
		str_glob->found_in_dtm = 1;

		rec2graphicll (intersection_point, str_glob->mp_axes, latlong);
   
		lat = latlong[0]*my_pi2deg;
		longi = latlong[1]*my_pi2deg*str_glob->poslongdir_fac;

/*SIGN		signvec[k] = 0; SIGN*/
		/*----------------------------------------------------	
		 Transform one point from lat/long to a map projected x/y	
		 -----------------------------------------------------  */	
		callfunc = zhwcarto (mp_obj, prefs, &x[k], &y[k], &lat, &longi, graphiclltype, forward);
		if (callfunc != mpSUCCESS)
			    {
 			    printf("\n hwcarto returns %d !",callfunc);
    			    zabend();
			    }
		if (longi < str_glob->min_longi) str_glob->min_longi = longi;
		if (longi > str_glob->max_longi) str_glob->max_longi = longi;
		if (lat < str_glob->min_lati) str_glob->min_lati = lat;
		if (lat > str_glob->max_lati) str_glob->max_lati = lat;

		if (loc_rec == 0) continue;
		}
					
	free(tempMDirView);

/*POLE	if (loc_rec == 0)
	    {
	    all_quads = str_glob->quad[0] + str_glob->quad[1] + str_glob->quad[2] + str_glob->quad[3];
	    if (((str_glob->max_longi-str_glob->min_longi)>340.0)&&(all_quads == 0))
		{str_glob->pole=1;}
	    }
POLE*/
	centerlongitude=(int)(longi);
if ((nof_pix==1)&&(loc_rec==0))x[0]=(double)((int)(lat)); /* rough approximation of requested center_latitude */

	return(centerlongitude);
	}

$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create hrortho.h
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "vicmain_c"

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>		
#include <string.h>  
#include <math.h> 

#if UNIX_OS
#include <malloc.h>	
#include <alloca.h>
#endif

#include "hwconst.h"
#include "ax_constants.h"
#include "dlrspice.h"
#include "mp_routines.h"
#include "dlrmapsub.h"
#include "dlrpho.h"
#include "hwldker.h"
#include "hrpref.h"
#include "dtm.h"
#include "hrgetstdscale.h"
#include "extori.h"
 

typedef unsigned char myBYTE;
#define ANCHDIST_FREQ 80.
#define MAXLINESIZE  1000
#define STRING_SIZE  120
#define MAX_PIXEL_PER_LINE TOTAL_ACTIVE_PIXEL

double my_pi2deg=(180.0/PI);
double my_deg2pi=(PI/180.0);

typedef struct	{int	inunit;
	 int    first_georec;
	 char	spacecraft_name[120];
	 char	out_filename[120];
	 char	inp_filename[120];
	 char	dtm_filename[120];
	 char	fittofile_name[120];
	 int	fittofile;
	 int    geom;
	 double expo_t;
	 double height;
	 double *time;
	 int    non_active_pixel_start;
	 char	geocal_dir[120];
	 char	h_geocal_version[80];
	 char	gcal_filename[120];
	 int	nof_inp_l;
	 int	nof_inp_s;
	 double	ignore;
	 double	ignore_min;
	 double	ignore_max;
	 int	sl_inp;
	 int	nl_inp;
	 int	dtmunit;
	 int	nof_dtm_l;
	 int	nof_dtm_s;
	 int	outunit;
	 int	new_match_type;
	 FILE   *new_match_x_unit;
	 FILE   *new_match_y_unit;
	 long   *index_x;
	 long   *index_y;
	 double match_prec;
	 int	first_used_l;
	 int	last_used_l;
	 int	first_out_l_part;
	 int	first_out_s_part;
	 int	nof_out_l_part;
	 int	nof_out_s_part;
	 int	nof_out_l;
	 int	nof_out_s;
	 int	first_io;
	 int	parts;
	 int	nof_parts ;
         int	first_inp_l_part;
         int	nof_inp_l_part;
	 double	maxx;
	 double	maxy;
	 double	minx;
	 double	miny;
	 int	oformat;
	 int	ram_set;
 	 double	ram_use;
 	 int	ram_dtm;
	 int	macro;
	 int	fp;
	 int	fap;
	 int	fillp;
	 double	max_sof_outfile;
	 double	scale_resolution;
	 double	scale_not_set;
	 int	interpol_type;
	 int	nbb;
	 int	nl;
	 int	ns;
	 char	report[4];
	 int	match;
	 int	anchdist;
	 int	border;
	 int	adj_par;
	 int	pole;
	 int	found;
	 int	found_in_dtm;
	 double	cenlat;
	 double	cenlong;
	 double	xcen;
	 double	ycen;
	 double	zcen;
	 double	d0;
	 double	d02;
	 double	ll[2];
	 double	min_lati;
	 double	min_longi;
	 double	max_lati;
	 double	max_longi;
	 char	mptype[mpMAX_KEYWD_LENGTH+1];
	 int	phocorr;
	 int	critical_projection;
	 int	quad[4];
	 double dtm_poslongdir_fac;
	 double poslongdir_fac;
	 double TargIncAng;
	 double TargViewAng;
	 double TargAzimAng;
	 double MDirInc[3];
	 int	target_id;
	 char	gps_target[120];
	 char	target_name[120];
	 double dtm_scale;
	 double dtm_axes[3];
	 double dtm_axes_map[3];
	 dtm dtmlabel;
	 double min_h_in_dtm;
	 double max_h_in_dtm;
	 MP mp_dtm_obj;
	 int *dtm_tab_in;
	 double axes[3];
	 double mp_axes[3];
	 int mp_radius_set;
	 double long_axis;
	 char	det_id[10];
	 char	ins_id[6];
	 int	plat_id;
	 char	ins_name[120];
	 char	sig_chain_id[120];
	 double	*xcal;
	 double	*ycal;
	 double	focal;
	 PHO	pho_obj;
	 int pho_calc_done;
	 double phoCorVal_vec[MAX_PIXEL_PER_LINE];
	 double DirEll[3];
	 float no_info_val;
	 int	use_extori;
	 double *xyz0;
	 double *xyz1;
	 double *xyz2;
	 double *phi;
	 double *omega;
	 double *kappa;
			} str_glob_type;

double  phot2cam[3][3]={0., 1., 0., 1., 0., 0., 0., 0., -1.};

/* private prototypes */
extern float hwpixnum();

void pixnum2ccd (str_glob_type *str_glob, float *ccd);
int hrortho_p (str_glob_type *str_glob);
int which_sensor(char *name,char *sensor);
int hw_get_label_info (str_glob_type *str_glob);
int hw_get_target(str_glob_type *str_glob);
int hw_rip_get_scale (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, double *scale, short int *dtm_buf);
int hworloc_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, short int *dtm_buf);
int hwgeorec_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, short int *dtm_buf);
int hwtraidtm_rip (str_glob_type *str_glob, MP mp_obj, Earth_prefs prefs, Earth_prefs prefs_dtm, int dtmunit, int line, int nof_pix,
	      float *ccd, double *x, double *y,
	      int *foundvec, int *signvec, int loc_rec, short int *dtm_buf);
void rec2graphicll ( double *xyz, double *axes, double *llh);
void xyz2graphicllh ( double *xyz, double *llh, double *axes);
int hwintdtm_bi ( short int *gv_lo, short int *gv_ro, short int *gv_lu, short int *gv_ru,
			 double dv, double du, short int miss_gv, short int *gv );
int hwintgv_bi ( float *gv_lo, float *gv_ro, float *gv_lu, float *gv_ru,
		 double dv, double du, float *gv );
int hwintgv_cc ( double dx, double dy, float *feld, float *result);
double	fct_hwintgv_cc ( double z);

int hwapppro (double x_inp, double y_inp, double inp_off[2], double out_off[2],
		      double *x_out, double *y_out, double *a);
int hwgetpro  (double *in_u, double *in_v, double *in_x,
		       double *in_y, double *a);
int hwgetapt (str_glob_type *str_glob, int l, int mid_of_l, int first_s, 
	       int *nof_le_p, int *nof_ri_p, int *s);
int hwsortap (int nof_up_le_p, int nof_up_ri_p, int *up_s, double *up_x, double *up_y, int *up_foundvec, int *up_signvec,
	      int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, double *lo_x, double *lo_y, int *lo_foundvec, int *lo_signvec);
int hwgetapp (int nof_up_le_p, int nof_up_ri_p, int *up_s, double *up_x, double *up_y, int *up_foundvec, int *up_signvec,
	      int nof_lo_le_p, int nof_lo_ri_p, int *lo_s, double *lo_x, double *lo_y, int *lo_foundvec, int *lo_signvec,
	      int *nof_p, int *s_ap1, int *s_ap2, int *s_ap3, int *s_ap4,
	      double *x_ap1, double *x_ap2, double *x_ap3, double *x_ap4,
	      double *y_ap1, double *y_ap2, double *y_ap3, double *y_ap4, int *dtm_no_dtm);
double max (double w1, double w2, double w3, double w4);
int imax (int w1, int w2, int w3, int w4);
double min (double w1, double w2, double w3, double w4);
int imin (int w1, int w2, int w3, int w4);

void check_size(str_glob_type *str_glob);
int check_quad ( double *line,  double *sample );
int check_quad_gespiegelt ( double *line,  double *sample );
void xyz2ll_centric ( double *xyz, double *llh);

int init_reffile_for_creation (FILE *fp, int nof_lines, int nof_samples, long *index);
int prepare_reffile_for_initclose (FILE *fp, int nof_lines, long *index, int sl, int nl, int ss, int ns, char *filename);
int encode_refline (float *line, int length_line, FILE *fp, double prec, int line_number, long *index);
int decode_refline (float *line, int length_line, FILE *fp, int line_number, long *index);

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrortho.imake
#define PROGRAM hrortho

#define MODULE_LIST hrortho.c 
#define INCLUDE_LIST hrortho.h 

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
$ create hrortho.pdf

process help=*

	parm inp	type=(string,120) count=0:1	default=--
	parm out	type=(string,120) count=0:1	default=--
	parm dtm	type=(string,120) count=0:1	default=0.0
	parm extorifile	type=(string,120) count=0:1	default=--

	parm fittofile	type=(string,120) count=0:1	default=--

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
			RD,					+
			UTM,					+
			BMN28,					+
			BMN31,					+
			BMN34,					+
			ING,					+
			SLK,					+
			GAUSS_KRUEGER,					+
			SOLDNER,					+
			CORRECTION ) 	

	parm MP_RADIUS	type=(real)	 count=0:1	default=--
			
	PARM IPOL     TYPE=KEYWORD  COUNT=1  VALID=(NN,BI,CC)  DEFAULT=BI
	PARM SL_INP       TYPE=int      COUNT=0:1 DEFAULT=1
	PARM NL_INP       TYPE=int      COUNT=0:1 DEFAULT=0
	PARM SWATH      TYPE=real      COUNT=1 VALID=(1:100)  DEFAULT=100.0
	PARM ANCHDIST TYPE=int 	    COUNT=0:1  VALID=(1:1000)  DEFAULT=5
	PARM BORDER   TYPE=int 	    COUNT=1  VALID=(0:50)  DEFAULT=0
	PARM MATCH 	TYPE=KEYWORD 	  count=1	VALID=(MATCH,NOMATCH) DEFAULT=NOMATCH

	PARM OUTMAX   TYPE=real     COUNT=1  DEFAULT=1024.
	PARM RAM	TYPE=real     COUNT=0:1  VALID=(1:2500) DEFAULT=--

	PARM REPORT   TYPE=KEYWORD  COUNT=1  VALID=(YES,NO) DEFAULT=YES
	parm gcaldir	type=(string,120) count=1	default=M94GEOCAL
    PARM VERSION_FILE               COUNT=(0:1)     DEFAULT=--
    PARM GEOCAL_VERSION             COUNT=(0:1)     DEFAULT=--

	! SPICE parameter
	
	parm A_AXIS	type=(real)	 count=0:1	default=--
	parm B_AXIS	type=(real) 	 count=0:1	default=--
	parm C_AXIS	type=(real) 	 count=0:1	default=--
  
	! Map projection parameter

	parm MP_RES	type=real	count=0:1	default=--
	parm MP_SCALE 	type=real	count=0:1	default=--
	parm POS_DIR	type=keyword	count=1		default=EAST +
							valid=(EAST,WEST)	
	parm CEN_LAT	type=real	count=0:1	default=--
	parm CEN_LONG	type=real	count=0:1	default=--
	parm SPHER_AZ	type=real	count=1		default=0.0
	parm L_PR_OFF	type=real	count=0:1	default=--
	parm S_PR_OFF	type=real	count=0:1	default=--
	parm CART_AZ	type=real	count=0:1	default=--
	parm F_ST_PAR	type=real	count=0:1	default=--
	parm S_ST_PAR	type=real	count=0:1	default=--

	parm USEMP 	type=keyword	count=0:1	default=-- valid=(USEMP)

  ! all following parameters are only for current DLR developments (not yet supported):

	parm project		type=(string,80)  	count=0:1	default=--
	parm strip		type=INT  		count=0:1	default=-- valid=(1:99)
	parm sensor		type=(string,3)  	count=0:1	default=-- valid=(nd,s1,s2,p1,p2,re,gr,bl,ir)

	parm TARGET	type=(string,32) count=1	default=MARS
	parm BOD_LONG	type=(real) 	 count=0:1	default=--
	PARM BSPFILE    TYPE=(STRING,120) COUNT=0:3 DEFAULT=HWSPICE_BSP,SUNKER
 	PARM BCFILE     TYPE=(STRING,120) COUNT=0:6 DEFAULT=HWSPICE_BC
	parm TSCFILE	type=(string,120) count=0:6 default=HWSPICE_TSC
	parm TIFILE	type=(string,120) count=1	default=HWSPICE_TI
    parm TFFILE	type=(string,120) count=1	default=HWSPICE_TF
	parm TLSFILE	type=(string,120) count=0:1	default=LEAPSECONDS
	parm TPCFILE	type=(string,120) count=1	default=CONSTANTS
	parm ORI	type=keyword count=1	default=EXT valid=(EXT,SPICE)
 
	PARM NL_OUT       TYPE=int      COUNT=0:1 DEFAULT=0
	PARM NS_OUT       TYPE=int      COUNT=0:1 DEFAULT=0
	PARM PREC 	TYPE=REAL 	  count=1	DEFAULT=0.1

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

	parm PHO_FUNC	type=(string,32) count=1  	default="NONE"	+
		 valid = (NONE,						+
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
VICAR program hrortho

.help
PURPOSE:
Generation of Orthomages from
scanner Images

.page
hrortho is a program created for generation of 
orthoimages from scanner (HRSC,MOC) images. 

.page

Programmer:
Frank Scholten
DLR

.level1

.var project
Project directory 
e.g./pho_pictor/berlin

.var strip
strip name

.var sensor
sensor name

.var inp
Input image
used if set,
if not set then
/project/strip/img/sensor.l2
will be used

.var dtm
dtm-file or 
height above sea level (geom-mode)
in meter,
used if set,
if not set then
/project/dtm/dtm
will be used

.var out
Output image
generated if set,
if not set then:
in project notation:
 in geom-mode
 /project/strip/geo/sensor.l3
 or in ortho-mode
 /project/strip/ort/sensor.l4
 or generally in match-mode
 /project/strip/mat/sensor.mat
 will be generated
without project notation:
 out = "inp"_out

.var fittofile
File to which OUT should fit.
if set to 
nd,s1,s2,p1,p2,re,gr,bl or ir,
then OUT will be fit 
to /project/strip/geo/fittofile.l3
in geom-mode,
to /project/strip/mat/fittofile.mat
generally in match-mode or
to /project/strip/ort/fittofile.l4
in ortho-mode
NOTE !: in geom-mode from fittofile-name
REFERENCE_HEIGHT will be used

.var MP_TYPE
map projection type

.var IPOL
Interpolation type

.var NL_OUT
Number of lines of the output image

.var NS_OUT
Number of samples of the output image

.var SL_INP
Start line of the input image

.var NL_INP
Number of lines of the input image
counted from SL_INP

.var SWATH
Percentage of swath width to be used

.var ANCHDIST
Anchorpoint distance

.var BORDER
Width of black image border

.var REPORT
Monitor output request buttom

.var MATCH
Match coordinates request buttom.

.var PREC
Precision of New Match-Files.

.var OUTMAX
Sizelimit for output image

.var RAM
RAM in MByte to be used

.var ORI
Switch between use of EXTORI files
or SPICE data

.var EXTORIFILE
Name of the EXTORI-file,
used if ORI is set to EXTORI

.VARI A_AXIS
Semimajor axis of target body.

.VARI B_AXIS
Semiminor axis of target body.

.VARI C_AXIS
Polar axis of target body.

.VARI MP_RADIUS
radius of map reference body [km], 

.VARI TARGET
defines reference body for map.
Default = MARS

.var  BSPFILE
Binary SP-Kernel. 

.var  BCFILE
Binary C-Kernel.

.var  TSCFILE
Clock, SCLK-kernel.

.var  TIFILE
Instrument data, I-kernel.

.var  TPCFILE
Planetary constants, PC-kernels.

.var  TLSFILE
Leapseconds, LS-kernel.

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
(only EAST) for earth

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
if set to 999, hrortho lets 
the output become bottom down
(similar to Level2-images)

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

.var PHO_FUNC
default=NONE

.var T_EMI_A
Target emission angle

.var T_INC_A
Target incidence angle

.var T_AZI_A
Target azimuth angle

.level2

.var project
Project directory 
e.g./pho_pictor/berlin

.var strip
strip name

.var sensor
sensor name
valid=(nd,s1,s2,p1,p2,re,gr,bl,ir)

.var inp
Input image
used if set,
if not set then
/project/strip/img/sensor.l2
will be used

.var dtm
dtm-file or 
height above sea level (geom-mode)
used if set,
in meter,
if not set then
/project/dtm/dtm
will be used

.var out
Output image
generated if set,
if not set then:
in project notation:
 in geom-mode
 /project/strip/geo/sensor.l3
 or in ortho-mode
 /project/strip/ort/sensor.l4
 or generally in match-mode
 /project/strip/mat/sensor.mat
 will be generated
without project notation:
 out = "inp"_out

.var fittofile
File to which OUT should fit.
if set to 
nd,s1,s2,p1,p2,re,gr,bl or ir,
then OUT will be fit to 
/project/strip/geo/fittofile.l3
in geom-mode, to
/project/strip/mat/fittofile.mat
generally in match-mode or to
/project/strip/ort/fittofile.l4
in ortho-mode
NOTE :
in geom-mode from fittofile-name
REFERENCE_HEIGHT will be used

.var MP_TYPE
Identifies the type of cartographic projection characteristic of 
a given map.  These names or types are derived from names used in 
USGS Professional Paper 1395. (default: SINUSOIDAL)

.var IPOL
Interpolation type: NN = Nearest Neighbor
                    BI = Bilinear Interpolation (default)
                    CC = Cubic Convolution

.var NL_OUT
Number of lines of the output image
(setting NL_OUT, NS_OUT, L_PR_OFF, S_PR_OFF
the user defines the location and size of the
output file, if not set, hrortho generates
an appropriate output file by itself)

.var NS_OUT
(setting NL_OUT, NS_OUT, L_PR_OFF, S_PR_OFF
the user defines the location and size of the
output file, if not set, hrortho generates
an appropriate output file by itself)
Number of samples of the output image

.var SL_INP
Start line of the input image
(default=1)

.var NL_INP
Number of lines of the input image
counted from SL_INP
(default=1)

.var SWATH
Percentage of swath width to be used
default = 100

.var ANCHDIST
Distance between the points that define the 
anchorpoint grid: valid is a value between 1 and 1000
default: 5

.var BORDER
This is the width of a black border region with a
grayvalue of 0 which is generated all arround the
output image. If a special projection offset is given by
the user the border will only be generated at the bottom and
right side of the output image. Default for BORDER = 0

Note, that BORDER does not allways define the width exact.
It might vary due to real-to-integer-conversion of
offsets by +/- 1 pixel and due to interpolation limitations
at the image border (e.g. using Cubic Convolution or 
Bilinear Interpolation) by additional +/- 1 pixel.
This does not affect the correctness of offsets.

.var REPORT
Monitor output request buttom.
YES = The monitor output of
      - Output image dimensions (lines, samples)
      - Location within the map projection
	(Line and Sample Projection Offset)
      - progress in processing 
      is requested.  (default)
NO  = No monitor output is requested

.var MATCH
Match coordinates request buttom.
MATCH = Two file will be generated,
they contain the line-coordinates
and the the sample-coordinates of the 
output pixels in the input file 
(lines are counted from the very first line 
of the input file, not from SL_INP !!)
NOMATCH  = No match coordinate-files are requested (default)

.var PREC
Precision of coordinates in
New Match-Files [in pixels]
default = 0.1

.var OUTMAX
Sizelimit for output image [in MegaByte]
default: 1024.

.var RAM
e.g. if set to 256.
then only 256 MByte
will be used for output allocation
NOTE: hrortho might acceed
this number in fitto-mode
if input-file is much larger
than fitto-file
VALID=(32:2500)
default=-- (use available, 
	    max. 2500 Mbyte)

.var ORI
Switch between use of EXTORI files
or SPICE data

.var EXTORIFILE
Name of the EXTORI-file,
used if ORI is set to EXTORI

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

.VARI MP_RADIUS
radius of map reference body [km],
especially for "potato targets",
where the SPICE-defined 
non-spherical model.
It is used for the map projection,
BUT is NOT  used for intersection
of line-of-sight with the real (SPICE-defined) body. 

.VARI TARGET
defines reference body for map.
Default = MARS

.var  BSPFILE
Binary SP-Kernel. 

.var  BCFILE
Binary C-Kernel.

.var  TSCFILE
Clock, SCLK-kernel.

.var  TIFILE
Instrument data, I-kernel.

.var  TPCFILE
Planetary constants, PC-kernels.

.var  TLSFILE
Leapseconds, LS-kernel.

.var BOD_LONG
The longitude of the semimajor (longest) axis of a triaxial 
ellipsoid.  Some bodies, like Mars, have the prime meridian 
defined at a longitude which does not correspond to the 
equatorial semimajor axis, if the equatorial plane is modeled 
as an ellipse.

.var MP_RES
Identifies the scale of a given map in pixels per degree.  Please refer
to the definition for map scale for a more complete definition. Note 
that map resolution and map scale both define the scale of a map except 
that they are expressed in different units. Map scale is measured in 
kilometers per pixel.

.var MP_SCALE
Map scale  is defined as the ratio of the actual distance between two 
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
if neither MP_SCA nor MP_RES is set, the mean real scale/resolution
on ground is calculated.

.var POS_DIR
Identifies the direction of longitude (e.g. EAST, WEST) for a planet. 
The IAU definition for direction of positive longitude is adopted.  
Typically, for planets with prograde rotations, positive longitude 
direction is to the west. For planets with retrograde rotations, positive
longitude direction is to the east.
For earth only east is valid, see function flgeoid
and dlrmapsub.com

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
(setting NL_OUT, NS_OUT, L_PR_OFF, S_PR_OFF
the user defines the location and size of the
output file, if not set, hrortho generates
an appropriate output file by itself)

.var S_PR_OFF
The sample offset value of the map projection origin position from the 
center of the pixel line and sample 1,1 (line and sample 1,1 is 
considered the upper left corner of the digital array). Note that the 
positive direction is to the right and down.
(setting NL_OUT, NS_OUT, L_PR_OFF, S_PR_OFF
the user defines the location and size of the
output file, if not set, hrortho generates
an appropriate output file by itself)

.var CART_AZ
After points have been projected to image space (x,y or line,sample), 
a clockwise rotation, in degrees, of the line and sample coordinates 
can be made with respect to the map projection origin - specified by
line and sample projection offset. This clockwise rotation in degrees 
is the Cartesian azimuth. This parameter is used to indicate where 'up' 
is in the projection.
if set to 999, hrortho lets the output become bottom down
(similar to Level2-images)

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

.var PHO_FUNC
default=NONE

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

.end
$ Return
$!#############################################################################
