#ifndef dlrframe_info_header
#define dlrframe_info_header
#endif

#include <stdio.h>    /* for FILE */
#include "SpiceUsr.h"

#ifdef	__cplusplus
extern "C" {
#endif

#define DLRFRAME_ERROR_LENGTH 255

typedef struct  {int    nl;
        	 int    ns;
       		 int    nb;
                 int    nbb;
                 int    nlb;
                 char   format[10];
     	     	 int    instrument_id;       /* 1 indicates "new SPICE",
                                                frame kernel available */
                 int    spacecraft_id;       /* only used if instrument_id < 0 
                                                SAMPLE_FIRST_PIXEL for SRC */
                 int    ck_id;               /* only used if instrument_id < 0 
                                                LINE_FIRST_PIXEL for SRC */
            SpiceInt    target_id;           
                 double tol;      /* just for the old missions */
                 int    adju_id;
		 char   utc[50];
                 int    trim_top;            
                 int    trim_bottom;
                 int    trim_left;
                 int    trim_right;
                 char   instrument_name[80]; 
                 char   spacecraft_name[80]; 
                 char   target_name[80];     
		} dlrframe_info;
 

int dlrframe_getinfo(int unit, dlrframe_info *dlrframe_info);

int dlrframe_getgeo (dlrframe_info dlrframe_info, FILE *adjuptr,
                     double *samp_x, double *sampy, double *focal,
                     double positn[3], double mat [3][3]);

int dlrframe_getgeo_ikernel (dlrframe_info dlrframe_info,
                      double *l0, double *s0, double *pix_per_mm,
                      double *alpha0, double *focal);
                        
void dlrframe_getgeo_xy (dlrframe_info dlrframe_info,
                        double l0, double s0, double pix_per_mm,
                        double alpha,
                        float line, float sample, double *x, double *y);
                        
int dlrframe_getgeo_cal (dlrframe_info dlrframe_info, FILE *adjuptr,
                         double *samp_x, double *samp_y, double *focal,
                         double csmat [3][3]);

int dlrframe_getgeo_cal_cmat(dlrframe_info dlrframe_info, 
                             double csmat[3][3]);

int dlrframe_getgeo_pr (dlrframe_info dlrframe_info, FILE *adjuptr,
                       double positn[3], 
                       double imat [3][3], double omat[3][3]);

int dlrframe_getview (dlrframe_info dlrframe_info, FILE *adjuptr,
                     int npixels, float *pixels, double mat[3][3],
                     double *samp_x, double *samp_y, double focal,
                     double *iv);

int dlrframe_error (int number, char *routine, 
                    char message[DLRFRAME_ERROR_LENGTH]);


/* some funny numbers */
#define VOYAGER_TRIM_TOP_LINES          50
#define VOYAGER_TRIM_BOTTOM_LINES       50
#define VOYAGER_TRIM_LEFT_SAMPLES       50
#define VOYAGER_TRIM_RIGHT_SAMPLES      50


#define VIKING_TRIM_TOP_LINES          25
#define VIKING_TRIM_BOTTOM_LINES       20
#define VIKING_TRIM_LEFT_SAMPLES       30
#define VIKING_TRIM_RIGHT_SAMPLES      30

/* SPICE instrument IDs, unfortunately this is not part
   of the toolkit and bodn2c_c is to slow .... */

#define Voyager_1          -31   
#define Voyager_1_NAC      -31001
#define Voyager_1_WAC      -31002
#define Voyager_2          -32
#define Voyager_2_NAC      -32001
#define Voyager_2_WAC      -32002

#define Viking1            -27
#define Viking2            -30

#define Galileo            -77
#define Galileo_SSI        -77036

#define Clementine         -40

#ifdef	__cplusplus
}
#endif

