terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-bootstrap"
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.18.0"
    }
  }
}


provider "helm" {
  kubernetes {
    config_path = "${path.module}/../output/kube-config.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/../output/kube-config.yaml"
}
