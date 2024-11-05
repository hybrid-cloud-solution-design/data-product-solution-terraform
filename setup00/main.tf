##############################################################################
# Retrieve information about all the Kubernetes configuration files and
# certificates to access the cluster in order to run kubectl / oc commands
##############################################################################
data "ibm_container_cluster_config" "dps_cluster_config" {
  cluster_name_id = var.cluster_name
  config_dir      = "${path.module}/kubeconfig"
  endpoint_type   = null # null represents default
  admin           = true
}

########################################################################################################################
# locals
########################################################################################################################

locals {

  kubeconfig = data.ibm_container_cluster_config.dps_cluster_config.config_file_path


} # locals

##############################################################################
# CSV Downloader 
############################################################################## 

resource "null_resource" "csv-downloader-setup" {
  provisioner "local-exec" {
    command = "${path.module}/csv-downloader/setup.sh"

    environment = {
      GIT_TOKEN = var.git_token
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Minio setup
############################################################################## 

resource "null_resource" "minio-setup" {
  provisioner "local-exec" {
    command = "${path.module}/minio/setup.sh"

    environment = {
      GIT_TOKEN = var.git_token
      KUBECONFIG = local.kubeconfig
    }
  }
}
##############################################################################
# portal setup
############################################################################## 

resource "null_resource" "minio-setup" {
  provisioner "local-exec" {
    command = "${path.module}/portal/setup.sh"

    environment = {
      GIT_TOKEN = var.git_token
      KUBECONFIG = local.kubeconfig
    }
  }
}

