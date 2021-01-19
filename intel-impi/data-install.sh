#!/bin/bash

INSTALL_ROOT=/opt
DATA_PREFIX=/opt/benchmark/wps-input/gfs.0p25.2018061700

source /opt/intel/oneapi/setvars.sh
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_ROOT}/hdf5/lib:${INSTALL_ROOT}/openmpi/lib:${INSTALL_ROOT}/netcdf/lib
export PATH=${PATH}:${INSTALL_ROOT}/openmpi/bin:${INddSTALL_ROOT}/netcdf/bin

# Install benchmark data
mv /tmp/benchmark /opt/
gsutil cp gs://wrf-gcp-benchmark-data/benchmark/conus-2.5km/* /opt/benchmark/conus-2.5km/

# Use WPS to create input deck
cd /opt/benchmark/conus-2.5km
ln -sf /opt/WPS-4.2/ungrib/Variable_Tables/Vtable.GFS /opt/benchmark/conus-2.5km/Vtable
ln -sf ${DATA_PREFIX}.f000.grib2 GRIBFILE.AAA
ln -sf ${DATA_PREFIX}.f003.grib2 GRIBFILE.AAB
ln -sf ${DATA_PREFIX}.f006.grib2 GRIBFILE.AAC
ln -sf ${DATA_PREFIX}.f009.grib2 GRIBFILE.AAD
ln -sf ${DATA_PREFIX}.f012.grib2 GRIBFILE.AAE

rm -rf /tmp/*
