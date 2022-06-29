$!****************************************************************************
$!
$! Build proc for MIPL module cltspice_sub_c
$! VPACK Version 1.9, Monday, June 11, 2001, 14:53:13
$!
$! Execute by entering:		$ @cltspice_sub_c
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
$ write sys$output "*** module cltspice_sub_c ***"
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
$ write sys$output "Invalid argument given to cltspice_sub_c.com file -- ", primary
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
$   if F$SEARCH("cltspice_sub_c.imake") .nes. ""
$   then
$      vimake cltspice_sub_c
$      purge cltspice_sub_c.bld
$   else
$      if F$SEARCH("cltspice_sub_c.bld") .eqs. ""
$      then
$         gosub Imake_File
$         vimake cltspice_sub_c
$      else
$      endif
$   endif
$   if (primary .eqs. " ")
$   then
$      @cltspice_sub_c.bld "STD"
$   else
$      @cltspice_sub_c.bld "''primary'" "''secondary'"
$   endif
$ Return
$!#############################################################################
$Repack_File:
$ create cltspice_sub_c.repack
$ DECK/DOLLARS="$ VOKAGLEVE"
$ vpack cltspice_sub_c.com -
	-s ckgpav_s.c ckrsg1.c getpav.c getpav_c.c linrot_g.c ls2ins.c -
	-i cltspice_sub_c.imake -
	-o cltspice_sub.hlp
$ Exit
$ VOKAGLEVE
$ Return
$!#############################################################################
$Source_File:
$ create ckgpav_s.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*  -- translated by f2c (version 19980908).
   You must link the resulting object file with the libraries:
	-lf2c -lm   (in that order)
*/

#include "f2c.h"

/* Table of constant values */

static integer c__2 = 2;
static integer c__6 = 6;

/* $Procedure   CKGPAV_SEG ( C-kernel, get pointing and angular velocity ) */
/* Subroutine */ int ckgpav_seg__(inst, sclkdp, tol, ref, cmat, av, clkout, 
	segid, descr, handle, found, ref_len, segid_len)
integer *inst;
doublereal *sclkdp, *tol;
char *ref;
doublereal *cmat, *av, *clkout;
char *segid;
doublereal *descr;
integer *handle;
logical *found;
ftnlen ref_len;
ftnlen segid_len;
{
    static logical pfnd, sfnd;
    extern /* Subroutine */ int chkin_(), dafus_(), ckbss_(), ckpfs_(), 
	    cksns_();
    static logical needav;
    static integer refseg, refreq;
    extern /* Subroutine */ int chkout_(), irfnum_(), irfrot_();
    extern logical return_();
    static doublereal dcd[2];
    static integer icd[6];
    extern /* Subroutine */ int mxm_();
    static doublereal rot[9]	/* was [3][3] */;
    extern /* Subroutine */ int mxv_();

/* $ Abstract */

/*     Get inertially referenced instrument pointing and angular */
/*     velocity for a specified spacecraft clock time. */

/* $ Required_Reading */

/*     CK */

/* $ Keywords */

/*     POINTING */

/* $ Declarations */
/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */
/*     INST       I   NAIF instrument ID. */
/*     SCLKDP     I   Spacecraft clock time. */
/*     TOL        I   Time tolerance. */
/*     REF        I   Inertial reference frame. */
/*     CMAT       O   C-matrix pointing data. */
/*     AV         O   Angular velocity vector. */
/*     CLKOUT     O   Output spacecraft clock time. */
/*     SEGID      O   The segment identifier. */
/*     DESCR      O   The segment descriptor. */
/*     HANDLE     O   The handle of the file. */
/*     FOUND      O   True when requested pointing is available. */

/* $ Detailed_Input */

/*     INST       is the unique NAIF integer ID for the spacecraft */
/*                instrument for which data is being requested. */

/*     SCLKDP     is the encoded spacecraft clock time for which */
/*                data is being requested.  The SPICELIB routines */
/*                SCENCD and SCDECD encode and decode SCLK times. */

/*     TOL        is a time tolerance in ticks, the units of encoded */
/*                spacecraft clock time.  The SPICELIB routine SCTIKS */
/*                converts a spacecraft clock tolerance time from its */
/*                character string representation to ticks.  SCFMT */
/*                performs the inverse conversion. */

/*                The C-matrix and angular velocity vector returned by */
/*                CKGPAV is the one whose time tag is closest to SCLKDP */
/*                and within TOL units of SCLKDP.  (More in Particulars, */
/*                below.) */

/*     REF        is the inertial reference frame desired for the */
/*                returned data. */

/*                See the SPICELIB routine CHGIRF for a complete list of */
/*                those frames supported by NAIF.  For example, 'J2000', */
/*                'B1950', 'FK4', and so on. */

/* $ Detailed_Output */

/*     CMAT       is a rotation matrix that transforms the components of */
/*                of a vector expressed in the inertial frame specified */
/*                by REF to components expressed in the instrument */
/*                fixed frame at time CLKOUT. */

/*                Thus, if a vector v has components x, y, z in the */
/*                inertial frame, then v has components x', y', z' in the */
/*                instrument fixed frame at time CLKOUT: */

/*                     [ x' ]     [          ] [ x ] */
/*                     | y' |  =  |   CMAT   | | y | */
/*                     [ z' ]     [          ] [ z ] */

/*                If you know x', y', z', use the transpose of the */
/*                C-matrix to determine x, y, z as follows: */

/*                     [ x ]      [          ]T    [ x' ] */
/*                     | y |  =   |   CMAT   |     | y' | */
/*                     [ z ]      [          ]     [ z' ] */
/*                              (Transpose of CMAT) */

/*     AV         is the angular velocity vector. */

/*                The angular velocity vector is the axis about which */
/*                the reference frame tied to the instrument is */
/*                instantaneously rotating at time CLKOUT.  The */
/*                magnitude of AV is the magnitude of the instantane- */
/*                ous velocity of the rotation, in radians per second. */

/*                The components of AV are given relative to the */
/*                reference frame specified by the input argument REF. */

/*     CLKOUT     is the encoded spacecraft clock time associated with */
/*                the returned C-matrix and the returned angular */
/*                velocity vector. */

/*                For CK data types that accommodate discrete pointing */
/*                values only, this value may differ from the requested */
/*                time, but never by more than the input tolerance. */

/*                The particulars section below describes the search */
/*                algorithm used by CKGPAV to satisfy a pointing */
/*                request.  This algorithm determines the pointing */
/*                instance (and therefore the associated time value) */
/*                that is returned. */

/*     FOUND      is true if a record was found to satisfy the pointing */
/*                request.  FOUND will be false otherwise. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     1)  If a C-kernel file is not loaded using CKLPF prior to calling */
/*         this routine, an error is signalled by a routine that this */
/*         routine calls. */

/*     2)  If TOL is negative, FOUND is false. */

/*     3)  If REF is not one of the supported inertial reference frames, */
/*         an error is signalled by a routine that this routine calls. */

/* $ Files */

/*     CKGPAV searches through files loaded by CKLPF to locate a segment */
/*     that can satisfy the request for pointing and angular velocity */
/*     for instrument INST at time SCLKDP.  You must load a C-kernel */
/*     file using CKLPF before calling this routine. */

/* $ Particulars */

/*     CKGPAV searches through files loaded by CKLPF to satisfy a */
/*     pointing request. Last-loaded files are searched first, and */
/*     individual files are searched in backwards order, giving */
/*     priority to segments that were added to a file later than the */
/*     others. CKGPAV considers only those segments that contain */
/*     angular velocity data, as indicated by the segment descriptor. */

/*     The search ends when a segment is found that can give pointing */
/*     and angular velocity for the specified instrument at a time */
/*     falling within the specified tolerance on either side of the */
/*     request time. Within that segment, the instance closest to the */
/*     input time is located and returned. */

/*     The following example illustrates this search procedure. Segments */
/*     A and B are in the same file, with segment A located further */
/*     towards the end of the file than segment B. */


/*                                      SCLKDP */
/*                                     / */
/*                                    |  TOL */
/*                                    | / */
/*                                    |/\ */

/*     Request 1                   [--+--] */
/*                                 .  .  . */
/*                                 .  .  . */
/*     Segment A          (0-----------------0--------0--0-----0) */
/*                                 .  .  . */
/*                                 .  .  . */
/*     Segment B    (0--0--0--0--0--0--0--0--0--0--0--0--0--0--0--0--0) */
/*                                     ^ */
/*                                     | */
/*                                     | */
/*                         CKGPAV returns this instance */



/*                                           SCLKDP */
/*                                          / */
/*                                         |  TOL */
/*                                         | / */
/*                                         |/\ */

/*     Request 2                        [--+--] */
/*                                      .  .  . */
/*                                      .  .  . */
/*     Segment A          (0-----------------0--------0--0-----0) */
/*                                           ^ */
/*                                           | */
/*                                           | */
/*                               CKGPAV returns this instance */

/*     Segment B    (0--0--0--0--0--0--0--0--0--0--0--0--0--0--0--0--0) */



/* $ Examples */


/*     Suppose you have two C-kernel files containing data for the */
/*     Voyager 2 narrow angle camera.  One file contains predict values, */
/*     and the other contains corrected pointing for a selected group */
/*     of images, that is, for a subset of images from the first file. */

/*     The following code fragment uses CKGPAV to get C-matrices and */
/*     associated angular velocity vectors for a set of images whose */
/*     SCLK counts (un-encoded character string versions) are contained */
/*     in the array SCLKCH. */

/*     If available, the program will get the corrected pointing values. */
/*     Otherwise, predict values will be used. */

/*     For each C-matrix, a unit inertial pointing vector is constructed */
/*     and printed along with the angular velocity vector. */


/*     C */
/*     C     Constants for this program. */
/*     C */
/*     C     -- The code for the Voyager 2 mission is -32 */
/*     C */
/*     C     -- The code for the narrow angle camera on the Voyager 2 */
/*     C        spacecraft is -32001. */
/*     C */
/*     C    --  Spacecraft clock times for successive images always */
/*     C        differ by more than 0:0:400.  This is an acceptable */
/*     C        tolerance, and must be converted to 'ticks' (units */
/*     C        of encoded SCLK) for input to CKGP. */
/*     C */
/*     C     -- The reference frame we want is FK4. */
/*     C */
/*     C     -- The narrow angle camera boresight defines the third */
/*     C        axis of the instrument-fixed coordinate system. */
/*     C        Therefore, the vector ( 0, 0, 1 ) always represents */
/*     C        the boresight direction in camera-fixed coordinates. */
/*     C */
/*           FILE1      = 'PREDICT.CK' */
/*           FILE2      = 'CORRECTED.CK' */
/*           SC         = -32 */
/*           INST       = -32001 */
/*           TOLVGR     = '0:0:400' */
/*           REF        = 'FK4' */
/*           VCFIX( 1 ) =  0.D0 */
/*           VCFIX( 2 ) =  0.D0 */
/*           VCFIX( 3 ) =  1.D0 */

/*     C */
/*     C     Loading the files in this order ensures that the */
/*     C     corrected file will get searched first. */
/*     C */
/*           CALL CKLPF ( FILE1, HANDL1 ) */
/*           CALL CKLPF ( FILE2, HANDL2 ) */

/*     C */
/*     C     Convert tolerance from VGR formatted character string */
/*     C     SCLK to ticks which are units of encoded SCLK. */
/*     C */
/*           CALL SCTIKS ( SC, TOLVGR, TOLTIK ) */


/*           DO I = 1, NPICS */

/*     C */
/*     C        CKGPAV requires encoded spacecraft clock. */
/*     C */
/*              CALL SCENCD ( SC, SCLKCH( I ), SCLKDP ) */

/*              CALL CKGPAV ( INST, SCLKDP, TOLTIK, REF, CMAT, CLKOUT, */
/*          .                 AV,   FOUND ) */

/*              IF ( FOUND ) THEN */

/*     C */
/*     C           Use the transpose of the C-matrix to transform the */
/*     C           boresight vector from camera-fixed to inertial */
/*     C           coordinates. */
/*     C */
/*                 CALL MTXV   ( CMAT, VCFIX,  VINERT ) */
/*                 CALL SCDECD ( SC,   CLKOUT, CLKCH  ) */

/*                 WRITE (*,*) 'Time:                    ', CLKCH */
/*                 WRITE (*,*) 'Pointing vector:         ', VINERT */
/*                 WRITE (*,*) 'Angular velocity vector: ', AV */

/*              ELSE */

/*                 WRITE (*,*) 'Pointing not found for time ', SCLKCH(I) */

/*              END IF */

/*           END DO */


/* $ Restrictions */

/*     None. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     M.J. Spencer   (JPL) */
/*     R.E. Thurman   (JPL) */
/*     I.M. Underwood (JPL) */

/* $ Version */

/* -    SPICELIB Version 1.1.0, 03-JUN-1993 (NJB) */

/* 	      Global SAVE added for port to NeXT. */

/* -    SPICELIB Version 1.0.0, 07-SEP-1990 (RET) (IMU) */

/* -& */
/* $ Revisions */

/* -    Beta Version 1.1.0, 30-AUG-1990 (MJS) */

/*        The following changes were made as a result of the */
/*        NAIF CK Code and Documentation Review: */

/*        1) The variable SCLK was changed to SCLKDP. */
/*        2) The variable INSTR was changed to INST. */
/*        3) The variable IDENT was changed to SEGID. */
/*        4) The declarations for the parameters NDC, NIC, NC, and */
/*           IDLEN were moved from the "Declarations" section of the */
/*           header to the "Local parameters" section of the code below */
/*           the header. These parameters are not meant to modified by */
/*           users. */
/*        5) The header was updated to reflect the changes. */

/* -    Beta Version 1.0.0, 04-JUN-1990 (RET) (IMU) */

/* -& */

/*     SPICELIB functions */


/*     Local parameters */

/*        NDC        is the number of double precision components in an */
/*                   unpacked C-kernel segment descriptor. */

/*        NIC        is the number of integer components in an unpacked */
/*                   C-kernel segment descriptor. */

/*        NC         is the number of components in a packed C-kernel */
/*                   descriptor.  All DAF summaries have this formulaic */
/*                   relationship between the number of its integer and */
/*                   double precision components and the number of packed */
/*                   components. */

/*        IDLEN      is the length of the C-kernel segment identifier. */
/*                   All DAF names have this formulaic relationship */
/*                   between the number of summary components and */
/*                   the length of the name (You will notice that */
/*                   a name and a summary have the same length in bytes.) */


/*     Local variables */


/* 	   Saved variables */


/*     Standard SPICE error handling. */

    /* Parameter adjustments */
    --descr;
    --av;
    cmat -= 4;

    /* Function Body */
    if (return_()) {
	return 0;
    } else {
	chkin_("CKGPAV", (ftnlen)6);
    }

/*     Need angular velocity data. */
/*     Assume the segment won't be found until it really is. */

    needav = TRUE_;
    *found = FALSE_;

/*     Begin a search for this instrument and time, and get the first */
/*     applicable segment. */

    ckbss_(inst, sclkdp, tol, &needav);
    cksns_(handle, &descr[1], segid, &sfnd, segid_len);

/*     Keep trying candidate segments until a segment can produce a */
/*     pointing instance within the specified time tolerance of the */
/*     input time. */

    while(sfnd) {
	ckpfs_(handle, &descr[1], sclkdp, tol, &needav, &cmat[4], &av[1], 
		clkout, &pfnd);
	if (pfnd) {

/*           Found one. If the data aren't already referenced to the */
/*           requested inertial frame, rotate them. */

	    *found = TRUE_;
	    dafus_(&descr[1], &c__2, &c__6, dcd, icd);
	    refseg = icd[1];
	    irfnum_(ref, &refreq, ref_len);
	    if (refreq != refseg) {
		irfrot_(&refreq, &refseg, rot);
		mxm_(&cmat[4], rot, &cmat[4]);
		mxv_(rot, &av[1], &av[1]);
	    }
	    chkout_("CKGPAV", (ftnlen)6);
	    return 0;
	}
	cksns_(handle, &descr[1], segid, &sfnd, segid_len);
    }
    chkout_("CKGPAV", (ftnlen)6);
    return 0;
} /* ckgpav_seg__ */

#ifdef uNdEfInEd
comments from the converter:  (stderr from f2c)
   ckgpav_seg:
#endif
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create ckrsg1.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*  -- translated by f2c (version 19980908).
   You must link the resulting object file with the libraries:
	-lf2c -lm   (in that order)
*/

#include "f2c.h"

/* Table of constant values */

static integer c__2 = 2;
static integer c__6 = 6;

/* $Procedure    CKRSG1 ( C-kernel, read segment, data type 1 ) */
/* Subroutine */ int ckrsg1_0_(n__, handle, descr, sclkdp, tol, needav, 
	record, index, nprec, found)
int n__;
integer *handle;
doublereal *descr, *sclkdp, *tol;
logical *needav;
doublereal *record;
integer *index, *nprec;
logical *found;
{
    /* System generated locals */
    integer i__1, i__2;
    doublereal d__1;

    /* Local variables */
    static integer nrec, ndir, indx, skip, psiz, i__, n;
    extern /* Subroutine */ int chkin_(), dafus_();
    static integer group;
    extern /* Subroutine */ int dafrda_();
    static doublereal buffer[100];
    static integer remain, dirloc;
    extern integer lstcld_(), lstled_();
    extern /* Subroutine */ int sigerr_(), chkout_();
    static integer grpndx;
    extern /* Subroutine */ int setmsg_();
    extern logical return_();
    static doublereal dcd[2];
    static integer beg, icd[6], end;
    static logical fnd;

/* $ Abstract */

/*     Read a CK segment of data type 1. */

/* $ Required_Reading */

/*     CK */
/*     DAF */

/* $ Keywords */

/*     POINTING */

/* $ Declarations */
/* $ Brief_I/O */

/*     Variable  I/O  Entry point */
/*     --------  ---  -------------------------------------------------- */
/*     HANDLE     I   CKR01 */
/*     DESCR      I   CKR01 */
/*     SCLKDP     I   CKR01 */
/*     TOL        I   CKR01 */
/*     NEEDAV     I   CKR01 */
/*     RECORD     O   CKR01 */
/*     INDEX      O   CKINDX */
/*     NPREC      O   CKINDX */
/*     FOUND      O   CKR01 */

/* $ Detailed_Input */

/*     See the entry points CKR01 and CKINDX. */

/* $ Detailed_Output */

/*     See the entry points CKR01 and CKINDX. */

/* $ Exceptions */

/*     1)  See the entry points CKR01 and CKINDX for exceptions */
/*         specific to those routines. */

/*     2)  If CKRSG1 is called directly, the error SPICE(BOGUSENTRY) */
/*         is signalled. */

/* $ Files */

/*     The file containing the segment is specified by its handle, and */
/*     should be opened for read access, either by CKLPF or DAFOPR. */


/* $ Particulars */

/*     CKRSG1 serves as an umbrella routine under which the shared */
/*     variables of its entry points are declared. CKRSG1 should */
/*     never be called directly. */

/*     The entry points of CKRSG1 are: */

/*        CKR01  ( C-kernel, read pointing record, data type 1   ) */
/*        CKINDX ( C-kernel, return index of record, data type 1 ) */

/* $ Examples */

/*     See the entry points CKR01 and CKINDX. */

/* $ Restrictions */

/*     1) The file containing the segment should be opened for read */
/*        access, either by CKLPF or DAFOPR. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     J.M. Lynch     (JPL) */

/* $ Version */

/* -    Beta Version 1.0.0, 19-OCT-1990 (JML) */

/* -& */

/*     Saved variables */


/*     SPICELIB functions */


/*     Local parameters */

/*        DIRSIZ     is the directory size. */

/*        NDC        is the number of double precision components in an */
/*                   unpacked C-kernel segment descriptor. */

/*        NIC        is the number of integer components in an unpacked */
/*                   C-kernel segment descriptor. */

/*        QSIZ       is the number of double precision numbers making up */
/*                   the quaternion portion of a pointing record. */

/*        QAVSIZ     is the number of double precision numbers making up */
/*                   the quaternion and angular velocity portion of a */
/*                   pointing record. */


/*     Local variables */

/* %&END_DECLARATIONS */

/*     Standard SPICE error handling. */

    /* Parameter adjustments */
    if (descr) {
	--descr;
	}
    if (record) {
	--record;
	}

    /* Function Body */
    switch(n__) {
	case 1: goto L_ckr01;
	case 2: goto L_ckindx;
	}

    if (return_()) {
	return 0;
    } else {
	chkin_("CKRSG1", (ftnlen)6);
    }
    sigerr_("SPICE(BOGUSENTRY)", (ftnlen)17);
    chkout_("CKRSG1", (ftnlen)6);
    return 0;
/* $Procedure      CKR01 ( C-kernel, read pointing record, data type 1 ) */

L_ckr01:
/* $ Abstract */

/*     Read a pointing record from a CK segment, data type 1. */

/* $ Required_Reading */

/*     CK */
/*     DAF */

/* $ Keywords */

/*     POINTING */

/* $ Declarations */

/*      INTEGER               HANDLE */
/*      DOUBLE PRECISION      DESCR  ( * ) */
/*      DOUBLE PRECISION      SCLKDP */
/*      DOUBLE PRECISION      TOL */
/*      LOGICAL               NEEDAV */
/*      DOUBLE PRECISION      RECORD ( * ) */
/*      LOGICAL               FOUND */

/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */
/*     HANDLE     I   File handle. */
/*     DESCR      I   Segment descriptor. */
/*     SCLKDP     I   Spacecraft clock time. */
/*     TOL        I   Time tolerance. */
/*     NEEDAV     I   True when angular velocity data is requested. */
/*     RECORD     O   Pointing data record. */
/*     FOUND      O   True when data is found. */

/* $ Detailed_Input */

/*     HANDLE     is the integer handle of the CK file containing the */
/*                segment. */

/*     DESCR      is the descriptor of the segment. */

/*     SCLKDP     is an encoded spacecraft clock time for which */
/*                pointing is being requested.  The SPICELIB routines */
/*                SCENCD and SCDECD are used to encode and decode SCLK */
/*                times. */

/*     TOL        is a time tolerance, measured in the same units as */
/*                encoded spacecraft clock. */

/*                The record returned by CKR01 is the one whose time is */
/*                closest to SCLKDP and within TOL units of SCLKDP. */
/*                (More in Particulars, below.) */

/*     NEEDAV     is true when angular velocity data is requested. */


/* $ Detailed_Output */

/*     RECORD     is the pointing record.  Contents are as follows: */

/*                   RECORD( 1 ) = CLKOUT */

/*                   RECORD( 2 ) = q0 */
/*                   RECORD( 3 ) = q1 */
/*                   RECORD( 4 ) = q2 */
/*                   RECORD( 5 ) = q3 */

/*                   RECORD( 6 ) = Av1  ] */
/*                   RECORD( 7 ) = Av2  |-- Returned optionally */
/*                   RECORD( 8 ) = Av3  ] */

/*                CLKOUT is the encoded spacecraft clock time for the */
/*                returned pointing values. CLKOUT will be the closest */
/*                time in the segment to the input time as long as it is */
/*                within the input tolerance (see FOUND below). If SCLKDP */
/*                falls at the exact midpoint of two times, the record */
/*                for the greater of the two will be returned. */

/*                The quantities q0 - q3 represent a quaternion. */
/*                The quantities Av1, Av2, and Av3 represent the angular */
/*                velocity vector, and are returned if the segment */
/*                contains angular velocity data and NEEDAV is true. */
/*                The components of the angular velocity vector are */
/*                specified relative to the inertial reference frame */
/*                for the segment. */

/*     FOUND      is true if a record was found to satisfy the pointing */
/*                request. FOUND will be false when there is no pointing */
/*                instance within the segment whose time falls within */
/*                the requested time tolerance on either side of the */
/*                input time. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     1)  If there is a need for angular velocity data and the segment */
/*         contains no such data, the error SPICE(NOAVDATA) is signalled. */

/*     2)  If the specified handle does not belong to any file that is */
/*         currently known to be open, an error is diagnosed by a */
/*         routine that this routine calls. */

/*     3)  If DESCR is not a valid, packed descriptor of a segment in */
/*         the CK file specified by HANDLE, the results of this routine */
/*         are unpredictable. */

/* $ Files */

/*     The file containing the segment is specified by its handle, and */
/*     should be opened for read, either by CKLPF or DAFOPR. */

/* $ Particulars */

/*     See the CK required reading file for a detailed description of */
/*     the structure of a type 1 pointing segment. */

/*     To minimize the number of file reads performed during the search, */
/*     a buffer of 100 double precision numbers is used.  If there are */
/*     10,001 or fewer pointing records, at most four reads will be */
/*     needed to satisfy the request:  one to read NREC, one to read in */
/*     100 or fewer directory times, one to read 100 or fewer actual */
/*     times, and then after the appropriate record has been located, */
/*     one to read the quaternion and angular velocity data. */

/*     One more read would be required for every other group of 10,000 */
/*     records in the segment. */

/* $ Examples */

/*     The CKRnn routines are usually used in tandem with the CKEnn */
/*     routines, which evaluate the record returned by CKRnn to give */
/*     the pointing information and output time. */

/*     The following code fragment searches through a file (represented */
/*     by HANDLE) for all segments applicable to the Voyager 2 wide angle */
/*     camera, for a particular spacecraft clock time, which have data */
/*     type 1.  It then evaluates the pointing for that epoch and prints */
/*     the result. */

/*     C */
/*     C     - Get the spacecraft clock time. Must encode it for use */
/*     C       in the C-kernel. */
/*     C */
/*     C     - Set the time tolerance high to catch anything close to */
/*     C       the input time. */
/*     C */
/*     C     - We don't need angular velocity data. */
/*     C */
/*           SC     = -32 */
/*           INST   = -32002 */
/*           TOL    =  1000.D0 */
/*           NEEDAV = .FALSE. */

/*           WRITE (*,*) 'Enter spacecraft clock time string:' */
/*           READ (*,FMT='(A)') SCLKCH */
/*           CALL SCENCD ( SC, SCLKCH, SCLKDP ) */

/*     C */
/*     C     Search from the beginning through all segments. */
/*     C */
/*           CALL DAFBFS ( HANDLE ) */
/*           CALL DAFFNA ( FOUND  ) */

/*           DO WHILE ( FOUND ) */

/*              CALL DAFGN ( IDENT                 ) */
/*              CALL DAFGS ( DESCR                 ) */
/*              CALL DAFUS ( DESCR, 2, 6, DCD, ICD ) */

/*              IF ( INST        .EQ. ICD( 1 )  .AND. */
/*          .        SCLKDP      .GE. DCD( 1 )  .AND. */
/*          .        SCLKDP      .LE. DCD( 2 ) ) THEN */

/*                 CALL CKR01 ( HANDLE, DESCR, SCLKDP, TOL, NEEDAV, */
/*          .                   RECORD, FOUND ) */

/*                 IF ( FOUND ) THEN */

/*                    CALL CKE01 ( NEEDAV, RECORD, CMAT, AV, CLKOUT ) */

/*                    WRITE (*,*) 'Segment descriptor and identifier:' */
/*                    WRITE (*,*) DCD, ICD */
/*                    WRITE (*,*) IDENT */

/*                    WRITE (*,*) 'C-matrix:' */
/*                    WRITE (*,*) CMAT */

/*                 END IF */

/*              END IF */

/*              CALL DAFFNA ( FOUND ) */

/*           END DO */

/* $ Restrictions */

/*     1) The file containing the segment should be opened for read */
/*        access, either by CKLPF or DAFOPR. */

/*     2) The routine assumes that it has been given a type 1 segment. */
/*        If it hasn't, the results will be erroneous. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     J.M. Lynch     (JPL) */
/*     J.E. McLean    (JPL) */
/*     M.J. Spencer   (JPL) */
/*     R.E. Thurman   (JPL) */
/*     I.M. Underwood (JPL) */

/* $ Version */

/* -    SPICELIB Version 1.1.0  22-OCT-1990 (JML) */

/*        Some variables were saved and the routine was */
/*        made an entry point to CKRSG1. */

/* -    SPICELIB Version 1.0.0, 07-SEP-1990 (RET) (IMU) */

/* -& */
/* $ Revisions */

/* -    SPICELIB Version 1.0.0 22-OCT-1990 (JML) */

/*        1) The header was updated to reflect the complete set of */
/*           changes recommended by the NAIF CK Code and Documentation */
/*           Review. */

/*        2) The saved variable INDX was introduced so that the entry */
/*           point CKINDX could return the index of the record in the */
/*           segment. */

/*        3) NREC was made a saved variable so that the entry point */
/*           CKINDX could also return the number of pointing records */
/*           in the segment. */


/* -    Beta Version 1.1.0, 29-AUG-1990 (MJS) (JEM) */

/*        The following changes were made as a result of the */
/*        NAIF CK Code and Documentation Review: */

/*        1) The variable SCLK was changed to SCLKDP. */
/*        2) The declarations for the parameters QSIZ, QAVSIZ, NDC, and */
/*           NIC were moved from the "Declarations" section of the */
/*           header to the "Local parameters" section of the code below */
/*           the header. These parameters are not meant to modified by */
/*           users. */
/*        3) The variable DIRSIZ has been parameterized in the code */
/*           following the header. DIRSIZ is still 100. */
/*        5) The header was improved and updated to reflect the changes. */
/*        6) The in-code comments were improved. */

/* -    Beta Version 1.0.0, 17-MAY-1990 (RET) (IMU) */

/* -& */

/*     Standard SPICE error handling. */

    if (return_()) {
	return 0;
    } else {
	chkin_("CKR01", (ftnlen)5);
    }

/*     We need to look at a few of the descriptor components. */

/*     The unpacked descriptor contains the following information */
/*     about the segment: */

/*        DCD(1)  Initial encoded SCLK */
/*        DCD(2)  Final encoded SCLK */
/*        ICD(1)  Instrument */
/*        ICD(2)  Inertial reference frame */
/*        ICD(3)  Data type */
/*        ICD(4)  Angular velocity flag */
/*        ICD(5)  Initial address of segment data */
/*        ICD(6)  Final address of segment data */

    dafus_(&descr[1], &c__2, &c__6, dcd, icd);

/*     The size of the record returned depends on whether or not the */
/*     segment contains angular velocity data. */

/*     This is a convenient place to check if the need for angular */
/*     velocity data matches the availability. */

    if (icd[3] == 1) {
	psiz = 7;
    } else {
	psiz = 4;
	if (*needav) {
	    setmsg_("Segment does not contain angular velocity data.", (
		    ftnlen)47);
	    sigerr_("SPICE(NOAVDATA)", (ftnlen)15);
	    chkout_("CKR01", (ftnlen)5);
	    return 0;
	}
    }

/*     The beginning and ending addresses of the segment are in the */
/*     descriptor. */

    beg = icd[4];
    end = icd[5];

/*     Get the number of records in this segment, and from that determine */
/*     the number of directory epochs. */

    dafrda_(handle, &end, &end, buffer);
    nrec = (integer) buffer[0];
    ndir = (nrec - 1) / 100;

/*     The directory epochs narrow down the search to a group of DIRSIZ */
/*     or fewer records. The way the directory is constructed guarantees */
/*     that we will definitely find the closest time in the segment to */
/*     SCLKDP in the indicated group. */

/*     There is only one group if there are no directory epochs. */

    if (ndir == 0) {
	group = 1;
    } else {

/*        Compute the location of the first directory epoch.  From the */
/*        beginning of the segment, need to go through all of the */
/*        pointing numbers (PSIZ*NREC of them), then through all of */
/*        the SCLKDP times (NREC more) to get to the first SCLK */
/*        directory. */

	dirloc = beg + (psiz + 1) * nrec;

/*        Locate the first directory epoch greater than SCLKDP. Read in */
/*        as many as DIRSIZ directory epochs at a time for comparison. */

	fnd = FALSE_;
	remain = ndir;
	group = 0;
	while(! fnd) {

/*           The number of records to read in the buffer. */

	    n = min(remain,100);
	    i__1 = dirloc + n - 1;
	    dafrda_(handle, &dirloc, &i__1, buffer);
	    remain -= n;

/*           If we find the first directory time greater than or equal */
/*           to the epoch, we're done. */

/*           If we reach the end of the directories, and still haven't */
/*           found one bigger than the epoch, the group is the last group */
/*           in the segment. */

/*           Otherwise keep looking. */

	    i__ = lstled_(sclkdp, &n, buffer);
	    if (i__ < n) {
		group = group + i__ + 1;
		fnd = TRUE_;
	    } else if (remain == 0) {
		group = ndir + 1;
		fnd = TRUE_;
	    } else {
		dirloc += n;
		group += n;
	    }
	}
    }

/*     Now we know which group of DIRSIZ (or less) times to look at. */
/*     Out of the NREC SCLKDP times, the number that we should skip over */
/*     to get to the proper group is DIRSIZ*( GROUP - 1 ). */

    skip = (group - 1) * 100;

/*     From this we can compute the index into the segment of the group */
/*     of times we want.  From the beginning, need to pass through */
/*     PSIZ*NREC pointing numbers to get to the first SCLKDP time. */
/*     Then we skip over the number just computed above. */

    grpndx = beg + nrec * psiz + skip;

/*     The number of times that we have to look at may be less than */
/*     DIRSIZ.  However many there are, go ahead and read them into the */
/*     buffer. */

/* Computing MIN */
    i__1 = 100, i__2 = nrec - skip;
    n = min(i__1,i__2);
    i__1 = grpndx + n - 1;
    dafrda_(handle, &grpndx, &i__1, buffer);

/*     Find the time in the group closest to the input time, and see */
/*     if it's within tolerance. */

    i__ = lstcld_(sclkdp, &n, buffer);
    if ((d__1 = *sclkdp - buffer[i__ - 1], abs(d__1)) > *tol) {
	*found = FALSE_;
	chkout_("CKR01", (ftnlen)5);
	return 0;
    }

/*     Now we know the exact record that we want. */

/*     RECORD( 1 ) holds SCLKDP. */

    *found = TRUE_;
    record[1] = buffer[i__ - 1];

/*     We need the Ith pointing record out of this group of */
/*     DIRSIZ. This group of DIRSIZ is SKIP records into the beginning */
/*     of the segment. And each record is PSIZ big. */

    indx = skip + i__;
    n = beg + psiz * (indx - 1);
    i__1 = n + psiz - 1;
    dafrda_(handle, &n, &i__1, &record[2]);

/*     That is all. */

    chkout_("CKR01", (ftnlen)5);
    return 0;
/* $Procedure      CKINDX ( C-kernel, return record index ) */

L_ckindx:
/* $ Abstract */

/*     Return the index of the last pointing record returned by */
/*     CKR01.  Also return the total number of pointing records */
/*     in the segment. */

/* $ Required_Reading */

/*     CK */
/*     DAF */

/* $ Keywords */

/*     POINTING */

/* $ Declarations */

/*      INTEGER               INDEX */
/*      INTEGER               NPREC */

/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */

/*      INDEX     O    The index of the last pointing record returned. */
/*      NPREC     O    The number of pointing records in the segment. */

/* $ Detailed_Input */

/*      None. */

/* $ Detailed_Output */

/*      INDEX          is the index within the segment of the last */
/*                     pointing record returned by CKR01. */

/*      NPREC          is the total number of pointing records in */
/*                     the segment that the last returned pointing */
/*                     was found in. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     None. */

/* $ Files */

/*     None. */

/* $ Particulars */

/*     This routine returns the index within a segment of the */
/*     last returned pointing record.  It also returns the total */
/*     number of records within that segment. */

/*     This routine should only be used after a call to CKR01, or */
/*     one of the high level CK readers, was successful in finding */
/*     a pointing record that satisfied the request.  In any other */
/*     instance the results of this routine will be unpredictable. */

/* $ Examples */

/*     CKINDX should be used after CKR01, or one of the high level CK */
/*     readers, has found a pointing record that satisfies the request. */

/*     The following code fragment searches for pointing for the */
/*     Voyager 2 wide angle camera at a time specified by the user. */
/*     After finding a pointing record that safisfies the request it */
/*     then searches for the pointing records that immediatedly precede */
/*     and follow the returned record in the segment.  It does this */
/*     using the index of the record, which is returned by the routine */
/*     CKINDX, and with the utility routine CKGR01 ( get record ). */
/*     It then converts the pointing data from its stored form to */
/*     C-matrices using the routine CKE01. */

/*     C */
/*     C   - Get the spacecraft clock time. Must encode it for use */
/*     C     in the C-kernel. */
/*     C */
/*     C   - Set the time tolerance high to catch anything close to */
/*     C     the input time. */
/*     C */
/*     C   - We don't need angular velocity data. */
/*     C */
/*         SC     = -32 */
/*         INST   = -32002 */
/*         TOL    =  1000.D0 */
/*         NEEDAV = .FALSE. */
/*     C */
/*     C   We need logical flags to indicate whether the pointing */
/*     C   records could be returned. */
/*     C */
/*         PFND   = .FALSE. */
/*         PREV   = .FALSE. */
/*         NEXT   = .FALSE. */


/*         WRITE (*,*) 'Enter spacecraft clock time string:' */
/*         READ (*,FMT='(A)') SCLKCH */
/*         CALL SCENCD ( SC, SCLKCH, SCLKDP ) */

/*     C */
/*     C   Search from the beginning through the segments. */
/*     C */
/*         CALL DAFBFS ( HANDLE ) */
/*         CALL DAFFNA ( SFND   ) */

/*         DO WHILE ( ( .NOT. PFND ) .AND. ( SFND ) ) */

/*           CALL DAFGN ( IDENT                 ) */
/*           CALL DAFGS ( DESCR                 ) */
/*           CALL DAFUS ( DESCR, 2, 6, DCD, ICD ) */

/*           IF ( INST        .EQ. ICD( 1 )  .AND. */
/*        .       SCLKDP      .GE. DCD( 1 )  .AND. */
/*        .       SCLKDP      .LE. DCD( 2 ) ) THEN */

/*             CALL CKR01 ( HANDLE, DESCR, SCLKDP, TOL, NEEDAV, */
/*        .                 RECORD, PFND  ) */

/*             IF ( PFND ) THEN */

/*               CALL CKE01  ( NEEDAV, RECORD, CMAT, AV, CLKOUT ) */

/*               CALL CKINDX ( INDEX,  NPREC ) */

/*     C          If the record returned is not the first one in the */
/*     C          segment, then we can get the previous one. */

/*                IF ( INDEX .NE. 1 )  THEN */
/*                  PREV = .TRUE. */
/*                  CALL CKGR01 ( HANDLE, DESCR, INDEX-1, RECORD        ) */
/*                  CALL CKE01  ( NEEDAV, RECORD,CMTPRE,  AVPRE, CLKPRE ) */
/*                ELSE */
/*                  WRITE (*,*) 'No previous pointing record' */
/*                END IF */


/*     C          If the record returned is not the last one in the */
/*     C          segment, then we can get the next one. */

/*                IF ( INDEX .NE. NPREC )  THEN */
/*                  NEXT = .TRUE. */
/*                  CALL CKGR01 ( HANDLE, DESCR, INDEX+1, RECORD        ) */
/*                  CALL CKE01  ( NEEDAV, RECORD,CMTNXT,  AVNXT, CLKNXT ) */
/*                ELSE */
/*                  WRITE (*,*) 'No following pointing record' */
/*                END IF */


/*              END IF */

/*            END IF */

/*            CALL DAFFNA ( SFND ) */

/*          END DO */


/* $ Restrictions */

/*     This routine should only be used after a call to CKR01, or */
/*     one of the high level CK readers, was successful in finding */
/*     a pointing record that satisfied the request.  In any other */
/*     instance the results of this routine will be unpredictable. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     J.M. Lynch     (JPL) */

/* $ Version */

/* -    Beta Version 1.0.0, 22-OCT-1990 (JML) */

/* -& */

/*     Standard SPICE error handling. */

    if (return_()) {
	return 0;
    } else {
	chkin_("CKINDX", (ftnlen)6);
    }

/*     Just output the final values of the variables that were */
/*     determined by the previous call to CKR01. */

    *index = indx;
    *nprec = nrec;
    chkout_("CKINDX", (ftnlen)6);
    return 0;
} /* ckrsg1_ */

/* Subroutine */ int ckrsg1_(handle, descr, sclkdp, tol, needav, record, 
	index, nprec, found)
integer *handle;
doublereal *descr, *sclkdp, *tol;
logical *needav;
doublereal *record;
integer *index, *nprec;
logical *found;
{
    return ckrsg1_0_(0, handle, descr, sclkdp, tol, needav, record, index, 
	    nprec, found);
    }

/* Subroutine */ int ckr01_(handle, descr, sclkdp, tol, needav, record, found)
integer *handle;
doublereal *descr, *sclkdp, *tol;
logical *needav;
doublereal *record;
logical *found;
{
    return ckrsg1_0_(1, handle, descr, sclkdp, tol, needav, record, (integer *
	    )0, (integer *)0, found);
    }

/* Subroutine */ int ckindx_(index, nprec)
integer *index, *nprec;
{
    return ckrsg1_0_(2, (integer *)0, (doublereal *)0, (doublereal *)0, (
	    doublereal *)0, (logical *)0, (doublereal *)0, index, nprec, (
	    logical *)0);
    }

#ifdef uNdEfInEd
comments from the converter:  (stderr from f2c)
   ckrsg1:
       entry    ckr01:
       entry    ckindx:
#endif
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create getpav.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*  -- translated by f2c (version 19980908).
   You must link the resulting object file with the libraries:
	-lf2c -lm   (in that order)
*/

#include "f2c.h"

/* Table of constant values */

static integer c__8 = 8;
static integer c__9 = 9;
static integer c__3 = 3;
static integer c__2 = 2;
static integer c__6 = 6;
static logical c_true = TRUE_;

/* $Procedure     GETPAV ( Get pointing and angular velocity ) */

/* Subroutine */ int getpav_(id, sclkdp, tol, mxlook, ref, cmat, av, found, 
	ref_len)
integer *id;
doublereal *sclkdp, *tol;
integer *mxlook;
char *ref;
doublereal *cmat, *av;
logical *found;
ftnlen ref_len;
{
    /* Initialized data */

    static logical first = TRUE_;
    static integer oldid = 0;
    static integer ret = 1;

    static doublereal frac;
    extern /* Subroutine */ int ckr01_();
    static doublereal prec[8];
    static integer lidx, uidx;
    static doublereal rest;
    extern /* Subroutine */ int mxmt_(), linrot_g__(), ckgr01_();
    static integer ckref;
    static char segid[40];
    extern /* Subroutine */ int chkin_();
    static doublereal descr[5], lcmat[9]	/* was [3][3] */;
    extern /* Subroutine */ int dafus_(), errch_();
    static doublereal lprec[8];
    static integer nprec;
    static doublereal ucmat[9]	/* was [3][3] */;
    extern /* Subroutine */ int moved_();
    static doublereal uprec[8];
    static integer state;
    extern /* Subroutine */ int vlcom_();
    static integer nlook;
    static doublereal trans[9]	/* was [3][3] */, lstav[3], dc[2];
    static integer ic[6];
    extern logical failed_();
    static integer refcde, handle, begidx;
    static doublereal scldav[3];
    extern /* Subroutine */ int ckindx_(), ckgpav_seg__();
    static logical srchok;
    extern /* Subroutine */ int sigerr_();
    static doublereal lstclk, lstrec[8];
    extern integer intmin_();
    static doublereal clkout;
    static integer looklm;
    static doublereal lstmat[9]	/* was [3][3] */;
    extern /* Subroutine */ int setmsg_(), errint_();
    static integer lstidx, pcount;
    extern /* Subroutine */ int chkout_(), irfnum_(), irfrot_();
    extern logical return_();
    extern /* Subroutine */ int q2m_();
    static logical fnd;
    extern /* Subroutine */ int mxv_();


/* $ Abstract */

/*     Return pointing, interpolating to the requested time. */

/* $ Required_Reading */

/*     CK */

/* $ Keywords */

/*     POINTING */

/* $ Declarations */


/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */
/*     ID         I   NAIF integer code of instrument or s/c structure. */
/*     SCLKDP     I   Request time in ticks. */
/*     TOL        I   Maximum radius of interpolation interval. */
/*     MXLOOK     I   Maximum linear look-ahead count. */
/*     REF        I   Inertial reference frame. */
/*     CMAT       O   C-matrix. */
/*     AV         O   Angular velocity. */
/*     FOUND      O   Flag indicating whether pointing and a.v. were */
/*                    found. */

/* $ Detailed_Input */

/*     ID             is the NAIF integer code of a spacecraft */
/*                    structure or instrument for which pointing and */
/*                    angular velocity are desired. */

/*     SCLKDP         is the encoded spacecraft clock time for which */
/*                    pointing and angular velocity are desired. */

/*     TOL            is a tolerance value that controls the size of the */
/*                    interval over which interpolation is performed. */
/*                    If it is necessary to interpolate to return */
/*                    pointing for the request time, this routine will */
/*                    attempt to find two adjacent pointing instances */
/*                    whose time tags bracket the request time SCLKDP. */
/*                    Both of these bracketing times must be no further */
/*                    than TOL from SCLKDP; otherwise no pointing will */
/*                    be returned. */

/*     MXLOOK         is the maximum linear look-ahead count.  This */
/*                    count determines how far this routine will search */
/*                    linearly while attempting to find pointing */
/*                    instances that bracket a request time.  `Linear */
/*                    searching' refers to sequential reading of */
/*                    consecutive pointing instances.  If a linear */
/*                    search does not find suitable pointing after */
/*                    MXLOOK steps, the routine will perform a binary */
/*                    search for pointing. */

/*                    MXLOOK must be at least 1.  It can be adjusted */
/*                    to optimize performance. */

/*     REF        is the inertial reference frame desired for the */
/*                returned data. */

/*                See the SPICELIB routine CHGIRF for a complete list of */
/*                those frames supported by NAIF.  For example, 'J2000', */
/*                'B1950', 'FK4', and so on. */


/* $ Detailed_Output */

/*     CMAT           is a C-matrix representing pointing of the */
/*                    structure designated by ID, evaluated at the */
/*                    time SCLKDP.  The C-matrix transforms vectors from */
/*                    the specified inertial frame to the frame */
/*                    corresponding to the specified spacecraft */
/*                    structure: */

/*                       CMAT * V          =   V */
/*                               Inertial       Instrument */

/*                    When pointing is not available for the exact */
/*                    request time, pointing is interpolated using */
/*                    two pointing instances whose time tags are */
/*                    adjacent and bracket the request time.  The */
/*                    interpolation algorithm assumes constant */
/*                    angular velocity over the interpolation interval; */
/*                    the angle of rotation of the structure about this */
/*                    constant vector is interpolated with linear */
/*                    weighting to arrive at the result.  See the */
/*                    routine LINROT_G for details. */


/*     AV             is angular velocity of the specified structure, */
/*                    specified relative to FRAME.  When angular */
/*                    velocity is not available for the exact */
/*                    request time, it is interpolated using */
/*                    two angular velocity instances whose time tags are */
/*                    adjacent and bracket the request time.  The */
/*                    interpolation algorithm uses linear weighting. */


/*     FOUND          is a logical flag indicating whether pointing was */
/*                    obtained for the specified spacecraft structure */
/*                    or instrument and the specified time.  CMAT and AV */
/*                    are valid if and only if FOUND is TRUE. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     1)  If this routine is called before a C-kernel has been */
/*         loaded, the error will be diagnosed by routines called */
/*         by this routine. */

/*     2)  Only type 1 C-kernels may be used with this routine. */
/*         Attempting to load C-kernels containing segments of other */
/*         types will cause routines called by this routine to signal an */
/*         error. */

/*     3)  If there are not two available bracketing pointing instances */
/*         whose time tags are within TOL of SCLKDP, and if SCLKDP */
/*         is not the exact time tag of some pointing instance, the */
/*         flag FOUND will be set to FALSE. */

/*     4)  If MXLOOK is less than 1, the error SPICE(INVALIDLOOKAHEAD) */
/*         will be signalled. */

/*     5)  If the input inertial reference frame specifier REF is not */
/*         valid, the error SPICE(FRAMENOTRECOGNIZED) will be */
/*         signalled. */

/* $ Files */

/*     1)  One or more C-kernels containing pointing for the instrument */
/*         or spacecraft structure designated by ID should be loaded */
/*         at the time this routine is called. */

/* $ Particulars */

/*      This routine is intended to simplify obtaining interpolated */
/*      pointing from type 1 C-kernels. */

/* $ Examples */

/*     1)  Load a C-kernel for use by GETPNT, then look up pointing. */


/*         C */
/*         C     Initialization section... */
/*         C */
/*         C     Load a C-kernel. Also load Leapseconds and SCLK kernels. */
/*         C */
/*               CALL CKLPF  ( CK,  HANDLE         ) */

/*               CALL LDPOOL ( 'MYLEAPSECONDS.KER' ) */
/*               CALL LDPOOL ( 'MYSCLK.KER'        ) */
/*                                . */
/*                                . */
/*                                . */
/*         C */
/*         C     Look up pointing relative to J2000 coordinates for UTC */
/*         C     time 1994 Feb 4 12:35.  First convert the UTC time to */
/*         C     encoded spacecraft clock time. */
/*         C */
/*         C     In this example, we assume that the spacecraft clock */
/*         C     ID code SCLKID is derived from the ID code for */
/*         C     the spacecraft structure in question by dividing by */
/*         C     1000.  In any case, the ID code for the appropriate */
/*         C     clock should be used. */
/*         C */
/*               CLCKID = ID / 1000 */
/*               CALL UTC2ET ( '1994 Feb 4 12:35',  ET     ) */
/*               CALL SCE2T  (  CLCKID,  ET,            SCLKDP ) */

/*         C */
/*         C     Convert the tolerance value from seconds to ticks. */
/*         C     We'll use the parameter TKPSEC to represent the */
/*         C     number of seconds per tick.  In this example, we'll */
/*         C     arbitrarily pick a tolerance value of 5 seconds. */
/*         C     In your own code, the tolerance value should be based on */
/*         C     an analysis of the interpolation error and knowlege of */
/*         C     what magnitude of error is acceptable for your */
/*         C     application. */
/*         C */
/*               TOL  =  5.D0 * TKPSEC */

/*         C */
/*         C     Look up pointing.  If none was found, don't use the */
/*         C     returned values of CMAT or AV. */
/*         C */
/*               CALL GETPAV ( ID,   SCLKDP,  TOL,   MXLOOK, */
/*              .              REF,  CMAT,    AV,    FOUND   ) */

/*               IF ( FOUND ) THEN */

/*                  [ Use pointing ] */

/*               ELSE */

/*                  [ Handle exceptional case ] */

/*               END IF */

/* $ Restrictions */

/*     1)  At the time this routine is called, all loaded C-kernel */
/*         segments having an ID code matching the input argument ID */
/*         must have the following properties: */

/*            -- The segments must be type 1. */

/*            -- The segments must provide angular velocity data. */

/*     2)  No C-kernels accessed by this routine should be unloaded */
/*         between calls to this routine. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     N.J. Bachman   (JPL) */

/* $ Version */

/* -    Beta Version 1.0.0, 01-FEB-1994 (NJB) */

/* -& */

/* $ Index_Entries */

/*     get interpolated pointing and angular velocity */

/* -& */

/* $ Revisions */

/*     None. */

/* -& */

/*     SPICELIB functions */


/*     Local parameters */


/*     State values: */


/*     Local variables */


/*     Saved variables */


/*     Initial values */

    /* Parameter adjustments */
    --av;
    cmat -= 4;

    /* Function Body */

/*     Standard SPICE error handling. */

    if (return_()) {
	return 0;
    } else {
	chkin_("GETPAV", (ftnlen)6);
    }
/*     We start out without any pointing. */

    *found = FALSE_;
    if (first) {

/*        Initialize our previous handle value. */

	oldid = intmin_();
	first = FALSE_;
    }

/*     Determine the initial state.  If we're looking up data for a */
/*     different structure from last time, the number of valid points */
/*     left over is zero.  Otherwise, use the state value RET that was */
/*     set on the last pass. */

/*     RET defaults to FOUND0. */

    if (*id != oldid) {
	state = 1;
	oldid = *id;
    } else {
	state = ret;
	ret = 1;
    }

/*     Make sure the look-ahead limit is reasonable. */

    if (*mxlook < 1) {
	setmsg_("MXLOOK was #; should be at least 1.", (ftnlen)35);
	errint_("#", mxlook, (ftnlen)1);
	sigerr_("SPICE(INVALIDLOOKAHEAD)", (ftnlen)23);
	chkout_("GETPAV", (ftnlen)6);
	return 0;
    }

/*     Find the code for the input reference frame. */

    irfnum_(ref, &refcde, ref_len);
    if (refcde == 0) {
	setmsg_("The frame # was not recognized.", (ftnlen)31);
	errch_("#", ref, (ftnlen)1, ref_len);
	sigerr_("SPICE(FRAMENOTRECOGNIZED)", (ftnlen)25);
	chkout_("GETPAV", (ftnlen)6);
	return 0;
    }
/*     Now we enter a little finite state machine for finding pointing. */

    while(state != 11) {
	if (state == 1) {

/*           We make no assumptions about the previous state. */
/*           We just entered the loop.  Do a binary search for pointing. */

	    state = 4;
	} else if (state == 2) {

/*           We just entered the loop.  The previous state was BING01. */
/*           The following values are left over from last time: */

/*              LSTIDX   LSTREC  LSTMAT  LSTCLK */
/*              HANDLE   DESCR   DC      IC      PCOUNT */

/*           Unless the request time matches LSTCLK, we'll have to */
/*           search for bracketing pointing. */

	    if (*sclkdp < dc[0] || *sclkdp > dc[1]) {

/*              If the request time is not covered by the previously */
/*              used segment, we'll have to start from scratch. */

		state = 4;
	    } else if (*sclkdp > lstclk) {

/*              Look ahead for an upper bracketing pointing instance. */

		moved_(lstrec, &c__8, lprec);
		q2m_(&lprec[1], lcmat);
		begidx = lstidx;
		looklm = *mxlook;
		srchok = TRUE_;
		state = 7;

/*              BEGIDX, LCMAT, and LPREC are set.  SCLKDP > LPREC(1). */

	    } else if (*sclkdp < lstclk) {

/*              Look backwards for a lower bracketing pointing instance. */

		moved_(lstrec, &c__8, uprec);
		q2m_(&uprec[1], ucmat);
		begidx = lstidx;
		looklm = *mxlook;
		srchok = TRUE_;
		state = 8;

/*              BEGIDX, UCMAT, and UPREC are set.  SCLKDP < UPREC(1). */

	    } else {

/*             The request time matches the previous request time */
/*              exactly. */

		state = 9;
	    }

/*           STATE is one of {BINGO1, LOOKB, LOOKF}. */

	} else if (state == 3) {

/*           We just entered the loop.  The previous state was one of */

/*              {FOUND2, INTERP}. */

/*           We have two distinct, valid, bracketing pointing instances */
/*           left over from last time, in addition to having saved the */
/*           returned pointing.  The leftover values are: */

/*              LSTMAT   LSTCLK  LSTAV */
/*              LPREC    UPREC   LCMAT  UCMAT  UIDX    LIDX */
/*              HANDLE   DESCR   DC     IC     PCOUNT */

/*           If the request time matches the previous request time, or if */
/*           the previous bracketing times bracket the current request */
/*           time, we can avoid searching for pointing. */

	    if (*sclkdp < dc[0] || *sclkdp > dc[1]) {

/*              If the request time is not covered by the previously */
/*              used segment, we'll have to start from scratch. */

		state = 4;
	    } else if (*sclkdp == lprec[0]) {

/*              The request time matches the lower bracketing time */
/*               exactly. */

		moved_(lcmat, &c__9, lstmat);
		moved_(&lprec[5], &c__3, lstav);
		state = 10;
	    } else if (*sclkdp == uprec[0]) {

/*              The request time matches the upper bracketing time */
/*               exactly. */

		moved_(ucmat, &c__9, lstmat);
		moved_(&uprec[5], &c__3, lstav);
		state = 10;
	    } else if (*sclkdp == lstclk) {

/*              The request time matches the last request time exactly. */

		state = 10;
	    } else if (*sclkdp > lprec[0] && *sclkdp < uprec[0]) {

/*              The current request time is bracketed by the previous */
/*              bracketing times. */

/*              We have LPREC(1) < SCLKDP < UPREC(1), with strict */
/*              inequality. */

		state = 5;
	    } else if (*sclkdp > uprec[0]) {

/*              The request time exceeds the previous upper bracketing */
/*              time. */

		moved_(ucmat, &c__9, lcmat);
		moved_(uprec, &c__8, lprec);
		begidx = uidx;
		looklm = *mxlook;
		srchok = TRUE_;
		state = 7;

/*              BEGIDX, LCMAT, and LPREC are set.  SCLKDP > LPREC(1). */

	    } else {

/*              The only other possibility is SCLKDP .LT. LPREC(1)., that */
/*              is, the request time is earlier than the previous lower */
/*              bracketing time. */

		moved_(lcmat, &c__9, ucmat);
		moved_(lprec, &c__8, uprec);
		begidx = lidx;
		looklm = *mxlook;
		srchok = TRUE_;
		state = 8;

/*              BEGIDX, UCMAT, and UPREC are set.  SCLKDP < UPREC(1). */

	    }

/*           STATE is set to any of {LOOKB, LOOKF, BRCKET, BINGO2}. */

	} else if (state == 7) {

/*           The previous state was one of {FOUND1, FOUND2, SEARCH}. */

/*           Look forward linearly for the first pointing instance having */
/*           a time tag greater than or equal to the request time. */

/*           BEGIDX, LCMAT, and LPREC are set.  SCLKDP > LPREC(1). */
/*           SRCHOK and LOOKLM are set also. */

	    if (begidx == pcount) {

/*              We're out of pointing. */

		state = 11;
	    } else {

/*              Look for an upper bracketing pointing instance. */

		lidx = begidx;
		uidx = begidx + 1;
		ckgr01_(&handle, descr, &uidx, uprec);
		if (failed_()) {
		    chkout_("GETPAV", (ftnlen)6);
		    return 0;
		}
		nlook = 1;
		while(*sclkdp > uprec[0] && uidx < pcount && nlook < looklm) {
		    moved_(uprec, &c__8, lprec);
		    lidx = uidx;
		    ++uidx;
		    ckgr01_(&handle, descr, &uidx, uprec);
		    if (failed_()) {
			chkout_("GETPAV", (ftnlen)6);
			return 0;
		    }
		    ++nlook;
		}
		if (*sclkdp > uprec[0]) {
		    if (uidx == pcount) {

/*                    We're out of pointing instances to look at. */

			state = 11;
		    } else if (srchok) {

/*                    It's time to abandon linear searching. */

			state = 4;
		    } else {

/*                    No joy. */

			state = 11;
		    }
		} else if (*sclkdp == uprec[0]) {

/*                 We have an exact hit. */

/*                    LPREC   UPREC   LIDX   UIDX */

/*                 are already set.  We must set */

/*                    LCMAT */
/*                    UCMAT */
/*                    LSTMAT */
/*                    LSTAV */

		    q2m_(&lprec[1], lcmat);
		    q2m_(&uprec[1], ucmat);
		    moved_(ucmat, &c__9, lstmat);
		    moved_(&uprec[5], &c__3, lstav);

/*                 We now have two valid, adjacent pointing values. */

		    state = 10;
		} else {

/*                 We have LPREC(1) < SCLKDP < UPREC(1), with strict */
/*                 inequality. */

/*                    LPREC  UPREC  LIDX  UIDX */

/*                 are already set. */

		    state = 5;
		}

/*              STATE is one of {BINGO2, SEARCH, BRCKET, TERM}. */

	    }

/*           STATE is one of {BINGO2, SEARCH, BRCKET, TERM}. */

	} else if (state == 8) {

/*           The previous state was one of {FOUND1, FOUND2, SEARCH}. */

/*           Look backwards linearly for the first pointing instance */
/*           having a time tag less than or equal to the request time. */

/*           BEGIDX, UCMAT, and UPREC are set.  SCLKDP < UPREC(1). */
/*           SRCHOK and LOOKLM are set also. */

	    if (begidx == 1) {

/*              We're out of pointing. */

		state = 11;
	    } else {

/*              Look for an lower bracketing pointing instance. */

		uidx = begidx;
		lidx = begidx - 1;
		ckgr01_(&handle, descr, &lidx, lprec);
		if (failed_()) {
		    chkout_("GETPAV", (ftnlen)6);
		    return 0;
		}
		nlook = 1;
		while(*sclkdp < lprec[0] && lidx > 1 && nlook < looklm) {
		    moved_(lprec, &c__8, uprec);
		    uidx = lidx;
		    --lidx;
		    ckgr01_(&handle, descr, &lidx, lprec);
		    if (failed_()) {
			chkout_("GETPAV", (ftnlen)6);
			return 0;
		    }
		    ++nlook;
		}
		if (*sclkdp < lprec[0]) {
		    if (lidx == 1) {

/*                    We're out of pointing instances to look at. */

			state = 11;
		    } else if (srchok) {

/*                    It's time to abandon linear searching. */

			state = 4;
		    } else {

/*                    No joy. */

			state = 11;
		    }
		} else if (*sclkdp == lprec[0]) {

/*                 We have an exact hit. */

/*                    LPREC   UPREC   LIDX   UIDX */

/*                 are already set.  We must set */

/*                    LCMAT   UCMAT  LSTMAT   LSTAV */

		    q2m_(&lprec[1], lcmat);
		    q2m_(&uprec[1], ucmat);
		    moved_(lcmat, &c__9, lstmat);
		    moved_(&lprec[5], &c__3, lstav);

/*                 We now have two valid, adjacent pointing values. */

		    state = 10;
		} else {

/*                 We have LPREC(1) < SCLKDP < UPREC(1), with strict */
/*                 inequality. */

/*                    LPREC   UPREC   LIDX   UIDX */

/*                 are already set. */

		    state = 5;
		}

/*              STATE is one of {BINGO2, SEARCH, BRCKET, TERM}. */

	    }

/*           STATE is one of {BINGO2, SEARCH, BRCKET, TERM}. */

	} else if (state == 4) {

/*           The previous state was one of {FOUND0, LOOKF, LOOKB}. */

/*           Do a binary search for the pointing instance having the */
/*           closest time tag to the request time. */

/*           Find the closest pointing instance to the request time.  Ask */
/*           for angular velocity (NEEDAV = TRUE) as well as pointing. */

	    ckgpav_seg__(id, sclkdp, tol, ref, &cmat[4], &av[1], &clkout, 
		    segid, descr, &handle, &fnd, ref_len, (ftnlen)40);
	    if (failed_() || ! fnd) {
		chkout_("GETPAV", (ftnlen)6);
		return 0;
	    }

/*           Save the reference frame code for the segment in which */
/*           pointing was found. */

	    dafus_(descr, &c__2, &c__6, dc, ic);
	    ckref = ic[1];

/*           Use the handle and descriptor returned by CKGPAV_G to obtain */
/*           the raw pointing record. */

	    ckr01_(&handle, descr, sclkdp, tol, &c_true, prec, &fnd);
	    if (failed_() || ! fnd) {
		chkout_("GETPAV", (ftnlen)6);
		return 0;
	    }

/*           Find the index within the segment of the returned record */
/*           and the total count of records within the segment. */

	    ckindx_(&nprec, &pcount);
	    if (prec[0] == *sclkdp) {

/*              An exact hit. */

		q2m_(&prec[1], lstmat);
		moved_(prec, &c__8, lstrec);
		lstidx = nprec;
		lstclk = *sclkdp;
		state = 9;
	    } else if (prec[0] < *sclkdp) {

/*              Search forward for the next pointing instance, */
/*              with a look-ahead limit of 1 and binary searching */
/*              inhibited. */

		moved_(prec, &c__8, lprec);
		q2m_(&prec[1], lcmat);
		begidx = nprec;
		srchok = FALSE_;
		looklm = 1;
		state = 7;
	    } else {

/*              Search backwards for the previous pointing instance, */
/*              with a look-ahead limit of 1 and binary searching */
/*              inhibited. */

		moved_(prec, &c__8, uprec);
		q2m_(&prec[1], ucmat);
		begidx = nprec;
		srchok = FALSE_;
		looklm = 1;
		state = 8;
	    }

/*           STATE is one of {BINGO1, LOOKF, LOOKB}. */

	} else if (state == 5) {

/*           The previous state was one of {FOUND2, LOOKF, LOOKB}. */

/*           The request time is bracketed between two times belonging */
/*           to adjacent pointing instances.  The request time does not */
/*           equal either of these boundary times.  If the request time */
/*           is within distance TOL of each boundary time, we can */
/*           interpolate. */

/*              LPREC  UPREC  LIDX  UIDX */

/*           are already set.  LPREC(1) < SCLKDP < UPREC(1). */


	    if (*sclkdp - lprec[0] < *tol && uprec[0] - *sclkdp < *tol) {

/*              If we made it this far, we can interpolate using LPREC */
/*              and UPREC.  Convert the quaternions to C-matrices at this */
/*              point. */

		q2m_(&lprec[1], lcmat);
		q2m_(&uprec[1], ucmat);
		state = 6;
	    } else {

/*              We already have the two instances closest to the */
/*              request time, and at least one of these isn't close */
/*              enough.  This was the last chance. */

		state = 11;
	    }

/*           STATE is one of {INTERP, TERM}. */

	} else if (state == 6) {

/*           The previous state was BRCKET. */

/*           Interpolate pointing for the request time using two */
/*           bracketing pointing instances. */

/*           At this point, we've found the matrices LCMAT and UCMAT to */
/*           use for interpolation. */

/*           The moment we've all been waiting for. */

	    frac = (*sclkdp - lprec[0]) / (uprec[0] - lprec[0]);
	    rest = 1. - frac;
	    linrot_g__(lcmat, ucmat, &frac, &cmat[4], scldav);

/*           Rather than using the average angular velocity derived */
/*           from the interpolation, we'll use the weighted average */
/*           of the bracketing a.v. values. */

	    vlcom_(&frac, &uprec[5], &rest, &lprec[5], &av[1]);
	    moved_(&cmat[4], &c__9, lstmat);
	    moved_(&av[1], &c__3, lstav);
	    lstclk = *sclkdp;

/*           Convert the outputs to the desired frame, if necessary. */

	    if (refcde != ckref) {
		irfrot_(&ckref, &refcde, trans);
		if (failed_()) {
		    chkout_("GETPAV", (ftnlen)6);
		    return 0;
		}
		mxmt_(&cmat[4], trans, &cmat[4]);
		mxv_(trans, &av[1], &av[1]);
	    }

/*           The saved variables */

/*              LPREC   UPREC  LCMAT  UCMAT  UIDX  LIDX */
/*              LSTMAT  LSTAV  LSTCLK */

/*           are set. */

	    *found = TRUE_;
	    ret = 3;
	    state = 11;
	} else if (state == 9) {

/*           The previous state was one of {FOUND1, SEARCH}. */

/*           We already have the pointing and angular velocity for the */
/*           request time. */

/*              LSTIDX    LSTCLK   LSTREC   LSTMAT */

/*           are already set. */

	    moved_(lstmat, &c__9, &cmat[4]);
	    moved_(&lstrec[5], &c__3, &av[1]);

/*           Convert the outputs to the desired frame, if necessary. */

	    if (refcde != ckref) {
		irfrot_(&ckref, &refcde, trans);
		if (failed_()) {
		    chkout_("GETPAV", (ftnlen)6);
		    return 0;
		}
		mxmt_(&cmat[4], trans, &cmat[4]);
		mxv_(trans, &av[1], &av[1]);
	    }
	    *found = TRUE_;
	    ret = 2;
	    state = 11;
	} else if (state == 10) {

/*          The previous state was one of {FOUND2, LOOKF, LOOKB}. */

/*          The current request time matches the either the previous */
/*          request time or one of the previous bracketing times. */

/*              LPREC   UPREC   LCMAT   UCMAT   LIDX   UIDX */
/*              LSTMAT  LSTAV */

/*           are already set. */


/*              LSTCLK  CMAT  AV */

/*           still need to be set. */


	    moved_(lstmat, &c__9, &cmat[4]);
	    moved_(lstav, &c__3, &av[1]);

/*           Convert the outputs to the desired frame, if necessary. */

	    if (refcde != ckref) {
		irfrot_(&ckref, &refcde, trans);
		if (failed_()) {
		    chkout_("GETPAV", (ftnlen)6);
		    return 0;
		}
		mxmt_(&cmat[4], trans, &cmat[4]);
		mxv_(trans, &av[1], &av[1]);
	    }
	    lstclk = *sclkdp;
	    *found = TRUE_;
	    ret = 3;
	    state = 11;
	}
    }

/*     FOUND is set. */

/*     RET is set.  RET is FOUND0 unless pointing was found. */

    chkout_("GETPAV", (ftnlen)6);
    return 0;
} /* getpav_ */

#ifdef uNdEfInEd
comments from the converter:  (stderr from f2c)
   getpav:
#endif
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create getpav_c.c
$ DECK/DOLLARS="$ VOKAGLEVE"
#include "SpiceUsr.h"
#include "SpiceZfc.h"
#include "SpiceZmc.h"

   void getpav_c ( SpiceInt            inst, 
                   SpiceDouble         sclkdp, 
                   SpiceDouble         tol, 
                   SpiceInt            mxlook,
                   ConstSpiceChar    * ref, 
                   SpiceDouble         cmat[3][3], 
                   SpiceDouble         av[3],
                   SpiceBoolean      * found      ) 

{ /* Begin getpav_c */


   /*
   Participate in error handling
   */
   chkin_c ( "getpav_c");
   

   /*
   Check the input string ref to make sure the pointer is non-null 
   and the string length is non-zero.
   */
   CHKFSTR ( CHK_STANDARD, "getpav_c", ref );
   
      
   getpav_( ( integer    * ) &inst, 
            ( doublereal * ) &sclkdp, 
            ( doublereal * ) &tol,
            ( integer    * ) &mxlook, 
            ( char       * ) ref, 
            ( doublereal * ) cmat, 
            ( doublereal * ) av, 
            ( logical    * ) found, 
            ( ftnlen       ) strlen(ref) );

   /*
   Transpose the c-matrix on output.
   */
   xpose_c ( cmat, cmat );
   
   
   chkout_c ( "getpav_c");

} /* End getpav_c */
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create linrot_g.c
$ DECK/DOLLARS="$ VOKAGLEVE"
/*  -- translated by f2c (version 19980908).
   You must link the resulting object file with the libraries:
	-lf2c -lm   (in that order)
*/

#include "f2c.h"

/* Table of constant values */

static doublereal c_b3 = 1e-8;

/* $Procedure    LINROT_G ( Linear interpolation between rotations ) */
/* Subroutine */ int linrot_g__(init, final, frac, r__, scldav)
doublereal *init, *final, *frac, *r__, *scldav;
{
    /* System generated locals */
    doublereal d__1;

    /* Local variables */
    static doublereal axis[3];
    extern /* Subroutine */ int vscl_(), mxmt_(), mtxv_();
    static doublereal q[9]	/* was [3][3] */, angle, delta[9]	/* 
	    was [3][3] */;
    extern /* Subroutine */ int chkin_();
    extern logical isrot_();
    extern /* Subroutine */ int raxisa_(), axisar_(), sigerr_(), chkout_(), 
	    setmsg_();
    extern logical return_();
    extern /* Subroutine */ int mxm_();

/* $ Abstract */

/*     Interpolate between two rotations using a constant angular rate. */

/* $ Required_Reading */

/*     ROTATIONS */

/* $ Keywords */

/*     GLLSPICE */
/*     MATRIX */
/*     ROTATION */

/* $ Declarations */
/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */
/*     INIT       I   Initial rotation. */
/*     FINAL      I   Final rotation. */
/*     FRAC       I   Fraction of rotation from INIT to FINAL by which */
/*                    to interpolate. */
/*     R          O   Linearly interpolated rotation. */
/*     SCLDAV     O   Scaled angular velocity of rotation. */

/* $ Detailed_Input */

/*     INIT, */
/*     FINAL, */
/*     FRAC           are, respectively, two rotation matrices between */
/*                    which to interpolate, and an interpolation */
/*                    fraction. */

/* $ Detailed_Output */

/*     R              is the matrix resulting from linear interpolation */
/*                    between INIT and FINAL by the fraction FRAC.  By */
/*                    `linear interpolation' we mean the following: */

/*                       We view INIT and FINAL as two values of a */
/*                       time-varying rotation matrix R(t) that rotates */
/*                       at a constant angular velocity (that is, the */
/*                       row vector of R(t) rotate with constant angular */
/*                       velocity).  We can say that */

/*                          INIT   =  R(t0) */
/*                          FINAL  =  R(t1). */

/*                       `Linear interpolation by the fraction FRAC' */
/*                       means that we evalute R(t) at time */

/*                          t0   +   FRAC * (t1 - t0). */


/*     SCLDAV         is a scaled version of the constant angular */
/*                    velocity vector used for interpolation.  When */
/*                    SCLDAV is divided by the scale factor */

/*                       t1 - t0, */

/*                    the result is the constant angular velocity */
/*                    assumed for the rows of R(t) in order to perform */
/*                    linear interpolation. */


/*                    Note that SCLDAV is NOT parallel to the rotation */
/*                    axis of */
/*                                   T */
/*                       FINAL * INIT ; */

/*                    if this is unclear, see $Particulars below for */
/*                    details. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     1)  If either of INIT or FINAL is not a rotation matrix, the error */
/*         SPICE(NOTAROTATION) is signalled. */

/*     2)  This routine assumes that the rotation that maps INIT to FINAL */
/*         has a rotation angle THETA radians, where */

/*            0  <  THETA  <  pi. */
/*               _ */

/*         This routine cannot distinguish between rotations of THETA */
/*         radians, where THETA is in the interval [0, pi), and */
/*         rotations of */

/*            THETA   +   2 * k * pi */

/*         radians, where k is any integer.  These `large' rotations will */
/*         yield invalid results when interpolated.  You must ensure that */
/*         the inputs you provide to this routine will not be subject to */
/*         this sort of ambiguity.  If in fact you are interpolating the */
/*         position of a rotating matrix with constant angular velocity */
/*         AV between times t0 and t1, you must ensure that */

/*            || AV ||  *  |t1 - t0|   <   pi. */

/*         Here we assume that the magnitude of AV is the angular rate */
/*         of the rotating matrix in units of radians per second. */


/*     3)  When FRAC is outside of the interval [0, 1], the process */
/*         performed is `extrapolation', not interpolation.  Such */
/*         values of FRAC are permitted. */

/* $ Files */

/*     None. */

/* $ Particulars */

/*     In the discussion below, we assume that the conditions specified */
/*     in item (3) of $ Exceptions have been satisfied. */

/*     The definition of the output of this routine merits a little */
/*     analysis.  As we've said, we view INIT and FINAL as two values */
/*     of a time-varying rotation matrix R(t) that rotates at a constant */
/*     angular velocity; we define R(t), t0, and t1 so that */

/*        INIT   =  R(t0) */
/*        FINAL  =  R(t1). */

/*     The output matrix R is R(t) evaluated at the time */

/*        t0   +   FRAC * (t1 - t0). */

/*     How do we evaluate R at times between t0 and t1?  Since */

/*                              T */
/*        FINAL = ( FINAL * INIT  ) * INIT, */

/*     we can write */

/*        FINAL = M * INIT */

/*     or */

/*        R(t1) = M * R(t0), */

/*     and we can find a rotation axis A and an angle THETA such that M */
/*     is a coordinate system rotation of THETA radians about axis A. */

/*     Let's use the notation */

/*        [ x ] */
/*             N */

/*     to indicate a coordinate system rotation of x radians about the */
/*     vector N.  Having found A and THETA, we can write */

/*                            (t  - t0) */
/*        R(t) =  [  THETA *  ---------  ]     *   R(t0) */
/*                            (t1 - t0)    A */

/*     By the way, the input argument FRAC plays the role of the quotient */

/*        t  - t0 */
/*        ------- */
/*        t1 - t0 */

/*     shown above. */


/*     Now, about SCLDAV:  If the rotation matrix M has property that */

/*             T              T */
/*        FINAL   =   M * INIT , */

/*     or equivalently */

/*             T               T */
/*        R(t1)   =   M * R(t0), */

/*     then M maps the rows of INIT to the rows of FINAL.  The rotation */
/*     axis of M is parallel to the angular velocity vector of the rows */
/*     of R(t).  The angular rate of R(t) (assuming R(t) has contant */
/*     angular velocity between times t0 and t1) is the rotation angle */
/*     of M divided by */

/*        t1 - t0. */

/*     So SCLDAV is a vector parallel to the rotation axis of M and */
/*     having length equal to the rotation angle of M (which is in */
/*     the range [0, pi]). */

/*     Now */
/*                        T */
/*        FINAL = INIT * M , */

/*     so */
/*                    T            T       T */
/*        FINAL * INIT  =  INIT * M  * INIT . */

/*     Let's define the matrix Q as */

/*                    T */
/*        FINAL * INIT ; */

/*     then since the right side of the last equation is just a */
/*     change-of-basis transformation, we know that Q is just */

/*         T */
/*        M , */

/*     expressed relative to the basis whose elements are the rows of */
/*     INIT.  Since these matrices represent the same rotation, the */
/*     rotation axis of Q is the rotation axis of */

/*         T */
/*        M, */

/*     expressed relative to the basis whose elements are the rows of */
/*     INIT.   Call these rotation axes AXIS_Q and AXIS_MT respectively. */
/*     Then since left multiplication by INIT transforms vectors to the */
/*     basis whose elements are the rows of INIT, */

/*        AXIS_Q = INIT * AXIS_MT, */

/*     which implies that */

/*              T */
/*        - INIT  * AXIS_Q */

/*     is the rotation axis of M (this axis is chosen so that the */
/*     rotation angle is non-negative). */


/* $ Examples */

/*     1)  Suppose we want to interpolate between two rotation matrices */
/*         R1 and R2 that give the orientation of a spacecraft structure */
/*         at times t1 and t2.  We wish to find an approximation of the */
/*         structure's orientation at the midpoint of the time interval */
/*         [t1, t2].  We assume that the angular velocity of the */
/*         structure equals the constant AV between times t1 and t2.  We */
/*         also assume that */

/*            || AV ||  *  (t2 - t1)   <   pi. */

/*         Then the code fragment */

/*            CALL LINROT_G ( R1, R2, 0.5D0, R, SCLDAV ) */

/*         produces the approximation we desire. */


/*     2)  Suppose R1 is the identity and R2 is */

/*            [ pi/2 ] . */
/*                    3 */

/*         Then the code fragment */

/*            CALL LINROT_G ( R1, R2, FRAC, R, SCLDAV ) */

/*         returns SCLDAV as the vector */

/*            ( 0, 0, pi/2 ). */


/*     3)  As long as R1 and R2 are not equal, the code fragment */

/*            CALL LINROT_G ( R1,     R2,            FRAC,  R,  SCLDAV ) */
/*            CALL AXISAR   ( SCLDAV, VORM(SCLDAV),  M                 ) */
/*            CALL MXMT     ( R1,     M,             R2                ) */

/*         should leave R2 unchanged, except for round-off error. */

/* $ Restrictions */

/*     None. */

/* $ Literature_References */

/*     None. */

/* $ Author_and_Institution */

/*     N.J. Bachman   (JPL) */

/* $ Version */

/* -    GLLSPICE Version 1.0.1, 10-MAR-1992 (WLT) */

/*        Comment section for permuted index source lines was added */
/*        following the header. */

/* -    GLLSPICE Version 1.0.0, 20-NOV-1990 (NJB) */

/* -& */
/* $ Index_Entries */

/*     linear interpolation between rotations */

/* -& */

/*     SPICELIB functions */


/*     Local parameters */


/*     NTOL and DTOL are tolerances used for determining whether INIT */
/*     and FINAL are rotation matrices.  NTOL is bound on the deviation */
/*     of the norms of the columns of a matrix from 1, and DTOL is a */
/*     bound on the deviation of the determinant of a matrix from 1. */


/*     Local variables */


/*     Standard SPICE error handling. */

    /* Parameter adjustments */
    --scldav;
    r__ -= 4;
    final -= 4;
    init -= 4;

    /* Function Body */
    if (return_()) {
	return 0;
    } else {
	chkin_("LINROT_G", (ftnlen)8);
    }

/*     INIT and FINAL must both be rotation matrices. */

    if (! isrot_(&init[4], &c_b3, &c_b3)) {
	setmsg_("INIT is not a rotation.", (ftnlen)23);
	sigerr_("SPICE(LINROT_G)", (ftnlen)15);
	chkout_("LINROT_G", (ftnlen)8);
	return 0;
    } else if (! isrot_(&final[4], &c_b3, &c_b3)) {
	setmsg_("INIT is not a rotation.", (ftnlen)23);
	sigerr_("SPICE(LINROT_G)", (ftnlen)15);
	chkout_("LINROT_G", (ftnlen)8);
	return 0;
    }

/*     Little to do, really.  Let */

/*        FINAL  =   Q      *   INIT; */

/*     then */
/*                                  T */
/*        Q      =   FINAL  *   INIT. */


/*     Find an axis and angle for the quotient rotation Q, and */
/*     interpolate the angle.  Form the interpolated rotation DELTA. */
/*     DELTA is not affected by the fact that RAXISA chooses an axis and */
/*     angle that describe the effect of Q on vectors rather than on */
/*     coordinate frames.  Since RAXISA and AXISAR are compatible, the */
/*     interpolation works anyway. */

    mxmt_(&final[4], &init[4], q);
    raxisa_(q, axis, &angle);
    d__1 = angle * *frac;
    axisar_(axis, &d__1, delta);
    mxm_(delta, &init[4], &r__[4]);

/*     Finding the `constant' angular velocity vector is easy to do; */
/*     it may take a moment to see why this works, though.  (See the */
/*     $Particulars section of the header if you find this too obscure). */

    mtxv_(&init[4], axis, &scldav[1]);
    d__1 = -angle;
    vscl_(&d__1, &scldav[1], &scldav[1]);
    chkout_("LINROT_G", (ftnlen)8);
    return 0;
} /* linrot_g__ */

#ifdef uNdEfInEd
comments from the converter:  (stderr from f2c)
   linrot_g:
#endif
$ VOKAGLEVE
$!-----------------------------------------------------------------------------
$ create ls2ins.c
$ DECK/DOLLARS="$ VOKAGLEVE"

/*  -- translated by f2c (version 19980908).
   You must link the resulting object file with the libraries:
	-lf2c -lm   (in that order)
*/

#include "f2c.h"

/* Table of constant values */

static doublereal c_b3 = 0.;
static integer c__2 = 2;

/* $Procedure      LS2INS (line and sample to instrument coordinates) */
/* Subroutine */ int ls2ins_(l0, s0, alpha, k, fl, l, s, vinst)
doublereal *l0, *s0, *alpha, *k, *fl, *l, *s, *vinst;
{
    /* System generated locals */
    doublereal d__1, d__2;

    /* Local variables */
    static doublereal vrls[2];
    extern /* Subroutine */ int chkin_(), vpack_(), vhatg_(), vsclg_(), 
	    chkout_();
    extern doublereal vnormg_();
    extern logical return_();
    static doublereal rmm, rls, rmm0, rmm1;

/* $ Abstract */

/*     Map line and sample coordinates to instrument coordinates. */

/* $ Required_Reading */


/* $ Keywords */

/*     CAMERA */
/*     CONVERSION */

/* $ Declarations */
/* $ Brief_I/O */

/*     Variable  I/O  Description */
/*     --------  ---  -------------------------------------------------- */
/*     L0, */
/*     S0         I   Line, sample coordinates of FOV center. */
/*     ALPHA      I   Distortion coefficient */
/*     K          I   Pixel size */
/*     FL         I   Focal length of instrument. */
/*     L, */
/*     S          I   Line, sample coordinates */
/*     VINST      O   Vector in instrument coordinates. */

/* $ Detailed_Input */

/*     L0, */
/*     S0          are the line and sample coordinates of the center of */
/*                 the field of view. */

/*     ALPHA       is the coefficient of radially symmetric optical */
/*                 distortion, in units of 1/(mm**2). */

/*     K           is the number of pixels per mm. */

/*     FL          is the focal length of the instrument in mm. */

/*     L, */
/*     S           are line and sample coordinates. The origin is located */
/*                 in the upper left corner of the field of view, as shown */
/*                 in the figure below. n and m are the dimensions of the */
/*                 FOV. */

/*                  sample                                  sample */
/*                    1                         S             n */
/*                     -------------------------+------------- */
/*             Line 1 |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                         *             + L */
/*                    |                         (L,S)         | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*                    |                                       | */
/*           Line m   |                                       | */
/*                     --------------------------------------- */

/* $ Detailed_Output */

/*     VINST       is the ray from the point through the focal point, */
/*                 in instrument coordinates. */

/* $ Parameters */

/*     None. */

/* $ Exceptions */

/*     None. */

/* $ Files */

/*     None. */

/* $ Particulars */

/*     This subroutine converts line, sample coordinates to millimeter */
/*     space coordinates using the distortion model described in */
/*     reference [1]. */

/* $ Examples */

/*     None. */

/* $ Restrictions */

/*     None. */

/* $ Literature_References */

/*     [1]   ``Models of the Clementine Spacecraft and Remote Sensing */
/*             Science Instruments for Geodesy, Cartography, and */
/*             Dynamical Sciences'', Draft version 1.0, December 1993. */

/* $ Author_and_Institution */

/*     M.J. Spencer   (JPL) */

/* $ Version */

/* -    Beta Version 1.0.0, 05-JAN-1994 (MJS) */

/* -& */
/* $ Index_Entries */

/*     line and sample to x y to instrument fixed */

/* -& */

/*     SPICELIB functions */


/*     Local parameters */


/*     TOL         is the accuracy used when calculating the inverse */
/*                 of the distortion function.  TOL is explained in more */
/*                 detail below. */


/*     Local variables */


/*     Statement functions.  These are used to calculate the inverse */
/*     of the distortion function. */


/*     Standard SPICE error handling. */

    /* Parameter adjustments */
    --vinst;

    /* Function Body */
    if (return_()) {
	return 0;
    } else {
	chkin_("LS2INS", (ftnlen)6);
    }

/*     If L and S are at the center of the FOV, return [0,0,1] */
/*     We also don't want to proceed if K is zero (LIDAR). */

    if (*s - *s0 == 0. && *l - *l0 == 0. || *k == 0.) {
/*     Changed by Thomas Roatsch, DLR, 29-Jun-1995 */
/*     We need the UNNORMALIZED VECTOR */
	vpack_(&c_b3, &c_b3, fl, &vinst[1]);
/*         CALL VPACK  (0.0D0, 0.0D0, 1.0D0, VINST) */
	chkout_("LS2INS", (ftnlen)6);
	return 0;
    }

/*     Find the vector pointing from the center of the field of view to */
/*     L and S. RLS is the magnitude of the vector and VRLS is its */
/*     direction. The vector should be in millimeters. */

    vrls[0] = (*s - *s0) / *k;
    vrls[1] = (*l - *l0) / *k;
    rls = vnormg_(vrls, &c__2);
    vhatg_(vrls, &c__2, vrls);

/*     Now find RMM, the distance in millimeter space from center of the */
/*     field of view to the point.  RLS and RMM are related to each other */
/*     by the following equation: */

/*        F(RMM) = ALPHA*RMM**3 + RMM - RLS = 0 */

/*     where A is the distortion coefficient.  The Newton-Raphson */
/*     method will be used to to find RMM.  In order to use */
/*     this method the derivative of F(RMM), F'(RMM), must be found. */
/*     The above equation is easily differentiable.  F'(RMM) is: */

/*        F'(RMM) = 3*ALPHA*RMM**2 + 1 */

/*     The Newton-Raphson iteration formula is */

/*        RMM  =  RMM    -  [ F(RMM)/F'(RMM) ] */
/*           i       i-1 */

/*     F'(RMM) will never be zero, therefore, the fraction in the */
/*     above formula will never explode on us.  The code below will */
/*     iterate until the absolute difference between RMM-values is less */
/*     than TOL. */

/*     The first guess, RMM  , will be RLS. */
/*                         0 */

    rmm0 = rls;
/* Computing 3rd power */
    d__1 = rmm0;
/* Computing 2nd power */
    d__2 = rmm0;
    rmm1 = rmm0 - (*alpha * (d__1 * (d__1 * d__1)) + rmm0 - rls) / (*alpha * 
	    3 * (d__2 * d__2) + 1);
    while((d__1 = rmm1 - rmm0, abs(d__1)) > 1e-10) {
	rmm0 = rmm1;
/* Computing 3rd power */
	d__1 = rmm0;
/* Computing 2nd power */
	d__2 = rmm0;
	rmm1 = rmm0 - (*alpha * (d__1 * (d__1 * d__1)) + rmm0 - rls) / (*
		alpha * 3 * (d__2 * d__2) + 1);
    }
    rmm = rmm1;

/*     Now find X and Y.  The origin is at the center of the field of */
/*     view.  The direction of the vector (X, Y) is the same as VRLS, */
/*     therefore we only need to scale the vector VRLS by RMM. */

    vsclg_(&rmm, vrls, &c__2, vrls);
    vpack_(vrls, &vrls[1], fl, &vinst[1]);

/*     Changed by Thomas Roatsch, DLR, 14-DEC-1994 */
/*     We need the UNNORMALIZED VECTOR */
/*      CALL VHAT  (VINST, VINST) */


/*     That's it. */

    chkout_("LS2INS", (ftnlen)6);
    return 0;
} /* ls2ins_ */

#ifdef uNdEfInEd
comments from the converter:  (stderr from f2c)
   ls2ins:
#endif
$ VOKAGLEVE
$ Return
$!#############################################################################
$Imake_File:
$ create cltspice_sub_c.imake
/* Imake file for VICAR subroutine  CLTSPICE_SUB   */
#define SUBROUTINE   cltspice_sub_c

#define MODULE_LIST  ckgpav_s.c ckrsg1.c getpav.c getpav_c.c \
                     linrot_g.c ls2ins.c

#define USES_ANSI_C

#define HW_SUBLIB
#define LIB_CSPICE

$ Return
$!#############################################################################
$Other_File:
$ create cltspice_sub.hlp
This com-file contains the SPICE routines which are developed for Clementine, 
specifically. 

These modules are:

- CKGPAV_S.F
- CKRSG1.F
- GETPAV.F
- LINROT_G.F
- LS2INS.F
- LDINST.F

These modules were packed into one com-file for better software managment by
Thomas Roatsch, DLR.

The first four modules are the type 1 C-kernel reader software that
performs interpolation (all Clementine C-kernels are type 1). 

The subroutine to call to get pointing is called 'getpav'. 
The header of this file (getpav.f)
describes in detail the calling arguments to this subroutine and shows
examples of its use.


LS2INS maps line and sample coordinates to instrument coordinates.
(returns the UNNORMALIZED vector, changed from the original software)

LD2INST loads instrument parameters from the kernel pool.


Any program that uses this software will need to be linked with
spicelib.
$ Return
$!#############################################################################
