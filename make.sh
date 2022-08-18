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

PROV_VERSIONS="content.tsv"
PARALLEL_OPTS="--line-buffer"
# A. create narrow dwca datasets
# 1. pick a preston snapshot 


function append_namespace {
  sed "s+$+\t$(echo $PROV_ID | cut -b15-18)+g"
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

VERSIONS_WITH_STILL_IMAGES="content-with-still-images.tsv"
VERSIONS_WITH_TYPES="content-with-multimedia.tsv"


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
  > content-name-image.tsv

echo aligning names
cat content-name-image.tsv\
  | nomer replace gbif-parse\
  | nomer append col\
  | grep -o -E "(Insecta|Mammalia|Plantae)"\
  | append_namespace\
  >> plantae_insecta_or_mammalia_image.tsv

