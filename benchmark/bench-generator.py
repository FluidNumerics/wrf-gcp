#!/usr/bin/python3

import yaml
import subprocess

PATH_TEMPLATE="slurm/@MACHINE_TYPE@/@COMPILER@/@MPI_FLAVOR@/conus_nt@NTASKS@_ppn@NTASKS_PER_NODE@.sh"
SBATCH_TEMPLATE="""#!/bin/bash
#SBATCH --partition=@MACHINE_TYPE@-@COMPILER@-@MPI_FLAVOR@
#SBATCH --ntasks=@NTASKS@
#SBATCH --ntasks-per-node=@NTASKS_PER_NODE@
#SBATCH --mem-per-cpu=@MEM_PER_CPU@g
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --account=wrf-users
#
# /////////////////////////////////////////////// #

WORK_PATH=${HOME}/wrf-benchmark/@COMPILER@-@MPI_FLAVOR@/@MACHINE_TYPE@/ntasks-@NTASKS@/ppn-@NTASKS_PER_NODE@/
MPI_FLAGS="@MPI_OPTS@ --np $SLURM_NTASKS @AFFINITY_FLAGS@" 

source @COMPILER_ENV_FILE@
module use /opt/modulefiles
module load wrf/4.2

mkdir -p ${WORK_PATH}
cd ${WORK_PATH}
ln -s /opt/benchmark/conus-2.5km/* .
ln -s /opt/benchmark/wrfstats.py .
ln -s /opt/WRF-4.2/run/* .

mpirun $MPI_FLAGS ./wrf.exe

python3 wrfstats.py "--ntasks=@NTASKS@ --ntasks-per-node=@NTASKS_PER_NODE@ --mem-per-cpu=@MEM_PER_CPU@g --cpus-per-task=1" "$MPI_FLAGS" $SLURM_JOB_NUM_NODES

"""

compiler_env = {'gcc':'/opt/rh/devtoolset-9/enable',
                'intel':'/opt/intel/oneapi/setvars.sh'}
hardware_vars = {'machine_type':'@MACHINE_TYPE@'}
software_vars = {'compiler':'@COMPILER@',
                 'mpi_flavor':'@MPI_FLAVOR@',
                 'mpi_opts':'@MPI_OPTS@'}
job_vars = {'ntasks':'@NTASKS@',
            'ntasks_per_node':'@NTASKS_PER_NODE@',
            'affinity_flags':'@AFFINITY_FLAGS@',
            'mem_per_cpu_gb':'@MEM_PER_CPU@'}

#'@COMPILER_ENV_FILE@',


def main():

    # Get the VM image for this host
    with open('jobs.yaml','r') as f:
      try:
        jobs = yaml.safe_load(f)
      except yaml.YAMLError as exc:
        print(exc)

    for hw in jobs['hardware']:
        for sw in jobs['software']:
            for spec in jobs['job_specs']:

                if not hw['machine_type'] in spec['exclude_machines']:
                    envfile = compiler_env[sw['compiler']]
                    batch = SBATCH_TEMPLATE.replace('@COMPILER_ENV_FILE@',envfile)
                    path = PATH_TEMPLATE
    
                    for key in hw.keys():
                        batch = batch.replace(hardware_vars[key],hw[key])
                        path = path.replace(hardware_vars[key],hw[key])
    
                    for key in sw.keys():
                        batch = batch.replace(software_vars[key],sw[key])
                        path = path.replace(software_vars[key],sw[key])
    
                    for key in spec.keys():
                        if not key == 'exclude_machines':
                           if key == 'ntasks_per_node':
                              hw_vcpu_count = int(hw['machine_type'].split('-')[-1])
                              ntasks_per_node = min(hw_vcpu_count, spec[key])
                              batch = batch.replace(job_vars[key],str(ntasks_per_node))
                              path = path.replace(job_vars[key],str(ntasks_per_node))
                           else:
                              batch = batch.replace(job_vars[key],str(spec[key]))
                              path = path.replace(job_vars[key],str(spec[key]))
    
                    # Make directory for slurm file
                    path_dir = '/'.join(path.split('/')[0:-1])
                    subprocess.run(['mkdir','-p',path_dir])
    
                    f = open(path,'w')
                    f.write(batch)
                    f.close()

if __name__ == '__main__':
    main()
