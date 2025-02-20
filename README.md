# **Deploying GKE Cluster Using Terraform**

## **Requirements**

Before deploying a Kubernetes cluster on **Google Kubernetes Engine (GKE)** using Terraform, ensure you have the following:

1. **Google Cloud Platform (GCP) Account** with billing enabled.
2. **GKE Cluster creation permissions** (or an existing cluster).
3. **Terraform installed and configured**.
4. **Google Cloud SDK (`gcloud`) installed**.
5. **`kubectl` installed** for Kubernetes interaction.
6. **IAM Roles Required:** Ensure your user or service account has the following roles:
   - `roles/container.admin`
   - `roles/compute.networkAdmin`
   - `roles/iam.serviceAccountUser`
7. **Authentication with GCP:** Run the following:
   ```sh
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project <your-project-id>
   ```
8. **(If using a private image)** Create a Kubernetes secret to pull images from a private container registry.

---

## **STEP 1: Install Google Cloud SDK (`gcloud`)**

### **Update and Install Required Packages:**
```sh
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip apt-transport-https ca-certificates gnupg
```

### **Add Google Cloud repository key and install SDK:**
```sh
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt update && sudo apt install -y google-cloud-sdk
```

### **Authenticate with Google Cloud CLI:**
```sh
gcloud auth login
gcloud auth application-default login
```

---

## **STEP 2: Install Terraform**

### **Download and Install the Latest Terraform:**
```sh
curl -fsSL https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
```

---

## **STEP 3: Configure Google Cloud Project**

### **List available projects:**
```sh
gcloud projects list
```

### **Set the active project:**
```sh
gcloud config set project pid-goeuweut-devops
gcloud auth application-default set-quota-project pid-goeuweut-devops
gcloud auth application-default print-access-token
```

### **Verify the current project:**
```sh
gcloud config get-value project
```

### **Check available regions and zones:**
```sh
gcloud compute regions list
```
- Choosing **region:** `us-central1`
```sh
gcloud compute zones list | grep us-central1
```
- Choosing **zone:** `us-central1-f`

---

## **STEP 4: Create a GKE Cluster Using Terraform**


Create a `main.tf` file with the following content:
```hcl
variable "region" {
  default = "us-central1-f"
}

variable "zone" {
  default = "us-central1-f"
}

variable "project" {
  default = "pid-goeuweut-devops"
}

provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "default" {}

resource "google_container_cluster" "primary" {
  name     = "go-ethereum-cluster"
  location = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  network_policy {
    enabled = true
  }
}

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

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  ignore_annotations = ["^cloud\\.google\\.com\/.*"]
}

resource "kubernetes_namespace" "devops_test_gke" {
  metadata {
    name = "devops-test-gke"
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name      = "go-ethereum-hardhat"
    namespace = kubernetes_namespace.devops_test_gke.metadata[0].name
  }
  spec {
    replicas = 3
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
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}
```

---

### **Navigate to the Terraform directory:**
```sh
cd /home/ivaylorashkov/new_repo/go-ethereum/Terraform
ls | grep main.tf  # Ensure main.tf exists
```

### **Initialize Terraform:**
```sh
terraform init
```

### **Check what Terraform will do:**
```sh
terraform plan
```

### **Apply Terraform Configuration to create the GKE cluster:**
```sh
terraform apply
```

---

## **STEP 5: Configure `kubectl` for GKE**

### **Install additional Google Cloud CLI plugin (if needed):**
```sh
sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
```

### **Get Kubernetes credentials for your cluster:**
```sh
gcloud container clusters get-credentials go-ethereum-cluster --zone us-central1-f
```

### **Verify the cluster is active:**
```sh
kubectl cluster-info
```

### **Check available nodes:**
```sh
kubectl get nodes
```

### **List available namespaces:**
```sh
kubectl get namespace
```

### **List running pods in the `devops-test-gke` namespace:**
```sh
kubectl get pods -n devops-test-gke
```
Example output:
```
NAME                                   READY   STATUS    RESTARTS   AGE
go-ethereum-hardhat-547946667d-gmv8w   1/1     Running   0          8m37s
go-ethereum-hardhat-547946667d-sbdkq   1/1     Running   0          16m
go-ethereum-hardhat-547946667d-zrrsv   1/1     Running   0          8m37s
```

### **Access a running pod:**
```sh
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```
Example:
```sh
kubectl exec -it go-ethereum-hardhat-547946667d-gmv8w -n devops-test-gke -- /bin/sh
```

---

## **STEP 6: Deploy Private Docker Images (If Required)**

### **If using a private container registry, create a Kubernetes secret:**
```sh
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<your-dockerhub-username> \
  --docker-password=<your-dockerhub-password> \
  --docker-email=<your-email@example.com>
```

### **Modify Terraform deployment configuration to use the secret:**
```hcl
spec {
  image_pull_secrets {
    name = "dockerhub-secret"
  }
}
```

---

## **Visuals and Outputs**

![Cluster Screenshot](https://github.com/user-attachments/assets/6902a1bf-8bf0-419e-98b7-d8e56304f44c)

![Pod Status Screenshot](https://github.com/user-attachments/assets/575906f4-beb7-4e9e-9da8-c7bf4fddd36a)

![image](https://github.com/user-attachments/assets/4a2486ba-8045-4b9e-9138-c817e1778fd9)


---
