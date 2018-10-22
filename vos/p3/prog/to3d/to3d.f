	INCLUDE 'VICMAIN_FOR'
	SUBROUTINE MAIN44
	INTEGER INST(200)
	CHARACTER*10 TASK(200),FORMAT
	CHARACTER*3 ORG
C							   open dataset (update)
	CALL XVUNIT(IUNIT,'INP',1,ISTAT,' ')
	CALL XVOPEN(IUNIT,ISTAT,'OP','UPDATE','OPEN_ACT','SA',
     +		    'IO_ACT','SA',' ')
C
	NHIST = 200
	CALL XLHINFO(IUNIT,TASK,INST,NHIST,ISTAT,' ')
	DO WHILE (NHIST.GT.0)
	    CALL XLINFO(IUNIT,'HISTORY','3D_NL',FORMAT,LEN,NUM,ISTAT,
     +			'HIST',TASK(NHIST),'INSTANCE',INST(NHIST),' ')
	    IF (ISTAT.NE.1) THEN
		NHIST = NHIST-1
	    ELSE
		CALL XLGET(IUNIT,'HISTORY','3D_NL',NL,ISTAT,
     +			   'FORMAT','INT','ERR_ACT','SA','INSTANCE',
     +			   INST(NHIST),'HIST',TASK(NHIST),' ')
		CALL XLGET(IUNIT,'HISTORY','3D_NS',NS,ISTAT,
     +			   'FORMAT','INT','ERR_ACT','SA','INSTANCE',
     +			   INST(NHIST),'HIST',TASK(NHIST),' ')
		CALL XLGET(IUNIT,'HISTORY','3D_NB',NB,ISTAT,
     +			   'FORMAT','INT','ERR_ACT','SA','INSTANCE',
     +			   INST(NHIST),'HIST',TASK(NHIST),' ')
		CALL XLGET(IUNIT,'HISTORY','3D_ORG',ORG,ISTAT,
     +			   'FORMAT','STRING','ERR_ACT','SA','INSTANCE',
     +			   INST(NHIST),'HIST',TASK(NHIST),' ')
C
		CALL XVGET(IUNUT,ISTAT,'NL',NLX,'NS',NSX,' ')
		IF (NL*NS*NB .NE. NLX*NSX) THEN
		    CALL XVMESSAGE(
     +		    ' Conflict in image dimensions; nothing changed',' ')
		    CALL ABEND
		ENDIF
C							       delete old values
		CALL XLDEL(IUNIT,'HISTORY','3D_NL',ISTAT,
     +			   'ERR_ACT','SA','INSTANCE',INST(NHIST),
     +			   'HIST',TASK(NHIST),' ')
		CALL XLDEL(IUNIT,'HISTORY','3D_NS',ISTAT,
     +			   'ERR_ACT','SA','INSTANCE',INST(NHIST),
     +			   'HIST',TASK(NHIST),' ')
		CALL XLDEL(IUNIT,'HISTORY','3D_NB',ISTAT,
     +			   'ERR_ACT','SA','INSTANCE',INST(NHIST),
     +			   'HIST',TASK(NHIST),' ')
		CALL XLDEL(IUNIT,'HISTORY','3D_ORG',ISTAT,
     +			   'ERR_ACT','SA','INSTANCE',INST(NHIST),
     +			   'HIST',TASK(NHIST),' ')
		CALL XLDEL(IUNIT,'SYSTEM','NL',ISTAT,'ERR_ACT','SA',' ')
		CALL XLDEL(IUNIT,'SYSTEM','NS',ISTAT,'ERR_ACT','SA',' ')
		CALL XLDEL(IUNIT,'SYSTEM','NB',ISTAT,'ERR_ACT','SA',' ')
		CALL XLDEL(IUNIT,'SYSTEM','ORG',ISTAT,'ERR_ACT','SA',
     +			   ' ')
C								  add new values
		CALL XLADD(IUNIT,'SYSTEM','NL',NL,ISTAT,'FORMAT','INT',
     +			   ' ')
		CALL XLADD(IUNIT,'SYSTEM','NS',NS,ISTAT,'FORMAT','INT',
     +			   ' ')
		CALL XLADD(IUNIT,'SYSTEM','NB',NB,ISTAT,'FORMAT','INT',
     +			   ' ')
		CALL XLADD(IUNIT,'SYSTEM','ORG',ORG,ISTAT,
     +			   'FORMAT','STRING',' ')
		NHIST = -1
	    END IF
	END DO
	IF (NHIST.EQ.0) THEN
	    CALL XVMESSAGE(' 3-D dimensions not found.',' ')
	    CALL ABEND
	ENDIF
C
	CALL XVCLOSE(IUNIT,ISTAT,' ')
	RETURN
	END
