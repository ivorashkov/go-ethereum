# **DevOps Take Home Task**
1. **Fork the following repo:**
    ```sh
      git clone https://github.com/ethereum/go-ethereum
    ```
2. **Update your forked repo with the following functionality:**
   - `When a PR with label CI:Build is merged in it, a trigger kicks in and`
   - `builds a new docker image of the given project`
   - `uploads it to a registry`
     
    ```yaml
      name: CI-Build
      
      on:
      pull_request:
       types: [closed]
       branches: ["master"]
      
      jobs:
      build-docker-image:
       if: github.event.pull_request.merged == true && contains(github.event.pull_request.labels.*.name, 'CI:Build')
       runs-on: ubuntu-latest
      
       steps:
         - name: Checkout repository
           uses: actions/checkout@v4
      
         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v3
      
         # - name: Cache Docker layers
         #   uses: actions/cache@v3
         #   with:
         #     path: /tmp/.buildx-cache
         #     key: ${{ runner.os }}-buildx-${{ github.sha }}
         #     restore-keys: |
         #       ${{ runner.os }}-buildx-
      
         - name: Log in to Docker Hub Container Registry
           uses: docker/login-action@v3
           with:
             username: ${{ vars.DOCKERHUB_USERNAME }}  
             password: ${{ secrets.DOCKERHUB_TOKEN }}  
      
         - name: Build and push Docker image to Docker Hub Registry
           uses: docker/build-push-action@v6
           with:
             context: .
             push: true
             tags: ivaylorashkov/go-ethereum:latest 
    ```

    ![image](https://github.com/user-attachments/assets/bac3c4ab-0066-4de6-91fc-1938b3514d0f)

    
   - `Create a Docker Compose definition that runs a local devnet with the newly built image.`
     `Followed the documentation from https://hub.docker.com/r/ethereum/client-go AND https://geth.ethereum.org/docs/fundamentals/command-line-options`
     
    ```yaml
      version: "3.9"
      
      services:
        geth:
          container_name: geth-devnet-go-ethereum
          image: ivaylorashkov/go-ethereum:latest
          networks:
            - devnet
          ports:
            - "8545:8545"  # Map host port 8545 to container port 8545
            - "8546:8546"  # Map host port 8546 to container port 8546
            - "30303:30303"  # Map host port 30303 to container port 30303
            - "30303:30303/udp"  # Map UDP port 30303 to the container
          volumes:
            - eth_data:/root/.ethereum  # Mount a Docker volume for persistent Ethereum data
      
          command: >
            --dev
            --http
            --http.addr=0.0.0.0
            --http.port=8545
            --http.api=web3,eth,net,personal
            --http.vhosts=*
            --dev.period=5
      
      networks:
        devnet:
          driver: bridge
      
      
      volumes:
        eth_data:  # Define the volume here
     
    ```

2. **Create e new directory named hardhat in the repository. Inside it start a new Sample Hardhat Project**
   - `created folder hardhat/`
   - `created Sample Hardhat Project with the documentation`
   - `created docker image with go-ethereum and hardhat`
   - `uploaded the image to dockerhub with gitActions workflow which triggers after PR with label CI:Deploy`
   - `Add a step to the pipeline which runs the hardhat tests from the sample project against the image with predeployed contracts `

   ```yaml
    name: CI-Deploy to Local Devnet
    
    on:
      pull_request:
        types: [closed]
        branches: ["master"]
    
    env:
      IMAGE: ivaylorashkov/go-ethereum
      OWNER: ivaylorashkov
      IMAGE_TAG: latest
      REGISTRY: docker.io
    
    jobs:
      deploy-hardhat-ethereum:
        if: github.event.pull_request.merged == true && contains(github.event.pull_request.labels.*.name, 'CI:Deploy')
        runs-on: ubuntu-latest
    
        steps:
          - name: Checkout repository
            uses: actions/checkout@v4
    
          - name: Log in to Docker Hub Container Registry
            uses: docker/login-action@v3
            with:
              username: ${{  vars.DOCKERHUB_USERNAME }}  
              password: ${{ secrets.DOCKERHUB_TOKEN }}
    
          - name: Pull Docker image if exists
            run: |
              if docker pull ${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ env.IMAGE_TAG }}; then
                echo "Image exists."
              else
                echo "Image does not exist, skipping pull."
              fi
    
          - name: Stop and remove old container if running
            run: |
              if [ "$(docker ps -q -f name=geth-devnet-go-ethereum)" ]; then
                docker stop geth-devnet-go-ethereum && docker rm geth-devnet-go-ethereum
              fi
    
          - name: Running image container
            run: |
              docker run -d --name geth-devnet-go-ethereum -p 8545:8545 -p 8546:8546 ${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ env.IMAGE_TAG }} \
                --dev --http --http.addr 0.0.0.0 --http.port 8545 \
                --http.api personal,db,eth,net,web3 --dev.period 5
    
          - name: Copy hardhat files to container
            run: |
              docker exec geth-devnet-go-ethereum mkdir -p /git_repo/hardhat
              docker cp hardhat/. geth-devnet-go-ethereum:/git_repo/hardhat/
              docker exec geth-devnet-go-ethereum ls -l /git_repo/hardhat
    
          - name: Install Node.js and npm in container
            run: docker exec geth-devnet-go-ethereum apk add --no-cache nodejs npm
    
          - name: Install Hardhat dependencies
            run: docker exec geth-devnet-go-ethereum sh -c "cd /git_repo/hardhat && npm install"
    
          - name: Check Hardhat version
            run: docker exec geth-devnet-go-ethereum npx hardhat --version
    
          - name: Run Hardhat tests
            run: docker exec geth-devnet-go-ethereum sh -c "cd /git_repo/hardhat && npx hardhat test"
    
          - name: Build new Docker image
            run: |
              docker commit geth-devnet-go-ethereum go-eth-hardhat:latest
              docker tag go-eth-hardhat:latest ${{ env.REGISTRY }}/${{ env.OWNER }}/go-ethereum-hardhat:${{ env.IMAGE_TAG }}
    
          - name: Push new Docker image
            run: docker push ${{ env.REGISTRY }}/${{ env.OWNER }}/go-ethereum-hardhat:${{ env.IMAGE_TAG }}
    
   ```

   ![image](https://github.com/user-attachments/assets/f17814d0-35ee-4690-84b3-8e2a87b2e477)


## **Deploying GKE Cluster Using Terraform**

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

❌ Due to account restrictions I am setting region and zone to be the same.

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
gcloud container clusters get-credentials <your-cluster-name> --zone <your-zone> OR gcloud container clusters get-credentials <your-cluster-name> --region <your-region>
```

Example:
```sh
gcloud container clusters get-credentials go-ethereum-cluster --zone us-central1-f
gcloud container clusters get-credentials go-ethereum-cluster --region=us-central1-f
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

6. **Add Blockscout explorer to the Docker Compose definition created:** [Github](https://github.com/ivorashkov/go-ethereum/tree/master/docker-compose)

 - `docker-compose/ folder has been created with all dependencies and variables according to the official github reposigory: https://github.com/blockscout/blockscout/tree/master`
   
❌ `backend was not able to start due to depricated functions in the code which were causing some issues, db_init and db could not start as well but there were no logs within the pods so I couldn't debug it.`



---
