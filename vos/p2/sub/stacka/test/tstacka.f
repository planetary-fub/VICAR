C TEST SUBROUTINE STACKA
C
      INCLUDE 'VICMAIN_FOR'
      SUBROUTINE MAIN44
      IMPLICIT INTEGER (A-Z)
      EXTERNAL T2STCK,T25STCK
C
      CALL XVMESSAGE(
     . 'CALL T2STCK(A,N,B,L,X): PRINT BYTE ARRAY A(N),  CONSTANT X',' ')
      L=0
      N=10
      X=100
      CALL STACKA(5,T2STCK,2,N,L,X)  ! 5 other parameters.
C
      CALL STACKA(27,T25STCK,1,N,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
     .               16,17,18,19,20,21,22,23,24,25)
      RETURN
      END
C
      SUBROUTINE T2STCK(A,N,B,N1,X)
C
C TEST SUBROUTINE STACKA
C
      IMPLICIT INTEGER (A-Z)
      BYTE A(N),B(N1)
C
      DO 1 I=1,10
    1 A(I)=I
      CALL PRNT(1,N,A,' ARRAY A:.')
      CALL PRNT(4,1,N1,' 0 DIMENSION CHANGED TO:.')
      CALL PRNT(4,1,X,' INTEGER X:.')
C
      RETURN
      END
      SUBROUTINE T25STCK(A,N, AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,
     .                        AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX)
C
C TEST SUBROUTINE STACKA
C
      IMPLICIT INTEGER (A-Z)
      BYTE A(N)
C
      DO 1 I=1,10
    1 A(I)=I
      CALL PRNT(1,N,A,' ARRAY A:.')
      CALL PRNT(4,1,AX,' INTEGER AX:.')
C
      RETURN
      END
