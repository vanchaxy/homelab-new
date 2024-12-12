locals {
  cilium = {
    values = file("${path.module}/proxmox-node/values.yaml")
    install = file("${path.module}/proxmox-node/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "192.168.50.211"
    gateway         = "192.168.50.1"
    talos_version   = "v1.8.3"
    proxmox_cluster = "homelab"
  }

  nodes = {
    mars = {
      name          = "mars"
      ip            = "192.168.50.211"
      mac_address   = "BC:24:11:2E:C8:11"
      cpu           = 8
      ram_dedicated = 4096
      disk_size_gb  = 20
      ssd_pci_id    = "0000:03:00.0"
      ssd_disk_id   = "nvme-SAMSUNG_MZVLB256HAHQ-000H7_S426NX0M109347"
      usb_id        = "1058:264d"
      usb_disk_id   = "usb-WD_easystore_264D_35444A4C53375352-0:0"
    }
    jupiter = {
      name          = "jupiter"
      ip            = "192.168.50.212"
      mac_address   = "BC:24:11:2E:C8:12"
      cpu           = 8
      ram_dedicated = 4096
      disk_size_gb  = 20
      ssd_pci_id    = "0000:01:00.0"
      ssd_disk_id   = "nvme-CT2000P3PSSD8_2443E990D502"
      usb_id        = ""
      usb_disk_id   = ""
    },
    saturn = {
      name          = "saturn"
      ip            = "192.168.50.213"
      mac_address   = "BC:24:11:2E:C8:13"
      cpu           = 8
      ram_dedicated = 4096
      disk_size_gb  = 20
      ssd_pci_id    = "0000:01:00.0"
      ssd_disk_id   = "nvme-CT2000P3PSSD8_2443E990D4E6"
      usb_id        = ""
      usb_disk_id   = ""

    }
  }
}

module "proxmox-mars" {
  source = "./proxmox-node"
  providers = {
    proxmox = proxmox.mars
  }

  cluster   = local.cluster
  cilium    = local.cilium
  node      = local.nodes.mars
  endpoints = [for k, v in local.nodes : v.ip]

  machine_secrets      = talos_machine_secrets.this.machine_secrets
  client_configuration = talos_machine_secrets.this.client_configuration
}

module "proxmox-jupiter" {
  source = "./proxmox-node"
  providers = {
    proxmox = proxmox.jupiter
  }

  cluster   = local.cluster
  cilium    = local.cilium
  node      = local.nodes.jupiter
  endpoints = [for k, v in local.nodes : v.ip]

  machine_secrets      = talos_machine_secrets.this.machine_secrets
  client_configuration = talos_machine_secrets.this.client_configuration
}

module "proxmox-saturn" {
  source = "./proxmox-node"
  providers = {
    proxmox = proxmox.saturn
  }

  cluster   = local.cluster
  cilium    = local.cilium
  node      = local.nodes.saturn
  endpoints = [for k, v in local.nodes : v.ip]

  machine_secrets      = talos_machine_secrets.this.machine_secrets
  client_configuration = talos_machine_secrets.this.client_configuration
}


resource "talos_machine_secrets" "this" {
  talos_version = local.cluster.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in local.nodes : v.ip]
  endpoints            = [for k, v in local.nodes : v.ip]
}

resource "talos_machine_bootstrap" "this" {
  node                 = [for k, v in local.nodes : v.ip][0]
  endpoint             = local.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_health" "this" {
  depends_on = [
    module.proxmox-mars.talos_machine_configuration_apply_id,
    module.proxmox-jupiter.talos_machine_configuration_apply_id,
    module.proxmox-saturn.talos_machine_configuration_apply_id,
    talos_machine_bootstrap.this
  ]
  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = [for k, v in local.nodes : v.ip]
  endpoints            = data.talos_client_configuration.this.endpoints
  timeouts = {
    read = "10m"
  }
}
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    data.talos_cluster_health.this
  ]
  node                 = [for k, v in local.nodes : v.ip][0]
  endpoint             = local.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
