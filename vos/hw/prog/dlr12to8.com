$!****************************************************************************
$!
$! Build proc for MIPL module dlr12to8
$! VPACK Version 1.9, Monday, August 18, 2003, 16:07:39
$!
$! Execute by entering:		$ @dlr12to8
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
$ write sys$output "*** module dlr12to8 ***"
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
$ write sys$output "Invalid argument given to dlr12to8.com file -- ", primary
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
$   if F$SEARCH("dlr12to8.imake") .nes. ""
$   then
$      vimake dlr12to8
$      purge dlr12to8.bld
$   else
$      if F$SEARCH("dlr12to8.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlr12to8
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlr12to8.bld "STD"
$   else
$      @dlr12to8.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlr12to8.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlr12to8.com -
	-s dlr12to8.c -
	-i dlr12to8.imake -
	-p dlr12to8.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlr12to8.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "vicmain_c"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <strings.h>
#include <errno.h>

#include "ibisfile.h"
#include "ax_constants.h"

#define  MAXFILES     1000
#define  FNAMLEN      120
#define  Pi    3.14159265358979310   

#define  M_NORMAL      1
#define  M_EQUAL       2
#define  M_LINEAR      3
#define  M_SQRT        4
#define  M_POW         5

#define  SMIN_DEF      0
#define  SMAX_DEF   4095      /* 12Bit !!! */

static void my_abort(char a[100]);
static void equal_lut (unsigned int *, unsigned int *);
static void normal_lut (unsigned int *, double, double, unsigned int *);
static double norm_gauss (double, double, double);
static void linear_a_lut (unsigned int  *, double, double, int *, int *, 
                          double *, double *, unsigned int  *);
static void linear_b_lut (int, int, double *, double *, unsigned int  *);
static int chk_vic_label(char *);
static void sqrt_a_lut (unsigned int  *, double, double, int *, int *, 
                          double *, double *, unsigned int  *);
static void sqrt_b_lut (int, int, double *, double *, unsigned int  *);
static void pow_c_lut (int, int, double, double *, double *, unsigned int  *);
static void pow_a_lut (unsigned int  *, double, double, int *, int *, 
                       double,  double *, double *, unsigned int  *);


void main44()
   {
   int            status, inunit[MAXFILES], ibis_unit;
   unsigned int   hist[AX_HIST_LENGTH], hist_xx[AX_HIST_LENGTH], hist_255[255];
   unsigned int   luttab[AX_HIST_LENGTH];
   double         sumhist_xx[AX_HIST_LENGTH], sumhist_255[255];
   int            i, j, index, cnt, anzhis;
   char          *fnam, outnam[FNAMLEN], hislist[FNAMLEN], hisfile[FNAMLEN];
   int            sptr[MAXFILES], leng[MAXFILES];
   FILE          *fp, *fp_hist;
   double         gmean = 127.5, gsig = 3.0;
   float          fvar;
   char           string[200], *st, ParamStr[200];
   int            mode;
   int            dnmin, dnmax, mmin, mmax, smin, smax;
   double         p_up, p_low;
   double         off, scale;
   int            hlst = 0, slen;
   int            missval = -1;
   int            ParamStr_len;
   double         c_pow;
   
   fnam = (char *) malloc (MAXFILES * FNAMLEN * sizeof(char));
   if (fnam == (char *) NULL) my_abort(" memory error!!!");
   
   zvp ("INP", fnam, &cnt);
   if (cnt < 1)  {
       
       my_abort(" input file(s)???");
       }
    mode = chk_vic_label(fnam);
    
    if (mode < 1) {                 /* ############### ASCII-Fileliste */
    
       sprintf (hislist, "%s\0", fnam);
       hlst = 1;
       fp_hist = fopen (hislist, "r");
       if (fp_hist == (FILE *)NULL) {
       
          fprintf (stderr, "\n ###%s:%s?\n\n", strerror(errno), hislist);
	  exit(0);
          }
       cnt     =   0;
       fnam[0] = '\0';
       while (1) {
           st = fgets (string, 200, fp_hist);
           if (st == (char *)NULL) break;
	   
	   sptr[cnt] = cnt * FNAMLEN + 1;
	   
	   slen = strlen(string);
	   if (slen > 0) string[slen-1] = '\0';
	       
           sprintf (fnam + sptr[cnt] - 1, "%s", string);
	   
	   cnt++;
           }
       fclose (fp_hist);
       }
   else {
      if (cnt > MAXFILES)   my_abort("to many histogram files");
      zvsptr(fnam, cnt, sptr, leng);   
      }
   
   anzhis = cnt;

   zvp("OUT", outnam, &cnt);
   if (cnt != 1) my_abort("Fehler beim lesen der PDF-Parameter\0");

/* ---------------------------------------------- open/write LUT */
   fp = fopen (outnam, "r");
   if (fp != (FILE *)NULL) {
       my_abort("Fehler: OUT-File existiert schon\n");
       }
       
 
/* --------------------------------------------- Histogramm-Mode */
   zvp ("MODE", string, &cnt);
   if (cnt != 1) my_abort("error reading MODE parameter");

        if (!strncmp("NORMAL", string, 6)) mode = M_NORMAL;
   else if (!strncmp("EQUAL",  string, 5)) mode = M_EQUAL;
   else if (!strncmp("LINEAR", string, 6)) mode = M_LINEAR;
   else if (!strncmp("SQRT",   string, 4)) mode = M_SQRT;
   else if (!strncmp("POW",    string, 3)) mode = M_POW;
   else mode = M_LINEAR;

   sprintf (ParamStr, "MODE: %s; \0", string);
   ParamStr_len = strlen(ParamStr);

   zvp ("MISSVAL", &missval, &cnt);
   if (cnt == 0) {
       missval = -1;
       }
   else {
       sprintf (ParamStr+ParamStr_len, "MISSVAL: %d;\0", missval);
       ParamStr_len = strlen(ParamStr);
       }


/* ------------------------------------- Histogramme (Ist) bestimmen */   
   for (j = 0; j < AX_HIST_LENGTH; j++) {
        hist_xx[j]    = 0;
	sumhist_xx[j] = 0.0;
	}
   for (j = 0; j < 255; j++) {
	sumhist_255[j] = 0.0;
	}

   if (1) {
       smin =  9999;
       smax = -9999;
       for (i = 0; i < anzhis; i++) {
    
    
           if (hlst == 0) {
               status = zvunit (inunit + i, "INP",       i+1, 
                                            "U_NAME",    fnam + sptr[i] - 1, 0);
	       }
	   else {
	   
               status = zvunit (inunit + i, "none",      i+1, 
                                            "U_NAME",    fnam + sptr[i] - 1, 0);
	       }
          if (status != 1) 
              my_abort("error open input file"); 
/* ---------------------------------- open /read the IBIS file */
           status=IBISFileOpen(inunit[i], &ibis_unit, IMODE_READ,0,0,0,0);
           if (status != 1) IBISSignalU(inunit[i],status,1);
       
           status=IBISColumnRead(ibis_unit, (char *)hist, 1, 1, AX_HIST_LENGTH);

           if (status !=1) 
               my_abort("error read input file"); 

           zlget(inunit[i], "HISTORY", "DNMIN", &mmin, "FORMAT", "INT", 0);
           zlget(inunit[i], "HISTORY", "DNMAX", &mmax, "FORMAT", "INT", 0);
           if (mmin < smin) smin = mmin;
           if (mmax > smax) smax = mmax;

           if (missval == 0) {
	   
	      hist_xx[0] = 0;
	      }
	   else {
	      hist_xx[0] = hist[0];
              }
           for (j = 1; j < AX_HIST_LENGTH; j++) hist_xx[j] += hist[j];

           zvclose (inunit[i], 0);
           status = IBISFileClose(ibis_unit, 0);
           }
       }
   else {
      smin  = SMIN_DEF;
      smax  = SMAX_DEF;                  /* ---------- 12 Bit Beschraenkung */
      
      mode = M_LINEAR;
      }
   
   
   
/* ------------------------------------------------- compute LUT */
   switch (mode) {
   
       case M_NORMAL: 
                      zvp ("GMEAN", &fvar, &cnt);
                      if (cnt != 1) gmean =127.5;
		      else gmean = fvar;
		      		      
		      sprintf (ParamStr+ParamStr_len, "GMEAN: %lf; \0", gmean);		      
                      ParamStr_len = strlen(ParamStr);
		      
		      zvp ("GSIG", &fvar, &cnt);
		      if (cnt != 1) gsig = 3.0;
                      else gsig = fvar;

		      sprintf (ParamStr+ParamStr_len, "GSIG: %lf; \0", gsig);
                      ParamStr_len = strlen(ParamStr);
		      
		      normal_lut (hist_xx, gmean, gsig, luttab);
                      
		      break;
       case M_SQRT: 

                      zvp ("DNMIN", &dnmin, &cnt);
		      if (cnt != 1) {
		          dnmin = -1;
		          }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMIN: %d; \0", dnmin);
                          ParamStr_len = strlen(ParamStr);
 		          }
                      zvp ("DNMAX", &dnmax, &cnt);
		      if (cnt != 1) {
		          dnmax = -1;
			  }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMAX: %d; \0", dnmax);
                          ParamStr_len = strlen(ParamStr);
		          }
		      
                      if (dnmin < 0 && dnmax < 0) {
                          zvp ("LOWER", &fvar, &cnt);
                          if (cnt != 1) {
		              p_low = -1.0;
			      }
		          else {
		              p_low = (double)fvar;
			      
		      	      sprintf (ParamStr+ParamStr_len, "LOWER: %lf; \0", p_low);
                              ParamStr_len = strlen(ParamStr);
			      }
                      
          		  zvp ("UPPER", &fvar, &cnt);
                          if (cnt != 1) {
		               p_up = -1.0;
			       }
		          else {
		               p_up = fvar;
		      	       sprintf (ParamStr+ParamStr_len, "UPPER: %lf; \0", p_up);
                               ParamStr_len = strlen(ParamStr);
			       }
		      
                          if (anzhis > 0 && (p_low > 0.0000001 && p_up > 0.0000001)) {
		              sqrt_a_lut (hist_xx, p_low, p_up, &dnmin, &dnmax, 
			                  &off, &scale, luttab);
			      }
		          }
                      else {
                      
                       
		         if (dnmin < 0) dnmin = smin;
		         if (dnmax < 0) dnmax = smax;
		      
		         if (dnmin >= dnmax) my_abort("error: value dnmax is less or equal to dnmin ");
		      
	                 sqrt_b_lut (dnmin, dnmax, &off, &scale, luttab);
			 }
		      break;
       case M_POW: 
                      zvp ("POWER", &fvar, &cnt);
                      if (cnt != 1) c_pow = 0.33333;
		      else c_pow = (double)fvar;

                      zvp ("DNMIN", &dnmin, &cnt);
		      if (cnt != 1) {
		          dnmin = -1;
		          }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMIN: %d; \0", dnmin);
                          ParamStr_len = strlen(ParamStr);
 		          }
                      zvp ("DNMAX", &dnmax, &cnt);
		      if (cnt != 1) {
		          dnmax = -1;
			  }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMAX: %d; \0", dnmax);
                          ParamStr_len = strlen(ParamStr);
		          }
		      
                      if (dnmin < 0 && dnmax < 0) {
                          zvp ("LOWER", &fvar, &cnt);
                          if (cnt != 1) {
		              p_low = -1.0;
			      }
		          else {
		              p_low = (double)fvar;
			      
		      	      sprintf (ParamStr+ParamStr_len, "LOWER: %lf; \0", p_low);
                              ParamStr_len = strlen(ParamStr);
			      }
                      
          		  zvp ("UPPER", &fvar, &cnt);
                          if (cnt != 1) {
		               p_up = -1.0;
			       }
		          else {
		               p_up = fvar;
		      	       sprintf (ParamStr+ParamStr_len, "UPPER: %lf; \0", p_up);
                               ParamStr_len = strlen(ParamStr);
			       }
		      
                          if (anzhis > 0 && (p_low > 0.0000001 && p_up > 0.0000001)) {
		              pow_a_lut (hist_xx, p_low, p_up, &dnmin, &dnmax, 
			                 c_pow, &off, &scale, luttab);
			      }
		          }
                      else {
                      
                       
		         if (dnmin < 0) dnmin = smin;
		         if (dnmax < 0) dnmax = smax;
		      
		         if (dnmin >= dnmax) my_abort("error: value dnmax is less or equal to dnmin ");
		      
	                 pow_c_lut (dnmin, dnmax, c_pow, &off, &scale, luttab);
			 }
		      break;

       case M_LINEAR: 

                      zvp ("DNMIN", &dnmin, &cnt);
		      if (cnt != 1) {
		          dnmin = -1;
		          }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMIN: %d; \0", dnmin);
                          ParamStr_len = strlen(ParamStr);
 		          }
                      zvp ("DNMAX", &dnmax, &cnt);
		      if (cnt != 1) {
		          dnmax = -1;
			  }
		      else {
		      	  sprintf (ParamStr+ParamStr_len, "DNMAX: %d; \0", dnmax);
                          ParamStr_len = strlen(ParamStr);
		          }
		      
                      if (dnmin < 0 && dnmax < 0) {

                          zvp ("LOWER", &fvar, &cnt);
                          if (cnt != 1) {
		              p_low = -1.0;
			      }
		          else {
		              p_low = (double)fvar;
			      
		      	      sprintf (ParamStr+ParamStr_len, "LOWER: %lf; \0", p_low);
                              ParamStr_len = strlen(ParamStr);
			      }
                      
          		  zvp ("UPPER", &fvar, &cnt);
                          if (cnt != 1) {
		               p_up = -1.0;
			       }
		          else {
		               p_up = fvar;
		      	       sprintf (ParamStr+ParamStr_len, "UPPER: %lf; \0", p_up);
                               ParamStr_len = strlen(ParamStr);
			       }
		
                          if (anzhis > 0 && (p_low > 0.000001 && p_up > 0.0000001)) {
		              linear_a_lut (hist_xx, p_low, p_up, &dnmin, &dnmax, 
			                   &off, &scale, luttab);
			      }
			  }
                      else {
                      
		         if (dnmin < 0) dnmin = smin;
		         if (dnmin < 0) dnmax = smax;
		      
		         if (dnmin >= dnmax) my_abort("error: value dnmax is less or equal to dnmin ");
		      
	                 linear_b_lut (dnmin, dnmax, &off, &scale, luttab);
			 }
                      break;
   
       case M_EQUAL : equal_lut (hist_xx, luttab);
                      break;

       default:       
                      break;
   
       }

   


   fp = fopen (outnam, "w");
   if (fp == (FILE *)NULL) {
      my_abort("Fehler beim oeffnen des Files\n");
      }
/* ###### */
   
   fprintf (fp, "histogram files:\n");
   
   for (i = 0; i < anzhis; i++) {
   
       fprintf (fp, "  %2d: %s\n", i+1, fnam + sptr[i] - 1);
       }
       
   fprintf (fp, "\n Parameter %s\n\n",  ParamStr);
    
   if (mode == M_NORMAL) {
   
       fprintf (fp, "Mode: Normal,   GMEAN: %5.1lf,  GSIG: %6.2lf\n", gmean, gsig);
       }
   else if (mode == M_EQUAL) {
   
       fprintf (fp, "Mode: Equal\n");
       }
   else if (mode == M_LINEAR) {
   
   
       fprintf (fp, "Mode: Linear,   DNMIN: %d,  DNMAX: %d;   DN-8Bit=%6.1lf + %8.6lf * DN-12Bit\n", 
                    dnmin, dnmax, off, scale);
       }
   else if (mode == M_SQRT) {
   
   
       fprintf (fp, "Mode: SQRT,   DNMIN: %d,  DNMAX: %d;   DN-8Bit=%6.1lf + %8.6lf * sqrt(DN-12Bit)\n", 
                    dnmin, dnmax, off, scale);
       }
   else if (mode == M_POW) {
   
   
       fprintf (fp, "Mode: POW (%4.3lf),   DNMIN: %d,  DNMAX: %d;   DN-8Bit=%6.1lf + %8.6lf * pow(DN-12Bit,%4.3lf)\n", 
                    c_pow, dnmin, dnmax, off, scale, c_pow);
       }
   fprintf (fp, "****\n");
   

/* ###### */

   if (missval == 0) {
      
       luttab[0] = 0;
   
       for (i = 1; i < 4096; i++) {
       
           if (luttab[i] == 0) luttab[i] = 1;
           }

      }
   
   for (i = 0; i < 4096; i++)
       {
       fprintf (fp, "%4d %d\n", i, luttab[i]);

       }
   fclose (fp);

   zvp ("HISFILE", string, &cnt);
   if (cnt == 1 && !strncmp(string, "YES", 3)) {
   



/* -------------------------------------- Histogramm 8 Bitfile */
       status = new_suffix (outnam, hisfile, "his_out\0");
        
       fp = fopen (hisfile, "w");  
       if (fp == (FILE *)NULL) {
           my_abort("Fehler beim oeffnen des Histogrammfiles\n");
           }
       for (i = 0; i <= 255; i++) hist_255[i] = 0;
       
       for (j = 0; j <= 4095; j++) {

           index = luttab[j];

	   hist_255[index] += hist_xx[j];

           }
             

       for (i = 0; i <= 255; i++) {
            if ( i == 0 ) {
	    
               sumhist_255[i] = (double)hist_255[i];
	       }
	    else {
	    
               sumhist_255[i] = sumhist_255[i-1] + (double)hist_255[i];
	       }
       
            fprintf (fp, "%04d  %10d %15.0lf\n", i, hist_255[i], sumhist_255[i]); 
            }
       
       fclose(fp);

   
/* -------------------------------------- Histogramm 12 Bitfile */
       status = new_suffix (outnam, hisfile, "his_inp\0");

       fp = fopen (hisfile, "w");  
       if (fp == (FILE *)NULL) {
           my_abort("Fehler beim oeffnen des Histogrammfiles\n");
           }
       for (i = smin; i <= smax; i++) {

           if (i == smin ) {
	   
	      sumhist_xx[i] = hist_xx[i];
	      }
	   else {
	   
	       sumhist_xx[i] = sumhist_xx[i-1] + (double) hist_xx[i];
	       }
       
           fprintf (fp, "%04d %10d %15.0lf\n", i, hist_xx[i], sumhist_xx[i]);
       
           }
       fclose(fp);
       }

   }



void normal_lut (unsigned int  *hist, double gmean, double gsig, unsigned int  *luttab) 
   {  
   int         i, j;
   double      sumhis_ist[4096], sumhis_soll[256]; 
   double      sum;
   double      AnzPixel, xx, yy, sig, diff;

   sig =   256 / (2.0 * gsig); 
   

/* -------------------------------------- Ist-Summenhistogramm der Bilddaten */
   sumhis_ist[0] = (double) hist[0];
   for (i = 1; i < 4096; i++) {      
      
      sumhis_ist[i] = sumhis_ist[i-1] + (double) hist[i];
      }
      
   
/* ------------------- Soll-Summenhistogramm fuer 8Bit und Gleichverteilung */
   sum = 0.0;
   AnzPixel = sumhis_ist[4095];
         
   for (i = 0; i < 256; i++)
       {
       xx =   (double)i;
       
       yy = norm_gauss (xx, gmean, sig)  / sig * AnzPixel;
       
       sum += (double)yy;
       }
   diff = (AnzPixel - sum) / 256.0;

   sum = 0.0;

   for (i = 0; i < 256; i++)
       {
       xx =   (double)i;
       
       yy = norm_gauss (xx, gmean, sig) / sig * (AnzPixel + diff);
       
       sum += (int) (yy + diff + 0.5);
        
       sumhis_soll[i] = sum;
       }
      
/* --------------------------------------------- Berechnung der LUT-Tabelle */
   for (i = 0; i < 4096; i++) {
        
	luttab[i] = 0;
        sum = sumhis_ist[i];
      
	for (j = 0; j < 256; j++) {
	    
	    luttab[i] = j;
	    if (sum <= sumhis_soll[j]) {
	       break;
	       }
	    }
        }       
   }




void equal_lut (unsigned int  *hist, unsigned int  *luttab) 
   {  
   int         i, j;
   double      sumhis_ist[4096], sumhis_soll[256]; 
   double      soll_dn, sum;


/* -------------------------------------- Ist-Summenhistogramm der Bilddaten */
   sumhis_ist[0] = (double) hist[0];
   for (i = 1; i < 4096; i++) {      
      
      sumhis_ist[i] = sumhis_ist[i-1] + (double) hist[i];
      }
      
/* --------------------------------- mittlere Anzahl an Pixeln pro Grauwert */
   soll_dn = sumhis_ist[4095] / (double) 256;
   
/* ------------------- Soll-Summenhistogramm fuer 8Bit und Gleichverteilung */
   sumhis_soll[0] = soll_dn;
   for (i = 1; i < 256; i++)
       {
       sumhis_soll[i] = sumhis_soll[i-1] + soll_dn;
       }

/* --------------------------------------------- Berechnung der LUT-Tabelle */
   for (i = 0; i < 4096; i++) {
        
	luttab[i] = 0;
        sum = sumhis_ist[i];
      
	for (j = 0; j < 256; j++) {
	    
	    luttab[i] = j;
	    if (sum <= sumhis_soll[j]) {

	       break;
	       }
	
	    }
        }       
   }




double norm_gauss (double x, double mean, double sigma)
   {
   double     w_2pi, expon;


   w_2pi = sqrt(2.0 * Pi);   
   
   expon = -((x-mean) * (x-mean)) / (2 * sigma * sigma);
/* -------------------------------------------------------
                          Gleichverteilt, Wertebereich -1, ..., 1.0 */
/* -------------------------------------------------------
                       Gaussverteilung, Varianz = Sigma, Mitte = 0.0 */
                       
   return (1.0 / w_2pi * exp(expon));

   }



void linear_a_lut (unsigned int  *hist, double p_low, double p_up, 
                   int * dn_min,  int *dn_max,  
		   double *off, double *scale, unsigned int  *luttab)
   {
   int        dnmin,  dnmax;
   int        i, index;
   double     sum, sumhis_ist[4096], AnzPixel, g_low, g_up;
   double     a = 0, b = 0;


   
   sumhis_ist[0] = hist[0];
   for (i = 1; i < 4096; i++) {
   
       sumhis_ist[i] =  sumhis_ist[i-1] + hist[i];
       }
   AnzPixel = sumhis_ist[4095];
  
   g_low = AnzPixel * p_low           / 100.0;
   g_up  = AnzPixel * (100.0 - p_up)  / 100.0;
   
   for (i = 1; i < 4096; i++) {
   
       dnmin = i - 1;
       if (sumhis_ist[i] > g_low) break;
       }
       
   for (i = 0; i < 4096; i++) {
   
       dnmax = i;

       if (sumhis_ist[i] > g_up) break;    
       }
  
   if (dnmin != dnmax) {

       b = 255.0 / (double) (dnmax - dnmin);
       a = 255.0 - b * (double) dnmax; 
       
       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * (double)i + 0.499999);

	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;
	   
           luttab[i] = (unsigned int) index; 
           }
       }
       
    *dn_min = dnmin;
    *dn_max = dnmax;
    *off    = a;
    *scale  = b;
    }


void linear_b_lut (int  dnmin, int  dnmax, double *off, double *scale, unsigned int  *luttab)
   {
   int        i, index;
   double     a = 0, b = 0;

   if (dnmin != dnmax) {

       b = 255.0 / (double) (dnmax - dnmin);
       a = 255.0 - b * (double) dnmax; 
       
       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * (double)i + 0.499999);

	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;

           luttab[i] = (unsigned int) index; 
           }
       }

    *off    = a;
    *scale  = b;
    }




void sqrt_b_lut (int  dnmin, int  dnmax, double *off, double *scale, unsigned int  *luttab)
   {
   int        i, index;
   double     a = 0, b = 0;

   if (dnmin != dnmax) {

       b = 255.0 /  (sqrt((double)dnmax) - sqrt((double)dnmin));
       
       
       a = 255.0 - b * sqrt ((double) dnmax); 


       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * sqrt((double)i ) + 0.499999);



	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;

           luttab[i] = (unsigned int) index; 
	   
	   printf (" I: %5d --> Index: %5d\n", i, index);
	   
           }
       }

    *off    = a;
    *scale  = b;
    }





void pow_a_lut (unsigned int  *hist, double p_low, double p_up, 
                 int * dn_min,  int *dn_max,  double c_pow,
	         double *off, double *scale, unsigned int  *luttab)
   {
   int        dnmin,  dnmax;
   int        i, index;
   double     sum, sumhis_ist[4096], AnzPixel, g_low, g_up;
   double     a = 0, b = 0;

   
   sumhis_ist[0] = hist[0];
   for (i = 1; i < 4096; i++) {
   
       sumhis_ist[i] =  sumhis_ist[i-1] + hist[i];
       }
   AnzPixel = sumhis_ist[4095];
  
   g_low = AnzPixel * p_low           / 100.0;
   g_up  = AnzPixel * (100.0 - p_up)  / 100.0;
   
   for (i = 1; i < 4096; i++) {
   
       dnmin = i - 1;
       if (sumhis_ist[i] > g_low) break;
       }
       
   for (i = 0; i < 4096; i++) {
   
       dnmax = i;

       if (sumhis_ist[i] > g_up) break;    
       }
  
   if (dnmin != dnmax) {

       b = 255.0 /  (pow((double)dnmax, c_pow) - pow((double)dnmin, c_pow));
       
       
       a = 255.0 - b * pow ((double) dnmax, c_pow); 
       
       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * pow((double)i, c_pow) + 0.499999);

	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;
	   
           luttab[i] = (unsigned int) index; 
           }
       }
       
    *dn_min = dnmin;
    *dn_max = dnmax;
    *off    = a;
    *scale  = b;
    }




void pow_c_lut (int  dnmin, int  dnmax, double c_pow, double *off, double *scale, unsigned int  *luttab)
   {
   int        i, index;
   double     a = 0, b = 0;

   if (dnmin != dnmax) {

       b = 255.0 /  (pow((double)dnmax, c_pow) - pow((double)dnmin, c_pow));
       
       
       a = 255.0 - b * pow ((double) dnmax, c_pow); 


       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * pow((double)i, c_pow) + 0.499999);



	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;

           luttab[i] = (unsigned int) index; 
	   
	   printf (" I: %5d --> Index: %5d\n", i, index);
	   
           }
       }

    *off    = a;
    *scale  = b;
    }







/* ############################################################
   Funktion ueberprueft ob Datei ein Vicar - Fileformat hat
   ############################################################ */
int chk_vic_label(char   *fnam)
   {
   int      status, label_size=99;
   char     buff[20];
   FILE    *fp;


   fp = fopen(fnam, "r");
   if (fp == (FILE *)NULL) return(EOF);

   *buff = '\0';
/* ------------------------------------------------------------
   Labelsize
   ------------------------------------------------------------ */
   status = fread(buff, 13, 1, fp);
   rewind(fp);
   if (status != 1) return(EOF); 
      
   if ((sscanf(buff, "LBLSIZE = %d", &label_size)) != 1) return(0);

   return(1);
   }





void my_abort(abort_message)

char abort_message[80];
{
   zvmessage("","");
   zvmessage("     ******* dlr12to8 error *******","");
   zvmessage(abort_message,"");
   zvmessage("","");
   zabend();
}





void sqrt_a_lut (unsigned int  *hist, double p_low, double p_up, 
                 int * dn_min,  int *dn_max,  
	         double *off, double *scale, unsigned int  *luttab)
   {
   int        dnmin,  dnmax;
   int        i, index;
   double     sum, sumhis_ist[4096], AnzPixel, g_low, g_up;
   double     a = 0, b = 0;

   
   sumhis_ist[0] = hist[0];
   for (i = 1; i < 4096; i++) {
   
       sumhis_ist[i] =  sumhis_ist[i-1] + hist[i];
       }
   AnzPixel = sumhis_ist[4095];
  
   g_low = AnzPixel * p_low           / 100.0;
   g_up  = AnzPixel * (100.0 - p_up)  / 100.0;
   
   for (i = 1; i < 4096; i++) {
   
       dnmin = i - 1;
       if (sumhis_ist[i] > g_low) break;
       }
       
   for (i = 0; i < 4096; i++) {
   
       dnmax = i;

       if (sumhis_ist[i] > g_up) break;    
       }
  
   if (dnmin != dnmax) {

       b = 255.0 /  (sqrt((double)dnmax) - sqrt((double)dnmin));
       
       
       a = 255.0 - b * sqrt ((double) dnmax); 
       
       for (i = 0; i < 4096; i++) {
       
           index = (int) (a + b * sqrt((double)i) + 0.499999);

	   if (index < 0)   index = 0;
	   if (index > 255) index = 255;
	   
           luttab[i] = (unsigned int) index; 
           }
       }
       
    *dn_min = dnmin;
    *dn_max = dnmax;
    *off    = a;
    *scale  = b;
    }

 
int new_suffix  (char     *name_alt,
                 char     *name_neu,
                 char     *suffix)
   {
/* ----------------------------------------------------------------------
   Variablen
   ---------------------------------------------------------------------- */
   char     *result;
   int      rs;
/* ----------------------------------------------------------------------
   Zusammenstellung des neuen Namens
   ---------------------------------------------------------------------- */
   result = strcpy  (name_neu, name_alt);
   result = strrchr (name_neu, '.');
   if (result != (char *)NULL) {
      result = strcpy  (result+1, suffix);
      }
   else {
      rs = strlen(name_alt);
      result = strcpy(name_neu+rs, ".");
      result = strcpy(result+1, suffix);
      }
 
   if (result == (char *)NULL)
      {
      return (EOF);
      }
   else
      return (1);
   }
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlr12to8.imake

#define PROGRAM dlr12to8

#define MODULE_LIST dlr12to8.c

#define MAIN_LANG_C

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_P1SUB 
$ Return
$!#############################################################################
$PDF_File:
$ create dlr12to8.pdf
process help=*

PARM INP     TYPE=(STRING,120)  COUNT=1:1000

PARM OUT    TYPE=(STRING,120)  COUNT=1

PARM MODE   TYPE=KEYWORD       COUNT=1    VALID=(NORMAL,EQUAL,LINEAR,SQRT,POW)  DEFAULT=LINEAR

PARM GMEAN  TYPE=REAL	  COUNT=0:1  VALID=(0:255)    DEFAULT=127.5
PARM GSIG   TYPE=REAL	  COUNT=0:1  VALID=(0.1:5.0)  DEFAULT=3.0

PARM POWER  TYPE=REAL	  COUNT=0:1  VALID=(0.1:0.9)  DEFAULT=0.33333


PARM DNMIN  TYPE=INT	  COUNT=0:1  VALID=(0:4095)   DEFAULT=--
PARM DNMAX  TYPE=INT	  COUNT=0:1  VALID=(0:4095)   DEFAULT=--

PARM LOWER  TYPE=REAL	  COUNT=0:1  VALID=(0.000001:99.999)   DEFAULT=0.3
PARM UPPER  TYPE=REAL	  COUNT=0:1  VALID=(0.000001:99.999)   DEFAULT=0.3
PARM MISSVAL  TYPE=INT	  COUNT=0:1  VALID=0                   DEFAULT=--
PARM HISFILE  TYPE=KEYWORD COUNT=1   VALID=(YES,NO)  DEFAULT=NO


END-PROC
.TITLE
 dlr12to8
.help
 dlr12to8 is a program to compute a LUT-table for the point by point 
 intensity value transformation of a 12 Bit to an 8 Bit image. 
 This ASCII LUT file is suitable for input to the program flcform_lut.

 Four transformation functions are given. 
 
      - Normalisation:     gmean, gsig
      - Equalisation
      - Linear             dnmin, dnmax  or
      - Linear (clipping)  lower, upper (bound, percentage of all 
		                         pixels [e.g: 0.1,0.1%])
      - SQRT (clipping)    lower, upper (bound, percentage of all 
		                         pixels [e.g: 0.1,0.1%])
      - pow (clipping)    lower, upper (bound, percentage of all 
		                         pixels [e.g: 0.1,0.1%])

.PAGE
EXECUTION:

 dlr12to8 histo-inp-file lut-out-file
          + Program reads the DNMIN DNMAX value in the  
	    histo-inp-file history label and performs
	    a linear scaling. 
 dlr12to8 lut-out-file dnmin=xx dnmax=yy
          + Program use the DNMIN, DNMAX parameter and 
	    performs a linear scaling (hwcform mode).
	    No histogram file is needed. 
 dlr12to8 histo-inp-file lut-out-file lower=xx upper=yy
          + Program calculates linear scaling factors.
	    xx percent of the lower and yy percent of 
	    the upper pixel values will be ignored. 
.page
 dlr12to8 histo-inp-file lut-out-file mode=equal
          + Program calculates LUT-table values for an
	    equalized output image. 
 dlr12to8 histo-inp-file lut-out-file mode=normal gmean=xx gsig=yy
              + Program calculates LUT-table values for an
	        normalized output image. 

.PAGE
 RESTRICTIONS:
 If there are no histogramm files the mode ist the linear 
 transformation mode with given dnmin and dnmax values.

 
.level1
.vari INP
 Input histogram files
.vari OUT
 output lut table file.
.vari MODE
 transformation mode
.vari GMEAN
 mean value of the 
 normalized image
.vari GSIG  
 standart deviation
 normalized image
.vari DNMIN 
 Minimum value to be used 
 for the calculation of 
 the scaling factor
.vari DNMAX 
 Maximum value to be used 
 for the calculation of 
 the scaling factor
.vari LOWER 
 percentage of the lower 
 pixel values which will be 
 ignored for the calculation 
 of the scaling factor
.vari UPPER 
 percentage of the upper 
 pixel values which will be 
 ignored for the calculation 
 of the scaling factor
.vari MISSVAL
 value will not be used 
 for histogram calculation  
 
.level2
.vari INP
 Input histogram files:
 
    list of ibis-file:   INP=his-1.ibis,his-2.ibis,his-3.ibis,....
 
        or ascii-file:   INP=List-of-his-files.ascii
	         with    File List-of-his-files.ascii contain all the 
		         ibis history files.


.end
$ Return
$!#############################################################################
