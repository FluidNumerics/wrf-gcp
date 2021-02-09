
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
