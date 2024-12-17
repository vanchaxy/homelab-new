

variable "node" {
  type = object({
    name          = string
    ip            = string
    cpu           = string
    ram_dedicated = number
    mac_address   = string
    disk_size_gb  = number
    ssd_pci_id    = string
    ssd_disk_id   = string
    usb_id        = string
    usb_disk_id   = string
  })
}

variable "talos_iso_url" {
  type = string
}

variable "machine_secrets" {
  type = any
}

variable "client_configuration" {
  type = any
}

variable "cluster" {
  type = object({
    name          = string
    endpoint      = string
    talos_version = string
  })
  sensitive = true
}

variable "talos_installer_url" {
  type = string
}