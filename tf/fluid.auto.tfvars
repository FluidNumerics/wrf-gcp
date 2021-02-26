cluster_name = "wrf-gcp"
controller_machine_type = "n1-standard-4"
login_machine_type = "n1-standard-4"
slurm_gcp_admins = ["group:support@fluidnumerics.com"]
slurm_gcp_users = ["group:support@fluidnumerics.com"]

// You must provide a GCP project ID that resides underneath a parent folder
parent_folder = "folders/551033253364"
primary_project = "wrf-gcp"
primary_zone = "us-west1-b"

//share_size_gb = 2048

// If you want to change the default images used to launch the cluster, you can set the self_link here.
// Note that you can use Packer to build on top of these images to retain full functionality of this
// deployment plus include your personal/company applications in the images
//
controller_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-controller-centos"
compute_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-compute-centos"
login_image = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-login-centos"

partitions = [{name = "n1-standard-96"
               project = "wrf-gcp"
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "n1-96"
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/wrf-gcp/global/images/wrf-gcp-gcc-openmpi"
                             machine_type = "n1-standard-96"
                             max_node_count = 50
                             zone = "us-west1-b"
                          }]
               },
               {name = "n2-standard-80"
               project = "wrf-gcp"
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "n2-80"
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/wrf-gcp/global/images/wrf-gcp-gcc-openmpi-n2"
                             machine_type = "n2-standard-80"
                             max_node_count = 50
                             zone = "us-west1-b"
                          }]
               },
               {name = "n2d-standard-224"
               project = "wrf-gcp"
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "n2d-224"
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/wrf-gcp/global/images/wrf-gcp-gcc-openmpi-n2d"
                             machine_type = "n2d-standard-224"
                             max_node_count = 50
                             zone = "us-west1-b"
                          }]
               },
               {name = "c2-standard-60"
               project = "wrf-gcp"
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "c2-60"
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/wrf-gcp/global/images/wrf-gcp-gcc-openmpi-c2"
                             machine_type = "c2-standard-60"
                             max_node_count = 50
                             zone = "us-west1-b"
                          }]
               }
]

slurm_accounts = [{ name = "wrf-users",
                    users = ["joe"]
                    allowed_partitions = ["n1-standard-96","n2-standard-80","n2d-standard-224","c2-standard-60"]
                 }]
 
