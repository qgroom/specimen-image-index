#!/bin/bash
#
# prints first dwc records with basisOfRecord PreservedSpecimen in provided content
# 
# Inspired by Quentin Groom's request to https://github.com/bio-guoda/preston/issues/168
# make a graph of all known specimen images over time.
# 

#set -xe

source env.sh

./extract-preserved-specimen-records.sh "$1"\
  | jq --raw-output '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | head -n1
