#!/usr/bin/env bash
#

PROJECT_ID="SET GCP PROJECT ID"

# ///////////////////////////////// #

INSTALL_ROOT="/apps"
SPACK_VERSION="v0.16.0"
GCC_VERSION=10.2.0
OPENMPI_VERSION="4.0.2"
HDF5_VERSION="1.12.0"
PNETCDF_VERSION="1.12.1"
NETCDF_C_VERSION="4.7.4"
NETCDF_FORTRAN_VERSION="4.5.3"
JASPER_VERSION="2.0.16"
WRF_VERSION="4.2"
WPS_VERSION="4.2"

# Install spack
git clone https://github.com/spack/spack.git --branch ${SPACK_VERSION} ${INSTALL_ROOT}/spack
echo "export SPACK_ROOT=/apps/spack" > /etc/profile.d/setup_spack.sh
echo ". \${SPACK_ROOT}/share/spack/setup-env.sh" >> /etc/profile.d/setup_spack.sh
source ${INSTALL_ROOT}/spack/share/spack/setup-env.sh
spack compiler find --scope site

# Hand-edits for packages.yaml
# Add Slurm to site packages.yaml
{
  echo "packages:"
  echo "  slurm:"
  echo "    externals:"
  echo "    - spec: slurm@20-02"
  echo "      prefix: /apps/slurm/current"
} >> /apps/spack/etc/spack/packages.yaml


# Install gcc+openmpi core-stack
spack install gcc % ${GCC_VERSION}
spack load gcc % ${GCC_VERSION}
spack compiler find

spack install openmpi@${OPENMPI_VERSION}%gcc@${GCC_VERSION}~atomics+cuda+cxx+cxx_exceptions+gpfs~java+legacylaunchers~lustre+memchecker+pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=slurm

# Install WRF dependencies
spack install hdf5@${HDF5_VERSION}%gcc@${GCC_VERSION}~cxx~debug+fortran+hl~java+mpi+pic+shared~szip~threadsafe
spack install jasper@${JASPER_VERSION}%gcc@${GCC_VERSION}+jpeg~opengl+shared build_type=Release
spack install libpng@1.6.37%gcc@${GCC_VERSION} arch=linux-debian10-haswell
spack install libtirpc@1.2.6%gcc@${GCC_VERSION} arch=linux-debian10-haswell
spack install netcdf-c@${NETCDF_C_VERSION}%gcc@${GCC_VERSION}~dap~hdf4~jna+mpi~parallel-netcdf+pic+shared
spack install netcdf-fortran@${NETCDF_FORTRAN_VERSION}%gcc@${GCC_VERSION}~doc+pic+shared
spack install parallel-netcdf@${PNETCDF_VERSION}%gcc@${GCC_VERSION}~burstbuffer+cxx+fortran+pic+shared

# Garbage collect
spack gc
 
spack load openmpi hdf5 jasper libpng libtirpc netcdf-c netcdf-fortran parallel-netcdf
## Install WRF
export I_really_want_to_output_grib2_from_WRF="TRUE" 
export NETCDF=$(spack location -i netcdf-c)
export PNETCDF=$(spack location -i parallel-netcdf)
export NETCDFF=$(spack location -i netcdf-fortran)
export PHDF5=$(spack location -i hdf5)
export JASPERINC=$(spack location -i jasper)/include
export JASPERLIB=$(spack location -i jasper)/lib64
export FC=$(spack location -i openmpi)/bin/mpif90
export CC=$(spack location -i openmpi)/bin/mpicc
export WRF_DIR=${INSTALL_ROOT}/WRF-${WRF_VERSION}

wget https://github.com/wrf-model/WRF/archive/v${WRF_VERSION}.tar.gz -P ${INSTALL_ROOT}
tar -xvzf /opt/v${WRF_VERSION}.tar.gz -C /${INSTALL_ROOT}
sed -i 's/\ $I_really_want_to_output_grib2_from_WRF = "FALSE" ;//g' ${INSTALL_ROOT}/WRF-${WRF_VERSION}/arch/Config.pl 
cd /opt/WRF-${WRF_VERSION}
./configure << EOL
34
EOL
sed -i 's/ time//g' configure.wrf
sed -i 's/FCOPTIM         =.*/FCOPTIM = -Ofast -ftree-vectorize -funroll-loops -march=cascadelake/g' configure.wrf
sed -i 's/CFLAGS_LOCAL    =.*/CFLAGS_LOCAL = -Ofast -ftree-vectorize -funroll-loops -march=cascadelake/g' configure.wrf
./compile -j $(nproc) em_real
rm ${INSTALL_ROOT}/v${WRF_VERSION}.tar.gz

# Install WPS
wget https://github.com/wrf-model/WPS/archive/v${WPS_VERSION}.tar.gz -P ${INSTALL_ROOT}
tar -xvzf /opt/v${WPS_VERSION}.tar.gz -C ${INSTALL_ROOT}
cd ${INSTALL_ROOT}/WPS-${WPS_VERSION}
./configure << EOL
1
EOL
sed -i 's/ time / /g' configure.wps
./compile

rm -rf /var/tmp/*

# Install benchmark data
mkdir -p ${INSTALL_ROOT}/share/conus-2.5km
gsutil -u ${PROJECT_ID} cp gs://wrf-gcp-benchmark-data/benchmark/conus-2.5km/* ${INSTALL_ROOT}/share/conus-2.5km/
