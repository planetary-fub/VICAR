	SUBROUTINE ITL(INT, BYT)
C
	BYTE BYT
C
	IF (INT.GT.127) THEN
	    BYT = INT - 256
	ELSE
	    BYT = INT
	END IF
	RETURN
	END
