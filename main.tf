########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

########################################################################################################################
# Public Gateway in 3 zones  
########################################################################################################################

resource "ibm_is_public_gateway" "gateway" {
  for_each       = toset(["1", "2", "3"])
  name           = "${var.prefix}-gateway-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-${each.key}"
}

########################################################################################################################
# Subnets accross 3 zones
# Public gateway attached to all the zones
########################################################################################################################

resource "ibm_is_subnet" "subnets" {
  for_each                 = toset(["1", "2", "3"])
  name                     = "${var.prefix}-subnet-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-${each.key}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[each.key].id
}

########################################################################################################################
# 3 zone OCP VPC cluster
########################################################################################################################

locals {
  # list of subnets in all zones
 cluster_1_vpc_subnets = {
  default = [
    for subnet in ibm_is_subnet.subnets :
    {
      id         = subnet.id
      zone       = subnet.zone
      cidr_block = subnet.ipv4_cidr_block
    }
  ]
 }

  # worker_pools one for workload, one for odf
  worker_pools = [
    {
      subnet_prefix                     = "default"
      pool_name                         = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type                      = "bx2.16x64"
      workers_per_zone                  = 1
      operating_system                  = "REDHAT_8_64"
      secondary_storage                 = "300gb.5iops-tier"
    },
    {
      subnet_prefix                     = "default"
      pool_name                         = "odf"
      machine_type                      = "bx2.16x64"
      workers_per_zone                  = 1
      secondary_storage                 = "300gb.5iops-tier"
      operating_system                  = "REDHAT_8_64"
 #     boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    }
  ]

  kubeconfig = data.ibm_container_cluster_config.dps_cluster_config.config_file_path

  ###############################
  # Pipelines operator locals
  ###############################
  pipeline_operator_namespace = "openshift-operators"
  # local path to the helm chart
  chart_path_pipeline_operator = "openshift-pipelines"
  # helm release name
  helm_release_name_pipeline_operator = local.chart_path_pipeline_operator
  # operator subscription name
  subscription_name_pipeline_operator = "openshift-pipelines-operator"  

} # locals

module "ocp_base" {
  source               = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version              = "3.34.0"
  cluster_name         = "${var.prefix}-cluster"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_1_vpc_subnets
  worker_pools         = local.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  access_tags          = var.access_tags
  ocp_entitlement      = var.ocp_entitlement
  disable_outbound_traffic_protection  = true # set as True to enable outbound traffic; required for accessing Operator Hub in the OpenShift console.
}

########################################################################################################################
# ODF add on
########################################################################################################################

resource "ibm_container_addons" "addons" {
  depends_on = [ module.ocp_base ]
  cluster = module.ocp_base.cluster_name
  addons {
    name = "openshift-data-foundation"
    version = "4.16.0"
    parameters_json = <<PARAMETERS_JSON
        {
            "osdSize":"2048Gi",
            "numOfOsd":"1",
            "osdStorageClassName":"ibmc-vpc-block-metro-10iops-tier",
            "odfDeploy":"true",
            "billingType":"advanced",
            "clusterEncryption":"false",
            "taintNodes":"true",
            "workerPool":"odf"
        }
        PARAMETERS_JSON
    }
}    

##############################################################################
# Retrieve information about all the Kubernetes configuration files and
# certificates to access the cluster in order to run kubectl / oc commands
##############################################################################
data "ibm_container_cluster_config" "dps_cluster_config" {
  cluster_name_id = module.ocp_base.cluster_id
  config_dir      = "${path.module}/kubeconfig"
  endpoint_type   = null # null represents default
  admin           = true
}


##############################################################################
# Install the Pipelines operator if requested by the user
##############################################################################
resource "helm_release" "pipelines_operator" {
  depends_on = [module.ocp_base]

  name              = local.helm_release_name_pipeline_operator
  chart             = "${path.module}/chart/${local.chart_path_pipeline_operator}"
  namespace         = local.pipeline_operator_namespace
  create_namespace  = true
  timeout           = 300
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "operators.namespace"
    type  = "string"
    value = local.pipeline_operator_namespace
  }
  set {
    name  = "operators.subscription_name"
    type  = "string"
    value = local.subscription_name_pipeline_operator
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh ${local.subscription_name_pipeline_operator} ${local.pipeline_operator_namespace} 'wait' ''"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}

##############################################################################
# Patch ODF classes
##############################################################################  
resource "kubernetes_annotations" "ocs-storagecluster-cephfs" {
  depends_on = [ibm_container_addons.addons]
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "ocs-storagecluster-cephfs"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }
}

resource "kubernetes_config_map_v1_data" "addon-vpc-block-csi-driver-configmap" {
  depends_on = [ibm_container_addons.addons]
  metadata {
    name = "addon-vpc-block-csi-driver-configmap"
    namespace = "kube-system"
  }
  data = {
    "IsStorageClassDefault" = "false"
  }
}

##############################################################################
# Install the pipeline tasks 
# wait 5 mins till pipeline operator fully initializes itself
##############################################################################  

resource "time_sleep" "wait_5_minutes" {
  depends_on = [helm_release.pipelines_operator]

  create_duration = "300s"
}  
resource "kubectl_manifest" "ibm-pak" {
  depends_on = [module.ocp_base, helm_release.pipelines_operator, time_sleep.wait_5_minutes]
  yaml_body = file("${path.module}/pipeline/ibm-pak.yaml")
}

resource "kubectl_manifest" "ibmcloud-secrets-manager-get" {
  depends_on = [module.ocp_base, helm_release.pipelines_operator, time_sleep.wait_5_minutes]
  yaml_body = file("${path.module}/pipeline/ibmcloud-secrets-manager-get.yaml")
}

resource "kubectl_manifest" "pipeline-out-cm" {
  depends_on = [module.ocp_base, helm_release.pipelines_operator, time_sleep.wait_5_minutes]
  yaml_body = file("${path.module}/pipeline/pipeline-output-cm.yaml")
}

resource "kubectl_manifest" "cluster-role-binding" {
  depends_on = [module.ocp_base, helm_release.pipelines_operator, time_sleep.wait_5_minutes]
  yaml_body = file("${path.module}/pipeline/crb.yaml")
}

resource "kubectl_manifest" "dps-deployer-pipeline" {
  depends_on = [module.ocp_base, helm_release.pipelines_operator, time_sleep.wait_5_minutes]
  yaml_body = file("${path.module}/pipeline/dps-deployer-pipeline.yaml")
}


