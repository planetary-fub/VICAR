$!****************************************************************************
$!
$! Build proc for MIPL module extori
$! VPACK Version 1.9, Tuesday, February 08, 2005, 13:28:18
$!
$! Execute by entering:		$ @extori
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
$ write sys$output "*** module extori ***"
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
$ write sys$output "Invalid argument given to extori.com file -- ", primary
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
$   if F$SEARCH("extori.imake") .nes. ""
$   then
$      vimake extori
$      purge extori.bld
$   else
$      if F$SEARCH("extori.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake extori
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @extori.bld "STD"
$   else
$      @extori.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create extori.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack extori.com -mixed -
	-s extori.c -
	-i extori.imake -
	-t tstextori.c tstextori.imake tstextori.pdf -
	-o extori.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create extori.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "ibisfile.h"
#include "SpiceUsr.h"
#include "extori.h"
#define     nc    7         /* number of columns */

/***********************************************************************/
int extori_or(char *filename, int *ib_unit, int *nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int   *macro, char *detec, int *first)

{
int   status;
int   inpunit;
char  type[20];
float help;

status = zvunit(&inpunit,"none",1,"U_NAME",filename, "");
status = zvopen(inpunit,"");
if (status != 1) return -1;

status = zlget(inpunit, "PROPERTY", "NR", nr,
            "PROPERTY", "IBIS", "");
if (status != 1) return -2;

status = zlget(inpunit, "PROPERTY", "TYPE", type,
            "PROPERTY", "IBIS", "");
if (strcmp(type,"EXTORI")) return -2;

status = zlget(inpunit, "PROPERTY", "ROT_ANG", ra,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -3;

status = zlget(inpunit, "PROPERTY", "SIGMA_X", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[0] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_Y", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[1] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_Z", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[2] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_XY", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[0] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_XZ", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[1] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_YZ", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[2] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_1", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[3] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_2", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[4] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_3", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
vari[5] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_1_2", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[3] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_1_3", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[4] = help;
status = zlget(inpunit, "PROPERTY", "SIGMA_ANGLE_2_3", &help,
            "PROPERTY", "EXTORI", "");
if (status != 1) return -4;
covari[5] = help;

status = zlget(inpunit, "PROPERTY", "START_TIME", start,
            "PROPERTY", "M94_ORBIT", "");
if (status != 1) return -5;

status = zlget(inpunit, "PROPERTY", "STOP_TIME", stop,
            "PROPERTY", "M94_ORBIT", "");
if (status != 1) return -6;

status = zlget(inpunit,"PROPERTY", "MACROPIXEL_SIZE", macro,
            "PROPERTY", "M94_CAMERAS", "FORMAT","INT", "");               
if (status != 1) return -7;
status = zlget(inpunit,"PROPERTY", "DETECTOR_ID", detec,
            "PROPERTY", "M94_INSTRUMENT", "FORMAT","STRING", "");               
if (status != 1) return -8;
status = zlget(inpunit,"PROPERTY", "SAMPLE_FIRST_PIXEL", first,
            "PROPERTY", "M94_CAMERAS", "FORMAT","INT", "");               
if (status != 1) return -9;

status = zvclose(inpunit,"");

status = IBISFileOpen(inpunit, ib_unit, IMODE_READ,nc,*nr,0,0);
if (status != 1) return -1;

return 1;
}

/***********************************************************************/
int extori_ow(char *filename, int *ib_unit, int nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int  macro, char *detec, int first)

{
int   status;
int   count;
int   lauf;
int   outunit;
char  ib_format[nc][IFMT_SIZE];
char  *fmt_ptr=(char *)0;
int   group[3];

status = zvunit(&outunit,"none",1,"U_NAME",filename, "");
for (lauf=0; lauf <= 6; lauf++)
   {
   strcpy(ib_format[lauf],IFMT_DOUB);
   }
fmt_ptr=(char *)ib_format;

status = IBISFileOpen(outunit, ib_unit,IMODE_WRITE,nc,nr,
         fmt_ptr,IORG_COLUMN);
if (status != 1) return -1;

status = zladd(outunit, "PROPERTY", "ROT_ANG", ra,
            "PROPERTY", "EXTORI", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -3;

status = zladd(outunit, "PROPERTY", "SIGMA_X", &vari[0],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_Y", &vari[1],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_Z", &vari[2],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_XY", &covari[0],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_XZ", &covari[1],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_YZ", &covari[2],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;

status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1", &vari[3],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_2", &vari[4],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_3", &vari[5],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1_2", &covari[3],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1_3", &covari[4],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_2_3", &covari[5],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;

status = zladd(outunit, "PROPERTY", "START_TIME", start,
            "PROPERTY", "M94_ORBIT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -5;
status = zladd(outunit, "PROPERTY", "STOP_TIME", stop,
            "PROPERTY", "M94_ORBIT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -6;
status = zladd(outunit, "PROPERTY", "MACROPIXEL_SIZE", &macro,
            "PROPERTY", "M94_CAMERAS", "FORMAT", "INT",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -8;
status = zladd(outunit, "PROPERTY", "DETECTOR_ID", detec,
            "PROPERTY", "M94_INSTRUMENT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -9;
status = zladd(outunit, "PROPERTY", "SAMPLE_FIRST_PIXEL", &first,
            "PROPERTY", "M94_CAMERAS", "FORMAT", "INT",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -10;


status = IBISFileSet(*ib_unit,IFILE_TYPE,"EXTORI",0);
/* first column, name time, unit seconds */
group[0]=1;
status = IBISGroupNew(*ib_unit,ITYPE_GROUP,"TIME",group,1,0);
status = IBISGroupNew(*ib_unit,ITYPE_UNIT,"seconds",group,1,0);

/* column 2,3,4, names X,Y,Z, unit m */
group[0]=2;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"X",group,1,0);
group[0]=3;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"Y",group,1,0);
group[0]=4;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"Z",group,1,0);
group[0]=2; group[1]=3; group[2]=4;
count = IBISGroupNew(*ib_unit,ITYPE_UNIT,"m",group,3,0);

/* column 5,6,7, names alpha,beta,gamma, unit gon */
group[0]=5;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_1",group,1,0);
group[0]=6;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_2",group,1,0);
group[0]=7;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_3",group,1,0);
group[0]=5; group[1]=6; group[2]=7;
count = IBISGroupNew(*ib_unit,ITYPE_UNIT,"gon",group,3,0);

return 1;
}
/***********************************************************************/

int extori_ow_cplabel(char *filename, int *ib_unit, int nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int  macro, char *detec, int first, char *filename_in)

{
int   status;
int   count;
int   lauf;
int   outunit, inunit;
char  ib_format[nc][IFMT_SIZE];
char  *fmt_ptr=(char *)0;
int   group[3];

status = zvunit(&inunit,"none",2,"U_NAME",filename_in, "");
zvselpiu(inunit);

status = zvunit(&outunit,"none",1,"U_NAME",filename, "");
for (lauf=0; lauf <= 6; lauf++)
   {
   strcpy(ib_format[lauf],IFMT_DOUB);
   }
fmt_ptr=(char *)ib_format;

status = IBISFileOpen(outunit, ib_unit,IMODE_WRITE,nc,nr,
         fmt_ptr,IORG_COLUMN);
zvselpi(0);
if (status != 1) return -1;

status = zladd(outunit, "PROPERTY", "ROT_ANG", ra,
            "PROPERTY", "EXTORI", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -3;

status = zladd(outunit, "PROPERTY", "SIGMA_X", &vari[0],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_Y", &vari[1],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_Z", &vari[2],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_XY", &covari[0],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_XZ", &covari[1],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_YZ", &covari[2],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;

status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1", &vari[3],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_2", &vari[4],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_3", &vari[5],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1_2", &covari[3],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_1_3", &covari[4],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;
status = zladd(outunit, "PROPERTY", "SIGMA_ANGLE_2_3", &covari[5],
            "PROPERTY", "EXTORI", "FORMAT", "REAL",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -4;

status = zladd(outunit, "PROPERTY", "START_TIME", start,
            "PROPERTY", "M94_ORBIT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -5;
status = zladd(outunit, "PROPERTY", "STOP_TIME", stop,
            "PROPERTY", "M94_ORBIT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -6;
status = zladd(outunit, "PROPERTY", "MACROPIXEL_SIZE", &macro,
            "PROPERTY", "M94_CAMERAS", "FORMAT", "INT",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -8;
status = zladd(outunit, "PROPERTY", "DETECTOR_ID", detec,
            "PROPERTY", "M94_INSTRUMENT", "FORMAT", "STRING",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -9;
status = zladd(outunit, "PROPERTY", "SAMPLE_FIRST_PIXEL", &first,
            "PROPERTY", "M94_CAMERAS", "FORMAT", "INT",
            "MODE", "REPLACE", "ELEMENT", 1, "");
if (status != 1) return -10;


status = IBISFileSet(*ib_unit,IFILE_TYPE,"EXTORI",0);
/* first column, name time, unit seconds */
group[0]=1;
status = IBISGroupNew(*ib_unit,ITYPE_GROUP,"TIME",group,1,0);
status = IBISGroupNew(*ib_unit,ITYPE_UNIT,"seconds",group,1,0);

/* column 2,3,4, names X,Y,Z, unit m */
group[0]=2;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"X",group,1,0);
group[0]=3;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"Y",group,1,0);
group[0]=4;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"Z",group,1,0);
group[0]=2; group[1]=3; group[2]=4;
count = IBISGroupNew(*ib_unit,ITYPE_UNIT,"m",group,3,0);

/* column 5,6,7, names alpha,beta,gamma, unit gon */
group[0]=5;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_1",group,1,0);
group[0]=6;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_2",group,1,0);
group[0]=7;
count = IBISGroupNew(*ib_unit,ITYPE_GROUP,"ANGLE_3",group,1,0);
group[0]=5; group[1]=6; group[2]=7;
count = IBISGroupNew(*ib_unit,ITYPE_UNIT,"gon",group,3,0);

return 1;
}
/***********************************************************************/

int extori_re(int ib_unit, int srow, int nrows, double *time, 
              double *x, double *y, double *z, 
              double *a, double *b, double *c)

{
int status;

status = IBISColumnRead(ib_unit, (char*)time, 1, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)x, 2, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)y, 3, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)z, 4, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)a, 5, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)b, 6, srow, nrows);
if (status !=1) return -1;
status = IBISColumnRead(ib_unit, (char*)c, 7, srow, nrows);
if (status !=1) return -1;

return 1;
}
/***********************************************************************/

int extori_wr(int ib_unit, int srow, int nrows, double *time, 
              double *x, double *y, double *z, 
              double *a, double *b, double *c)

{
int status;

status = IBISColumnWrite(ib_unit, time, 1, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, x, 2, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, y, 3, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, z, 4, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, a, 5, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, b, 6, srow, nrows);
if (status !=1) return -1;
status = IBISColumnWrite(ib_unit, c, 7, srow, nrows);
if (status !=1) return -1;

return 1;
}
/***********************************************************************/

int extori_cl(int ib_unit)

{
int status;

status = IBISFileClose(ib_unit, ICLOSE_UDELETE);
if (status !=1) return -1;
return 1;
}


$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create extori.imake
/* Imake file for VICAR subroutines extori_* */

#define SUBROUTINE  extori

#define MODULE_LIST  extori.c

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_P1SUB
#define LIB_CSPICE
$ Return
$!#############################################################################
$Test_File:
$ create tstextori.c
#include "vicmain_c"
#include "extori.h"

void my_abort(char abort_message[80]);

void main44()
{
int         count;
char        filename[80];
int         lauf;
int         nr;
int         status;

int         ib_unit;
char        ra[20];
float       vari[6];
float       covari[6];
char        start[50];
char        stop[50];
int         macro,first;
char        detec[50];
double      angles[3];
double      matrix[3][3];

double      *time;
double      *x, *y, *z;
double      *a, *b, *c;

zvp("IBISFILE", filename, &count);

/* lets write a file with 100 rows */
nr = 100;
time = (double *) malloc(nr*sizeof(double));
x    = (double *)  malloc(nr*sizeof(double));
y    = (double *)  malloc(nr*sizeof(double));
z    = (double *)  malloc(nr*sizeof(double));
a    = (double *)  malloc(nr*sizeof(double));
b    = (double *)  malloc(nr*sizeof(double));
c    = (double *)  malloc(nr*sizeof(double));


/* fill the columns and labels with something */
for (lauf=0; lauf < nr; lauf++)
    {
    time[lauf] = 0.1 * (double) lauf;
    x[lauf]    = 99.0 - (double) lauf;
    y[lauf]    = x[lauf] * x[lauf];
    z[lauf]    = x[lauf] - y[lauf];
    a[lauf]    = z[lauf] * z[lauf];
    b[lauf]    = a[lauf] - 1.0;
    c[lauf]    = a[lauf] + b[lauf];
    }

for (lauf=0; lauf < 6; lauf++)
    {
    vari[lauf]   = (float) lauf;
    covari[lauf] = vari[lauf] * vari[lauf];
    }

strcpy(ra, "POK");
strcpy(start, "1997 Jan 03 12:00:00.12345");
strcpy(stop,  "1997 Jan 03 13:00:01.12345");
macro=8;
first=80;
strcpy(detec,"MEX_HRSC_BLUE");   
/* open the extori file for write */
status=extori_ow(filename, &ib_unit, nr, ra, vari, covari, start, stop,
                  macro, detec, first);
if (status !=1) my_abort ("could not open the IBIS file for write");

/* write nr rows */
status=extori_wr(ib_unit, 1, nr, time, x, y, z, a, b, c);
if (status !=1) my_abort ("could not write into the IBIS file");

/* close the extori file */
status=extori_cl(ib_unit);
if (status !=1) my_abort ("could not close the IBIS file");

/* open the same file for read */
status=extori_or(filename, &ib_unit, &nr, ra, vari, covari, start, stop,
                 &macro, detec, &first);
if (status !=1) my_abort ("could not open the IBIS file for read");

/* read 10 rows */
status=extori_re(ib_unit, 1, 10, time, x, y, z, a, b, c);
if (status !=1) my_abort ("could not read from the IBIS file");

/* close the extori file */
status=extori_cl(ib_unit);
if (status !=1) my_abort ("could not close the IBIS file");

zvmessage("","");

zprnt(7,6,vari,"vari");
zprnt(7,6,covari,"covari");

zprnt(8,10,time,"time");
zprnt(8,10,b,"b");

zvmessage("","");
zvmessage("TSTEXTORI succesfully completed","");
}

void my_abort(abort_message)

char abort_message[80];
{
   zvmessage("","");
   zvmessage("     ******* TSTEXTORI error *******","");
   zvmessage(abort_message,"");
   zvmessage("","");
   zabend();
}

$!-----------------------------------------------------------------------------
$ create tstextori.imake
/* IMAKE file for program TSTEXTORI */

#define PROGRAM tstextori

#define MODULE_LIST tstextori.c

#define MAIN_LANG_C

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_TAE
#define LIB_P1SUB
#define LIB_HWSUB
$!-----------------------------------------------------------------------------
$ create tstextori.pdf
Process help=*
PARM IBISFILE

END-PROC

.Title
  This is the test program for the subroutines extori_read and extori_write.

.Help
PURPOSE:
 to test extori_read and extori_write

 WRITTEN BY Thomas Roatsch, DLR  02-Dec-1996

.Page
.level1
.vari IBISFILE
.End
$ Return
$!#############################################################################
$Other_File:
$ create extori.hlp
Extori.com consists of 8 functions to handle EXTORI-IBIS files.

1. extori_or    opens an IBIS-file of type "EXTORI" for reading
                and returns the history label items (rot_ang,
                variances, covariances )

2. extori_ow    opens an IBIS-file of type "EXTORI" for writing
                and writes history labels : rot_ang, variances, covariances

3. extori_re    returns from an IBIS-file of type "EXTORI" time and navigation
                parameters at a requested row number

4. extori_wr    writes time and navigation parameters to an IBIS-file
                of type "EXTORI"

5. extori_cl    closes an IBIS-file of type "EXTORI"

6. extori_m2a   converts rotation matrix to angles in gon
                
7. extori_g2r   converts angles in gon to angles in rad

8. extori_a2m   converts angles in gon to rotation matrix



These functions are described in detail below:

int extori_or(filename, ib_ib_unit, nr, ra, vari, covari, start, stop)

   input values
   char *filename:       name of the IBIS file to read

   output values:
   int *ib_unit:         IBIS unit number
   int *nr:              number of rows of the IBIS file
   char*ra:              keyword ROT_ANG
   float *vari:          variances
   float *covari:        covariances
   char  *start:         keyword START_TIME
   char  *stop:          keyword STOP_TIME

   status values:
   1            success
   -1           could not open the input IBIS file
   -2           IBIS file is not of type EXTORI
   -3           ROT_ANG is missing
   -4           SIGMA* is missing
   -5           START_TIME missing
   -6           STOP_TIME missing

int extori_ow(filename, ib_unit, nr, ra, vari, covari, start, stop)

   input values
   char *filename:       name of the IBIS file to read
   int nr:               number of rows of the IBIS file
   char *ra:             keyword ROT_ANG
   float *vari:          variances
   float *covari:        covariances
   char  *start:         keyword START_TIME
   char  *stop:          keyword STOP_TIME

   output values
   int *ib_unit:         IBIS unit number

   status values:
   1            success
   -1           could not open the input IBIS file
   -3           could not write ROT_ANG
   -4           could not write SIGMA*
   -5           could not write START_TIME
   -6           could not write STOP_TIME

int extori_re(ib_unit, srow, nrows, time, x, y, z, a, b, c)

   input values
   int ib_unit:          IBIS unit number
   int srow:             start row
   int nrows:            number of rows

   output values
   double *time:         array of time values
   double *x,*y,*z:      arrays of position in m
   double *a,*b,*c:      arrays of angles in gon

   status values:
   1            success
   -1           IBIS read error


int extori_wr(ib_unit, srow, nrows, time, x, y, z, a, b, c)

   input values
   ib_unit:              IBIS unit number
   int srow:             start row
   int nrows:            number of rows
   double *time:         array of time values
   double *x,*y,*z:      arrays of position in m
   double *a,*b,*c:      arrays of angles in gon

   status values:
   1            success
   -1           IBIS write error

void extori_cl(ib_unit)

   input values
   int ib_unit:          IBIS unit number

   status values:
   1            success
   -1           IBIS close error

int extori_m2a(matrix, angles, ra)

   input values
   double *matrix:       rotation matrix from body to photogrammetry system
   char *ra:             keyword ROT_ANG

   output values
   double *angles:        Euler angles in gon (as in the EXTORI file)

   status values:
   1            success
   -1           SPICE error in M2EUL

void extori_g2r(angles_g, angles_r)
     /* should be called directly only by HWSTRIP */

   input values
   double *angles_g:      Euler angles in gon (as in the EXTORI file)

   output values
   double *angles_r:     Euler angles in rad

int extori_a2m(angels, matrix, ra)

   input values
   double *angles:       Euler angles in gon (as in the EXTORI file)
   char  *ra:            keyword ROT_ANG

   output values
   double *matrix:       rotation matrix from body to photogrammetry system

   status values:
   1            success
   -1           SPICE error in EUL2M
   -2           unsupported ROT_ANG
============================================================================
vari and covari are defined as:

vari[0] = SIGMA_X
vari[1] = SIGMA_Y
vari[2] = SIGMA_Z
vari[3] = SIGMA_ANGLE_1
vari[4] = SIGMA_ANGLE_2
vari[5] = SIGMA_ANGLE_3

covari[0] = SIGMA_XY
covari[1] = SIGMA_XZ
covari[2] = SIGMA_YZ
covari[3] = SIGMA_ANGLE_1_2
covari[4] = SIGMA_ANGLE_1_3
covari[5] = SIGMA_ANGLE_2_3
$ Return
$!#############################################################################
