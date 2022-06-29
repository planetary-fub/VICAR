$!****************************************************************************
$!
$! Build proc for MIPL module dlrframe_info
$! VPACK Version 1.9, Wednesday, November 23, 2005, 11:45:36
$!
$! Execute by entering:		$ @dlrframe_info
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
$ write sys$output "*** module dlrframe_info ***"
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
$ write sys$output "Invalid argument given to dlrframe_info.com file -- ", primary
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
$   if F$SEARCH("dlrframe_info.imake") .nes. ""
$   then
$      vimake dlrframe_info
$      purge dlrframe_info.bld
$   else
$      if F$SEARCH("dlrframe_info.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake dlrframe_info
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @dlrframe_info.bld "STD"
$   else
$      @dlrframe_info.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create dlrframe_info.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack dlrframe_info.com -mixed -
	-s dlrframe_info.c -
	-i dlrframe_info.imake -
	-t tstdlrframe_info.c tstdlrframe_info.imake tstdlrframe_info.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create dlrframe_info.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "SpiceUsr.h"
#include "dlrframe.h"

#define TARGET_LENGTH  255

/*     Written by Thomas Roatsch, DLR     25-May-1999
       Added tol for Viking, GLL, Clementine 21-Sep-1999 */


int code2name(dlrframe_info *dlrframe_info);

int dlrframe_getinfo (int unit, dlrframe_info *dlrframe_info)

{

int          status,lauf;
char         helpstring[255], helpstring1[255];
char         *value;
double       dhelp;
int          ihelp;
char         mipl_project[20];
int          found;
char         target[TARGET_LENGTH];
SpiceBoolean id_found;
char         issprop[50];


/* read the system label */
status = zvget(unit, "NL", &dlrframe_info->nl, "NS", &dlrframe_info->ns,
               "NB", &dlrframe_info->nb, "NBB", &dlrframe_info->nbb,
               "NLB", &dlrframe_info->nlb, "FORMAT", dlrframe_info->format, "");
if (status != 1) return (-1);

dlrframe_info->trim_top    = 0;
dlrframe_info->trim_bottom = 0;
dlrframe_info->trim_left   = 0;
dlrframe_info->trim_right  = 0;

dlrframe_info->tol = -1;    /* -1 is not allowed for tol */

found = 0;       

/* lets try Voyager */
status = find_hist_key(unit, "LAB02", 1, helpstring1, &ihelp);
if (status == 1)
   {
status = zlget(unit, "HISTORY", "LAB02", helpstring, "HIST", helpstring1, "");   
if (status == 1)
   {
   /* voyager 1 ?*/
   if(strstr(helpstring,"VGR-1") != NULL)
      {
      strcpy(mipl_project, "VGR-1");
      dlrframe_info->spacecraft_id = Voyager_1;
      found = 1;      
      }
   
   /* voyager 2 ?*/
   if(strstr(helpstring,"VGR-2") != NULL)
      {
      strcpy(mipl_project, "VGR-2");
      dlrframe_info->spacecraft_id = Voyager_2;
      found = 1;      
      }
   } 
   } /* find_hist lab02 */
if (found) /* it is Voyager! */
   {
   dlrframe_info->ck_id         = dlrframe_info->spacecraft_id * 1000;
   dlrframe_info->tol =1;  
   
   dlrframe_info->trim_top    = VOYAGER_TRIM_TOP_LINES;
   dlrframe_info->trim_bottom = VOYAGER_TRIM_BOTTOM_LINES;
   dlrframe_info->trim_left   = VOYAGER_TRIM_LEFT_SAMPLES;
   dlrframe_info->trim_right  = VOYAGER_TRIM_RIGHT_SAMPLES;
   
   value = strstr(helpstring,"FDS"); 
   if (value != NULL)
      {
      strcpy(helpstring1,value);
      sscanf(&helpstring1[4],"%lf",&dhelp);
      dlrframe_info->adju_id = (int) (dhelp * 100 +0.2);
      }
   else return (-101); 
   
   value = strstr(helpstring,"SCET"); 
   if (value != NULL)
      {
      strcpy(helpstring,value);
      sscanf(&helpstring[5],"%s",helpstring1);
      strcpy(dlrframe_info->utc,"19");
      strcat(dlrframe_info->utc,helpstring1);
      dlrframe_info->utc[4]='-';
      sscanf(&helpstring[12],"%s",helpstring1);
      strcat(dlrframe_info->utc,"::");
      strcat(dlrframe_info->utc,helpstring1);
      }
   else return (-102); 
   
   status = find_hist_key(unit, "LAB03", 1, helpstring1, &ihelp);
   status = zlget(unit, "HISTORY", "LAB03", helpstring, "HIST", helpstring1, "");
   value = strstr(helpstring,"CAMERA");
   if (value != NULL)
      {
      value = value -3;
      strcpy(helpstring1,value);
      if (!strncmp(helpstring1,"NA",2))
         if (!strcmp(mipl_project,"VGR-1")) 
            dlrframe_info->instrument_id = Voyager_1_NAC;
         else dlrframe_info->instrument_id = Voyager_2_NAC;
      else if (!strncmp(helpstring1,"WA",2))
              if (!strcmp(mipl_project,"VGR-1"))
                 dlrframe_info->instrument_id = Voyager_1_WAC;
              else dlrframe_info->instrument_id = Voyager_2_WAC;
           else return (-103);      
      }
   else return (-104);      
   
   status = find_hist_key(unit, "LAB05", 1, helpstring1, &ihelp);
   status = zlget(unit, "HISTORY", "LAB05", helpstring, "HIST", helpstring1, "");
   /* we have to start after Io since Io is contained in Dione */
   lauf = 501; 
   status = 0;
   do {
      lauf++;
      bodc2n_c(lauf, TARGET_LENGTH, target, &id_found);
      /* it is just ENCELADU in the VGR label */
      if (!strcmp("ENCELADUS", target)) strcpy(target,"ENCELADU");
      if (id_found && (strstr(helpstring,target) != NULL)) status = 1;
      } while ((lauf < 900) && (!status));
   if (status == 1)
      dlrframe_info->target_id = lauf;
   else /* now check  Io */
      if (strstr(helpstring,"IO"))
          dlrframe_info->target_id = 501;
      else  
          return (-105);
   status = code2name(dlrframe_info);
   if (status != 1) return -1000;
   return (1);
   } /*end of Voyager */


/* lets try the DLR label,
   currently Viking, Clementine */

/* The DLR SPACECRAFT_NAME is different from the NAIF names 
   for Viking and Clementine !!! */
status = zlget(unit, "PROPERTY", "SPACECRAFT_NAME", helpstring, 
   "PROPERTY", "M94_INSTRUMENT", "");
if (status == 1)
   {
   status = zlget(unit, "PROPERTY", "SPICE_TARGET_ID", 
       &dlrframe_info->target_id,  
       "PROPERTY", "M94_ORBIT", "");
   if (status != 1) return (-201);
   
   status = zlget(unit, "PROPERTY", "SPICE_INSTRUMENT_ID", 
       &dlrframe_info->instrument_id,  
       "PROPERTY", "M94_ORBIT", "");
   if (status != 1) return (-202);
   dlrframe_info->spacecraft_id = dlrframe_info->instrument_id / 1000;
            
   if (!strncmp(helpstring,"VIKING_ORBITER",14)) found = 1;
      else if (!strcmp(helpstring,"CLEMENTINE1")) found = 2;
         else return (-203);
         
   dlrframe_info->ck_id = dlrframe_info->spacecraft_id * 1000;
   
   switch (found)
   {
   case 1: /* Viking */
           dlrframe_info->trim_top    = VIKING_TRIM_TOP_LINES;
           dlrframe_info->trim_bottom = VIKING_TRIM_BOTTOM_LINES;
           dlrframe_info->trim_left   = VIKING_TRIM_LEFT_SAMPLES;
           dlrframe_info->trim_right  = VIKING_TRIM_RIGHT_SAMPLES;
           dlrframe_info->tol         = 5000;
           
           status = zlget(unit, "PROPERTY", "IMAGE_TIME", 
                    dlrframe_info->utc,  
                    "PROPERTY", "M94_ORBIT", "");
           if (status != 1) return (-211);
           status = zlget(unit, "PROPERTY", "IMAGE_NUMBER", 
                    &dlrframe_info->adju_id,  
                    "PROPERTY", "M94_ORBIT", "");
           if (status != 1) return (-212);
           break;
   case 2: /* Clementine */
           dlrframe_info->tol         = 10000;
           status = zlget(unit, "PROPERTY", "START_TIME", 
                    dlrframe_info->utc,  
                    "PROPERTY", "M94_ORBIT", "");
           if (status != 1) return (-221);
           status = zlget(unit, "PROPERTY", "FRAME_SEQUENCE_NUMBER", 
                    &dlrframe_info->adju_id,  
                    "PROPERTY", "M94_ORBIT", "");
           if (status != 1) return (-222);
           status = zlget(unit, "PROPERTY", "ORBIT_NUMBER", 
                    &ihelp,  
                    "PROPERTY", "M94_ORBIT", "");
           if (status != 1) return (-223);
           dlrframe_info->adju_id = 
                       dlrframe_info->adju_id * 1000 + ihelp;
           break;
   }
   
status = code2name(dlrframe_info);
if (status != 1) return -1000;
return (1);
   } /*end of DLR label */ 


/* lets try Galileo-SSI */
status = find_hist_key(unit, "MISSION", 1, helpstring, &ihelp);
if (status == 1)
   {
   status = zlget(unit, "HISTORY", "MISSION", 
                  helpstring1, "HIST", helpstring, "");
   if (!strcmp(helpstring1,"GALILEO"))
      {
      status = find_hist_key(unit, "SENSOR", 1, helpstring, &ihelp);
      status = zlget(unit, "HISTORY", "SENSOR", 
                     helpstring1, "HIST", helpstring, "");
      if (!strcmp(helpstring1,"SSI")) found = 1;
      }
   }
   
if (found) /* it is Galileo-SSI */
   {
   dlrframe_info->instrument_id = Galileo_SSI;
   dlrframe_info->spacecraft_id = dlrframe_info->instrument_id / 1000;
   dlrframe_info->ck_id         = dlrframe_info->spacecraft_id * 1000 - 1;
   dlrframe_info->tol           = 1000;
   status = find_hist_key(unit, "TARGET", 1, helpstring, &ihelp);
   if (status != 1) return (-301);
   status = zlget(unit, "HISTORY", "TARGET", 
                  helpstring1, "HIST", helpstring, "");
   bodn2c_c(helpstring1,&dlrframe_info->target_id, &id_found);
   if (!id_found) return (-302);
   status = find_hist_key(unit, "RIM", 1, helpstring, &ihelp);
   if (status != 1) return (-303);
   status = zlget(unit, "HISTORY", "RIM", 
                  &dlrframe_info->adju_id, "HIST", helpstring, "");
   status = find_hist_key(unit, "MOD91", 1, helpstring, &ihelp);
   if (status != 1) return (-304);
   status = zlget(unit, "HISTORY", "MOD91", 
                  &ihelp, "HIST", helpstring, "");
   dlrframe_info->adju_id = 
              dlrframe_info->adju_id * 100 + ihelp;

   status = find_hist_key(unit, "SCETYEAR", 1, helpstring, &ihelp);
   if (status != 1) return (-305);
   status = zlget(unit, "HISTORY", "SCETYEAR", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(dlrframe_info->utc,"%4d",ihelp);
   status = find_hist_key(unit, "SCETDAY", 1, helpstring, &ihelp);
   if (status != 1) return (-306);
   status = zlget(unit, "HISTORY", "SCETDAY", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(helpstring,"-%03d",ihelp);
   strcat(dlrframe_info->utc,helpstring);
   status = find_hist_key(unit, "SCETHOUR", 1, helpstring, &ihelp);
   if (status != 1) return (-307);
   status = zlget(unit, "HISTORY", "SCETHOUR", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(helpstring,"::%02d",ihelp);
   strcat(dlrframe_info->utc,helpstring);
   status = find_hist_key(unit, "SCETMIN", 1, helpstring, &ihelp);
   if (status != 1) return (-308);
   status = zlget(unit, "HISTORY", "SCETMIN", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(helpstring,":%02d",ihelp);
   strcat(dlrframe_info->utc,helpstring);
   status = find_hist_key(unit, "SCETSEC", 1, helpstring, &ihelp);
   if (status != 1) return (-309);
   status = zlget(unit, "HISTORY", "SCETSEC", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(helpstring,":%02d",ihelp);
   strcat(dlrframe_info->utc,helpstring);
   status = find_hist_key(unit, "SCETMSEC", 1, helpstring, &ihelp);
   if (status != 1) return (-310);
   status = zlget(unit, "HISTORY", "SCETMSEC", 
                  &ihelp, "HIST", helpstring, "");
   sprintf(helpstring,".%03d",ihelp);
   strcat(dlrframe_info->utc,helpstring);
   
   status = code2name(dlrframe_info);
   if (status != 1) return -1000;
   return (1);
   } /* end of Galileo */

/* lets try Cassini */
/* old ISS label */
status = zlget(unit, "PROPERTY", "MISSION_NAME", helpstring, 
         "PROPERTY", "CASSINI-ISS2", "");
if ((status == 1) && (!strcmp(helpstring,"CASSINI"))) 
   {
   found =1;
   strcpy(issprop,"CASSINI-ISS2");
   }
   
/* new ISS label */   
if (!found)
   {
   status = zlget(unit, "PROPERTY", "MISSION_NAME", helpstring, 
         "PROPERTY", "IDENTIFICATION", "");
   if ((status == 1) && 
      ( (!strcmp(helpstring,"CASSINI")) ||
         (!strcmp(helpstring,"CASSINI-HUYGENS")) ) ) 
      {
      found =1;
      strcpy(issprop,"IDENTIFICATION");
      }
   }
if (found) /* it is Cassini-ISS ! */
   {
   dlrframe_info->instrument_id = 1; /* new SPICE */
   strcpy(dlrframe_info->spacecraft_name,"CASSINI");
   strcpy(dlrframe_info->instrument_name,"CASSINI");
   status = zlget(unit, "PROPERTY", "INSTRUMENT_ID", helpstring, 
         "PROPERTY", issprop, "");
   if (status != 1) return (-401);
   if (!strcmp(helpstring,"ISSNA")) 
      strcat(dlrframe_info->instrument_name, "_ISS_NAC");
   else 
      if (!strcmp(helpstring,"ISSWA")) 
          strcat(dlrframe_info->instrument_name, "_ISS_WAC");
      else return (-402);
   /* not defined in frame kernel !!! */
   boddef_c("CASSINI_ISS_NAC",-82360);
   boddef_c("CASSINI_ISS_WAC",-82361);
   
   status = zlget(unit, "PROPERTY", "IMAGE_NUMBER", &dlrframe_info->adju_id, 
         "PROPERTY", issprop, "");
   if (status != 1) return (-403);
   status = zlget(unit, "PROPERTY", "IMAGE_MID_TIME", dlrframe_info->utc, 
         "PROPERTY", issprop, "");
   if (status != 1) return (-404);
   /* stupid Z */
   dlrframe_info->utc[strlen(dlrframe_info->utc)-1]='\0';
   /* let's first try TARGET_NAME ??? */
   status = zlget(unit, "PROPERTY", "TARGET_NAME", helpstring, 
         "PROPERTY", issprop, "");
   bodn2c_c(helpstring, &dlrframe_info->target_id, &id_found);
   if (!id_found) 
      { /* let's try TARGET_DESC */
      status = zlget(unit, "PROPERTY", "TARGET_DESC", helpstring, 
            "PROPERTY", issprop, "");
      if (status != 1) return (-405);
      /* let's hope that the first word is the target ... */
      value=strchr(helpstring,',');
      if (value != NULL) value[0]='\0';
      strcpy(dlrframe_info->target_name,helpstring);
      bodn2c_c(helpstring, &dlrframe_info->target_id, &id_found);
      if (!id_found) return (-406); 
      }
   else
      strcpy(dlrframe_info->target_name,helpstring);
   return (1);
   } /* end of Cassini-ISS */

/* lets try MEX-SRC */
status = zlget(unit, "PROPERTY", "DETECTOR_ID", helpstring, 
         "PROPERTY", "M94_INSTRUMENT", "");
if ((status == 1) && (!strcmp(helpstring,"MEX_HRSC_SRC"))) found =1;
if (found) /* it is MEX-SRC */
   {
   dlrframe_info->instrument_id = 1; /* new SPICE */
   strcpy(dlrframe_info->spacecraft_name,"MARS EXPRESS");
   strcpy(dlrframe_info->instrument_name, helpstring);
   status = zlget(unit, "PROPERTY", "IMAGE_TIME", dlrframe_info->utc, 
         "PROPERTY", "M94_ORBIT", "");
   if (status != 1) return (-501);
   /* stupid Z */
   dlrframe_info->utc[strlen(dlrframe_info->utc)-1]='\0';
   status = zlget(unit, "PROPERTY", "TARGET_NAME", helpstring, 
         "PROPERTY", "MAP", "");
   if (status != 1) return (-502);
   strcpy(dlrframe_info->target_name,helpstring);
   bodn2c_c(helpstring, &dlrframe_info->target_id, &id_found);
   if (!id_found) return (-503);
   status = zlget(unit, "PROPERTY", "FILE_NAME", helpstring, 
            "PROPERTY", "FILE", "");
   if (status != 1) return (-504);
   dlrframe_info->adju_id = atoi(&helpstring[1]);
   dlrframe_info->adju_id = dlrframe_info->adju_id * 10000 +
      atoi(&helpstring[6]);
   status = zlget(unit, "PROPERTY", "PROCESSING_LEVEL_ID", &ihelp, 
            "PROPERTY", "FILE", "");
   if ((status != 1) || (ihelp !=2)) return (-505);
   status = zlget(unit, "PROPERTY", "SAMPLE_FIRST_PIXEL", &dlrframe_info->spacecraft_id, 
            "PROPERTY", "M94_CAMERAS", "");
   if (status != 1) return (-506);
   status = zlget(unit, "PROPERTY", "LINE_FIRST_PIXEL", &dlrframe_info->ck_id, 
            "PROPERTY", "M94_CAMERAS", "");
   if (status != 1) return (-507);
   return 1;
   }  /* end of MEX SRC */

     
/* lets try VEX-VMC */
status = zlget(unit, "PROPERTY", "DETECTOR_ID", helpstring, 
         "PROPERTY", "VEX_INSTRUMENT", "");
if ((status == 1) && (strstr(helpstring,"VEX_VMC"))) found =1;
if (found) /* it is VEX-VMC */
   {
   dlrframe_info->instrument_id = 1; /* new SPICE */
   strcpy(dlrframe_info->spacecraft_name,"VENUS EXPRESS");
   strcpy(dlrframe_info->instrument_name, helpstring);
   status = zlget(unit, "PROPERTY", "IMAGE_TIME", dlrframe_info->utc, 
         "PROPERTY", "VEX_ORBIT", "");
   if (status != 1) return (-601);
   /* stupid Z */
   dlrframe_info->utc[strlen(dlrframe_info->utc)-1]='\0';
   status = zlget(unit, "PROPERTY", "MACROPIXEL_SIZE", &found, 
            "PROPERTY", "VEX_INSTRUMENT", "");
   if (status != 1) return (-608);
   if (found != 1)
      {
      printf("**************************\n");
      printf("**************************\n");
      printf("VMC macropixel is %d\n", found);
      printf("NOT YET IMPLEMENTED !!!\n");
      printf("**************************\n");
      printf("**************************\n");
      }
   status = zlget(unit, "PROPERTY", "TARGET_NAME", helpstring, 
         "PROPERTY", "MAP", "");
   if (status != 1) return (-602);
   strcpy(dlrframe_info->target_name,helpstring);
   bodn2c_c(helpstring, &dlrframe_info->target_id, &id_found);
   if (!id_found) return (-603);
   status = zlget(unit, "PROPERTY", "FILE_NAME", helpstring, 
            "PROPERTY", "FILE", "");
   if (status != 1) return (-604);
   dlrframe_info->adju_id = atoi(&helpstring[1]);
   dlrframe_info->adju_id = dlrframe_info->adju_id * 10000 +
      atoi(&helpstring[6]);
   status = zlget(unit, "PROPERTY", "PROCESSING_LEVEL_ID", &ihelp, 
            "PROPERTY", "FILE", "");
   if ((status != 1) || (ihelp !=2)) return (-605);
   status = zlget(unit, "PROPERTY", "SAMPLE_FIRST_PIXEL", &dlrframe_info->spacecraft_id, 
            "PROPERTY", "VEX_INSTRUMENT", "");
   if (status != 1) return (-606);
   status = zlget(unit, "PROPERTY", "LINE_FIRST_PIXEL", &dlrframe_info->ck_id, 
            "PROPERTY", "VEX_INSTRUMENT", "");
   if (status != 1) return (-607);
   return 1;
   }  /* end of VEX VMC */

return (-99);

}

int code2name(dlrframe_info *dlrframe_info)
/* fill the strings if necessary */
{
SpiceBoolean found;
bodc2n_c(dlrframe_info->target_id, 80, dlrframe_info->target_name, &found);
if (!found) return -1;
bodc2n_c(dlrframe_info->spacecraft_id, 80, 
         dlrframe_info->spacecraft_name, &found);
if (!found) return -1;
bodc2n_c(dlrframe_info->instrument_id, 80, 
         dlrframe_info->instrument_name, &found);

return 1;
}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create dlrframe_info.imake
/* Imake file for VICAR subroutine  dlrframe_info*/

#define SUBROUTINE   dlrframe_info

#define MODULE_LIST  dlrframe_info.c

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE

$ Return
$!#############################################################################
$Test_File:
$ create tstdlrframe_info.c
#include "vicmain_c"

#include "dlrframe.h"

void my_abort(char abort_message[80]);

void main44()

{
int unit;
int status;

dlrframe_info dlrframe_info;

status = zvunit (&unit, "INP", 1, "");
status = zvopen(unit, "COND", "BINARY", "");
if (status != 1)  my_abort("error open input file"); 

status = dlrframe_getinfo(unit,&dlrframe_info);

printf("status %d\n", status);
if (status == 1)
{
zvmessage("system label","");
printf("ns %d nl %d nb %d nbb %d nlb %d\n",
dlrframe_info.nl,dlrframe_info.ns,dlrframe_info.nb,dlrframe_info.nbb,
dlrframe_info.nlb);
zvmessage("other items","");
printf("%d %d %d %d %s\n",       dlrframe_info.spacecraft_id,
                                 dlrframe_info.instrument_id,
                                 dlrframe_info.target_id,
                                 dlrframe_info.adju_id,
                                 dlrframe_info.utc);
}


}


void my_abort(abort_message)

char abort_message[80];
{
   zvmessage("","");
   zvmessage("     ******* TSTDLRFRAME_INFO error *******","");
   zvmessage(abort_message,"");
   zvmessage("","");
   zabend();
}
$!-----------------------------------------------------------------------------
$ create tstdlrframe_info.imake
/* IMAKE file for test program tstdlrframe_info */

#define PROGRAM   tstdlrframe_info  

#define MODULE_LIST  tstdlrframe_info.c

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_P2SUB  /*for find_hist_key */
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create tstdlrframe_info.pdf
Process help=*
PARM INP
END-PROC
.Title
 Test Program for dlrframe_info
.HELP

WRITTEN BY:     Thomas Roatsch, DLR   25-May-1999

.LEVEL1
.VARI INP
Input image
.End

$ Return
$!#############################################################################
