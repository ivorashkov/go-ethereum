variable "region" {
  default = "us-central1-f"
}

variable "zone" {
  default = "us-central1-f"
}

variable "project" {
  default = "pid-goeuweut-devops"
}

# Configure GCP Provider
provider "google" {
  project = var.project
  region  = var.region
}

# Fetch Google Cloud credentials
data "google_client_config" "default" {}

# Create a GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "go-ethereum-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network_policy {
    enabled = true
  }
}

# Create a separate node pool with autoscaling
resource "google_container_node_pool" "primary_nodes" {
  name       = "go-ethereum-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name

  initial_node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_type    = "pd-standard"

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Configure Kubernetes Provider
# token -> Current credentials of the user that is loged in( auth when terraform talks to k8s)
# host -> API endpoint for k8s the cluster
# cluster_ca_certificate -> Cluster CA Certificate (security certificate used to verify the cluster’s identity)
# ignore_annotations -> prevents Terraform from detecting unwanted changes in annotations that Kubernetes automatically adds
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

  ignore_annotations = [
    "^cloud\\.google\\.com\\/.*"
  ]
}

# Kubernetes Namespace
resource "kubernetes_namespace" "devops_test_gke" {
  metadata {
    name = "devops-test-gke"
  }
}

#using the image ivaylorashkov/go-ethereum-hardhat
# Kubernetes Deployment
resource "kubernetes_deployment" "default" {
  metadata {
    name      = "go-ethereum-hardhat"
    namespace = kubernetes_namespace.devops_test_gke.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "go-ethereum-hardhat"
      }
    }

    template {
      metadata {
        labels = {
          app = "go-ethereum-hardhat"
        }
      }

      spec {
        container {
          name  = "go-ethereum-hardhat"
          image = "docker.io/ivaylorashkov/go-ethereum-hardhat:latest"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}


# Kubernetes LoadBalancer Service
resource "kubernetes_service" "default" {
  metadata {
    name      = "go-eth-service"
    namespace = kubernetes_namespace.devops_test_gke.metadata[0].name
  }

  spec {
    selector = {
      app = "go-eth-app"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
