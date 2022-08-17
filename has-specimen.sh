#!/bin/bash
#
# prints first dwc records with basisOfRecord PreservedSpecimen in provided content
# 
# Inspired by Quentin Groom's request to https://github.com/bio-guoda/preston/issues/168
# make a graph of all known specimen images over time.
# 

#set -xe

source env.sh

echo "$1"\
  | sed 's+^+<foo:bar> <http://purl.org/pav/hasVersion> <+g'\
  | sed 's+$+> .+g'\
  | preston dwc-stream --data-dir="${DATA_DIR}"\
  | jq --compact-output 'select(.["http://rs.tdwg.org/dwc/terms/basisOfRecord"] == "PreservedSpecimen")'\
  | jq --raw-output '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | head -n1
