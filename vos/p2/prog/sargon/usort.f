C     THIS SUBROUTINE WILL SORT THE LINES AND SAMPLES IN ASCENDING ORDER
C     USING THE LINE VALUES.

      SUBROUTINE SORTX(BUF,N)

      INTEGER*2 BUF(2,4000)
C
      CALL SORTIN(BUF,N)

      RETURN
      END
