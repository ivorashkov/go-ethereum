provider "google" {
  project = "avian-serenity-451412-t2"
  region  = "europe-west1`"
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "europe-west1-b"
  initial_node_count = 2

  node_config {
    machine_type = "e2-medium"
  }
}

provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "my-app"
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }
      spec {
        container {
          image = "gcr.io/your-gcp-project-id/my-image:latest"
          name  = "my-app"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name = "my-app-service"
  }
  spec {
    selector = {
      app = "my-app"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
