########################################################################################################################
# Input variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "ibm_entitlement_key" {
  type        = string
  description = "The IBM entitlement key"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = "cloud_pak"
}

variable "worker-machine-type" {
  type        = string
  description = "Worker node machine type. Should be a GPU flavor. Use 'ibmcloud ks flavors --zone <zone>' to retrieve the list."
  default = "bx2.16x64"
}

variable "workers_per_zone" {
  type        = number
  description = "Worker nodes per zone"
  default = 2
}
variable "odf-machine-type" {
  type        = string
  description = "ODF node machine type. Should be a GPU flavor. Use 'ibmcloud ks flavors --zone <zone>' to retrieve the list."
  default = "bx2.16x64"
}
variable "cluster_name" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
  default = "data-product-pilot"
}