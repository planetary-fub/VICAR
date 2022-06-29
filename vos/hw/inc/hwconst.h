/***************************************************************************/
/*                                                                         */
/*             +++ Header-File for HRSC/WAOSS-Constants +++                */
/*                      +++ PROJECT Mars-94 +++                            */
/*                                                                         */
/*     Description: This file defines the global 'C' constants used        */
/*                  in all HRSC/WAOSS programs.                            */
/*                                                                         */
/* Date         Who             Description                                */
/* ---------    --------------- -------------------------------------------*/
/*                                                                         */
/* 05-May-94    R. Berlin       initial release                            */
/* 11-Jul-94    Th. Roatsch     NON_ACTIVE_HRSC_PIXEL_START and SPICE IDs  */
/*                              added                                      */
/* 18-Sep-95    Th. Roatsch     NON_ACTIVE_HRSC_PIXEL_START changed to 75  */
/*                              (it was 76)                                */
/*                                                                         */
/***************************************************************************/

/* number of all pixels in one CCD-line */
#define TOTAL_PIXEL                    5272 

/* number of active pixels in one CCD-line */
#define TOTAL_ACTIVE_PIXEL             5184  

/* number of non active pixels in one HRSC-CCD-line at the beginning */
#define NON_ACTIVE_HRSC_PIXEL_START    75

/* SPICE instrument ID for HRSC aboard Mars-94 */
#define HRSC_94_SPICE_ID               -550101

/* SPICE instrument ID for WAOSS aboard Mars-94 */
#define WAOSS_94_SPICE_ID              -550102

/* Nominal pixel size for HRSC and WAOSS in microns */
#define NOMINAL_PIXEL_SIZE             7
