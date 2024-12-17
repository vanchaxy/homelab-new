variable "proxmox" {
  type = object({
    username = string
    password = string
  })
  sensitive = true
}
