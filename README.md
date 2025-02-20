# **Creating GKE Cluster using Terraform**

## **Creating Kubernetes Cluster in GKE**

### What we need:

    1. GKE Account;
    2. Create GKE (Google Kubernetes Engine) cluster in Google Cloud;
    3. Deploys a Kubernetes deployment using container image;
    4. Configures kubectl to interact with the cluster;
    5. Terraform configured;
    6. Gcloud CLI;
    7. Kubectl installed;

**Project:** `pid-goeuweut-devops`\
**Project ID:** `pid-goeuweut-devops`

```sh
kubectl version --client
# gcloud version
# terraform version
```

---

## **Install Google Cloud SDK (gcloud)**

### **Update and Install Required Packages:**

```sh
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip apt-transport-https ca-certificates gnupg
```

### **Add Google Cloud repository key:**

```sh
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
```

### **Add Google Cloud repository:**

```sh
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
```

### **Install Google Cloud SDK:**

```sh
sudo apt update && sudo apt install -y google-cloud-sdk
```

### **Authenticate Google Cloud CLI:**

```sh
gcloud auth login
gcloud auth application-default login
```

---

## **Install Terraform**

### **Download and Install the Latest Terraform:**

```sh
curl -fsSL https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
```

---

## **Authenticate with Google Cloud**

### **Login into Google Account:**

```sh
gcloud auth login
```

### **List Available Projects:**

```sh
gcloud projects list
```

### **Set the Active Project:**

```sh
gcloud config set project pid-goeuweut-devops
gcloud auth application-default set-quota-project pid-goeuweut-devops
gcloud auth application-default print-access-token
```

### **Verify the Current Project:**

```sh
gcloud config get-value project
```

### **Check Available Regions:**

```sh
gcloud compute regions list
```

**Choosing region:** `us-central1`

```sh
gcloud compute zones list | grep us-central1
```

**Choosing zone:** `us-central1-f`

---

## **Required Roles for GKE Creation**

The user should have the following roles:

- `roles/container.admin`
- `roles/compute.networkAdmin`
- `roles/iam.serviceAccountUser`

---

## **Pulling Private Docker Image**

If the image is private, create a secret:

```sh
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=your-dockerhub-username \
  --docker-password=your-dockerhub-password \
  --docker-email=your-email@example.com
```

Add to your `spec`:

```hcl
spec {
  image_pull_secrets {
    name = "dockerhub-secret"
  }
}
```

---

## **Deploying Terraform to GKE**

### **Authenticate with Google Cloud:**

```sh
gcloud auth login
gcloud auth application-default login
```

Credentials saved to:
`/home/ivaylorashkov/.config/gcloud/application_default_credentials.json`

### **Set the Project ID:**

```sh
gcloud config set project pid-goeuweut-devops
```

### **Navigate to the Terraform Directory:**

```sh
cd /home/ivaylorashkov/new_repo/go-ethereum/Terraform
ls | grep main.tf
```

### **Initialize Terraform:**

```sh
terraform init
```

### **Plan Terraform Deployment:**

```sh
terraform plan
```

### **Apply Terraform Deployment:**

```sh
terraform apply
```

---

## **GKE Cluster Created - Next Steps**

### **Install GKE Auth Plugin:**

```sh
sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin
```

### **Get Cluster Credentials:**

```sh
gcloud container clusters get-credentials go-ethereum-cluster --zone us-central1-f
```

### **Verify Cluster Status:**

```sh
kubectl cluster-info
kubectl get nodes
kubectl get namespace
kubectl get pods -n devops-test-gke
```

Example Output:

```
NAME                                   READY   STATUS    RESTARTS   AGE
go-ethereum-hardhat-547946667d-gmv8w   1/1     Running   0          8m37s
go-ethereum-hardhat-547946667d-sbdkq   1/1     Running   0          16m
go-ethereum-hardhat-547946667d-zrrsv   1/1     Running   0          8m37s
```

### **Access a Pod:**

```sh
kubectl exec -it go-ethereum-hardhat-547946667d-gmv8w -n devops-test-gke -- /bin/sh
```


![image](https://github.com/user-attachments/assets/6902a1bf-8bf0-419e-98b7-d8e56304f44c)

![image](https://github.com/user-attachments/assets/575906f4-beb7-4e9e-9da8-c7bf4fddd36a)



