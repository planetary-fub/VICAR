#!/bin/csh

echo " "
echo "*****************************************************************"
echo "*****************************************************************"
echo " "
echo "		TEST PROCEDURE FOR HWGETPAR"
echo " "
echo "		July 1994"
echo " "
echo "		Justin McNeill, JPL"
echo " "
echo "*****************************************************************"

./thwgetpar MP_TYPE=ALBERS_ONE_PAR CEN_LONG=150 L_PR_OFF=100 \
		S_PR_OFF=150 CART_AZ=20	F_ST_PAR=45

./thwgetpar  MP_TYPE=ALBERS_TWO_PAR CEN_LONG=10 L_PR_OFF=400 \
		S_PR_OFF=20 CART_AZ=150	F_ST_PAR=15 S_ST_PAR=65 


echo " "
echo "*****************************************************************"
echo " "
echo "	Run test on some warning and error conditions of HWGETPAR"
echo " "
echo " "
echo " The first call of ./thwgetpar results in a status flag of -2"
echo " because MOON is not found in kernel data file."
echo " "
echo " The second call of ./thwgetpar results in a status flag of -6"
echo " and an error message because the CORRECTION mode is attempted"
echo " when no existing MP address is passed to the hwgetpar routine."
echo " "
echo "*****************************************************************"
echo " "

./thwgetpar  MP_TYPE=PERSPECTIVE TARGET=MOON FOC_LEN=1.2 SUB_LAT=35.0

./thwgetpar  MP_TYPE=CORRECTION  MP_RES=4.0 CART_AZ=180.0

