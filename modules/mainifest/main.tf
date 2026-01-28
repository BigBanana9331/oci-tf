resource "kubernetes_manifest" "ingress_class_parameters" {
  manifest = {
    apiVersion = "ingress.oraclecloud.com/v1beta1"
    kind       = "IngressClassParameters"
    metadata = {
      name      = "native-ic-params"
      namespace = "native-ingress-controller-system"
    }
    spec = {
      compartmentId    = var.compartment_id
      subnetId         = var.subnet_id
      loadBalancerName = "native-ic-lb"
      isPrivate        = false
      maxBandwidthMbps = 400
      minBandwidthMbps = 100
    }
  }
}

resource "kubernetes_manifest" "ingress_class" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "IngressClass"
    metadata = {
      name = "native-ic-ingress-class"
      annotations = {
        "ingressclass.kubernetes.io/is-default-class" = "true"
      }
      #     
    }
    spec = {
      controller = "oci.oraclecloud.com/native-ingress-controller"
      parameters = {
        scope     = "Namespace"
        namespace = "native-ic-ingress-class"
        apiGroup  = "ingress.oraclecloud.com"
        kind      = "ingressclassparameters"
        name      = "native-ic-params"
      }
    }
  }
}

