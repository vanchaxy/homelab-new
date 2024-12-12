variable "cilium" {
  description = "Cilium configuration"
  type = object({
    values  = string
    install = string
  })
}

variable "cluster" {
  type = object({
    name            = string
    endpoint        = string
    gateway         = string
    talos_version   = string
    proxmox_cluster = string
  })
  sensitive = true
}


variable "node" {
  type = object({
    name          = string
    ip            = string
    mac_address   = string
    cpu           = number
    ram_dedicated = number
    disk_size_gb  = number
    ssd_pci_id    = string
    ssd_disk_id   = string
    usb_id        = string
    usb_disk_id   = string
  })
  sensitive = true
}

variable "endpoints" {
  type = list(string)
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


resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node.name
  url          = data.talos_image_factory_urls.this.urls.iso
}
