/*				DTM.H
 *****************************************************************************
 * Mars-96
 *
 *	This file defines the structures containing the DTM keywords.
 *
 * Date		Who		   Description
 * ---------	---------------	   ------------------------------------------
 * 7-Jul-94	M. Waehlisch@DLR   Initial delivery
 *****************************************************************************
 */

#ifndef dtm_header
#define dtm_header

typedef struct  {int dtm_maximum_dn;
        	 int dtm_minimum_dn;
       		 int dtm_missing_dn;
   	     	 float dtm_offset;
        	 float dtm_scaling_factor;
		 float dtm_a_axis_radius;
		 float dtm_b_axis_radius;
		 float dtm_c_axis_radius;
		 float dtm_body_long_axis;
		 char dtm_positive_longitude_direction[5];
		 char dtm_height_direction[7];
        	 char dtm_desc[250]; 
		}dtm;
 

int hwdtmrl(int inpunit, dtm *dtm_struct);
int hwdtmwl(int inpunit, dtm *dtm_struct);

#endif
