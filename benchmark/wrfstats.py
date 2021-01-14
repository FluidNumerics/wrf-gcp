#!/usr/bin/env python3

import argparse, re
import socket
import json
import yaml

def main(args):

  # Adapted from https://github.com/akirakyle/WRF_benchmarks/blob/master/scripts/wrf_stats
  files = ["rsl.out.0000"]
  max_fname = max([len(f) for f in files]+[4])

  cpu_regex = r'Ntasks in X\s*(\d+)\s*,\s*ntasks in Y\s*(\d+)'
  main_regex = r'\s*Timing for main: time [0-9_:-]+ on domain'
  write_regex = r'Timing for Writing [a-zA-Z0-9_:-]+ for domain'
  secs_regex = r'\s*\d+:\s*(\d+\.\d+)\s*elapsed seconds'

  for fname in files:
    with open(fname, 'r') as f:
      txt = f.read()
      cpu_match = re.search(cpu_regex, txt)
      X, Y = int(cpu_match.group(1)), int(cpu_match.group(2))

      write = [float(t) for t in re.findall(write_regex+secs_regex, txt)]

      init = []; comp = []
      for m in re.finditer(r'('+main_regex+secs_regex+r')+', txt):
        secs = [float(t) for t in re.findall(main_regex+secs_regex, m.group())]
        init += [secs[0]]
        comp += secs[1:]

    # Get the VM image for this host
    with open('/apps/cls/etc/cluster-config.yaml','r') as f:
      try:
        config = yaml.safe_load(f)
      except yaml.YAMLError as exc:
        print(exc)

    machine_profile = {}
    for partition in config['partitions']:
        for p_machine in partition['machines']:
            if p_machine['name'] in socket.gethostname() :
                machine_profile = p_machine
                break

    # Write the statistics to NLD JSON
    payload = {'machine_type':machine_profile['machine_type'],
               'sbatch_flags':args['sbatch-flags'],
               'mpirun_flags':args['mpirun-flags'],
               'node_count':args['node-count'],
               'vm_image': machine_profile['image'],
               'rsl_file':fname,
               'comp_steps':len(comp),
               'comp_total':sum(comp),
               'init_total':sum(init),
               'write_total':sum(write),
               'mpi_nPx':X,
               'mpi_nPy':Y}

    with open(fname+'_stats.json','w') as f:
      json.dump(payload,f)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(
    description="Analyzes timing output info for WRF runs. If no rsl output "
    "files are specified then look for rsl.out.0000 in current directory")
  parser.add_argument("sbatch-flags", help= "Flags used for sbatch")
  parser.add_argument("mpirun-flags", help= "Flags used for mpirun")
  parser.add_argument("node-count", help= "Number of nodes used for job")

  main(vars(parser.parse_args()))

