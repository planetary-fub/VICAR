C-----THIS IS A TEST OF MODULE PPROJ
      INCLUDE 'VICMAIN_FOR'
	SUBROUTINE MAIN44
C-----THIS ROUTINE WILL SET UP A DATA BUFFER FOR INPUT TO PPROJ.
C-----PPROJ WILL THEN CONVERT (L,S) TO (LAT,LON) OR INVERSE.
	IMPLICIT REAL (A-Z)
        CHARACTER*132 PBUF
	INTEGER ILAT,IND
	REAL MAP(40)
CCCC      REAL*8 OM(3,3),RS(3)                    FYI, BUT NOT REFERENCED.
CCCC      EQUIVALENCE (MAP,OM),(MAP(19),RS)
C
	CALL ZIA(MAP,40)
	MAP(25) = 1000.             ! POLAR RADIUS       KM
	MAP(26) = 1500.             ! EQUATORIAL RADIUS  KM
	MAP(27) = 1500.             ! FOCAL LENGTH IN MM
	MAP(28) = 500.              ! OPTICAL AXIS LINE NUMBER
	MAP(29) = 500.              ! OPTICAL AXIS SAMP NUMBER
	MAP(30) = 100.              ! SCALE   PX/MM
	MAP(31) = 10.               ! SUB SPCRFT POINT  LAT
	MAP(32) = 10.               ! SUB SPCRFT POINT  LON 
	MAP(33) = 300.              ! SUB SPCRFT POINT  LINE
	MAP(34) = 400.              ! SUB SPCRFT POINT  SAMP
	MAP(35) = 20.               ! NORTH ANGLE
	MAP(38) = 100000.           ! RANGE TO CENTER OF PLANET  KM
	CALL FORMOM(MAP)            ! CREATE OM AND RS 
C
C-----ALL SET TO TRY PPROJ
	LINE = 400.
	SAMP = 500.
10	ILAT = 1	! GEODETIC LAT
	CALL XVMESSAGE('DERIVE (LT,LN) FROM (L,S)',' ')
	CALL PPROJ(MAP,LINE,SAMP,LAT,LON,2,ILAT,RTANG,SLANT,IND)
	IF (IND.EQ.0) THEN
	  CALL XVMESSAGE('POINT IS OFF PLANET',' ')
	  CALL PRNT(7,1,RTANG,'TANGENT RADIUS =.')
	ELSE
          WRITE (PBUF,9000) LINE,SAMP,LAT,LON
9000      FORMAT ('L,S,LT,LN', 1PE10.3,1PE10.3,1PE10.3,1PE10.3)
          CALL XVMESSAGE(PBUF, ' ')
	  CALL PRNT(7,1,RTANG,'RADIUS =.')
	  CALL PRNT(7,1,SLANT,'SLANT DISTANCE =.')
	ENDIF
C  PUT IN A TEST FOR RTANG OPTION:
        IF (LINE.GT.400.) GO TO 15
	LINE = 1500.
	SAMP = 5000.
	GO TO 10
15	LAT = 30.
	LON = 5.
	CALL XVMESSAGE('DERIVE (L,S) FROM (LT,LN)',' ')
	CALL PPROJ(MAP,LINE,SAMP,LAT,LON,1,ILAT,RTANG,SLANT,IND)
	IF (IND.ne.0) then
          WRITE (PBUF,9000) LINE,SAMP,LAT,LON
          CALL XVMESSAGE(PBUF, ' ')
	else
20	CALL XVMESSAGE('POINT IS ON BACKSIDE OF PLANET',' ')
        end if
        CALL XVMESSAGE(
     . 'Repeat test case in C to test C interface: zpproj', ' ')

        call tzpproj(MAP)

	RETURN
	END

C     THIS IS IBM SUBROUTINE FARENC   -----NAME CHANGE-----
C/*   2 FEB 83   ...CCA...     INITIAL RELEASE
      SUBROUTINE FORMOM(DATA)
C ROUTINE TO SET UP CAMERA POINTING GEOMETRY INFO FOR CALCULATION OF
C THE PLANET-TO-CAMERA ROTATION MATRIX (OM).
      IMPLICIT DOUBLE PRECISION (A-Z)
      REAL DATA(*)
C
      PI = 3.141592653589793D0
      RADDEG = 180.D0 / PI
      DEGRAD = PI / 180.D0
      FL = DATA(27)
      OAL = DATA(28)
      OAS = DATA(29)
      SCALE = DATA(30)
      LAT = DATA(31)
      LON = DATA(32)
      LSS = DATA(33)
      SSS = DATA(34)
      NA = DATA(35)
      D = DATA(38)
C          CONVERT FROM GEODETIC TO GEOCENTRIC LATITUDE
      IF(DABS(LAT).EQ.90.D0) GOTO 10
      RP = DATA(25)
      RE = DATA(26)
      E = RE/RP
      LAT = DATAN(DTAN(LAT*DEGRAD)/E**2)*RADDEG
   10 CALL MOMATI(OAL,OAS,LSS,SSS,SCALE,FL,LON,LAT,NA,D,DATA,DATA(19))
      RETURN
C
      END
