# specimen-image-index
scripts to help index images of specimen in versioned snapshots of digital catalogs of natural history collections around the world.

## Background

Natural History Collections keep physical specimen of organisms. Some of these collections provide digital catalogs. These digital catalogs may be registered with, and tracked by, digital registries like GBIF, iDigBio, and BioCASe. To assist in discovery of catalog records, these registries typically offer search indexes and download services through internet accessible web pages and web apis. As the digital catalog update, and their changes propagate to the registries, search results are expected to change over time. So, a search for mouse records (_Mus musculus_) may yield different results depending on the time the query was done.

Instead of relying on dynamic search indices, we aim to show building blocks to process versioned digital catalogs. Our processing methods use well-defined inputs: (a) a versioned corpus of known origin, and (b) a question (e.g., How many preserved specimen records of Mammalia, Plantae, and Insecta have at least image for a given versioned corpus?). For (a), we use a Preston biodiversity data archive that spans 2018-2022 and contains biodiversity datasets, including digital catalogs of natural history collections, that were registered with GBIF, iDigBio, and BioCaSE. We encoded the input (b), the question, in an executable bash program [```make.sh```](./make.sh) that takes the version of the corpus as input.

In short: 

```
corpus version 
+
question
= 
answer
```

The answer is contained in file named ```plantae_insecta_or_mammalia_image_[...].tsv``` that looks like:

```
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
Insecta	251f	2021-07-01
...
```

Where each row represents a record of a preserved specimen with at least one image. The first column indicates the taxonomic context of the records and contains either Insecta, Mammalia, or Plantae. The second column contains the first four characters of the version id (or content id) of the Preston archive version. The third column is the start date at which the version, or snapshot, was generated.

    You should be able to copy-paste the examples into a linux terminal (or equivalent). The examples assume knowledge of the linux command-line and that you installed [Preston](https://github.com/bio-guoda/preston), [jq](https://stedolan.github.io/jq/), and [mlr](https://github.com/johnkerl/miller).
# Step-by-step

At time of writing, the [```make.sh```](./make.sh) uses two main techniques: versioning and stream processing. Versioning helps to be specific on what _exactly_ you are (intending) to process. Stream processing performs transformations on a sequence of small chunks of data. This kind of processing in small chunks allows for handling large datasets because you only keep small bits in memory at the time. And, you can stop whenever you had enough without too much trouble. Think of a river of data and catching fish as they swim by (stream processing) vs having to build an aquarium to put all the fish in and then start fishing (batch processing). 

The text below outlines these building blocks. Hopefully, these should give you some context and copy-paste examples to help better understand what the [```make.sh```](./make.sh) script does. The design of the script was inspired by the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy). 

If you have any questions, please open [an issue](../../issues/new). 

☝️ You should be able to copy the multi-line examples below straight into your terminal window.  

## Pick a Snapshot

Preston archives consist of a list of versioned snapshots. You can get a list this snapshots by running:

```
preston history --remote https://linker.bio 
```

or find any other biodiversity data snapshot available (see https://github.com/bio-guoda/preston#data-publications for inspiration). 

In our case, the last 2 lines of ```preston history --remote https://linker.bio``` produced:

```
<hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86> <http://purl.org/pav/previousVersion> <hash://sha256/aab08c5c87ce6a8f400972e2b09b7fa3421947b59407a8feb98388d7e42b49e8> .
<hash://sha256/38e8e17f6742d39379b96cec2d4e70a5a63a85a28aee49727031c9061f4b1e03> <http://purl.org/pav/previousVersion> <hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86> .

```

and documents snapshot version ```hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86```. 

Inspecting the snapshot version using:

```
preston cat --remote https://linker.bio hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86 | grep startedAt 
```

produced:

```
<urn:uuid:d0990404-5670-4cfa-8d6b-43faadeec93e> <http://www.w3.org/ns/prov#startedAtTime> "2022-07-01T18:28:22.172Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> <urn:uuid:d0990404-5670-4cfa-8d6b-43faadeec93e> .
```

which is RDF speak for indicating that something, or more specifically ```urn:uuid:d0990404-5670-4cfa-8d6b-43faadeec93e```, was started at 2022-07-01T18:28:22.172Z, or on 1 July 2022. 

## Stream Darwin Core Records

Now that we have a snapshot version, we can stream all the darwin core records referenced in the snapshot (maybe billions) as JSON objects by piping (using ```|```) the output of the snapshot description into ```preston dwc-stream```:

```
preston cat --remote https://linker.bio hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86\
| preston dwc-stream --remote https://linker.bio
```

For sake of simplicity, we'll only show the first record (try it!) and make it print pretty using ```jq```, a command-line program specializing in JSON processing:


```
preston cat --remote https://linker.bio hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86\
| preston dwc-stream --remote https://linker.bio\
| head -n1\
| jq . 
```
Note that depending on your circumstance, it may take a while to retrieve the first record:

```json 
{
  "http://www.w3.org/ns/prov#wasDerivedFrom": "line:zip:hash://sha256/dcbdd3158ba0e17b332fe3c9b7428a6eb0fab8ae9ed1dd671f92624b60af4c47!/occurrence.txt!/L2",
  "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": "http://rs.tdwg.org/dwc/terms/Occurrence",
  "http://rs.tdwg.org/dwc/text/id": "urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032",
  "http://rs.tdwg.org/dwc/terms/collectionCode": "Godthåbsfjord2013",
  "http://rs.tdwg.org/dwc/terms/disposition": "Voucher in collection at NHMA, Denmark",
  "http://rs.tdwg.org/dwc/terms/country": "Greenland",
  "http://rs.tdwg.org/dwc/terms/geodeticDatum": "WGS84",
  "http://rs.tdwg.org/dwc/terms/associatedReferences": null,
  "http://rs.tdwg.org/dwc/terms/order": "Aranea",
  "http://rs.tdwg.org/dwc/terms/verbatimEventDate": "2013-06-29/2013-07-23",
  "http://rs.tdwg.org/dwc/terms/class": "Arachnida",
  "http://rs.tdwg.org/dwc/terms/associatedMedia": null,
  "http://rs.tdwg.org/dwc/terms/coordinateUncertaintyInMeters": "10",
  "http://rs.tdwg.org/dwc/terms/phylum": "Arthropoda",
  "http://rs.tdwg.org/dwc/terms/organismQuantity": "2",
  "http://rs.tdwg.org/dwc/terms/organismQuantityType": "Individuals",
  "http://rs.tdwg.org/dwc/terms/municipality": "Kommuneqarfik Sermersooq",
  "http://purl.org/dc/terms/license": "https://creativecommons.org/licenses/by/4.0/",
  "http://rs.tdwg.org/dwc/terms/locality": "Godthåbsfjord",
  "http://rs.tdwg.org/dwc/terms/habitat": "Heath",
  "http://rs.tdwg.org/dwc/terms/decimalLongitude": "-51.506501",
  "http://rs.tdwg.org/dwc/terms/scientificName": "Arctosa insignita (Thorell, 1872)",
  "http://rs.tdwg.org/dwc/terms/catalogNumber": null,
  "http://rs.tdwg.org/dwc/terms/eventDate": "2013-06-29",
  "http://rs.tdwg.org/dwc/terms/recordedBy": "Rikke Reisner Hansen",
  "http://rs.tdwg.org/dwc/terms/family": "Lycosidae",
  "http://rs.tdwg.org/dwc/terms/kingdom": "Animalia",
  "http://rs.tdwg.org/dwc/terms/decimalLatitude": "64.48416",
  "http://rs.tdwg.org/dwc/terms/verbatimLocality": "Site: 2, Plot: heath4",
  "http://rs.tdwg.org/dwc/terms/identifiedBy": "Rikke Reisner Hansen",
  "http://rs.tdwg.org/dwc/terms/basisOfRecord": "PreservedSpecimen",
  "http://rs.tdwg.org/dwc/terms/occurrenceID": "urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032",
  "http://rs.tdwg.org/dwc/terms/institutionCode": "AU-Bioscience"
}
```

There's hundreds of millions of objects similar to these. 

Instead of printing every one of them and reading them manually, you can also use ```jq``` to extract information. 

## Processing Darwin Core Records

For instance, to retrieve the scientific name of the first record, you can ask:

```
preston cat --remote https://linker.bio hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86\
| preston dwc-stream --remote https://linker.bio\
| head -n1\
| jq '.["http://rs.tdwg.org/dwc/terms/scientificName"]'
```

this yields the answer:

```
"Arctosa insignita (Thorell, 1872)"
```

According to https://eol.org/pages/1196719 acccessed at 2022-08-18, "Arctosa insignita is a species of spiders in the family wolf spiders."  

## Trace Record Origin

Another question you can ask is: where did this record come from? by:

```
preston cat --remote https://linker.bio hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86\
| preston dwc-stream --remote https://linker.bio\
| head -n1\
| jq '.["http://www.w3.org/ns/prov#wasDerivedFrom"]'
```

which produced:

```
"line:zip:hash://sha256/dcbdd3158ba0e17b332fe3c9b7428a6eb0fab8ae9ed1dd671f92624b60af4c47!/occurrence.txt!/L2"
```

This is the *exact* identification of the line published that described this wolf spider record.

You can retrieve this content using:

```
preston cat --remote https://linker.bio 'line:zip:hash://sha256/dcbdd3158ba0e17b332fe3c9b7428a6eb0fab8ae9ed1dd671f92624b60af4c47!/occurrence.txt!/L2'
```

which produces:

```
urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032	https://creativecommons.org/licenses/by/4.0/	AU-Bioscience	Godthåbsfjord2013	PreservedSpecimen	urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032		Rikke Reisner Hansen	2	Individuals	Voucher in collection at NHMA, Denmark			2013-06-29	2013-06-29/2013-07-23	Heath	Greenland	Kommuneqarfik Sermersooq	Godthåbsfjord	Site: 2, Plot: heath4	64.48416	-51.506501	WGS84	10	Rikke Reisner Hansen	Arctosa insignita (Thorell, 1872)	Animalia	Arthropoda	Arachnida	Aranea	Lycosidae
```

## Transform Tabular Source Data

It appears that this is a line from a tab-separated file. Print the header of this file, along with the record row above, into a file test.tsv by running:

```
preston cat --remote https://linker.bio 'line:zip:hash://sha256/dcbdd3158ba0e17b332fe3c9b7428a6eb0fab8ae9ed1dd671f92624b60af4c47!/occurrence.txt!/L1,L2' > test.tsv
```

You can now try and open this file into your favorite spreadsheet program. In my case, that is ```miller``` or ```mlr```, a commandline tool for processing tabular data. I produced the table below with the following code:

```
preston cat --remote https://linker.bio 'line:zip:hash://sha256/dcbdd3158ba0e17b332fe3c9b7428a6eb0fab8ae9ed1dd671f92624b60af4c47!/occurrence.txt!/L1,L2' \
 | mlr --itsvlite --omd cat
```

| id | license | institutionCode | collectionCode | basisOfRecord | occurrenceID | catalogNumber | recordedBy | organismQuantity | organismQuantityType | disposition | associatedMedia | associatedReferences | eventDate | verbatimEventDate | habitat | country | municipality | locality | verbatimLocality | decimalLatitude | decimalLongitude | geodeticDatum | coordinateUncertaintyInMeters | identifiedBy | scientificName | kingdom | phylum | class | order | family |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032 | https://creativecommons.org/licenses/by/4.0/ | AU-Bioscience | Godthåbsfjord2013 | PreservedSpecimen | urn:AU-Bioscience:GreenlandGodthåbsfjordMacroArthropods2013:00032 |  | Rikke Reisner Hansen | 2 | Individuals | Voucher in collection at NHMA, Denmark |  |  | 2013-06-29 | 2013-06-29/2013-07-23 | Heath | Greenland | Kommuneqarfik Sermersooq | Godthåbsfjord | Site: 2, Plot: heath4 | 64.48416 | -51.506501 | WGS84 | 10 | Rikke Reisner Hansen | Arctosa insignita (Thorell, 1872) | Animalia | Arthropoda | Arachnida | Aranea | Lycosidae |

By now, you have seen the basics of processing biodiversity dataset files using versioned snapshots using Preston, jq, and mlr. 

## Answer a More Complicated Question

These techniques were applied to create [```make.sh```](./make.sh). 

After instaling the prerequisites (e.g., Preston, mlr, jq, Nomer), you should be able to run:

```
./make.sh hash://sha256/da7450941e7179c973a2fe1127718541bca6ccafe0e4e2bfb7f7ca9dbb7adb86
```

if all goes well, this should produce a file called ```plantae_insecta_or_mammalia_image_da74.tsv``` that should help you to answer questions like:

"How many preserved specimen records of mammals, insects, and plants that have one or more images associated with them?"

by counting the number of lines in the file:

```
cat plantae_insecta_or_mammalia_image_da74.tsv\
 | wc -l
```

You can also calculate a breakdown of mammal, insect, and plant imaged specimen records by:

```
cat plantae_insecta_or_mammalia_image_da74.tsv\
 | sort\
 | uniq -c
```




:warning: under construction

prereqs:

ubuntu linux
java8
preston 
jq

to run:

1. copy env.sh.template to env.sh
2. edit env.sh 
3. get a copy of some preston corpus
5. run make.sh



