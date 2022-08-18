#!/bin/bash
#
#

source env.sh 

# first on 2019-03
FIRST=hash://sha256/261177a96185166f1c301beacf7350abff03d1b5710be6bfd8c4aff9caffef12

# last on 2022-07-01
LAST=hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86

echo -e "${LAST}\n${FIRST}"\
 > prov-ids.txt

FIRST_ROW=$(preston history --data-dir="${DATA_DIR}"\
 | grep -n ${FIRST}\
 | tail -n1\
 | grep -o -E "^[0-9]+")

LAST_ROW=$(preston history --data-dir="${DATA_DIR}"\
 | tail -n+${FIRST_ROW}\
 | grep -n ${LAST}\
 | tail -n1\
 | grep -o -E "^[0-9]+")

# range in between
preston history -l tsv --data-dir "${DATA_DIR}"\
 | tail -n+${FIRST_ROW}\
 | head -n${LAST_ROW}\
 >> prov-ids.txt
  

 # cat prov-ids.txt\
 # | xargs -L1 bash make.sh 
