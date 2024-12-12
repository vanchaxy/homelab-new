variable "machine_secrets" {
  type = any
}

variable "client_configuration" {
  type = any
}

data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.endpoint}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = "controlplane"
  machine_secrets  = var.machine_secrets
  config_patches = [
    templatefile("${path.module}/control-plane.yaml.tftpl", {
      hostname       = var.node.name
      node_name      = var.node.name
      cluster_name   = var.cluster.proxmox_cluster
      install_image  = data.talos_image_factory_urls.this.urls.installer
      cilium_values  = var.cilium.values
      cilium_install = var.cilium.install
      ssd_disk_id    = var.node.ssd_disk_id
      usb_disk_id    = var.node.usb_disk_id
    })
  ]
}
output "machine_config" {
  value = data.talos_machine_configuration.this
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

output "talos_machine_configuration_apply_id" {
  value = talos_machine_configuration_apply.this.id
}
