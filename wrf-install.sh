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

}

function install_additional_systempackages {
  yum install -y libseccomp-devel
}

function install_aomp {

  # Install ROCm AOMP for clang, flang, and clang-cpp
  wget https://github.com/ROCm-Developer-Tools/aomp/releases/download/rel_11.11-2/aomp_REDHAT_7-11.11-2.x86_64.rpm
  rpm -i aomp_REDHAT_7-11.11-2.x86_64.rpm

}

function setup_wrf_envs {

  source /etc/profile.d/setup_spack.sh

  # GCC + OpenMPI
  spack env create wrf_gcc_openmpi
  cp spack/wrf_gcc_openmpi/spack.yaml /apps/spack/environments/wrf_gcc_openmpi/spack.yaml
  spack env activate wrf_gcc_openmpi
  spack concretize

}
# <><><><><><><><><><><><><><><><><><><><><><><><><><><><> #
# Main

install_additional_systempackages

install_lustre_client

install_spack

install_aomp

setup_wrf_envs

