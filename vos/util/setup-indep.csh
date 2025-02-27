#!/bin/csh
#
# This script performs the following platform independent processes:
#
#  - Makes certain util/scripts executable.   
#  - Builds the packer/unpacker programs for the platform
#    on which the script is run. 
#  - Unpacks the include files for specific subsytems  
# 
cd $V2UTIL
#
#
# Build the packer/unpacker programs.
#
mkdir $VICCPU
make -f vpack.make
#
#
# Unpack or setup rtl, vids, ssv, div subsystems
# include files.   
#
if (-d $V2TOP/rtl) $V2UTIL/setup-rtlinc.csh
if (-d $V2TOP/vids) $V2UTIL/setup-vidsinc.csh
if (-d $V2TOP/ssv) $V2UTIL/unpk-ssvinc.csh
if (-d $V2TOP/div) $V2UTIL/unpk-divinc.csh
