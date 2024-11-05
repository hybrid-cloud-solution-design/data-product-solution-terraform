########################################################################################################################
# Input variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}
variable "region" {
  type        = string
  description = "Region where resources are created"
}
variable "cluster_name" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
  default = "data-product-pilot"
}

variable "git_token" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
}