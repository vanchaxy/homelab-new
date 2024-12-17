resource "kubectl_manifest" "argocd-ns" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}

locals {
  argo = {
    chart = yamldecode(file("${path.module}/../../k8s/bootstrap/argocd/Chart.yaml"))
    values = yamldecode(file("${path.module}/../../k8s/bootstrap/argocd/values.yaml")).argo-cd
  }
}

data "helm_template" "argocd-template" {
  name       = "argocd"
  repository = local.argo.chart.dependencies[0].repository
  chart      = local.argo.chart.dependencies[0].name
  version    = local.argo.chart.dependencies[0].version

  values = [
    yamlencode(local.argo.values)
  ]

  set {
    name  = "configs.secret.createSecret"
    value = true
  }

  namespace        = "argocd"
  create_namespace = true
  kube_version     = "v1.30.0"
}

resource "kubectl_manifest" "argocd-apply" {
  for_each = data.helm_template.argocd-template.manifests

  ignore_fields = ["metadata.labels.\"argocd.argoproj.io/instance\""]
  yaml_body = each.value

  depends_on = [kubectl_manifest.argocd-ns]
}

resource "null_resource" "wait_for_crd" {
  provisioner "local-exec" {
    command = "kubectl -n argocd wait --timeout=60s --for condition=Established crd/applications.argoproj.io crd/applicationsets.argoproj.io"
  }

  depends_on = [kubectl_manifest.argocd-apply]
}

data "helm_template" "root-template" {
  name  = "argocd"
  chart = "${path.module}/../../k8s/bootstrap/root"

  namespace         = "argocd"
  create_namespace  = true
  dependency_update = true
}

resource "kubectl_manifest" "root-apply" {
  for_each = data.helm_template.root-template.manifests

  ignore_fields = ["metadata.labels.\"argocd.argoproj.io/instance\""]
  yaml_body = each.value

  depends_on = [null_resource.wait_for_crd]
}
