$!****************************************************************************
$!
$! Build proc for MIPL module hrwrpref
$! VPACK Version 1.9, Tuesday, March 15, 2005, 17:09:26
$!
$! Execute by entering:		$ @hrwrpref
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
$ write sys$output "*** module hrwrpref ***"
$!
$ Create_Source = ""
$ Create_Repack =""
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
$ if primary .eqs. "IMAKE" then Create_Imake = "Y"
$ if (f$locate("CLEAN", primary) .eqs. 0) then Do_Make = "Y"
$!
$ if (Create_Source .or. Create_Repack .or. Create_Imake .or. Do_Make) -
        then goto Parameter_Okay
$ write sys$output "Invalid argument given to hrwrpref.com file -- ", primary
$ write sys$output "For a list of valid arguments, please see the header of"
$ write sys$output "of this .com file."
$ exit
$!
$Parameter_Okay:
$ if Create_Repack then gosub Repack_File
$ if Create_Source then gosub Source_File
$ if Create_Imake then gosub Imake_File
$ if Do_Make then gosub Run_Make_File
$ exit
$!
$ Set_Unpack_Options:
$   Create_Repack = "Y"
$   Create_Source = "Y"
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
$   if F$SEARCH("hrwrpref.imake") .nes. ""
$   then
$      vimake hrwrpref
$      purge hrwrpref.bld
$   else
$      if F$SEARCH("hrwrpref.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrwrpref
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrwrpref.bld "STD"
$   else
$      @hrwrpref.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrwrpref.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrwrpref.com -mixed -
	-s hrwrpref.c -
	-i hrwrpref.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrwrpref.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*				HRWRPREF.C
 *****************************************************************************
 *
 * Mars-94/96
 * Jet Propulsion Laboratoy
 * Pasadena, California  USA
 *
 * This subroutine write the VICAR binary prefix for HRSC products.  The
 * structure of the prefix is defined in "hrpref.h".  It is the responsiblity
 * of the calling program to open the desired VICAR file and check the
 * organization of that file such as openning the file with visible binary
 * header and labels.
 *
 * For an example, please study the enclosed test program.
 *
 *
 * Date		Who		Description
 * ---------	---------------	----------------------------------------------
 * 15-Mar-05    KDM             Added keyword BAND in call of zvwrit
 * 28-Dec-94	Payam Zamani	Seperated packing into hrprefpack
 * 22-Jun-94	Payam Zamani	Added FORTRAN bridge routine xhrwrpref
 * 10-May-94	P. Zamani	Added support for new field FillerFlag
 *  4-Mar-94	P. Zamani	Support for new fields in the binary prefix
 * 30-Sep-93	Payam Zamani	Initial delivery
 *****************************************************************************
 */

#include	<stdio.h>
#include	"hrpref.h"
#include 	"xvmaininc.h"

#define	MODULE_NAME		"HRWRPREF"	/* Name of this soubroutine*/
#define	ZV_LEN			12		/* size of conversion space*/

/*
 *----------------------------------------------------------------------------
 * 	MACROS TO REDUCE TYPING DURRING TYPE CONVERSION
 *----------------------------------------------------------------------------
 */
#define TX_BYTE( from) zvtrans( BConv, (from), BPtr, 1); BPtr += BSize;
#define TX_DOUB( from) zvtrans( DConv, (from), BPtr, 1); BPtr += DSize;
#define TX_FULL( from) zvtrans( FConv, (from), BPtr, 1); BPtr += FSize;
#define TX_HALF( from) zvtrans( HConv, (from), BPtr, 1); BPtr += HSize;
#define TX_REAL( from) zvtrans( RConv, (from), BPtr, 1); BPtr += RSize;

void	hrprefpack( hrpref_typ *, int, unsigned char []);
/*
 *=============================================================================
 *	Write the binary prefix for a specified line
 *=============================================================================
 */
void	hrwrpref(  
        int		OutUnit,
        int		Line,  
        hrpref_typ	*Prefix)
{
	char		BLType[16];			/* B. Label type    */
	int		nbb;			/* length of binary prefix  */
	int		nlb;			/* number of lines, bin hdr */
	unsigned char	PkdPrfx[HRPREF_LEN];		/* packed B. prefix */
        int             status;

   /*
    *------------------------------------------------------------
    * Get some basic information about the file to be processed
    *------------------------------------------------------------
    */    
    zvget( OutUnit,	"NBB", &nbb,			/* legnth of prefix */
			"NLB", &nlb,
			"BLTYPE", BLType,		/* Binary label type*/
			0);
    if (strncmp( BLType, BL_TYPE, strlen(BL_TYPE)) != 0) {
	zvmessage( "Unsupported binary prefix type", MODULE_NAME);
	zabend();
    }
    if (nbb == 0) {					/* no prefix	    */
	zvmessage( "Binary prefix does not exist", MODULE_NAME);
	zabend();
    }
    if (nbb != HRPREF_LEN) {				/* Wrong size	    */
	zvmessage( "Invalid binary prefix length", MODULE_NAME);
	zabend();
    }
    hrprefpack( Prefix, OutUnit, PkdPrfx);
    status=zvwrit( OutUnit, PkdPrfx,		/* write next line's prefix  */
		"LINE",  (Line + nlb),		/* desired line     */
		"NSAMPS", HRPREF_LEN,		/* just the prefix  */
		"BAND", 1,
                 0);
    if (status != 1) {
        printf("#E  Error by writing prefix #%d (VICAR Error Code = %d)\n",
                Line,status);
        }
}
/* *=============================================================================
 */
void	hrprefpack(
                   hrpref_typ   	*Prefix,
                   int  		OutUnit,
                   unsigned char	Buffer[])
{
	int		BConv[ZV_LEN], BSize;		/* Byte conversion  */
	unsigned char	*BPtr;				/* binary prefix ptr*/
	int		DConv[ZV_LEN], DSize;		/* Double conversion*/
	char		IntFrmt[16];			/* Integer format   */
	int		FConv[ZV_LEN], FSize;		/* Long conversion  */
	int		HConv[ZV_LEN], HSize;		/* Short conversion */
	int		RConv[ZV_LEN], RSize;		/* Real conversion  */
	char		RealFrmt[16];			/* Real format??    */

    zvget( OutUnit,     "BINTFMT", IntFrmt,             /* integer format   */
                        "BREALFMT", RealFrmt,           /* float format     */
                        0);

    /*
     *-----------------------------------------------------------------------
     *	Setup type conversion transfer vectors for all needed types.  Although
     * inefficient, this is done for every call for a good reason.  The
     * number of open files for the calling program is unknown.  And each
     * file may have a different format.
     *-----------------------------------------------------------------------
     */
    zvtrans_out(BConv, "BYTE", "BYTE", IntFrmt, RealFrmt);
    zvtrans_out(DConv, "DOUB", "DOUB", IntFrmt, RealFrmt);
    zvtrans_out(FConv, "FULL", "FULL", IntFrmt, RealFrmt);
    zvtrans_out(HConv, "HALF", "HALF", IntFrmt, RealFrmt);
    zvtrans_out(RConv, "REAL", "REAL", IntFrmt, RealFrmt);

    zvpixsizeb( &BSize, "BYTE", OutUnit);	/* get machine-dependent   >*/
    zvpixsizeb( &HSize, "HALF", OutUnit);	/*> data type lengths	    */
    zvpixsizeb( &FSize, "FULL", OutUnit);
    zvpixsizeb( &RSize, "REAL", OutUnit);
    zvpixsizeb( &DSize, "DOUB", OutUnit);

    /*
     *-----------------------------------------------------------------------
     * Pack all fields of the sturcture into the prefix buffer
     *-----------------------------------------------------------------------
     */
    BPtr = Buffer;			/* set pointer to start of packed  */
    TX_DOUB( &Prefix->EphTime);
    TX_REAL( &Prefix->Exposure);
    TX_FULL( &Prefix->COT);
    TX_FULL( &Prefix->FEETemp);
    TX_FULL( &Prefix->FPMTemp);
    TX_FULL( &Prefix->OBTemp);
    TX_FULL( &Prefix->FERT);
    TX_FULL( &Prefix->LERT);
    TX_FULL( &Prefix->reserved1);
    TX_HALF( &Prefix->CmpDataLen);
    TX_HALF( &Prefix->FrameCount);
    TX_HALF( &Prefix->Pischel);
    TX_HALF( &Prefix->ActPixel);
    TX_HALF( &Prefix->RSHits);
    TX_HALF( &Prefix->reserved2);
    TX_BYTE( &Prefix->DceInput);
    TX_BYTE( &Prefix->DceOutput);
    TX_BYTE( &Prefix->FrameErr1);
    TX_BYTE( &Prefix->FrameErr2);
    TX_BYTE( &Prefix->Gob1);
    TX_BYTE( &Prefix->Gob2);
    TX_BYTE( &Prefix->Gob3);
    TX_BYTE( &Prefix->DSS);
    TX_BYTE( &Prefix->DecmpErr1);
    TX_BYTE( &Prefix->DecmpErr2);
    TX_BYTE( &Prefix->DecmpErr3);
    TX_BYTE( &Prefix->FillerFlag);
    TX_FULL( &Prefix->reserved3);

    /*
     *---------------------------------------------------------------
     *	This code is provided to check for consistency of HRPREF_LEN
     *  in hrpref.h.  It may be commented out before delivery.
     *---------------------------------------------------------------
     */
    if ((BPtr - Buffer) != HRPREF_LEN) {
	zvmessage( "Incorrect HRPREF_LEN detected", MODULE_NAME);
	zabend();
    }
}

$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create hrwrpref.imake
/* Imake file for VICAR subroutine hrwrpref   */

#define SUBROUTINE  hrwrpref

#define MODULE_LIST  hrwrpref.c  

#define HW_SUBLIB

#define USES_ANSI_C
$ Return
$!#############################################################################
