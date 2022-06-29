$!****************************************************************************
$!
$! Build proc for MIPL module hrorcgcl
$! VPACK Version 1.9, Thursday, October 23, 2003, 12:53:13
$!
$! Execute by entering:		$ @hrorcgcl
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
$ write sys$output "*** module hrorcgcl ***"
$!
$ Create_Source = ""
$ Create_Repack =""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if primary .eqs. "OTHER" then Create_Other = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Imake .or. Create_Other .or -
        Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hrorcgcl.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Create_Other then gosub Other_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
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
$   if F$SEARCH("hrorcgcl.imake") .nes. ""
$   then
$      vimake hrorcgcl
$      purge hrorcgcl.bld
$   else
$      if F$SEARCH("hrorcgcl.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrorcgcl
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrorcgcl.bld "STD"
$   else
$      @hrorcgcl.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrorcgcl.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrorcgcl.com -
	-s hrorcgcl.c version_string.c -
	-i hrorcgcl.imake -
	-o hrorcgcl.hlp throrcgcl.c throrcgcl.imake throrcgcl.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrorcgcl.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*
************************************************************************
*								       *
* This subroutine opens,reads and closes a geometric calibration file. *
* The calibration file must be put in IBIS-2 format.		       *
*								       *
************************************************************************

   Any programs calling this routine must have the following include
   file defined somewhere: vicmain_c */

#include <stdio.h>
#include <string.h>
#include <math.h>
#include "ibisfile.h"
#include "hwconst.h"
#include "ax_constants.h"
#include "SpiceUsr.h"
#include "hrgcl.h"
#define NVALS 20

void version_string(char *geocal_version, char *version);

void hrorcgcl (char *geocal_dir, char *h_geocal_version,
               char *spacecraft_name,
               char *instrument_id, char *detector_id, 
               char *filename, 
               double *x, double *y, double *focal, 
               int *non_active_pixel)

{

char	file_long[120];
char	label[80];
char    version[3];
char    instrument_number[2];
char    detector_short[3];
char    *getenv();
char    *value;
int     lauf,lauf2;

/* define of variables for IBIS-functions */
int	vi_un;
int	ib_un;
int	nrow;
int	status;
int	row;
int	col;

float   foc_dummy;
float   x_dummy[AXLEVEL1_ACTIVE_PIXEL]; /* AX is larger as HRSC and MOC*/
float   y_dummy[AXLEVEL1_ACTIVE_PIXEL];

SpiceDouble  pb, c[NVALS], s, a;
char         instring[50],kernelstring[50];
SpiceInt     nvals;
SpiceBoolean found;
double       cp, ap, ap2, r, phi, z;

/* get the environments */
value=getenv(geocal_dir);
if (value != NULL) strcpy(geocal_dir,value);

value=getenv(h_geocal_version);
if (value != NULL) strcpy(h_geocal_version,value);

/* check MOC */
if (strcmp(spacecraft_name,"MGS")) { /* no MOC */

    /* Build the name of the data file */

    if (strcmp(spacecraft_name,"MARS_EXPRESS")==0) { /* MARS-EXPRESS */

	/* We have only HRSC FM2 */
   	strcpy(file_long,"h2g");

        if      (!strcmp(detector_id,"MEX_HRSC_S2"))    strcpy(detector_short,"s2");
        else if (!strcmp(detector_id,"MEX_HRSC_RED"))   strcpy(detector_short,"re");
        else if (!strcmp(detector_id,"MEX_HRSC_P2"))    strcpy(detector_short,"p2");
        else if (!strcmp(detector_id,"MEX_HRSC_BLUE"))  strcpy(detector_short,"bl");
        else if (!strcmp(detector_id,"MEX_HRSC_NADIR")) strcpy(detector_short,"nd");
        else if (!strcmp(detector_id,"MEX_HRSC_GREEN")) strcpy(detector_short,"gr");
        else if (!strcmp(detector_id,"MEX_HRSC_P1"))    strcpy(detector_short,"p1");
        else if (!strcmp(detector_id,"MEX_HRSC_IR"))    strcpy(detector_short,"ir");
        else if (!strcmp(detector_id,"MEX_HRSC_S1"))    strcpy(detector_short,"s1");
        else {
            zvmessage("Unknown detector ID","");
            zabend();
            }
	strncat(file_long,detector_short,2);
	strcat(file_long,"_");

        }

    else if (strncmp(instrument_id,"FL_",3)==0) { /* AX */

	strcpy(file_long,"ag");
	strcat(file_long,spacecraft_name);
	strcat(file_long,"_");

        }
    else if (strncmp(instrument_id,"FL",2)==0) { /* airplane instrument (but no AX) */

	file_long[0] = 'f';
	file_long[1] = instrument_id[2];
	file_long[2] = 'g';
	file_long[3] = '\0';

	strncat(file_long,detector_id,2);
	strcat(file_long,"1");

	}
    else {	

        zvmessage("*** hrorcgcl ***", "");
        zvmessage("Invalid Spacecraft_Name:","");
        zvmessage(spacecraft_name,"");
        zabend();

        }

    /* Complete the name of the data file */

    version_string(h_geocal_version, version);
    strcat(file_long,version);
    strcat(file_long,".cal");
    for (lauf=0; lauf<strlen(file_long); lauf++)
    file_long[lauf] = tolower(file_long[lauf]);

    if (strcmp(geocal_dir,"\0") != 0) {
   	    strcat(geocal_dir,"/");
   	    strcat(geocal_dir,file_long);
  	    strcpy(file_long,geocal_dir);
   	    }

    /* assign a unit No. to the IBIS file */
    status=zvunit(&vi_un,"none",1,"U_NAME",file_long,0);
    if(status !=1) {
   	    zvmessage("hrorcgcl","");
   	    zvmessage("could not open geocal file","");
   	    zvmessage(file_long,"");
   	    zabend();
   	    }

    /* open the IBIS file */
    status=IBISFileOpen(vi_un,&ib_un,IMODE_READ,2,0,0,0);
    if (status!=1) IBISSignalU(vi_un,status,1);

    /* How many pixel? */
    status=zlget(vi_un,"PROPERTY","NR",&nrow,"FORMAT","INT",
                   "PROPERTY","IBIS",0);
    if (status != 1) {
   	    zvmessage("keyword NR missing","");
   	    zabend();
   	    }

    /* Read the label for the focal length */
    status=zlget(vi_un,"HISTORY","FOCAL_LENGTH",&foc_dummy,"format","real",0);
    if (status !=1) {
   	    status=zlget(vi_un,"HISTORY","FOCUS",&foc_dummy,"format","real",0);
	    if (status !=1) {
                    zvmessage("keywords FOCAL_LENGTH and FOCUS missing","");
   		    zabend();
   		    }
            }

    *focal = (double) foc_dummy;

    if (strncmp(instrument_id,"FL",2))
       {/* not airplane, we can check the SPACECRAFT_NAME */
       status=zlget(vi_un,"HISTORY","INSTRUMENT_HOST_NAME",label,"format","string",0);
       if (status !=1) {
            status=zlget(vi_un,"HISTORY","SPACECRAFT_NAME",label,"format","string",0);
            if (status !=1) {
                zvmessage("keywords SPACECRAFT_NAME and INSTRUMENT_HOST_NAME missing","");
   		zabend();
   		}
            }
       if (strcmp(spacecraft_name,label)) {
	  IBISFileClose(ib_un,0);
	  zvmessage("The label-keyword SPACECRAFT_NAME is not corresponding","");
	  zabend();
	  }
       }

    if (strncmp(instrument_id,"FL_",3))
       { /* not AX, we can check the INSTRUMENT_NAME  and DETECTOR_ID */
       zlget(vi_un,"HISTORY","INSTRUMENT_NAME",label,"format","string",0);
       if (strcmp("HIGH_RESOLUTION_STEREO_CAMERA",label)) 
	  {
	  IBISFileClose(ib_un,0);
	  zvmessage("The label-keyword INSRUMENT_NAME is not corresponding","");
	  zabend();
	  }
       zlget(vi_un,"HISTORY","DETECTOR_ID",label,"format","string",0);
       if (strcmp(detector_id,label)) 
	    {
	    IBISFileClose(ib_un,0);
	    zvmessage("The label-keyword DETECTOR_ID is not corresponding","");
	    zabend(); 
	    }
       }
    else
       { /* AX check SIGNAL_CHAIN_ID which is in spacecraft_name !!! */
       zlget(vi_un,"HISTORY","SIGNAL_CHAIN_ID",label,"format","string",0);
       if (strcmp(spacecraft_name,label)) 
	  {
	  IBISFileClose(ib_un,0);
	  zvmessage("The label-keyword SIGNAL_CHAIN_ID is not corresponding","");
	  zabend();
	  }
       }


    /* read the columns */

    status=IBISColumnRead(ib_un,(char*)x_dummy,1,1,nrow);
    if (status!=1) IBISSignalU(vi_un,status,1);
    status=IBISColumnRead(ib_un,(char*)y_dummy,2,1,nrow);
    if (status!=1) IBISSignalU(vi_un,status,1);

    for(row=0;row<nrow;row++)
       {
	x[row] = (double) x_dummy[row];
	y[row] = (double) y_dummy[row];
	}

    IBISFileClose(ib_un,0);  
    hwnopath(file_long);
    strcpy(filename,file_long);

    /* set non_active_pixel */
    if (strncmp(instrument_id,"FL_",3))
       /* non AX */
       *non_active_pixel = NON_ACTIVE_HRSC_PIXEL_START;
    else
       if (strncmp(instrument_id,"FL_2",4))
          *non_active_pixel = AXCCD_FIRST_ACTIVE_PIXEL - 1;
       else /* ADS */
          *non_active_pixel = 0;
    } /* end of no-MOC */

else

    { /* MOC , copied from Fortran program in I-kernel */
    *non_active_pixel = 0;
    if (strcmp(instrument_id,"WA"))
       /* NA */
       strcpy(instring,"INS-94031_");
    else
       /* WA */
       if (strcmp(detector_id, "RED"))
          /* BLUE */
          strcpy(instring,"INS-94033_");
       else
          /* RED */
          strcpy(instring,"INS-94032_");

    strcpy(kernelstring, instring);
    strcat(kernelstring, "PIXEL_SAMPLES");
    gdpool_c(kernelstring, 0, 1, &nvals, c, &found); 
    if (found)
       nrow = (int) (c[0] + 0.4);
    else
       {
       zvmessage("MOC SAMPLES missing in I-kernel","");
       zabend();
       }   
    strcpy(kernelstring,instring);
    strcat(kernelstring,"FOCAL_LENGTH");
    gdpool_c(kernelstring, 0, 1, &nvals, focal, &found);
    if (!found)
       {
       zvmessage("MOC FOCAL missing in I-kernel","");
       zabend();
       }
   /* we want foal in mm, it is in m in the I-kernel */
   *focal = *focal * 1000;

    strcat(instring,"RD_");
    strcpy(kernelstring,instring);
    strcat(kernelstring,"PB");
    gdpool_c(kernelstring, 0, 1, &nvals, &pb, &found);
    if (!found)
       {
       zvmessage("MOC PB missing in I-kernel","");
       zabend();
       }
    strcpy(kernelstring,instring);
    strcat(kernelstring,"S");
    gdpool_c(kernelstring, 0, 1, &nvals, &s, &found);
    if (!found)
       {
       zvmessage("MOC S missing in I-kernel","");
       zabend();
       }
    strcpy(kernelstring,instring);
    strcat(kernelstring,"A");
    gdpool_c(kernelstring, 0, 1, &nvals, &a, &found);
    if (!found)
       {
       zvmessage("MOC A missing in I-kernel","");
       zabend();
       }
    strcpy(kernelstring,instring);
    strcat(kernelstring,"C");
    gdpool_c(kernelstring, 0, NVALS, &nvals, c, &found);
    if (!found)
       {
       zvmessage("MOC C missing in I-kernel","");
       zabend();
       }

    ap  = a /1000.0;
    ap2 = ap * ap;
    for (lauf=0; lauf<nrow; lauf++)
       {
       cp = s * (lauf - pb) / 1000.0;
       r = sqrt(cp * cp + ap2);
       phi = 0;
       for (lauf2=0; lauf2<nvals; lauf2++)
          phi = phi + c[lauf2] * pow(r, (double) (lauf2+1));
       phi = phi * rpd_c();
       if (r != 0)
          {
          x[lauf] =  sin(fabs(phi)) * (ap/r);
          y[lauf] = -sin(     phi ) * (cp/r);
          z       =  cos(     phi );
          if (z == 0)
             { 
             zvmessage("hrorcgcl error, z == 0", "");
             zabend();
             }
          /* convert to (x,y,focal) amd chamge the sign
             as necessary for hrviewpa */
          z = *focal / z;
          x[lauf] = -x[lauf] * z;
          y[lauf] = -y[lauf] * z;
          }
       else
          {
          x[lauf] = 0;
          y[lauf] = 0;
          }       
       }

    }
}



void version_string(char *geocal_version, char *version)

{
  if (strlen(geocal_version) > 2)
      {
      zvmessage("*** hrorcgcl ***", "");
      zvmessage("invalid version number", "");
      zabend();
      } 
      if (strlen(geocal_version) == 1)
         {
         strcpy(version,"0");
         strcat(version,geocal_version);
         }
      else  strcpy(version,geocal_version);
}
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create version_string.c
$ DECK/DOLLARS="$ VOKAGLEVE"
void version_string(char *geocal_version, char *version)

{
  if (strlen(geocal_version) > 2)
      {
      zvmessage("*** hrorcgcl ***", "");
      zvmessage("invalid version number", "");
      zabend();
      } 
      if (strlen(geocal_version) == 1)
         {
         strcpy(version,"0");
         strcat(version,geocal_version);
         }
      else  strcpy(version,geocal_version);
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrorcgcl.imake
/* IMAKE file for subroutine hrorcgcl */

#define SUBROUTINE hrorcgcl  

#define MODULE_LIST hrorcgcl.c version_string.c

#define HW_SUBLIB

#define USES_ANSI_C
#define LIB_P1SUB
#define LIB_CSPICE
$ Return
$!#############################################################################
$Other_File:
$ create hrorcgcl.hlp
1  Subroutine hrorcgcl

	Calling Sequence:
	hrorcgcl ( geocal_dir, geocal_version, spacecraft_name, 
           instrument_id, detector_id, 
           filename, x, y, &focal,&non_active_pixel);

2  Arguments

	geocal_dir:      enviroment which points to the diectory
		         whith the geometric calibration files,  INPUT
	geocal_version:  enviroment which gives the version
		         of the geometric calibration files,     INPUT
	spacecraft_name: name of the mission (MARS94 or MARS96), INPUT
	instrument_id:	 name of the camera (QM or FM1 or FM2),	 INPUT
	detector_id:	 name of CCD line permitted keywords:
			 (S1,IR,P1,GR,ND,BL,P2,RE,S2),		 INPUT
	filename:	 name of the calibration file		 OUTPUT
	x:		 array of x coordinates			 OUTPUT
	y:		 array of y coordinates                  OUTPUT
	focal:		 focal length				 OUTPUT
        non_active_pixel non_active_pixelat the CCD start        OUTPUT
        
3  Operation

	This subroutine opens,reads and closes a geometric calibration-
	file (only IBIS-2 format). 
	This subroutine determines the full filename from all input
	parameters and searches for and opens the geometric calibration
	file and reads its label.
	The keywords "SPACRAFT_NAME","INSTRUMENT_ID" and
	"DETECTOR_ID" are checked.
4  History

	Project:	Mars-94
	Programmer:	KDM, 29-Sep-93
	Modification:	J.Kachlicki, 09-Mai-94
        Modification:	Th. Roatsch, 15-feb-00
                        (renamed from hworcgcl to hrorcgcl)
        Modification:	K.-D. Matz, 21-feb-02
$!-----------------------------------------------------------------------------
$ create throrcgcl.c
#include "vicmain_c"
#include "hwldker.h"
#include "hrgcl.h"

/*
testprogram for hrorcgcl, currently only for the MOC part
*/

void main44()

{

   int    count;
   int    status;

   char   d1[250];
   char   outstring[80];
   int    lauf;
   double x[5000],y[5000];
   double focal;
   hwkernel_1 ti;
   
   

status=hwldker(1, "ti", &ti);
if (status != 1) 
   {
   zvmessage("problem with I-kernel","");
   printf("status %d\n",status);
   zabend();
   }
hrorcgcl ( "xxx", "yyy",
           "MGS",
           "NA", "zzz", 
           outstring, x, y, &focal, &count);
zvmessage("NAC","");
printf("focal %10.5f\n", focal);
for (lauf=0; lauf<2048; lauf++)
   printf("%4d %10.5f %10.5f\n", lauf, x[lauf],y[lauf]);           
zvmessage("","");

hrorcgcl ( "xxx", "yyy",
           "MGS",
           "WA", "RED", 
           outstring, x, y, &focal, &count);
zvmessage("RED","");
printf("focal %10.5f\n", focal);
for (lauf=0; lauf<3456; lauf++)
   printf("%4d %10.5f %10.5f\n", lauf, x[lauf],y[lauf]);           
zvmessage("","");

hrorcgcl ( "xxx", "yyy",
           "MGS",
           "WA", "BLUE", 
           outstring, x, y, &focal, &count);
zvmessage("BLUE","");
printf("focal %10.5f\n", focal);
for (lauf=0; lauf<3456; lauf++)
   printf("%4d %10.5f %10.5f\n", lauf, x[lauf],y[lauf]);           
zvmessage("","");

           

}
$!-----------------------------------------------------------------------------
$ create throrcgcl.imake
/* IMAKE file for Cookbook program HWCOOK1C */

#define PROGRAM   throrcgcl  

#define MODULE_LIST throrcgcl.c

#define MAIN_LANG_C

#define HWLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_LOCAL
#define LIB_HWSUB
#define LIB_P1SUB
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create throrcgcl.pdf
Process help=*
 PARM TIFILE DEFAULT=/vicsys/mgs/sun-solr/MGS_MOC_V20.TI
END-PROC
.Title
 Cookbook Program HWCOOK1C
.HELP

PURPOSE

HWCOOK1C demonstrates the parameter inputand the usage of default
directories.

WRITTEN BY Thomas Roatsch, DLR    3-Jun-1993
REVISED BY Thomas Roatsch, DLR   27-Sep-1993

.LEVEL1
.VARI A1
 Necessary Integer 
.VARI A2
 Nullable Integer 
.VARI B
 Necessary Real (float)
.VARI C
 Necessery Integer Array
.VARI D1
 Necessary String
.VARI D2
 Nullable String
.Vari E
 Necessary Keyword
.LEVEL2
.VARI A1
 A1 has the type integer, it is a necessary parameter (COUNT=1),
 has a default value and a valid range.
 Only the type definition is necessary for an integer input parameter.
 The definition of count and valid ensures that already TAE checks the
 parameter input, no check inside the program is necessary.
 A default value is useful for a standard input.
 In batch mode the parameter has to be specified in the 
 "parameter_name=value" format.

.VARI A2
 A2 is a nullable integer (COUNT=(0:1). One paramter input is
 possible but not necessary. 
 The DEFAULT=-- definition is necessary  for nullable parameters.

.VARI B
 B has the type real, it has the type float inside the program.
 Only float is allowed, no double.

.VARI C
 C is an integer array with the dimension 5 (COUNT=5).

.VARI D1
 D1 has the type string, this is the default type.

.VARI D2
 D2 is a nullable string. 

.VARI E
 E has the type keyword. A valid list is necessary for this type,
 count is always one for a keyword and has not to be defined.
 In batch mode a single quote,', replaces the "parameter_name=" part of the 
 specification for keywords. 

.End
$ Return
$!#############################################################################
