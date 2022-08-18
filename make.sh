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

PARALLEL_OPTS="--line-buffer"
PROV_ID_SHORT=$(echo $PROV_ID | cut -b15-18)

PROV_VERSIONS="content_${PROV_ID_SHORT}.tsv"
# A. create narrow dwca datasets
# 1. pick a preston snapshot 


function find_prov_date {
  preston cat --data-dir "${DATA_DIR}" "${PROV_ID}"\
  | grep "http://www.w3.org/ns/prov#startedAtTime"\
  | head -n1\
  | grep -o -E "20[0-9]{2}-[0-9]{2}-[0-9]{2}T"\
  | cut -b1-10
}

PROV_DATE=$(find_prov_date)

function append_namespace {
  sed "s+$+\t$PROV_ID_SHORT\t$PROV_DATE+g"
}

function generate_versions {
  preston cat --data-dir "${DATA_DIR}" "${PROV_ID}"\
  | grep hasVersion\
  | grep -v "api\.gbif\.org/v1/dataset"\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | sort\
  | uniq\
  | append_namespace
}

generate_versions > ${PROV_VERSIONS}

VERSIONS_WITH_STILL_IMAGES="content-with-still-images_${PROV_ID_SHORT}.tsv"
VERSIONS_WITH_TYPES="content-with-multimedia_${PROV_ID_SHORT}.tsv"


echo selecting dwc content with types
cat "${PROV_VERSIONS}"\
  | cut -f1\
  | parallel ${PARALLEL_OPTS} '/bin/bash has-multimedia.sh {1}'\
  | append_namespace\
  > "${VERSIONS_WITH_TYPES}"

echo selecting dwc content with still images
cat "${VERSIONS_WITH_TYPES}"\
  | cut -f1\
  | parallel ${PARALLEL_OPTS} '/bin/bash has-still-image.sh {1}'\
  | append_namespace\
  > "${VERSIONS_WITH_STILL_IMAGES}"

echo selecting dwc content with preserved specimen
cat ${VERSIONS_WITH_STILL_IMAGES}\
  | cut -f1\
  | parallel ${PARALLEL_OPT} '/bin/bash has-specimen.sh {1}'\
  | append_namespace\
  > content-with-still-images-and-specimen.tsv

echo joining named specimen with images 
cat content-with-still-images-and-specimen.tsv\
  | cut -f1\
  | parallel ${PARALLEL_OPT} '/bin/bash create-named-specimen-with-image-table.sh {1}'\
  | append_namespace\
  > content-name-image_${PROV_ID_SHORT}.tsv

echo aligning names
cat content-name-image_${PROV_ID_SHORT}.tsv\
  | head\
  | nomer replace gbif-parse\
  | nomer append globalnames\
  | grep -o -E "(Insecta|Mammalia|Plantae)"\
  | append_namespace\
  > plantae_insecta_or_mammalia_image_${PROV_ID_SHORT}.tsv

