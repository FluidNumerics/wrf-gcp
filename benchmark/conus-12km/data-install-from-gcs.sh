#!/bin/bash

INSTALL_ROOT=/opt
DATA_PREFIX=/opt/benchmark/wps-input/gfs.0p25.2018061700

# Install benchmark data
mv /tmp/benchmark /opt/
gsutil cp gs://wrf-gcp-benchmark-data/benchmark/conus-12km/* /opt/benchmark/conus-12km/

# Use WPS to create input deck
cd /opt/benchmark/conus-12km
ln -sf /opt/WPS-4.2/ungrib/Variable_Tables/Vtable.GFS /opt/benchmark/conus-12km/Vtable
ln -sf ${DATA_PREFIX}.f000.grib2 GRIBFILE.AAA
ln -sf ${DATA_PREFIX}.f003.grib2 GRIBFILE.AAB
ln -sf ${DATA_PREFIX}.f006.grib2 GRIBFILE.AAC
ln -sf ${DATA_PREFIX}.f009.grib2 GRIBFILE.AAD
ln -sf ${DATA_PREFIX}.f012.grib2 GRIBFILE.AAE

rm -rf /tmp/*
