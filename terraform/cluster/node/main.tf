resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node.name
  url          = var.talos_iso_url
}

resource "proxmox_virtual_environment_vm" "talos_vm" {
  node_name = var.node.name

  name        = "talos-vm"
  description = "Talos Control Plane"
  tags = ["k8s", "control-plane"]
  on_boot     = true
  vm_id       = 800

  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores = var.node.cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.node.ram_dedicated
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = var.node.mac_address
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = var.node.disk_size_gb
    file_format  = "raw"
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.talos_iso.id
    interface = "ide2"
  }

  operating_system {
    type = "l26"
  }

  hostpci {
    device = "hostpci0"
    id     = var.node.ssd_pci_id
  }

  dynamic "usb" {
    for_each = var.node.usb_id != "" ? [1] : []
    content {
      host = var.node.usb_id
    }
  }

  depends_on = [proxmox_virtual_environment_download_file.talos_iso]
}

data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.endpoint}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = "controlplane"
  machine_secrets  = var.machine_secrets
  config_patches = [
    templatefile("${path.module}/config-patch.yaml.tftpl", {
      hostname      = var.node.name
      node_name     = var.node.name
      cluster_name  = var.cluster.name
      install_image = var.talos_installer_url
      cilium_values = yamlencode(yamldecode(file("${path.module}/../../../k8s/system/cilium/values.yaml")).cilium)
      cilium_install = file("${path.module}/manifests/cilium-install.yaml")
      ssd_disk_id   = var.node.ssd_disk_id
      usb_disk_id   = var.node.usb_disk_id
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [proxmox_virtual_environment_vm.talos_vm]

  node                        = var.node.name
  endpoint                    = var.node.ip
  client_configuration        = var.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration

  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.talos_vm]
  }
}
