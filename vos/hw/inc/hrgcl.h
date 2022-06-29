void hrorcgcl (char *geocal_dir, char *h_geocal_version,
               char *spacecraft_name,
               char *instrument_id, char *detector_id, 
               char *filename, 
               double *x, double *y, double *focal, 
               int *non_active_pixel);

void hrowcgcl (char *filename,
               char *spacecraft_name, char *instrument_name,
               char *detector_id, char *prod_time,
               float focal, int nrow, 
               float *x, float *y );
