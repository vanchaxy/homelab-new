resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = var.nodes_ips
  endpoints            = var.nodes_ips
}

resource "talos_machine_bootstrap" "this" {
  node                 = var.nodes_ips[1]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    var.talos_cluster_health_depends_on
  ]

  client_configuration = data.talos_client_configuration.this.client_configuration
  control_plane_nodes  = var.nodes_ips
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
  node                 = var.nodes_ips[1]
  endpoint             = var.cluster.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
