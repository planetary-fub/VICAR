


#define	NUMBER_OF_STD_SCALES_HRSC_SRC 10

#define	BASIC_SCALE_SRC  0.0025 /* [km/pixel] => standards 0.0025 - 1.280 */
#define	BASIC_SCALE_HRSC 0.0125 /* [km/pixel] => standards 0.0125 - 6.400 */

#define	NUMBER_OF_STD_SCALES_HRSC_SRC 10
				/* => SRC  standards 0.0025 - 1.280 km/pixel */
				/* => HRSC standards 0.0125 - 6.400 km/pixel */
/* Prototype */
    
int hrgetstdscale(/* Input */
                 char *det_id,      /* detector ID (MEX IDs are valid) */
                 double scale,      /* given scale [km/pixel]*/
                 
                 /* Output */
                 double *std_scale   /* nearest standard scale to given scale 
				                       for this detector [km/pixel]*/
                 );
