# This is the original README that came from the deployable architecture. Please modify accordingly to fit your use case.

Depending on your level of customization, IBM Cloud might not support the deployable architecture. The components of the architecture supplied in the customization bundle are supported by IBM Cloud, but any customized code added to extend is not.

# Red Hat OpenShift Container Platform on VPC landing zone (QuickStart pattern)

The goal of this Deployable Architecture is to create a PoX environment to get hands on Data Product Solution using an OpenShift cluster in IBM Cloud. The resources created are simple and concerns like high availability, observability, and security are not taken into account.

![Architecture diagram for the Data Product Solution of ROKS on VPC landing zone - FIX](https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-landing-zone/main/reference-architectures/roks-quickstart.drawio.svg)

This pattern deploys the following infrastructure:

- Workload VPC with three subnets, in three zones, allow-all ACL and Security Group
- One ROKS cluster in workload VPC with six worker nodes, public endpoint enabled
- OpenShift Data Foundation installed on separate worker pool
- Cloud Object Storage instance (required for cluster)

[TBC]
