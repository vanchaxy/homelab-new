output "machine_secrets" {
  value = talos_machine_secrets.this.machine_secrets
}

output "client_configuration" {
  value = talos_machine_secrets.this.client_configuration
}

output "kubernetes_client_configuration" {
  value = talos_cluster_kubeconfig.this.kubernetes_client_configuration
}

output "kubeconfig_raw" {
  value = talos_cluster_kubeconfig.this.kubeconfig_raw
}

output "talos_config" {
  value = data.talos_client_configuration.this.talos_config
}
