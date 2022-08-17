#!/bin/bash
#
# Attempts to build an specimen image index for biodiversity datasets
# tracked by Preston, a biodiversity data tracker. 
# 
# Inspired by Quentin Groom's request to https://github.com/bio-guoda/preston/issues/168
# make a graph of all known specimen images over time.
# 

#set -xe

source env.sh

PROV_SHA256=$(echo "$PROV_ID" | grep -o -P '[a-f0-9]{64}$')
PROV_VERSIONS="${PROV_SHA256}-versions.nq"
# A. create narrow dwca datasets
# 1. pick a preston snapshot 


function generate_versions {
  preston cat --data-dir "${DATA_DIR}" "${PROV_ID}"\
  | grep hasVersion\
  | grep -v "api\.gbif\.org/v1/dataset"\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | sort\
  | uniq
}

function stream_dwc {
  cat ${PROV_VERSIONS}\
  | preston dwc-stream --data-dir "${DATA_DIR}"
}

generate_versions > ${PROV_VERSIONS}

VERSIONS_WITH_STILL_IMAGES="${PROV_SHA256}-with-still-images.txt"
VERSIONS_WITH_TYPES="${PROV_SHA256}-with-types.txt"


echo selecting dwc content with types
cat "${PROV_VERSIONS}"\
  | parallel '/bin/bash has-type.sh {1}'\
  > "${VERSIONS_WITH_TYPES}"

echo selecting dwc content with still images
cat "${VERSIONS_WITH_TYPES}"\
  | parallel '/bin/bash has-image.sh {1}'\
  > "${VERSIONS_WITH_STILL_IMAGES}"

echo selecting dwc content with preserved specimen
cat ${VERSIONS_WITH_STILL_IMAGES}\
  | parallel '/bin/bash has-specimen.sh {1}'\
  > ${PROV_SHA256}-with-still-images-and-specimen.txt
