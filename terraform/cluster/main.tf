locals {
  cluster = {
    name          = "talos-homelab"
    endpoint      = "192.168.50.211"
    talos_version = "v1.8.3"
  }

  nodes = {
    mars = {
      name          = "mars"
      ip            = "192.168.50.211"
      mac_address   = "BC:24:11:2E:C8:11"
      cpu           = 8
      ram_dedicated = 13*1024
      disk_size_gb  = 128
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
      ram_dedicated = 28*1024
      disk_size_gb  = 128
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
      ram_dedicated = 28*1024
      disk_size_gb  = 128
      ssd_pci_id    = "0000:01:00.0"
      ssd_disk_id   = "nvme-CT2000P3PSSD8_2443E990D4E6"
      usb_id        = ""
      usb_disk_id   = ""
    }
  }
}

module "node-mars" {
  source = "./node"
  providers = {
    proxmox = proxmox.mars
  }

  cluster = local.cluster
  node    = local.nodes.mars

  talos_iso_url       = module.talos.iso_url
  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-jupiter" {
  source = "./node"
  providers = {
    proxmox = proxmox.jupiter
  }

  cluster = local.cluster
  node    = local.nodes.jupiter

  talos_iso_url       = module.talos.iso_url
  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-saturn" {
  source = "./node"
  providers = {
    proxmox = proxmox.saturn
  }

  cluster = local.cluster
  node    = local.nodes.saturn

  talos_iso_url       = module.talos.iso_url
  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "talos" {
  source = "./talos"

  cluster   = local.cluster
  nodes_ips = [for k, v in local.nodes : v.ip]

  talos_cluster_health_depends_on = [
    module.node-saturn.talos_machine_configuration_apply_id,
    module.node-jupiter.talos_machine_configuration_apply_id,
    module.node-saturn.talos_machine_configuration_apply_id
  ]
}
