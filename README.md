# WRF-GCP

Weather Research and Forecasting (WRF) Model on Google Cloud Platform.

## WRF Installation
This repository includes scripts that install WRF and its dependencies for benchmarking purposes on Google Cloud Platform.

Build flavors include
* GCC 9 + OpenMPI 4.0.2
* Intel + OpenMPI 4.0.2 (OneAPI HPC Toolkit)
* Intel + Intel-MPI (OneAPI HPC Toolkit)



## Building images
To build these images, you can use Google Cloud Build. For example
```
gcloud builds submit . --substitutions="_MACHINE=c2","_COMPILER=gcc","_MPI=openmpi"
```

### Substitution Variables

* `_MACHINE` can be set to `generic`, `c2`, `n2`, or `n2d`
* `_COMPILER` can be set to `gcc` or `intel`
* `_MPI` can be set to `openmpi` or `impi`. Note that `impi` is only function with `_COMPILER=intel`
* `_SOURCE_IMAGE` can be set to the selfLink of any CentOS 7 based VM image on Google Cloud. By default `_SOURCE_IMAGE = 'fluid-slurm-gcp-compute-centos'`, providing compatibility with Fluid-Slurm-GCP autoscaling clusters on Google Cloud.
* `_SOURCE_IMAGE_PROJECT` must be set to the project ID that hosts the `_SOURCE_IMAGE`. By default `_SOURCE_IMAGE_PROJECT = 'fluid-cluster-ops'` 




