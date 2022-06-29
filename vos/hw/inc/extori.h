
#ifndef EXTORI
#define EXTORI

int extori_or(char *filename, int *ib_unit, int *nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int  *macro, char *detec, int *first);

int extori_ow(char *filename, int *ib_unit, int nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int   macro, char *detec, int first);

int extori_ow_cplabel(char *filename, int *ib_unit, int nr, 
              char *ra, float *vari, float *covari, 
              char *start, char *stop,
              int  macro, char *detec, int first, char *filename_in);

int extori_re(int ib_unit, int srow, int nrows, double *time, 
              double *x, double *y, double *z, 
              double *a, double *b, double *c);
              
int extori_wr(int ib_unit, int srow, int nrows, double *time, 
              double *x, double *y, double *z, 
              double *a, double *b, double *c);
              
int extori_cl(int ib_unit);

#endif
