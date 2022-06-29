$!****************************************************************************
$!
$! Build proc for MIPL module flcform_lut
$! VPACK Version 1.9, Wednesday, October 26, 2005, 15:49:07
$!
$! Execute by entering:		$ @flcform_lut
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
$ write sys$output "*** module flcform_lut ***"
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
$ write sys$output "Invalid argument given to flcform_lut.com file -- ", primary
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
$   if F$SEARCH("flcform_lut.imake") .nes. ""
$   then
$      vimake flcform_lut
$      purge flcform_lut.bld
$   else
$      if F$SEARCH("flcform_lut.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake flcform_lut
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @flcform_lut.bld "STD"
$   else
$      @flcform_lut.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create flcform_lut.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack flcform_lut.com -mixed -
	-s flcform_lut.c -
	-i flcform_lut.imake -
	-p flcform_lut.pdf
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create flcform_lut.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "vicmain_c"

#include "hrpref.h"

#define ERROR        -1
#define HRSC          1
#define STRING_LEN    200
void my_abort(char abort_message[80]);

void main44()
{
char        *byte_ptr;
int         count;
float       expo_1;
char        filename[120];
char        format[10];
short       *half_ptr;
char        histtask[100];
int         inunit;
int         nbb;
int         nl, ns;
int         lauf, i;
int         lauf_nl, lauf_ns;
int         numtask;
int         outunit;
hrpref_typ  PrefH;
int         status;
char        task[100];
char        lutnam[120];
FILE       *fp_lut;
int         luttab[8192];
int         gw, dum;
char       *st, string[STRING_LEN];

status = zvunit (&inunit, "INP", 1, "");
status = zvopen (inunit, "COND", "BINARY", "");
if (status != 1)  my_abort("error open input file"); 

status = zvget(inunit, "NL", &nl, "NS", &ns, "NBB", &nbb,
               "FORMAT", format, "");

if (status != 1) my_abort("error reading input system label"); 
 
if(strcmp(format, "HALF"))  my_abort("input images must be HALF format"); 

byte_ptr = (char *) malloc(ns*sizeof(char));
if(byte_ptr==NULL) my_abort ("Sorry, memory problems !!"); 

half_ptr=(short *)malloc(ns*sizeof(short));
if(half_ptr==NULL) my_abort ("Sorry, memory problems !!"); 

status = zvunit (&outunit, "OUT", 1, "");
status = zvopen (outunit, "COND",     "BINARY", 
                          "OP",       "WRITE", 
			  "U_NBB",     nbb,
                          "U_FORMAT", "BYTE", 
			  "O_FORMAT", "BYTE", "");
if (status != 1) my_abort ("error open output file"); 


zvp("LUT", lutnam, &count);
if (count != 1)  my_abort ("Sorry, pdf reading problems !!");

fp_lut = fopen (lutnam, "r");
if (fp_lut == (FILE *)NULL) 
    my_abort ("Can't open the file of the look-up-table !!");

/* -------------------------------------- read the LUT-file header */
while (1) {

   st = fgets (string, STRING_LEN, fp_lut);
   if (st == (char *) NULL) my_abort ("Error while reading the LUT-file !!");
   
   if (!strncmp("****", string, 4)) break;
   }

for (lauf = 0; lauf < 8192; lauf++) {

    status = fscanf (fp_lut, "%d %d", &dum, luttab + lauf);
    if (status != 2)
    	{
		if (lauf < 4096) my_abort ("Problems reading look-up-table values for 0-4095 !!");
		else
			{
			for (i = lauf; i < 8192; i++) luttab[i] = luttab[i-1];
			break;
			}
		}
       
    if (luttab[lauf] < 0)    luttab[lauf] = 0;
    if (luttab[lauf] > 255)  luttab[lauf] = 255;
    }

   status = zlget(outunit, "PROPERTY", "FILE_NAME", filename,
                           "PROPERTY", "FILE", "");
   if (status == 1) zldel(outunit, "PROPERTY", "FILE_NAME",
                                   "PROPERTY", "FILE", "");
   zvp("OUT", filename, &count); /* we need the filename for update */
   hwnopath(filename);
   for (lauf =0; lauf < strlen(filename); lauf++) {
        filename[lauf] = toupper(filename[lauf]);
        }
   status = zladd(outunit, "PROPERTY", "FILE_NAME", filename,
                           "PROPERTY", "FILE", "FORMAT", "STRING", "");

   /* remove the DN entries from the history label,  not necessary for AX */
   status = zldel(outunit, "HISTORY", "DNMAX",  "HIST", "HWSYSTE", "");
   status = zldel(outunit, "HISTORY", "DNMIN",  "HIST", "HWSYSTE", "");
   status = zldel(outunit, "HISTORY", "DNMEAN", "HIST", "HWSYSTE", "");
   status = zldel(outunit, "HISTORY", "DNSD",   "HIST", "HWSYSTE", "");


   for (lauf_nl = 1; lauf_nl <= nl; lauf_nl++)
       {
       if (nbb)
          {
          hrrdpref(inunit, lauf_nl, &PrefH);
          zvread(inunit, half_ptr, "Line",   lauf_nl,
  	                           "SAMP",  (nbb+1),
  	                           "NSAMPS", ns, "");
          }
       else
          zvread(inunit, half_ptr, "Line",   lauf_nl,
  	                           "SAMP",  1,
  	                           "NSAMPS", ns, "");
     for (lauf_ns = 0; lauf_ns < ns; lauf_ns++)
  	 {
	  /* cast does not round */
  	 gw = (int) half_ptr[lauf_ns];
	 if (gw < 0) gw = 0;
	 if (gw > 8191) gw = 8191;
  	 byte_ptr[lauf_ns] = (unsigned char) luttab[gw];
  	 }
       if (nbb == HRPREF_LEN)
          {
          hrwrpref(outunit, lauf_nl, &PrefH);
          zvwrit(outunit, byte_ptr, "Line", lauf_nl,
  		          "SAMP", (HRPREF_LEN+1),
  		          "NSAMPS", ns, "");
          }
       else
          zvwrit(outunit, byte_ptr, "Line", lauf_nl,
  		          "SAMP", 1,
  		          "NSAMPS", ns, "");
     }
   status = find_hist_key(outunit, "RADIANCE_SCALING_FACTOR",
                                    1, histtask, &numtask);
   if (status != 1) {
      zvmessage("","");
      zvmessage("flcform_lut warning", "");
      zvmessage("can not update RADIANCE_SCALING_FACTOR", "");
      }
   else
      {
    /* ###########
      status = zlget(outunit, "HISTORY", "RADIANCE_SCALING_FACTOR", &rad, 
                              "HIST", "histtask", "");
      status = zldel(outunit, "HISTORY", "RADIANCE_SCALING_FACTOR",
   	                     "HIST", histtask, "");
      rad = rad / help;
      status = zladd(outunit, "HISTORY", "RADIANCE_SCALING_FACTOR", &rad, "");
      fdnmin = (float) dnmin;
      status = zladd(outunit, "HISTORY", "RADIANCE_SCALING_OFFSET", &fdnmin, "");
      
      ############# */
      
      }

}


void my_abort(abort_message)

char abort_message[80];
{
   zvmessage("","");
   zvmessage("     ******* flcform_lut error *******","");
   zvmessage(abort_message,"");
   zvmessage("","");
   zabend();
}

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create flcform_lut.imake

#define PROGRAM flcform_lut

#define MODULE_LIST flcform_lut.c

#define MAIN_LANG_C

#define HW_SUBLIB

#define USES_ANSI_C

#define LIB_RTL
#define LIB_TAE
#define LIB_HWSUB
#define LIB_P1SUB 
$ Return
$!#############################################################################
$PDF_File:
$ create flcform_lut.pdf
process help=*
  PARM INP  TYPE=(STRING,120) COUNT=1
  PARM OUT  TYPE=(STRING,120) COUNT=1
  PARM LUT  TYPE=(STRING,120) COUNT=1
END-PROC
.help
flcform_lut:  The program converts 'half' data     
          level 2 image files 
          into 'byte' format

.level1
.vari inp
Name of a single input file.
.vari out
Name of an output file
.vari lut 
Name of the look-up-table
(generated by program: FL12TO8_LUT)
.end
$ Return
$!#############################################################################
