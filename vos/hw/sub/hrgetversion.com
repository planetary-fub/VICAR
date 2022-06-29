$!****************************************************************************
$!
$! Build proc for MIPL module hrgetversion
$! VPACK Version 1.9, Tuesday, August 27, 2002, 10:47:41
$!
$! Execute by entering:		$ @hrgetversion
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
$ write sys$output "*** module hrgetversion ***"
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
$ write sys$output "Invalid argument given to hrgetversion.com file -- ", primary
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
$   if F$SEARCH("hrgetversion.imake") .nes. ""
$   then
$      vimake hrgetversion
$      purge hrgetversion.bld
$   else
$      if F$SEARCH("hrgetversion.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrgetversion
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrgetversion.bld "STD"
$   else
$      @hrgetversion.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrgetversion.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrgetversion.com -
	-s hrgetversion.c -
	-i hrgetversion.imake -
	-t tsthrgetversion.c tsthrgetversion.imake tsthrgetversion.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrgetversion.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include <stdio.h>
#include <string.h>
#include "hrgetversion.h"

/* status values 

1:   o.k.
-1:  typ is neither rad or geo 
-2:  user specified version has strlen > 2
-4:  wrong ins_id 
-5:  can not open version file 
-7:  no calibration files available */

int hrgetversion(/* Input */
                 char *typ,      /* rad or geo */
                 char *start,    /* image start time */
                 char *ins_id,   /* Instrument ID for airborne (FL2, FL_001
                                    Dtector ID for MEX */
                 
                 /* Output */
                 char *version   /*version */
                 )

{
int         count,lauf;
char        *cp, *lp;
char        versionfile[512], cdummy[512], utc_i[50], line[256];
char        type[10];
char        *getenv();
FILE        *vfp;

/* Use user defined Version? */

strcpy(type,typ);
for (lauf=0; lauf <strlen(type); lauf++) 
   type[lauf] = tolower(type[lauf]);

if (!strcmp(type,"rad"))
   zvp("RADCAL_VERSION", cdummy, &count);
else
   if (!strcmp(type,"geo"))
      zvp("GEOCAL_VERSION", cdummy, &count);
   else
      return -1;

if (count > 0) 
   {
   cp=getenv(cdummy);
   if (cp != NULL) strcpy(cdummy,cp);
   if (strlen(cdummy) > 2) 
       return -2;
   if (strlen(cdummy) == 1) 
      {
      strcpy(version,"0");
      strcat(version,cdummy);
      }
   else strcpy(version,cdummy);
   return 1;
   }

/* Get the version from the Version file */

zvp("VERSION_FILE",cdummy,&count);
if (count > 0) 
    {
    cp=getenv(cdummy);
    if (cp != NULL) strcpy(versionfile,cp);
    else            strcpy(versionfile,cdummy);
    }
else 
   { /* build the standard versionfile name */
   if (!strncmp(ins_id,"FL2",3))
       strcpy(cdummy,"f2");
   else
      if (!strncmp(ins_id,"FL_",3))
         {
         cdummy[0] = 'a';
         cdummy[1] = ins_id[3];
         cdummy[2] = ins_id[4];
         cdummy[3] = ins_id[5];
         cdummy[4] = '\0';
         }
      else
         if (!strncmp(ins_id,"MEX_HRSC_SRC",12))
            strcpy(cdummy,"mex_src");
         else
            if (!strncmp(ins_id,"MEX_HRSC",8))
               strcpy(cdummy,"mex_hrsc");
            else
               return -4;
   if (!strcmp(type,"rad"))
      {
      cp=getenv("HRSC_RADCAL_DIR");
      if (cp != NULL) 
         {
         strcpy(versionfile,cp);
         strcat(versionfile,"/");
         strcat(versionfile,cdummy);
         }
      else
         strcpy(versionfile,cdummy);   
      strcat(versionfile,"_radcal.version");
      }
   else
      {
      cp=getenv("M94GEOCAL");
      if (cp != NULL) 
         {
         strcpy(versionfile,cp);
         strcat(versionfile,"/");
         strcat(versionfile,cdummy);
         }
      else
         strcpy(versionfile,cdummy);   
      strcat(versionfile,"_geocal.version");
      }
   } /* end of versionfilename */
                         
if ((vfp=(FILE *)fopen(versionfile,"r")) == NULL) return -5;

strcpy(version,"00");

while (lp=(char *)fgets(line,255,vfp)) 
   {
   if (strlen(line) < 2) continue;
   if (line[0] == '#') continue;

   strncpy(utc_i, &line[3],11);
   utc_i[11]='\0';
   if (strcmp(utc_i,start) > 0) break;

   version[0]=line[0];
   version[1]=line[1];
   }

fclose(vfp);

if (!strcmp(version,"00")) return -7;
else return 1;

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrgetversion.imake
#define SUBROUTINE   hrgetversion

#define MODULE_LIST hrgetversion.c

#define USES_ANSI_C

#define HW_SUBLIB

$ Return
$!#############################################################################
$Test_File:
$ create tsthrgetversion.c
#include <stdio.h>
#include "vicmain_c"

#include "hrgetversion.h"

/* Testprogramm for Function hrgetversion   */
            
void main44()

{
int        status,count;
char       utc[100],typ[10],ins_id[50],version[10];

zvp("UTC",utc,&count);
zvp("TYP", typ, &count);
zvp("INS_ID", ins_id,&count);

status = hrgetversion(typ,utc,ins_id,version);
if (status != 1)
   {
   printf("error in hrgetversion %d\n", status);
   zabend();
   }

printf("Version         %s\n",  version);

zvmessage("","");
zvmessage("TSThrgetversion succesfully completed", "");

}
$!-----------------------------------------------------------------------------
$ create tsthrgetversion.imake
#define PROGRAM tsthrgetversion

#define MODULE_LIST tsthrgetversion.c 

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create tsthrgetversion.pdf
Process help=*
 PARM      INS_ID   TYPE=(STRING,120) 
 PARM      UTC                                        DEFAULT=2004-06-1
 PARM      TYP     VALID=(RAD,GEO)                    DEFAULT=GEO         
 PARM      RADCAL_VERSION             COUNT=(0:1)     DEFAULT=--
 PARM      GEOCAL_VERSION             COUNT=(0:1)     DEFAULT=--
 PARM      VERSION_FILE               COUNT=(0:1)     DEFAULT=--
END-PROC
.Title
 Testprogramm for hrgetversion
.HELP

WRITTEN BY: Thomas Roatsch, DLR     19-Dec-2001

.End
$ Return
$!#############################################################################
