#!/bin/bash
#
#

source env.sh 

preston history -l tsv --data-dir "${DATA_DIR}"\
 | cut -f3\
 | shuf -n10\
 | tee prov-ids.txt\
 | xargs -L1 bash make.sh 
