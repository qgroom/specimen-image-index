#!/bin/bash
#
#

source env.sh

SPECIMEN_FILE=$(mktemp)
IMAGES_FILE=$(mktemp)

echo "$1"\
  | sed 's+^+<foo:bar> <http://purl.org/pav/hasVersion> <+g'\
  | sed 's+$+> .+g'\
  | preston dwc-stream --data-dir="${DATA_DIR}"\
  | jq --compact-output 'select(.["http://rs.tdwg.org/dwc/terms/basisOfRecord"] == "PreservedSpecimen")'\
  | jq --raw-output '[.["http://rs.tdwg.org/dwc/text/id"], .["http://rs.tdwg.org/dwc/terms/scientificName"]] | @tsv'\
  > "${SPECIMEN_FILE}"

echo "$1"\
 | sed 's+^+<foo:bar> <http://purl.org/pav/hasVersion> <+g'\
 | sed 's+$+> .+g'\
 | preston dwc-stream --data-dir="${DATA_DIR}"\
 | jq --compact-output 'select(.["http://purl.org/dc/terms/type"])'\
 | grep StillImage\
 | jq --raw-output '[.["http://rs.tdwg.org/dwc/text/coreid"]] | @tsv'\
 | sort\
 > "${IMAGES_FILE}"

cat "${SPECIMEN_FILE}"\
 | mlr --implicit-csv-header --tsvlite join -s -f "${IMAGES_FILE}" -j 1

