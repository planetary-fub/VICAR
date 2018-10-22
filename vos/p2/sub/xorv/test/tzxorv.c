#include "xvmaininc.h"
#include "ftnbridge.h"

void FTN_NAME(tzxorv)() 

{
  char pbuf[81];
  static unsigned char b[2] = {5,255}, 
                  c[2] = {10,3};

/*  ==================================================================  */

      zvmessage("Test the C interface","");

      zxorv( 1,2, b, c, 1,1);   /*  XOR b and c*/

      sprintf( pbuf, "Output from zxorv = %u   %u", c[0], c[1]);
      zvmessage(pbuf, "");
      zvmessage("Correct values are   15    252","");
}
