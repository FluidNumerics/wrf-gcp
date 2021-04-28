#!/bin/bash

DATA_PREFIX=/opt/benchmark/wps-input/gfs.0p25.2018061700

source /opt/rh/devtoolset-9/enable || source /opt/intel/oneapi/setvars.sh
module use /opt/modulefiles
module load wrf

# Install benchmark data
mv /tmp/benchmark /opt/

wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz -P /opt/benchmark/wps-input
wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_low_res_mandatory.tar.gz -P /opt/benchmark/wps-input

tar -xvzf /opt/benchmark/wps-input/geog_high_res_mandatory.tar.gz -C /opt/benchmark/wps-input
tar -xvzf /opt/benchmark/wps-input/geog_low_res_mandatory.tar.gz -C /opt/benchmark/wps-input

rm /opt/benchmark/wps-input/*.tar.gz

# GRIB can be found at https://rda.ucar.edu/datasets/ds084.1/
gsutil cp gs://wrf-gcp-benchmark-data/benchmark/conus-2.5km/*.grib2 /opt/benchmark/wps-input


# Use WPS to create input deck
mkdir -p /opt/benchmark/conus-2.5km
cd /opt/benchmark/conus-2.5km
/opt/WPS-4.2/geogrid.exe
ln -sf /opt/WPS-4.2/ungrib/Variable_Tables/Vtable.GFS /opt/benchmark/conus-2.5km/Vtable
ln -sf ${DATA_PREFIX}.f000.grib2 GRIBFILE.AAA
ln -sf ${DATA_PREFIX}.f003.grib2 GRIBFILE.AAB
ln -sf ${DATA_PREFIX}.f006.grib2 GRIBFILE.AAC
ln -sf ${DATA_PREFIX}.f009.grib2 GRIBFILE.AAD
ln -sf ${DATA_PREFIX}.f012.grib2 GRIBFILE.AAE
/opt/WPS-4.2/ungrib.exe
/opt/WPS-4.2/metgrid.exe
