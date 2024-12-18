terraform {
  required_version = ">=1.3.0"

  # Ensure that there is always 1 example locked into the lowest provider version of the range defined in the main
  # module's version.tf (basic and add_rules_to_sg), and 1 example that will always use the latest provider version (advanced, fscloud and multiple mzr).
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.68.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.12.1"
    }    
  }
}
