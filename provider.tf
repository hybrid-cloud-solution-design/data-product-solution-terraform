########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

provider "kubernetes" {
  host  = data.ibm_container_cluster_config.dps_cluster_config.host
  token = data.ibm_container_cluster_config.dps_cluster_config.host
}

provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.dps_cluster_config.host
    token = data.ibm_container_cluster_config.dps_cluster_config.token
  }
}

provider "kubectl" {
  host                   = data.ibm_container_cluster_config.dps_cluster_config.host
  token                  = data.ibm_container_cluster_config.dps_cluster_config.host
}