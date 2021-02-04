#!/bin/bash
INSTALL_ROOT="/opt"
OPENMPI_VERSION="v4.0.5"
HDF5_VERSION="1.12.0"
PNETCDF_VERSION="1.12.1"
NETCDF_C_VERSION="4.7.4"
NETCDF_FORTRAN_VERSION="4.5.3"
JASPER_VERSION="2.0.16"
WRF_VERSION="4.2"
WPS_VERSION="4.2"

yum install -y cmake curl-devel tcsh jasper-devel libpng-devel

## Install the GCC-9 devtoolset
yum -y update
yum install -y centos-release-scl-rh
yum install -y devtoolset-9-toolchain
source /opt/rh/devtoolset-9/enable

cat > /etc/profile.d/gcc-9.sh <<EOL
#!/bin/bash
source /opt/rh/devtoolset-9/enable
EOL

source /opt/rh/devtoolset-9/enable

yum install -y bison flex

## Install OpenMPI
mkdir -p ${INSTALL_ROOT}/build
git clone --depth 1 -b ${OPENMPI_VERSION} https://github.com/open-mpi/ompi.git ${INSTALL_ROOT}/build/ompi
echo "OpenMPI License can be obtained at https://www.open-mpi.org/community/license.php" > ${INSTALL_ROOT}/LICENSE.OpenMPI
cd ${INSTALL_ROOT}/build/ompi
./autogen.pl
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
setenv MPIRUN ${INSTALL_ROOT}/openmpi/bin/mpirun

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
module load openmpi/${OPENMPI_VERSION}
EOL


export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_ROOT}/hdf5/lib:${INSTALL_ROOT}/openmpi/lib

# Install parallel-netcdf
wget https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/pnetcdf-${PNETCDF_VERSION}.tar.gz -C /tmp
cd /tmp/pnetcdf-${PNETCDF_VERSION}
./configure --enable-shared \
            --prefix=${INSTALL_ROOT}/netcdf --with-mpi=${INSTALL_ROOT}/openmpi
make check
make -j install


## Install netcdf-c & netcdf-fortran
wget https://github.com/Unidata/netcdf-c/archive/v${NETCDF_C_VERSION}.tar.gz -P /tmp
tar -xvzf /tmp/v${NETCDF_C_VERSION}.tar.gz -C /tmp
cd /tmp/netcdf-c-${NETCDF_C_VERSION}
CC=/opt/rh/devtoolset-9/root/usr/bin/gcc \
CXX=/opt/rh/devtoolset-9/root/usr/bin/g++ \
FC=/opt/rh/devtoolset-9/root/usr/bin/gfortran \
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
CC=/opt/rh/devtoolset-9/root/usr/bin/gcc \
CXX=/opt/rh/devtoolset-9/root/usr/bin/g++ \
Fc=/opt/rh/devtoolset-9/root/usr/bin/gfortran \
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
setenv NETCDF ${INSTALL_ROOT}/netcdf
setenv NETCDFF ${INSTALL_ROOT}/netcdf
setenv PNETCDF ${INSTALL_ROOT}/netcdf

module load hdf5/${HDF5_VERSION}


EOL

## Install WRF
export I_really_want_to_output_grib2_from_WRF="TRUE" 
export PATH=${PATH}:${INSTALL_ROOT}/openmpi/bin:${INSTALL_ROOT}/netcdf/bin
export NETCDF="${INSTALL_ROOT}/netcdf"
export PNETCDF="${INSTALL_ROOT}/netcdf"
export NETCDFF="${INSTALL_ROOT}/netcdf"
export PHDF5="${INSTALL_ROOT}/hdf5"
export JASPERINC="/usr/include/jasper"
export JASPERLIB="/usr/lib64"
export FC="${INSTALL_ROOT}/openmpi/bin/mpif90"
export CC="${INSTALL_ROOT}/openmpi/bin/mpicc"
export WRF_DIR=${INSTALL_ROOT}/WRF-${WRF_VERSION}

wget https://github.com/wrf-model/WRF/archive/v${WRF_VERSION}.tar.gz -P /opt
tar -xvzf /opt/v${WRF_VERSION}.tar.gz -C /opt
sed -i 's/\ $I_really_want_to_output_grib2_from_WRF = "FALSE" ;//g' /opt/WRF-${WRF_VERSION}/arch/Config.pl 
cd /opt/WRF-${WRF_VERSION}
./configure << EOL
34
EOL
sed -i 's/ time//g' configure.wrf
./compile -j $(nproc) em_real
rm /opt/v${WRF_VERSION}.tar.gz

# Install WPS
wget https://github.com/wrf-model/WPS/archive/v${WPS_VERSION}.tar.gz -P /opt
tar -xvzf /opt/v${WPS_VERSION}.tar.gz -C /opt
cd /opt/WPS-${WPS_VERSION}
./configure << EOL
1
EOL
sed -i 's/ time / /g' configure.wps
# Replace flags with -march=znver2 -Ofast -ftree-vectorize -funroll-loops
# See https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
sed -i 's/FCOPTIM         =.*/FCOPTIM = -Ofast -ftree-vectorize -funroll-loops -march=cascadelake/g' configure.wrf
sed -i 's/CFLAGS_LOCAL    =.*/CFLAGS_LOCAL = -Ofast -ftree-vectorize -funroll-loops -march=cascadelake/g' configure.wrf
./compile

rm -rf /var/tmp/*

mkdir -p ${INSTALL_ROOT}/modulefiles/wrf
cat > ${INSTALL_ROOT}/modulefiles/wrf/${WRF_VERSION} <<EOL
#%Module 1.0

conflict                wrf

prepend-path            PATH             ${INSTALL_ROOT}/WRF-${WRF_VERSION}/run
prepend-path            PATH             ${INSTALL_ROOT}/WPS-${WPS_VERSION}

setenv INSTALL_ROOT ${INSTALL_ROOT}
setenv WRF_VERSION ${WRF_VERSION}
setenv WPS_VERSION ${WPS_VERSION}
setenv WRF_DIR ${INSTALL_ROOT}/WRF-${WRF_VERSION}

module load netcdf/${NETCDF_C_VERSION}

EOL


cat > /opt/setup.sh <<EOL
#!/bin/bash

source /opt/rh/devtoolset-9/enable
module use /opt/modulefiles
module load wrf/${WRF_VERSION}
EOL
