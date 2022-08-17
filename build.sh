#!/bin/bash
#
# Attempts to build an specimen image index for biodiversity datasets
# tracked by Preston, a biodiversity data tracker. 
# 
# Inspired by Quentin Groom's request to https://github.com/bio-guoda/preston/issues/168
# make a graph of all known specimen images over time.
# 

set -xe

source env.sh

PROV_SHA256=$(echo "$PROV_ID" | grep -o -P '[a-f0-9]{64}$')
PROV_VERSIONS="${PROV_SHA256}-versions.nq"
# A. create narrow dwca datasets
# 1. pick a preston snapshot 


function generate_versions {
  preston cat --data-dir "${DATA_DIR}" "${PROV_ID}"\
  | grep hasVersion\
  | grep -v ".well-known/genid"\
  | cut -d ' ' -f1-3\
  | sed 's/$/ ./g'\
  | sort\
  | uniq
}

function stream_dwc {
  cat ${PROV_VERSIONS}\
  | preston dwc-stream --data-dir "${DATA_DIR}"
}

generate_versions > ${PROV_VERSIONS}

function versions_with_specimen {
  stream_dwc\
  | jq --compact-output 'select(.["http://rs.tdwg.org/dwc/terms/basisOfRecord"] == "PreservedSpecimen")'\
  | jq --raw-output '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | uniq
}

function versions_with_still_images {
  stream_dwc\
  jq --compact-output 'select(.["http://purl.org/dc/terms/type"] == "StillImage")'\
  | jq --raw-output '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | uniq
}

VERSIONS_WITH_STILL_IMAGES="${PROV_SHA256}-with-still-images.txt"

versions_with_still_images > "${VERSIONS_WITH_STILL_IMAGES}"

cat ${VERSIONS_WITH_STILL_IMAGES}\
 | sed 's+^+<foo:bar> <http://purl.org/pav/hasVersion> <+g'\
 | sed 's+$+> .+g'\
 | preston dwc-stream --data-dir="${DATA_DIR}"\
 | jq --compact-output 'select(.["http://rs.tdwg.org/dwc/terms/basisOfRecord"] == "PreservedSpecimen")'\
  | jq --raw-output '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'\
  | grep -o -P "hash://sha256/[a-f0-9]{64}"\
  | uniq\
  > ${PROV_SHA256}-with-still-images-and-specimen.txt


#cat ${PROV_SHA256}-with-specimen.txt ${PROV_SHA256}-with-still-images.txt\
# | sort\
# | uniq -c\
# | grep -v -P "^[ 1]+.*"\
# > ${PROV_SHA256}-with-specimen-and-still-images.txt


# 2. select dwca with mention of PreservedSpecimen\

# 3. select all dwca zips with meta.xml
# 4. select all dwca zips with meta.xml containing some image schema


# hash://sha256/.../!/meta.xml 
# ...


#B. process narrow dwca datasets

#1. count number of media records
#2. associate media record with taxonomic information
