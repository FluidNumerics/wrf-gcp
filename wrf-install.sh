#!/bin/bash


SLURM_VER="20-02"

function source_packages {
  source /apps/spack/share/spack/setup-env.sh
  source /etc/profile.d/cuda.sh
}

function install_lustre_client {
  cat >/etc/yum.repos.d/lustre.repo <<EOL
[lustre-server]
name=lustre-server
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el7/server
# exclude=*debuginfo*
gpgcheck=0

[lustre-client]
name=lustre-client
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el7/client
# exclude=*debuginfo*
gpgcheck=0

[e2fsprogs-wc]
name=e2fsprogs-wc
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7
# exclude=*debuginfo*
gpgcheck=0
EOL
  
  yum clean all
  yum update -y
  yum install -y kernel-devel-$(uname -r) \
  	       kernel-headers-$(uname -r) \
  	       kernel-tools-$(uname -r) \
  	       kernel-tools-libs-$(uname -r) \
  	       kernel-tools-libs-devel-$(uname -r) \
  	       kerenel-abi-whitelists-*
  
  yum install -y lustre-client

}

function install_spack {

  git clone https://github.com/spack/spack.git /apps/spack
  echo "export SPACK_ROOT=/apps/spack" > /etc/profile.d/setup_spack.sh
  echo ". \${SPACK_ROOT}/share/spack/setup-env.sh" >> /etc/profile.d/setup_spack.sh

  source_packages

  spack compiler find --scope site

  setup_packages_yaml
}

function setup_packages_yaml {

  source_packages

  # Install additional system dependencies
  yum install -y libseccomp-devel

  # Create a packages.yaml file
  spack external find --scope site

  # Hand-edits for packages.yaml
  # Add Slurm to site packages.yaml
  {
    echo "  slurm:"
    echo "    externals:"
    echo "    - spec: slurm@${SLURM_VER}"
    echo "      prefix: /apps/slurm/current"
  } >> /apps/spack/etc/spack/packages.yaml
  
  # Add libseccomp to site packages.yaml
  {
    echo "  libseccomp:"
    echo "    externals:"
    echo "    - spec: libseccomp@2.3.1"
    echo "      prefix: /usr"
  } >> /apps/spack/etc/spack/packages.yaml
  # Add numactl to site packages.yaml
  {
    echo "  numactl:"
    echo "    externals:"
    echo "    - spec: numactl@2.0.12"
    echo "      prefix: /usr"
  } >> /apps/spack/etc/spack/packages.yaml
  # Add squashfs to site packages.yaml
  {
    echo "  squashfs:"
    echo "    externals:"
    echo "    - spec: squashfs@4.3"
    echo "      prefix: /usr/sbin"
  } >> /apps/spack/etc/spack/packages.yaml
  # Add lustre to site packages.yaml
  {
    echo "  lustre:"
    echo "    externals:"
    echo "    - spec: lustre@2.12.5"
    echo "      prefix: /usr"
  } >> /apps/spack/etc/spack/packages.yaml
}

function install_gcc_openmpi {

  source_packages
  
  # Install gcc - Build using the system installed gcc 4.8.5
  spack install gcc@10.2.0 % gcc@4.8.5
  spack load gcc@10.2.0
  spack compiler find --scope site

  # Install OpenMPI
  spack install openmpi@4.0.2%gcc@10.2.0~atomics+cuda+cxx+cxx_exceptions+gpfs~java+legacylaunchers+lustre+memchecker+pmi+singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=slurm

  # Install WRF
  spack install wrf@4.2+pnetcdf%gcc@10.2.0

  spack unload gcc@10.2.0

}

function install_aomp_openmpi {

  # For Clang, we are using AMD's AOMP compiler (v3.9.0)
  # The aomp package is built using the system installed gcc 4.8.5
  spack install aomp@3.9.0 % gcc@4.8.5

  spack load aomp@3.9.0
  spack compiler find --scope site

  # May need to hand edit compilers.yaml to add clang flang/f18 combination here.

  # Install OpenMPI
#  spack install openmpi@4.0.2%aomp@3.9.0~atomics+cuda+cxx+cxx_exceptions+gpfs~java+legacylaunchers+lustre+memchecker+pmi+singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=slurm

  # Install WRF
  #spack install wrf@4.2+pnetcdf%aomp@3.9.0


}

# <><><><><><><><><><><><><><><><><><><><><><><><><><><><> #
# Main

install_lustre_client

install_spack

install_gcc_openmpi

