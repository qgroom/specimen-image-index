#!/bin/bash
#
#

source env.sh

SPECIMEN_FILE=$(mktemp)
IMAGES_FILE=$(mktemp)

#set -xe

./extract-preserved-specimen-records.sh "$1"\
  | jq --raw-output '[.["http://rs.tdwg.org/dwc/text/id"], .["http://rs.tdwg.org/dwc/terms/scientificName"]] | @tsv'\
  | sort\
  > "${SPECIMEN_FILE}"

./extract-still-image-records.sh "$1"\
 | jq --raw-output '[.["http://rs.tdwg.org/dwc/text/coreid"]] | @tsv'\
 | sort\
 > "${IMAGES_FILE}"

cat "${SPECIMEN_FILE}"\
 | mlr --implicit-csv-header --tsvlite join -s -f "${IMAGES_FILE}" -j 1

