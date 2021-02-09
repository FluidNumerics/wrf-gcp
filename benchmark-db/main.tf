
terraform {
  backend "gcs" {
    bucket  = "wrf-gcp-benchmark-data"
    prefix  = "benchmark-db"
  }
}

// Configure the Google Cloud provider
provider "google" {
 version = "3.54"
}

provider "google-beta" {
  version = "3.54"
}


resource "google_bigquery_dataset" "wrf_benchmarks" {
  dataset_id = "wrf_benchmark_db"
  friendly_name = "WRF Benchmarks"
  description = "A dataset for logging WRF benchmark simulations on multiple HPC provider platforms"
  location = "US"
  project = "wrf-gcp"
}

resource "google_bigquery_table" "benchmark_data" {
  dataset_id = google_bigquery_dataset.wrf_benchmarks.dataset_id
  table_id = "benchmark_data"
  project = "wrf-gcp"

  schema = <<EOF
[
  {
    "name": "benchmark_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Name of the benchmark that is run. Must be listed in the benchmark_info table"
  },
  {
    "name": "system_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Identifier for the system the benchmark is run on. Must be listed in the compute_systems table"
  },
  {
    "name": "scheduler_walltime_sec",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "Amount of walltime recorded by the job scheduler for the benchmark run."
  },
  {
    "name": "wrf_upstream",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The upstream git repository of WRF used for this benchmark"
  },
  {
    "name": "wrf_version",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Tagged release or commit sha from the `wrf_upstream` used to run this benchmark"
  },
  {
    "name": "compiler",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The compiler provider and version used to build WRF (e.g. gcc-10.2.0)"
  },
  {
    "name": "compiler_flags",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The compiler flags used to build WRF"
  },
  {
    "name": "mpi_provider",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The MPI provider used to build WRF. For example, openmpi, mpich, mvapich, intel-impi"
  },
  {
    "name": "mpi_launcher",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The binary or wrapper used to launch the mpi job. This can be a resource provided by a job scheduler / workload manager (e.g. srun, jsrun) or can be provided by the mpi_provider (e.g. mpirun, mpiexec)"
  },
  {
    "name": "openmp",
    "type": "BOOL",
    "mode": "REQUIRED",
    "description": "A flag to indicate whether or not OpenMP is enabled"
  },
  {
    "name": "gpu_accelerated",
    "type": "BOOL",
    "mode": "REQUIRED",
    "description": "A flag to indicate whether or not GPU acceleration is used."
  },
  {
    "name": "pnetcdf",
    "type": "BOOL",
    "mode": "NULLABLE",
    "description": "A flag to indicate if parallel netcdf is used for file IO"
  },
  {
    "name": "scheduler_flags",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Flags sent to the job scheduler to reserve compute resources"
  },
  {
    "name": "affinity_flags",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Flags used to map and bind MPI ranks to reserved compute resources. These are the flags sent to the mpi_launcher"
  },
  {
    "name": "forwardstep_time",
    "type": "FLOAT64",
    "mode": "REQUIRED",
    "description": "The total amount of time spent forward stepping the model (seconds)"
  },
  {
    "name": "fileio_time",
    "type": "FLOAT64",
    "mode": "REQUIRED",
    "description": "The total amount of time spent in file IO activities (seconds)."
  },
  {
   "name": "init_time",
    "type": "FLOAT64",
    "mode": "REQUIRED",
    "description": "The total amount of time spent in model initialization (seconds)"
  },
  {
    "name": "nmpi_x",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "The number of MPI rank tiles used in the longitude direction"
  },
  {
    "name": "nmpi_y",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "The number of MPI rank tiles used in the latitude direction"
  }
]
EOF
}

resource "google_bigquery_table" "benchmark_info" {
  dataset_id = google_bigquery_dataset.wrf_benchmarks.dataset_id
  table_id = "benchmark_info"
  project = "wrf-gcp"

  schema = <<EOF
[
  {
    "name": "benchmark_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Name of the benchmark that is run."
  },
  {
    "name": "inputdeck_url",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "URL pointing to namelist.wps, namelist.input, and necessary initial conditions, boundary conditions, and forcing related fields."
  },
  {
    "name": "n_timesteps",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "Number of forward timesteps"
  },
  {
    "name": "simulation_duration_hrs",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": "The simulation duration/forecast period."
  },
  {
    "name": "n_filewrites",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Number of model states written to file"
  },
  {
    "name": "nx",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Number of longitudinal grid cells"
  },
  {
    "name": "ny",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Number of latitudinal grid cells"
  },
  {
    "name": "nz",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Number of vertical grid cells"
  }
]
EOF
}

resource "google_bigquery_table" "compute_systems" {
  dataset_id = google_bigquery_dataset.wrf_benchmarks.dataset_id
  table_id = "compute_systems"
  project = "wrf-gcp"

  schema = <<EOF
[
  {
    "name": "system_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "A unique identifier for an HPC system entry. A unique system consists of a unique set of all of the variables listed in this compute_systems table. For heterogeneous HPC clusters, there are multiple possible systems"
  },
  {
    "name": "system_provider",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The name of the provider for the HPC system. For cloud resources, the system provider follows the convention PROVIDER-SOLUTION, where PROVIDER is the name of the cloud provider and SOLUTION is the name of the deployment solution used for benchmarking (e.g. google-fluidslurmgcp, azure-cyclecloud)"
  },
  {
    "name": "scheduler_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name of the job scheduler, if one is used, for this system. Options are slurm, pbs, htcondor, other, none"
  },
  {
    "name": "operating_system",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The name and version of the operating system (e.g. centos-7)"
  },
  {
    "name": "linux_kernel",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "If a Linux operating system is used, the kernel version that is used on the compute nodes for the system"
  },
  {
    "name": "compute_node_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Node type as classified by the system provider (e.g. on aws ec2, on gcp c2-standard-60)"
  },
  {
    "name": "compute_mem_gb_per_node",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "The amount of memory in GB on each compute node"
  },
  {
    "name": "compute_logical_cores_per_node",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "The number of logical cores (hyperthreads) available on each compute node"
  },
  {
    "name": "compute_physical_cores_per_node",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "The number of physical cores available on each compute node"
  },
  {
    "name": "compute_platform",
    "type": "INT64",
    "mode": "REQUIRED",
    "description": "Vendor Make/Model (e.g. Intel Xeon E5, AMD EPYC7200 Rome)"
  },
  {
    "name": "iac_url",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "URL to Infrastructure-as-code (for cloud deployment reproducibility)"
  },
  {
    "name": "io_filesystem_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "One of NFS, Lustre, GPFS"
  }
]
EOF
}
