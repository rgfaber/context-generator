#! /bin/bash

registry=registry.macula.io
user=
password=
api_prefix=
img_prefix=
assy_suffix=
img_suffix=
id_prefix=


cid_repo=../../cid.git

sdk_version=1.9.0

schema_sdk=M5x.DEC.Schema
domain_sdk=M5x.DEC
infra_sdk=M5x.DEC.Infra
testkit_sdk=M5x.DEC.TestKit
art_sdk=M5x.AsciiArt
swagger_sdk=M5x.Swagger
bogus_sdk=M5x.Bogus



sdk_nugets_url=https://nexus.macula.io/repository/macula-nugets/

logatron_nugets_url=https://nexus.macula.io/repository/logatron-nugets/
logatron_oci_url=https://nexus.macula.io/repository/logatron-oci/