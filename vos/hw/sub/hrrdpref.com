$!****************************************************************************
$!
$! Build proc for MIPL module hrrdpref
$! VPACK Version 1.9, Tuesday, March 15, 2005, 17:09:32
$!
$! Execute by entering:		$ @hrrdpref
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
$ write sys$output "*** module hrrdpref ***"
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
$ write sys$output "Invalid argument given to hrrdpref.com file -- ", primary
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
$   if F$SEARCH("hrrdpref.imake") .nes. ""
$   then
$      vimake hrrdpref
$      purge hrrdpref.bld
$   else
$      if F$SEARCH("hrrdpref.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake hrrdpref
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @hrrdpref.bld "STD"
$   else
$      @hrrdpref.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create hrrdpref.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack hrrdpref.com -mixed -
	-s hrrdpref.c -
	-i hrrdpref.imake
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create hrrdpref.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*				HRRDPREF.C
 *****************************************************************************
 *
 * Mars-94/96
 * Jet Propulsion Laboratoy
 * Pasadena, California  USA
 *
 * This subroutine reads the VICAR binary prefix for HRSC products.  The
 * structure of the prefix is defined in "hrpref.h".  It is the responsiblity
 * of the calling program to open the desired VICAR file and check the
 * organization of that file such as openning the file with visible binary
 * header and labels.
 *
 * For an example, please study the corresponding test program.
 *
 *
 * Date		Who		Description
 * ---------	---------------	----------------------------------------------
 * 15-Mar-05    KDM             Added keyword BAND in call of zvread
 * 30-Dec-94	Payam Zamani	Seperated unpacking into hrprefunpack
 * 22-Jun-94	Payam Zamani	Added FORTRAN bridge routine xhrrdpref
 * 10-May-94	P. Zamani	Added suport for new field FillerFlag
 *  4-Mar-94	P. Zamani	Support for new fields in the binary prefix
 * 30-Sep-93	Payam Zamani	Initial delivery
 *****************************************************************************
 */

#include	<stdio.h>
#include	"hrpref.h"			/* HRSC binary prefix      */
#include 	"xvmaininc.h"

#define	MODULE_NAME		"HRRDPREF"	/* Name of this subroutine */
#define	ZV_LEN			12		/* size of conversion space*/

/*
 *----------------------------------------------------------------------------
 * 	MACROS TO REDUCE TYPING DURRING TYPE CONVERSION
 *----------------------------------------------------------------------------
 */
#define TX_BYTE( to) zvtrans( BConv, BPtr, (to), 1); BPtr += BSize;
#define TX_DOUB( to) zvtrans( DConv, BPtr, (to), 1); BPtr += DSize;
#define TX_FULL( to) zvtrans( FConv, BPtr, (to), 1); BPtr += FSize;
#define TX_HALF( to) zvtrans( HConv, BPtr, (to), 1); BPtr += HSize;
#define TX_REAL( to) zvtrans( RConv, BPtr, (to), 1); BPtr += RSize;

void	hrprefunpack( unsigned char [], int, hrpref_typ *);

/*
 *=============================================================================
 *	Read and return the binary prefix of the specified line
 *=============================================================================
 */
void	hrrdpref(
        int		InUnit,
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
    zvget( InUnit,	"NBB", &nbb,			/* legnth of prefix */
			"NLB", &nlb,			/* #of binary header*/
			"BLTYPE", BLType,		/* Binary label type*/
			0);

    if (strncmp( BLType, BL_TYPE, strlen(BL_TYPE)) != 0) {	/* Project  */
	zvmessage( "Unsupported binary prefix type", MODULE_NAME);
	zabend();
    }

    if (nbb == 0) {						/* NO PREFIX*/
	zvmessage( "Binary prefix does not exist", MODULE_NAME);
	zabend();
    }

    if (nbb != HRPREF_LEN) {				/* WRONG SIZE	    */
	zvmessage( "Invalid binary prefix length", MODULE_NAME);
	zabend();
    }

    status=zvread( InUnit, PkdPrfx,		/* read next line's prefix  */
		"LINE",  (Line + nlb),		/* desired line     */
		"NSAMPS", HRPREF_LEN,		/* just the prefix  */
		"BAND", 1,
                 0);
    if (status != 1) {
        printf("#E  Error by reading prefix #%d (VICAR Error Code = %d)\n",
               Line,status);
        }

    hrprefunpack( PkdPrfx, InUnit, Prefix);
}

/*
 *=============================================================================
 */
void    hrprefunpack(
        unsigned char   Buffer[],
        int             InUnit,
        hrpref_typ      *Prefix)
{
        unsigned char   *BPtr;                          /* binary prefix ptr*/
        int             BConv[ZV_LEN], BSize;           /* Byte conversion  */
        int             DConv[ZV_LEN], DSize;           /* Double conversion*/
        int             FConv[ZV_LEN], FSize;           /* Long conversion  */
        int             HConv[ZV_LEN], HSize;           /* Short conversion */
        int             RConv[ZV_LEN], RSize;           /* Real conversion  */
 
    /*
     *-----------------------------------------------------------------------
     * Setup type conversion transfer vectors for all needed types.  Although
     * inefficient, this is done for every call.  The number of open files
     * for the calling program is unknown.  And each file may have a different 
     * format.
     *-----------------------------------------------------------------------
     */
    zvtrans_inb(BConv, "BYTE", "BYTE", InUnit);
    zvtrans_inb(DConv, "DOUB", "DOUB", InUnit);
    zvtrans_inb(FConv, "FULL", "FULL", InUnit);
    zvtrans_inb(HConv, "HALF", "HALF", InUnit);
    zvtrans_inb(RConv, "REAL", "REAL", InUnit);
 
    zvpixsizeb( &BSize, "BYTE", InUnit);        /* get machine-dependent   >*/
    zvpixsizeb( &HSize, "HALF", InUnit);        /*> data type lengths       */
    zvpixsizeb( &FSize, "FULL", InUnit);
    zvpixsizeb( &RSize, "REAL", InUnit);
    zvpixsizeb( &DSize, "DOUB", InUnit);
 
    /*
     *-----------------------------------------------------------------------
     *  Expand the packed prefix to individual fields of the sturcture
     *  NOTE:  Order of execution is significant, must match structure.
     *-----------------------------------------------------------------------
     */
    BPtr = Buffer;                     /* set pointer to start of packed  */
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
     *  This code is provided to check for consistency of HRPREF_LEN
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
$ create hrrdpref.imake
/* Imake file for VICAR subroutine hrrdpref   */

#define SUBROUTINE  hrrdpref

#define MODULE_LIST  hrrdpref.c  

#define USES_ANSI_C

#define HW_SUBLIB
$ Return
$!#############################################################################
