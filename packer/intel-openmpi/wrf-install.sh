#!/bin/bash
INSTALL_ROOT="/opt"
HDF5_VERSION="1.12.0"
OPENMPI_VERSION="v4.0.5"
PNETCDF_VERSION="1.12.1"
NETCDF_C_VERSION="4.7.4"
NETCDF_FORTRAN_VERSION="4.5.3"
JASPER_VERSION="2.0.16"
WRF_VERSION="4.2"

yum install -y cmake curl-devel tcsh

# Install the oneAPI base kit and HPC toolkit
cat >/etc/yum.repos.d/oneAPI.repo <<EOF
[oneAPI]
name=Intel(R) oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
EOF

yum update -y
yum install -y intel-basekit intel-hpckit

cat > /etc/profile.d/oneapi.sh <<EOF
#!/bin/bash
source /opt/intel/oneapi/setvars.sh
EOF

source /opt/intel/oneapi/setvars.sh

yum install -y bison flex

## Install OpenMPI
mkdir -p ${INSTALL_ROOT}/build
git clone --depth 1 -b ${OPENMPI_VERSION} https://github.com/open-mpi/ompi.git ${INSTALL_ROOT}/build/ompi
echo "OpenMPI License can be obtained at https://www.open-mpi.org/community/license.php" > ${INSTALL_ROOT}/LICENSE.OpenMPI
cd ${INSTALL_ROOT}/build/ompi
./autogen.pl
CC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icc \
CXX=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icpc \
FC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/ifort \
./configure --prefix=${INSTALL_ROOT}/openmpi
make -j
make install

mkdir -p ${INSTALL_ROOT}/modulefiles/openmpi
cat > ${INSTALL_ROOT}/modulefiles/openmpi/${OPENMPI_VERSION} <<EOL
#%Module 1.0

conflict                openmpi

prepend-path            LD_LIBRARY_PATH             ${INSTALL_ROOT}/openmpi/lib
prepend-path            PATH             ${INSTALL_ROOT}/openmpi/bin
prepend-path            PATH             ${INSTALL_ROOT}/openmpi/include

setenv MPICXX ${INSTALL_ROOT}/openmpi/bin/mpic++
setenv MPICC ${INSTALL_ROOT}/openmpi/bin/mpicc
setenv MPIFC ${INSTALL_ROOT}/openmpi/bin/mpif90
setenv MPIEXEC ${INSTALL_ROOT}/openmpi/bin/mpiexec
EOL

## Install hdf5
yum install -y bzip2 file make wget zlib-devel
rm -rf /var/cache/yum/*

mkdir -p /var/tmp 
wget -q -nc --no-check-certificate -P /var/tmp http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.bz2
tar -x -f /var/tmp/hdf5-${HDF5_VERSION}.tar.bz2 -C /var/tmp -j
cd /var/tmp/hdf5-${HDF5_VERSION} 
# Configure
CC=${INSTALL_ROOT}/openmpi/bin/mpicc \
CXX=${INSTALL_ROOT}/openmpi/bin/mpic++ \
F77=${INSTALL_ROOT}/openmpi/bin/mpifort \
F90=${INSTALL_ROOT}/openmpi/bin/mpifort \
FC=${INSTALL_ROOT}/openmpi/bin/mpifort \
./configure --prefix=${INSTALL_ROOT}/hdf5 --enable-parallel --enable-threadsafe --enable-unsupported --enable-cxx --enable-fortran
make -j$(nproc)
make -j$(nproc) install && \
rm -rf /var/tmp/hdf5-${HDF5_VERSION}.tar.bz2 /var/tmp/hdf5-${HDF5_VERSION}

mkdir -p ${INSTALL_ROOT}/modulefiles/hdf5
cat > ${INSTALL_ROOT}/modulefiles/hdf5/${HDF5_VERSION} <<EOL
#%Module 1.0

conflict                hdf5

prepend-path            LD_LIBRARY_PATH             ${INSTALL_ROOT}/hdf5/lib
prepend-path            PATH             ${INSTALL_ROOT}/hdf5/bin
prepend-path            PATH             ${INSTALL_ROOT}/hdf5/include

setenv HDF5_DIR ${INSTALL_ROOT}/hdf5
source /opt/intel/oneapi/setvars.sh

EOL


export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_ROOT}/hdf5/lib

# Install parallel-netcdf
wget https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/pnetcdf-${PNETCDF_VERSION}.tar.gz -C /tmp
cd /tmp/pnetcdf-${PNETCDF_VERSION}
./configure --enable-shared \
            --prefix=${INSTALL_ROOT}/netcdf --with-mpi=/opt/intel/oneapi/mpi/2021.1.1/
make check
make -j install


## Install netcdf-c & netcdf-fortran
wget https://github.com/Unidata/netcdf-c/archive/v${NETCDF_C_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/v${NETCDF_C_VERSION}.tar.gz -C /tmp
cd /tmp/netcdf-c-${NETCDF_C_VERSION}
CC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icc \
CXX=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icpc \
FC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/ifort \
CPPFLAGS="-I${INSTALL_ROOT}/hdf5/include -I${INSTALL_ROOT}/openmpi/include -I${INSTALL_ROOT}/netcdf/include" \
LDFLAGS="-L${INSTALL_ROOT}/hdf5/lib -L${INSTALL_ROOT}/netcdf/lib" \
./configure --enable-pnetcdf \
            --enable-parallel-tests \
            --prefix=${INSTALL_ROOT}/netcdf
make check
make -j install

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_ROOT}/netcdf/lib
wget https://github.com/Unidata/netcdf-fortran/archive/v${NETCDF_FORTRAN_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/v${NETCDF_FORTRAN_VERSION}.tar.gz -C /tmp
cd /tmp/netcdf-fortran-${NETCDF_FORTRAN_VERSION}
CC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icc \
CXX=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/icpc \
FC=/opt/intel/oneapi/compiler/2021.1.1/linux/bin/intel64/ifort \
CPPFLAGS="-I${INSTALL_ROOT}/hdf5/include -I${INSTALL_ROOT}/openmpi/include -I${INSTALL_ROOT}/netcdf/include" \
LDFLAGS="-L${INSTALL_ROOT}/hdf5/lib -L${INSTALL_ROOT}/netcdf/lib" \
./configure --prefix=${INSTALL_ROOT}/netcdf
make check
make -j install

mkdir -p ${INSTALL_ROOT}/modulefiles/netcdf
cat > ${INSTALL_ROOT}/modulefiles/netcdf/${NETCDF_C_VERSION} <<EOL
#%Module 1.0

conflict                netcdf

prepend-path            LD_LIBRARY_PATH             ${INSTALL_ROOT}/netcdf/lib
prepend-path            PATH             ${INSTALL_ROOT}/netcdf/bin

setenv NETCDF_C_VERSION ${NETCDF_C_VERSION}
setenv NETCDF_FORTRAN_VERSION ${NETCDF_FORTRAN_VERSION}

module load hdf5/${HDF5_VERSION}

EOL


### Install Jasper
wget https://github.com/mdadams/jasper/archive/version-${JASPER_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/version-${JASPER_VERSION}.tar.gz -C /tmp
mkdir /tmp/jasper-version-${JASPER_VERSION}/build
cd /tmp/jasper-version-${JASPER_VERSION}/build
cmake -DJAS_ENABLE_LIBJPEG=true \
      -DJAS_ENABLE_SHARED=true \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_ROOT}/jasper \
      /tmp/jasper-version-${JASPER_VERSION}
make -j
make -j install
mkdir -p ${INSTALL_ROOT}/modulefiles/jasper
cat > ${INSTALL_ROOT}/modulefiles/jasper/${JASPER_VERSION} <<EOL
#%Module 1.0

conflict                jasper

prepend-path            LD_LIBRARY_PATH             ${INSTALL_ROOT}/jasper/lib64
prepend-path            PATH             ${INSTALL_ROOT}/jasper/bin

EOL

## Install WRF
export PATH=${PATH}:${INSTALL_ROOT}/openmpi/bin
export NETCDF="${INSTALL_ROOT}/netcdf"
export PNETCDF="${INSTALL_ROOT}/netcdf"
export NETCDFF="${INSTALL_ROOT}/netcdf"
export PHDF5="${INSTALL_ROOT}/hdf5"
export JASPERINC="${INSTALL_ROOT}/jasper/include"
export JASPERLIB="${INSTALL_ROOT}/jasper/lib64"
export FC="${INSTALL_ROOT}/openmpi/bin/mpif90"
export CC="${INSTALL_ROOT}/openmpi/bin/mpicc"

wget https://github.com/wrf-model/WRF/archive/v${WRF_VERSION}.tar.gz -P /opt
tar -xvzf /opt/v${WRF_VERSION}.tar.gz -C /opt
cp /tmp/configure.wrf /opt/WRF-${WRF_VERSION}
cd /opt/WRF-${WRF_VERSION}
./compile -j $(nproc) em_real

mkdir -p ${INSTALL_ROOT}/modulefiles/wrf
cat > ${INSTALL_ROOT}/modulefiles/wrf/${WRF_VERSION} <<EOL
#%Module 1.0

conflict                wrf

prepend-path            PATH             ${INSTALL_ROOT}/WRF-${WRF_VERSION}/run

module load netcdf/${NETCDF_C_VERSION} jasper/${JASPER_VERSION}

EOL

rm -rf /tmp/*
rm -rf /var/tmp/*

