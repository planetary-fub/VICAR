
#ifdef  __cplusplus
extern  "C"     {
#endif

typedef	struct	{
/*0-7 */	double	EphTime;	/* Ephemeris Time		    */
/*8-11 */	float	Exposure;	/* Camera exposure time in ms	    */

/*12-15 */	int	COT;		/* Camera Objective Temp in 1/100 K */
/*16-18 */	int	FEETemp;	/* FEE unit temperature, 1/100 K    */
/*20-23 */	int	FPMTemp;	/* FPM temperature, 1/100 K	    */
/*24-27 */	int	OBTemp;		/* Optical bench temperature, 1/100K*/
/* Please, note that FERT is used for DU_CENTRAL_BRACKET, 1/100 K */
/*28-31 */	int	FERT;		/* First Earth Recieved Time	    */
/* Please, note that LERT is used for CH_THERMAL_I/F, 1/100 K */
/*32-35 */	int	LERT;		/* Last Earth Recieved Time	    */

/* Please, note that reserved1 is used for DU Temperature */
/*36-39 */	int	reserved1;	/* reserved for future use	    */

/*40-41 */	unsigned short	CmpDataLen;   /* Compressed Data Length     */
/*42-43 */	unsigned short	FrameCount;   /* Frame counter	            */

/* Please, note that Pischel is used for Gain number */
/*44-45	*/	unsigned short	Pischel;      /* Pischel Byte		    */

/*46-47 */	unsigned short	ActPixel;     /* Number of active pixels    */

/* Please, note that RSHits is used for total number of frame erros per frame
in bypass mode it is the number of filled pixels */
/*48-49 */	unsigned short	RSHits;	      /* Reed-Solomon errors	    */

/* Please, note that reserved2 is used for overflow frames  */
/*50-51 */	unsigned short	reserved2;    /* reserved for future use    */

/*52 */	        unsigned char	DceInput;     /* Status of DCE input stage  */
/*53 */ 	unsigned char	DceOutput;    /* Status of DCE output buffer */
/* FrameErr1 and FrameErr2 are currently not used in MEX */
/*54 */	        unsigned char	FrameErr1;    /* Frame Error Number 1	    */
/*55 */	        unsigned char	FrameErr2;    /* Frame Error Number 2	    */
/*56 */	        unsigned char	Gob1;	      /* GOB Number1		    */
/*57 */ 	unsigned char	Gob2;	      /* GOB Number 2		    */
/*58 */	        unsigned char	Gob3;	      /* GOB Number 3		    */
/* Please, note that DSS is used for DU_THERM_REF, K + 173.15  */
/*59 */	        unsigned char	DSS;	      /* Deep space station id      */
/*60 */	        unsigned char	DecmpErr1;    /* Decompression error 1      */
/*61 */	        unsigned char	DecmpErr2;    /* Decompression error 2      */
/*62 */	        unsigned char	DecmpErr3;    /* Decompression error 3      */
/* Please, note that FillerFlag is used for New gain number */
/*63 */ 	unsigned char	FillerFlag;   /* Filler bits exist or not   */
/* Please, note that reserved3 is used for First pixel with the new gain */
/*64-67 */	unsigned int	reserved3;    /* reserved for future use    */
	}
	hrpref_typ;

#define	HRPREF_LEN	68	/* PACEKED length of the hrpref_typ with   >*/
				/*> no fill bytes.			    */
/*==========================================================================*/

#define	BL_TYPE			"M94_HRSC"

void    hrrdpref(int Unit, int Line, hrpref_typ *Prefix);
void    hrwrpref(int Unit, int Line, hrpref_typ *Prefix);
void    hrprefinit(hrpref_typ *Prefh);                       

#ifdef  __cplusplus
}
#endif

/* Frame error list, defined by C. Doberenz 1996 

for compresed data:

DecmpErr1.2.3   Message in dec.c

2               WARNING 74: sync lost at GOB %d
3               WARNING 75: GOB %d missing in frame
4               WARNING 76: GOB number %d is out of order
5               WARNING 77: using possibly incorrect GOB %d
6               WARNING 78: GOB %d assigned twice 
7               WARNING 79: Found GOB %d out of range
8               WARNING 80: Fixing GOB Nr %d 
9               WARNING 83: ignoring second possibly incorrect GOB %d


for bypass data:

DecmpErr1       Message in dec.c

10              WARNING 31: Filling bypass overflow with %d zeros
11              WARNING 32: Bypassed frame %d of sensor %d is smaller 
                            than window
12              WARNING 33: Bypassed frame %d of sensor %d is longer 
                            than window
*/
