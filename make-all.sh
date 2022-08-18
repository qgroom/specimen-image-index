#!/bin/bash
#
#

source env.sh 

cat prov-ids.txt\
  | xargs -L1 bash make.sh 
