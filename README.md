# Data Product Solutions deployable architecture

Assets for deploying Data Product Solutions pilot environment in OpenShift cluster on IBM Cloud (ROKs)

## Mission Statement

The goal of this Deployable Architecture is to create a PoX environment to get hands on Data Product Solution using an OpenShift cluster in IBM Cloud.
Try to re-use as much assets (e.g. pipeline scripts, Juypter notebooks etc.) from the DPS TechZone deployer environment.

# Approach

This repository contains 2 terraform file sets that setup DPS environment:

1. Main module - `main.tf` located in the `/` (root) directory of the repository
2. Additional module - `main.tf` located in the `setup00` folder

Main module can be run via:
- Deployment Architecture from IBM Cloud Private catalog - [Onboarding a deployable architecture to a private catalog](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-onboard-da&interface=ui)
- Schematics workspace - [Creating workspaces and importing your Terraform](https://cloud.ibm.com/docs/schematics?topic=schematics-sch-create-wks&interface=ui)
- `terraform` command line on any Linux workstation

Additonal module can be run via separate:
- Schematics workspace - [Creating workspaces and importing your Terraform](https://cloud.ibm.com/docs/schematics?topic=schematics-sch-create-wks&interface=ui)
- `terraform` command line on any Linux workstation

## Main module
Main module installs and configures following products:
- OpenShift with ODF in VPC in IBM Cloud (ROKS)
- OpenShift Pipelines 
- Cloud Pak for Data with required components 
- Cloud Pak for Integration with API Connect 
- API Connect Essentials (StepZen)
- Development mail server (used by APIC)
- OpenLdap (used for user directory)

List of the resources created in IBM Cloud can be found below in the [Created resources in details] section.


## Additional module
Main module installs and configures following products:
- csv-downloader application
- minio-webhook application
- DPS portal application


# Installation and setup
To configure full DPS environment in IBM Cloud follow these steps:
1. IBM Cloud account  
Ensure you have "admin" access to **paid** IBM Cloud account (free account is not sufficient). 
Create `api-key` for your user in the IBM Cloud.
2. Install Main module  
Use one of the above methods (Depolyable architecture, Schematics, or command line) to run terraform.  
Specify following required variables (via UI or `terraform.tfvars` file):
- `ibmcloud_api_key` - your IBM Cloud api key
- `ibm_entitlement_key` - your IBM software entitlement key (required for CP4D install)
- `prefix` - prefix for all created resources in the IBM Cloud
- `region` - region where to deploy the cluster e.g. "us-east"
- `ocp_version` - OpenShift version to provision e.g. "4.16"

Main module installation can take up to **12 hours**.
Verify that you can access the cluster and that installation pipeline has finished successfully (via OCP console, pipeline in the `default` project).

3. Install additional module  
Once the main module is installed you can run additional module from the `setup00` folder. You can use Schematics or `terraform` command line.  
Specify following required variables (via UI or `terraform.tfvars` file):
- `ibmcloud_api_key` - your IBM Cloud api key
- `region` - region where cluster was deployed e.g. "us-east"
- `cluster_name` - created cluster name (default name is "data-product-pilot")
- `git_token` - your git tokent to `github.ibm.com` required to access additonal software repositories.

4. Contiinue "Post provisioning" starting **Step 01** described in [this page ](https://github.ibm.com/data-product-solutions/techzone/tree/main/v1/Setup)


### Appendix - Created resources in details
#### Red Hat OpenShift Container Platform on VPC landing zone 

 The resources created are simple and concerns like high availability, observability, and security are not taken into account.

![Architecture diagram for the Data Product Solution of ROKS on VPC landing zone - FIX](https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-landing-zone/main/reference-architectures/roks-quickstart.drawio.svg)

This pattern deploys the following infrastructure:

- Workload VPC with three subnets, in three zones, allow-all ACL and Security Group
- One ROKS cluster in workload VPC with six worker nodes, public endpoint enabled
- OpenShift Data Foundation installed on separate worker pool
- Cloud Object Storage instance (required for cluster)

[TBC]
