/*				HWLDKER.H
 *****************************************************************************
 * Mars-94
 *
 *	This file defines the structures for the subroutine hwldker
 *      which will be used to load all types of SPICE kernels.
 *      File handles will be filled only in case of binary kernels.
 *
 *      The maximum length of the filenames is 120.
 *
 * Date	     Who		Description
 * --------- ------------------	----------------------------------------------
 * 20-Dec-93 Th. Roatsch@DLR	Initial delivery
 * 21-Jun-94 Th. Roatsch@DLR	MAX_KERNEL_NAME_LENGTH introduced
 * 16-Jul-01 Payam Zamani@JPL   Made this include file to be C++ compatible
 *****************************************************************************
 */
#ifndef	HWLDKER_H
#define HWLDKER_H

#include	"xvmaininc.h"

#ifdef	__cplusplus
extern "C" {
#endif

#define MAX_KERNEL_NAME_LENGTH     255
#define HWLDKER_ERROR_LENGTH 255
#include "SpiceUsr.h"

#define   SPICE_ERR_LENGTH         350

/* one kernel per type, count =(0:1) */

typedef struct 
        {
       	char       filename[MAX_KERNEL_NAME_LENGTH+1];
	int        count;
	} 
        hwkernel_1;

/* 3 kernels per type, count =(0:3) */

typedef struct 
	{
	char      filename[3][MAX_KERNEL_NAME_LENGTH+1];
	int       count;
	}
        hwkernel_3;

/* 6 kernels per type, count =(0:6) */

typedef struct               
	{
	char       filename[6][MAX_KERNEL_NAME_LENGTH+1];
	int        count;
	}
        hwkernel_6;


/* prototypes */

int hwldker(int nargs, ...);
void zhwerrini();
void zhwfailed();

#ifdef	__cplusplus
}
#endif

#endif	/* HWLKKER_H */
