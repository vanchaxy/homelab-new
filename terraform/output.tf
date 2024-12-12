resource "local_file" "machine_configs_mars" {
  content         = module.proxmox-mars.machine_config.machine_configuration
  filename        = "output/talos-machine-config-mars.yaml"
  file_permission = "0600"
}

resource "local_file" "machine_configs_jupiter" {
  content         = module.proxmox-jupiter.machine_config.machine_configuration
  filename        = "output/talos-machine-config-jupiter.yaml"
  file_permission = "0600"
}

resource "local_file" "machine_configs_saturn" {
  content         = module.proxmox-saturn.machine_config.machine_configuration
  filename        = "output/talos-machine-config-saturn.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  content         = data.talos_client_configuration.this.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}
