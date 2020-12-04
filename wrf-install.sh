#!/bin/bash


SLURM_VER="20-02"

function install_intel_oneapi {
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


}

function source_packages {
  source /apps/spack/share/spack/setup-env.sh
  source /etc/profile.d/cuda.sh
  source /opt/intel/oneapi/setvars.sh
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

  cp ./spack/packages.yaml /apps/spack/etc/spack/packages.yaml

  spack compiler find --scope site

  spack install gcc@10.2.0
  spack load gcc@10.2.0
  spack compiler find --scope site
  spack unload gcc@10.2.0
}

function install_additional_systempackages {
  yum install -y libseccomp-devel \
                 csh
}

function setup_wrf_envs {

  source /etc/profile.d/setup_spack.sh

  # GCC + OpenMPI
  spack env create wrf_gcc_openmpi
  cp spack/wrf_gcc_openmpi/spack.yaml /apps/spack/var/spack/environments/wrf_gcc_openmpi/spack.yaml
  spack env activate wrf_gcc_openmpi
  spack concretize

}
# <><><><><><><><><><><><><><><><><><><><><><><><><><><><> #
# Main

install_additional_systempackages

install_lustre_client

install_intel_oneapi

install_spack

setup_wrf_envs

