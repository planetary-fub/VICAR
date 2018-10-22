C--2-JAN-1995 ...CRI... MSTP S/W CONVERSION (VICAR PORTING)
C
      INCLUDE 'VICMAIN_FOR'
      SUBROUTINE MAIN44
      IMPLICIT INTEGER (A-Z)
      INCLUDE 'pgminc'            ! TAE CONSTANTS & PARAMETERS
      CHARACTER*8  FORMAT
      INTEGER      STATUS, VBLOCK(xprdim), NLSB(3)

      CALL IFMESSAGE('FORM version 2-JAN-1995')
      CALL XVEACTION('SA',' ')
C--OPEN INPUT FILE & GET ITS FORMAT PARAMETERS:
      CALL XVUNIT( IUN, 'INP', 1, STATUS,' ')
      CALL XVOPEN( IUN, STATUS,' ')
      CALL XVGET ( IUN, STATUS, 'FORMAT', FORMAT, 'NL', NLSB(1),
     . 'NS', NLSB(2), 'NB', NLSB(3),' ')

      CALL XVCLOSE( IUN, STATUS,' ')

C--CREATE V-BLOCK:
      CALL XQINI( VBLOCK, xprdim, xabort, STATUS)
      CALL XQSTR( VBLOCK, 'FORMAT', 1, FORMAT,xadd, STATUS)
      CALL XQINTG( VBLOCK, 'NL', 1, NLSB(1), xadd, STATUS)
      CALL XQINTG( VBLOCK, 'NS', 1, NLSB(2), xadd, STATUS)
      CALL XQINTG( VBLOCK, 'NB', 1, NLSB(3), xadd, STATUS)
      CALL XVQOUT( VBLOCK, STATUS)

      RETURN
      END
