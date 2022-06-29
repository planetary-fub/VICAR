#include "mp_routines.h"

/* -------------------------------------------------------------------- */
/* defines */

#define	PI  3.14159265358979323
#define	DEG2PI  (PI/180.0)
#define	PI2DEG  (180.0/PI)
#define	MAX_EARTH_PREFS  60

typedef struct {
    int		earth_case;
    double	val[MAX_EARTH_PREFS];
    } Earth_prefs;   

typedef struct {
    double	d[3];
    double	m;
    double	rotmat[3][3];
    } DatumShift;  

#ifdef	__cplusplus
extern	"C"	{
#endif

/* -------------------------------------------------------------------- */
int dlr_load_earth_constants( char *target, double *radii);
/* prototypes map */
int dlr_mpLabelWrite( MP mp_obj, int unit, char *in_string, Earth_prefs prefs);
int dlr_mpLabelRead( MP mp_obj, int unit, Earth_prefs *prefs);
/* -------------------------------------------------------------------- */

/* -------------------------------------------------------------------- */
/* prototypes map */
int dlr_earth_map_get_prefs 
    (MP mp, Earth_prefs *prefs);
int dlr_earth_map_LL2LS_RD_Niederlande 
	(double *lat, double *lon, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LS2LL_RD_Niederlande 
	(double *line, double *sample, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LL2RU_RD_Niederlande 
	(double *lat, double *lon, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LL_RD_Niederlande 
	(double *right, double *up, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LS2RU_RD_Niederlande 
	(double *line, double *sample, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LS_RD_Niederlande 
	(double *right, double *up, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LL2LS_TransverseMercator 
    (double *lat, double *lon, double *line, double *sample, 
     Earth_prefs prefs);
int dlr_earth_map_LS2LL_TransverseMercator 
    (double *line, double *sample, double *lat, double *lon, 
     Earth_prefs prefs);
int dlr_earth_map_LL2RU_TransverseMercator 
    (double *lat, double *lon, double *right, double *up, 
     Earth_prefs prefs);
int dlr_earth_map_LS2RU_TransverseMercator 
    (double *line, double *sample, double *right, double *up, 
     Earth_prefs prefs);
double dlr_earth_map_ArcLen 
    (double phi, Earth_prefs prefs);
int dlr_earth_map_LL2LS_SLK 
    (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LS2LL_SLK 
    (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LL2RU_SLK 
    (double *lat, double *lon, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LL_SLK 
    (double *right, double *up, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LS2RU_SLK 
    (double *line, double *sample, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LS_SLK 
    (double *right, double *up, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LL2LS_SOLDNER 
    (double *lat, double *lon, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LS2LL_SOLDNER 
    (double *line, double *sample, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LL2RU_SOLDNER 
    (double *lat, double *lon, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LL_SOLDNER 
    (double *right, double *up, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LS2RU_SOLDNER 
    (double *line, double *sample, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LS_SOLDNER 
    (double *right, double *up, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LL2LS_EQUIDISTANT 
	(double *lat, double *lon, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LS2LL_EQUIDISTANT  
	(double *line, double *sample, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LL2RU_EQUIDISTANT  
	(double *lat, double *lon, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LL_EQUIDISTANT  
	(double *right, double *up, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LS2RU_EQUIDISTANT  
	(double *line, double *sample, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LS_EQUIDISTANT  
	(double *right, double *up, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LL2LS_SINUSOIDAL 
	(double *lat, double *lon, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LS2LL_SINUSOIDAL  
	(double *line, double *sample, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LL2RU_SINUSOIDAL  
	(double *lat, double *lon, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LL_SINUSOIDAL  
	(double *right, double *up, double *lat, double *lon, Earth_prefs prefs);
int dlr_earth_map_LS2RU_SINUSOIDAL  
	(double *line, double *sample, double *right, double *up, Earth_prefs prefs);
int dlr_earth_map_RU2LS_SINUSOIDAL  
	(double *right, double *up, double *line, double *sample, Earth_prefs prefs);
int dlr_earth_map_LL2RU 
    (double *ll, double *ru, Earth_prefs prefs);
int dlr_earth_map_RU2LL 
    (double *ru, double *ll, Earth_prefs prefs);
int dlr_earth_map_LS2RU 
    (double *ls, double *ru, Earth_prefs prefs);
int dlr_earth_map_RU2LS 
    (double *ru, double *ls, Earth_prefs prefs);
/* -------------------------------------------------------------------- */

/* prototypes datum shift */
int  dlr_get_datumshift (char *filename, DatumShift *shift);
void dlr_datumshift (double *in_vec, DatumShift shift);
void dlr_datumshift_inv (double *in_vec, DatumShift shift);
/* -------------------------------------------------------------------- */


/* prototype zhwcarto */
int zhwcarto( MP mp, Earth_prefs prefs,
        double *line, double *sample, double *latitude, 
	double *longitude, int ll_type, int mode);

#ifdef	__cplusplus
}
#endif



