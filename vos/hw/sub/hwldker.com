$!****************************************************************************
$!
$! Build proc for MIPL module hwldker
$! VPACK Version 1.9, Monday, December 06, 2004, 14:04:36
$!
$! Execute by entering:		$ @hwldker
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
$ write sys$output "*** module hwldker ***"
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
$ write sys$output "Invalid argument given to hwldker.com file -- ", primary
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
$   if F$SEARCH("hwldker.imake") .nes. ""
$   then
$      vimake hwldker
$      purge hwldker.bld
$   else
$      if F$SEARCH("hwldker.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hwldker
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hwldker.bld "STD"
$   else
$      @hwldker.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hwldker.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hwldker.com -mixed -
	-s hwldker.c -
	-i hwldker.imake -
	-t tsthwldker.c tsthwldker.imake tsthwldker.pdf -
	-o hwldker.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hwldker.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*
     Written by Thomas Roatsch, DLR     9-Jun-1993
     Revised by Thomas Roatsch, DLR     2-Sep-1993
     Revised by Natascha Russ,  DLR     16-Dec-1993 
	(variable paramter list included)
     Revised by Thomas Roatsch, DLR     21-Jun-1994   
        (deprecated function zvsptr removed)
     Revised by Thomas Roatsch, DLR     7-Mar-1995   
        (bpc added)
     Revised by Rainer Berlin, DLR      1-Dec-1996
        (storage of kernel file handle inserted)
     Revised by Thomas Roatsch, DLR     13-Oct-1998
        (uses CSPICE)
     Revised  by Thomas Roatsch, DLR    5-Sep-2000
         (changed to stdarg.h and now uses furnsh_c)
*/

#include <stdio.h>
#include <string.h>
#include <stdarg.h>      
#include "stdlib.h"
#include "hwldker.h"


/*
Function hwldker (loads all necessary kernels and 
                  returns all filenames without path) 

valid keywords are:
      bsp     --> loads S/P kernel
      sunker  --> loads sun kernel
      bc      --> loads C kernel
      tls     --> loads leapsecond kernel
      ti      --> loads instrument kernel
      tpc     --> loads ASCII planetary constants kernel
      bpc     --> loads binary planetary constants kernel
      tsc     --> loads spacecraft clock kernel

*/

#define RETURN(status) \
   { \
   va_end(ap); \
   return(status); \
   }

int hwldker(int nargs, ...)

{

hwkernel_1 *ker1;
hwkernel_3 *ker3;
hwkernel_6 *ker6;
int        ptr[6];
int        lauf;
int        count;
int        def;
FILE       *fptr;
char       *value;
int        status; 
int        ptr_no = 0;
char       *array;
va_list ap;

/* SPICE error handling */
zhwerrini();

/* copied from stdarg man page example */
va_start(ap,nargs);

for (ptr_no=0; ptr_no < nargs; ptr_no++)
   {
   array = va_arg(ap, char*);
   if(!strcmp(array,"bsp"))	
      { /*bsp*/  
      ker3=va_arg(ap, hwkernel_3 *); 
      status = zvparm("bspfile",ker3->filename,&ker3->count,&def,3,
                      MAX_KERNEL_NAME_LENGTH+1);
      if (status != 1) RETURN(-11); 
      if (ker3->count < 1) RETURN(-12);
      for (lauf = 0; lauf < ker3->count; lauf++)
         {
         value=getenv(ker3->filename[lauf]);
         if (value != NULL) strcpy((ker3->filename[lauf]),value); 
         fptr=fopen((ker3->filename[lauf]),"r");
         if (fptr <= (FILE *)NULL) RETURN(-13);                
         fclose(fptr);
         furnsh_c(ker3->filename[lauf]);
         if (failed_c() ) RETURN(-14);
         hwnopath(ker3->filename[lauf]);
         }
      } /*end bsp */

   if(!strcmp(array,"sunker"))
      { /*sun*/
      ker1=va_arg(ap,  hwkernel_1 *);
      status = zvp("sunfile",ker1->filename,&ker1->count);
      if (status != 1) RETURN(-21);
      if (ker1->count != 1) RETURN(-22);
      value=getenv( ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-23);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-24);
      hwnopath(ker1->filename);
      } /* end of sun */
      
   if(!strcmp(array,"bc"))
      { /* bc */
      ker6=va_arg(ap, hwkernel_6 *); 
      status = zvparm("bcfile",ker6->filename,&ker6->count,&def,6,
                      MAX_KERNEL_NAME_LENGTH+1);
      if (status !=1 ) RETURN(-41);
      if (ker6->count < 1) RETURN(-42);
      for (lauf = 0; lauf < ker6->count; lauf++)
         {
         value=getenv(ker6->filename[lauf]);
         if (value != NULL) strcpy((ker6->filename[lauf]),value); 
         fptr=fopen((ker6->filename[lauf]),"r");
         if (fptr <= (FILE *)NULL) RETURN(-43);                
         fclose(fptr);
         furnsh_c(ker6->filename[lauf]);
         if (failed_c() ) RETURN(-44);
         hwnopath(ker6->filename[lauf]);
         }	
      } /* end of bc */

   if(!strcmp(array,"tsc"))
      { /* tsc */
      ker6=va_arg(ap,  hwkernel_6 *);
      status = zvparm("tscfile",ker6->filename,&ker6->count,&def,6,
                      MAX_KERNEL_NAME_LENGTH+1);
      if (status != 1) RETURN(-51);
      if (ker6->count < 1) RETURN(-52);
      for (lauf = 0; lauf < ker6->count; lauf++)
         {
         value=getenv(ker6->filename[lauf]);
         if (value != NULL) strcpy(ker6->filename[lauf],value); 
         fptr=fopen(ker6->filename[lauf],"r");
         if (fptr <=(FILE *) NULL) RETURN(-53);
         fclose(fptr);
         furnsh_c(ker6->filename[lauf]);
         if (failed_c() ) RETURN(-54);
         hwnopath((ker6->filename[lauf]));
         }
      } /* end of tsc */

   if(!strcmp(array,"tpc"))
      { /* tpc*/
      ker1=va_arg(ap, hwkernel_1 *);
      status = zvp("tpcfile",ker1->filename, &ker1->count);
      if (status != 1) RETURN(-61);
      if (ker1->count != 1) RETURN(-62);
      value=getenv(ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-63);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-64);
      hwnopath(ker1->filename);
      } /* end of tpc */

   if(!(strcmp(array,"bpc")))
      { /* bpc*/
      ker1=va_arg(ap, hwkernel_1 *);
      status = zvp("bpcfile",ker1->filename, &ker1->count);
      if (status != 1) RETURN(-71);
      if (ker1->count != 1) RETURN(-72);
      value=getenv(ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-73);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-74);
      hwnopath(ker1->filename);
      } /* end of bpc */

   if(!strcmp(array,"tls"))
      { /* tls */
      ker1=va_arg(ap, hwkernel_1*);
      status = zvp("tlsfile",ker1->filename, &ker1->count);
      if (status != 1) RETURN(-81);
      if (ker1->count != 1) RETURN(-82);
      value=getenv(ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-83);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-84);
      hwnopath(ker1->filename);
      }	/* end of tls */
      
   if(!strcmp(array,"ti"))
      { /*ti */
      ker1=va_arg(ap, hwkernel_1 *);
      status = zvp("tifile", ker1->filename,&ker1->count);
      if (status != 1) RETURN(-91);
      if (ker1->count != 1) RETURN(-92);
      value=getenv(ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-93);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-94);
      hwnopath(ker1->filename);
      }	/* end of ti */

   if(!strcmp(array,"tf"))
      { /*tf */
      ker1=va_arg(ap, hwkernel_1 *);
      status = zvp("tffile", ker1->filename,&ker1->count);
      if (status != 1) RETURN(-101);
      if (ker1->count != 1) RETURN(-102);
      value=getenv(ker1->filename);
      if (value != NULL) strcpy(ker1->filename,value);
      fptr=fopen(ker1->filename,"r");
      if (fptr <=(FILE *) NULL) RETURN(-1033);
      fclose(fptr);
      furnsh_c(ker1->filename);
      if (failed_c() ) RETURN(-104);
      hwnopath(ker1->filename);
      }	/* end of tf */

   } /* end of loop */
     
va_end(ap);

return (1);

}
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hwldker.imake
/* Imake file for HWLDKER */

#define SUBROUTINE   hwldker

#define MODULE_LIST hwldker.c

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE


$ Return
$!#############################################################################
$Test_File:
$ create tsthwldker.c
#include <string.h>
#include <stdio.h>
#include "vicmain_c"
#include "hwldker.h"


/* Testprogramm for Function HWLDKER.C   */
            
void main44()

{

   int    lauf,status;
   hwkernel_3 bsp;
   hwkernel_6 bc;
   hwkernel_6 tsc;
   hwkernel_1 tpc;
   hwkernel_1 bpc;
   hwkernel_1 ti;
   hwkernel_1 sunker;
   hwkernel_1 tls;
   char       message[HWLDKER_ERROR_LENGTH];
   int        nargs;

/* load all kernels */
   zvmessage("","");
   zvmessage("load some kernels","");
   zvmessage("","");
 
   bsp.count=0;
   bc.count=0;
   tsc.count=0;
   tpc.count=0;
   bpc.count=0;
   ti.count=0;
   sunker.count=0;
   tls.count=0;
   
   status = hwldker(7, "bsp", &bsp,
           "sunker", &sunker,
           "bc", &bc,
           "tpc", &tpc,
           "ti", &ti,
           "tls", &tls,
           "tsc", &tsc);

   if (status != 1)
      {
      zvmessage ("problem in hwldker", "");
      printf("hwldker-status: %d\n",status);
      hwldker_error(status, message);
      zvmessage(message,"");
      zabend();
      }
      
   for (lauf=0; lauf < bsp.count; lauf++) zvmessage(bsp.filename[lauf], "");
   if (sunker.count != 0) zvmessage(sunker.filename,"");
   for (lauf=0; lauf < bc.count; lauf++) zvmessage(bc.filename[lauf], "");
   for (lauf=0; lauf < tsc.count; lauf++) zvmessage(tsc.filename[lauf], "");
   if (tpc.count != 0) zvmessage(tpc.filename, "");
   if (bpc.count != 0) zvmessage(bpc.filename, "");
   if (tls.count != 0) zvmessage(tls.filename, "");
   if (ti.count != 0) zvmessage(ti.filename, "");

   zvmessage("","");
   zvmessage("TSTHWLDKER succesfully completed", "");

}
$!-----------------------------------------------------------------------------
$ create tsthwldker.imake
/* Imake file for TSTHWLDKER */

#define PROGRAM tsthwldker

#define MODULE_LIST tsthwldker.c 

#define MAIN_LANG_C

#define TEST

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_CSPICE
$!-----------------------------------------------------------------------------
$ create tsthwldker.pdf
Process help=*
 PARM      BSPFILE  TYPE=(STRING,120) COUNT=(0:3)     DEFAULT=HWSPICE_BSP
 PARM      SUNFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=SUNKER
 PARM      BCFILE   TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=HWSPICE_BC
 PARM      TSCFILE  TYPE=(STRING,120) COUNT=(0:6)     DEFAULT=HWSPICE_TSC
 PARM      TPCFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=HWSPICE_TPC
 PARM      BPCFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=--
 PARM      TLSFILE  TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=HWSPICE_TLS
 PARM      TIFILE   TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=HWSPICE_TI
 PARM      TFFILE   TYPE=(STRING,120) COUNT=(0:1)     DEFAULT=--
END-PROC
.Title
 Testprogramm fuer HWLDKER
.HELP

WRITTEN BY: Thomas Roatsch, DLR     9-Jun-1993
REVISED BY: Thomas Roatsch, DLR     2-Sep-1993
            Natascha Russ,  DLR     16-Dec-1993 (variable paramter list 
					        included)
            Thomas Roatsch, DLR     7-Mar-1995  (bpc added)

.LEVEL1
.VARI BSPFILE
 Binary SP-Kernel 
.VARI SUNFILE
 Binary SUN-Kernel 
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
.VARI TFFILE
 Text Frame Kernel
.End
$ Return
$!#############################################################################
$Other_File:
$ create hwldker.hlp
General subroutine to lad different SPICE kernels:

      bsp     --> loads S/P kernel
      sunker  --> loads sun kernel
      pho_dei --> loads Phobos-Deimos kernel
      bc      --> loads C kernel
      tls     --> loads leapsecond kernel
      ti      --> loads instrument kernel
      tpc     --> loads ASCII planetary constants kernel
      tsc     --> loads spacecraft clock kernel
      bpc     --> loads binary planetary constants kernel

Last revision: 2-Jun-1999
Cognizitant programer: Th. Roatsch, DLR 


return values:

1:      success

-11:    could not get  bspfile from PDF
-12:    no bspfilename given
-13:    could not open bspfile
-14;    could not load bspfile

-21:    could not get  sunfile from PDF
-22:    no sunfilename given
-23:    could not open sunfile
-24;    could not load sunfile

-31:    could not get  pho_deifile from PDF
-32:    no pho_deifilename given
-33:    could not open pho_deifile
-34;    could not load pho_deifile

-41:    could not get  bcfile from PDF
-42:    no bcfilename given
-43:    could not open bcfile
-44;    could not load bcfile

-51:    could not get  tscfile from PDF
-52:    no tscfilename given
-53:    could not open tscfile
-54;    could not load tscfile

-61:    could not get  tpcfile from PDF
-62:    no tpcfilename given
-63:    could not open tpcfile
-64;    could not load tpcfile

-71:    could not get  bpcfile from PDF
-72:    no bpcfilename given
-73:    could not open bpcfile
-74;    could not load bpcfile

-81:    could not get  tlsfile from PDF
-82:    no tlsfilename given
-83:    could not open tlsfile
-84;    could not load tlsfile

-91:    could not get  tifile from PDF
-92:    no tifilename given
-93:    could not open tifile
-94;    could not load tifile

$ Return
$!#############################################################################
