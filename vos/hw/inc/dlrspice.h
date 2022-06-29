/* -------------------------------------------------------------------- */
/* prototypes */

 void dlrsurfpt (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double point[3],
                int    *found);

 void dlrsurfptl_llr (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double long_axis,
                double latlong[2],
                double *radius,
                int    *found);

void dlrsurfptl_xyz (double positn[3],
                double u[3],
                double a,
                double b,
                double c,
                double long_axis,
                double point[3],
                int    *found);

void dlrsurfnm (double a,
                double b,
                double c, 
                double point[3],
                double normal[3]);
 void dlrmxm (double M1[3][3], double M2[3][3], double MOUT[3][3]);
 void dlrmtxm (double M1[3][3], double M2[3][3], double MOUT[3][3]); 
 void dlrmxmt (double M1[3][3], double M2[3][3], double MOUT[3][3]); 
 void dlrmxv (double M[3][3], double *V, double *VOUT); 
 void dlrmtxv (double M[3][3], double *V, double *VOUT); 
 void dlropk2m (double omega, double phi, double kappa, double MOUT[3][3]);
 void dlrkpo2m (double kappa, double phi, double omega, double MOUT[3][3]);
 void dlrkop2m (double kappa, double omega, double phi, double MOUT[3][3]);
 void dlrkok2m (double kappa2, double omega, double kappa1, double MOUT[3][3]);
 void dlrm2kop (double M[3][3], double *kappa, double *omega, double *phi);
 void dlrvhat (double *V, double *VOUT);
 double dlrvnorm (double *V);
 double dlrvdot (double *V1, double *V2);
 void dlrvlcom (double A, double *V1, double B, double *V2, double *SUMOUT);
 void dlrreclat ( double *xyz, double *radius, double *lon, double *lat);
 void dlrlatrec ( double radius, double lon, double lat, double *xyz);
 void dlrrotate ( double ANGLE, int IAXIS, double MOUT[3][3]);

 double dlrdpr();
 double dlrrpd();

 void hrscori (double position1[3], double position2[3], double rbp[3][3], 
	  		   float *scori);
/* -------------------------------------------------------------------- */
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/* defines */

#define	PI  3.14159265358979323
#define	twoPI  2.0*PI

/* threshold for long-axis */
#define LONG_AXIS_THRESHOLD 1e-10
