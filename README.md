

Creating GKE Cluster using ./Terraform/main.tf script

Creating Kubernetes Custer in GKE:
What we need:
    1. GKE Account;
    2. Create GKE (Google Kubernetes Engine) cluster in Google Cloud;
    3. Deploys a Kubernetes deployment using container image;
    4. Configures kubectl to interact with the cluster;
    5. Terraform configured;
    6. Gcloud CLI;
    7. Kubectl installed;

project: pid-goeuweut-devops
project ID: pid-goeuweut-devops

kubectl version --client
    Client Version: v1.32.2
    Kustomize Version: v5.5.0
gcloud version
    Google Cloud SDK 510.0.0
    alpha 2025.02.10
    beta 2025.02.10
    bq 2.1.12
    bundled-python3-unix 3.12.8
    core 2025.02.10
    gcloud-crc32c 1.0.0
    gsutil 5.33
terraform version
    Terraform v1.10.5
    on linux_amd64  

Steps:
******** Install Google Cloud SDK (gcloud) ******** 
Update and Install Required Packages:
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip apt-transport-https ca-certificates gnupg

Add Google Cloud repository key:
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

Add Google Cloud repository:
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

Install Google Cloud SDK:
sudo apt update && sudo apt install -y google-cloud-sdk

Authenticate Google Cloud CLI:
gcloud auth login
gcloud auth application-default login

******** Install Terraform ********

Download and Install the Latest Terraform:
curl -fsSL https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip


Login into my google account:
gcloud auth login

List available Projects: 
gcloud projects list

Set the active project:
gcloud config set project pid-goeuweut-devops
gcloud auth application-default set-quota-project pid-goeuweut-devops
gcloud auth application-default print-access-token

Verify the current project:
gcloud config get-value project

Check regions:
gcloud compute regions list
- Choosing region: us-central1
gcloud compute zones list | grep us-central1
- Choosing zone: us-central1-f 

In order to Create GKE the user should have the following roles:
 roles/container.admin, roles/compute.networkAdmin, roles/iam.serviceAccountUserc

for deploying the image, we can easily extrac it from dockerhub if it's public,
but if the image is in private repo we should do the following:

1.kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=your-dockerhub-username \
  --docker-password=your-dockerhub-password \
  --docker-email=your-email@example.com

2.spec {
  image_pull_secrets {
    name = "dockerhub-secret"
  }
}


******** Deploying Terraform to GKE ********

We are running Terraform on local machine so we need to authenticate:
1. Authenticate:
 1.1 gcloud auth login
    - You are now logged in as [ivaylo.s.rashkov@gmail.com].
    - Your current project is [pid-goeuweut-devops].
    - You are now authenticated with the gcloud CLI!
 1.2 gcloud auth application-default login
    - Credentials saved to file: [/home/ivaylorashkov/.config/gcloud/application_default_credentials.json]
    - These credentials will be used by any library that requests Application Default Credentials (ADC).
    - Quota project "pid-goeuweut-devops" was added to ADC which can be used by Google client libraries for billing and quota.
    - You are now authenticated with the gcloud CLI!

2. Just in case set the project-id:
 2.1 gcloud config set project pid-goeuweut-devops

3. Navigate to the directory where main.tf is:
    - pwd: /home/ivaylorashkov/new_repo/go-ethereum/Terraform
    - ivaylorashkov@DESKTOP-RBJR4FO:~/new_repo/go-ethereum/Terraform$ ls | grep main.tf
    *main.tf

4.terraform init
    - Terraform has been successfully initialized!

5.Check what terraform is planning to do:
    5.1 terraform plan

6. Deploy infrastructure:
    6.1 terraform apply

7. Setting up region and zone as zone = us-central1-f, due to Google
Copy policy on 3 zones, which exceeds the limit 250GB since 3*100GB = 300GB

GKE created

1. install: sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin

2.- gcloud container clusters get-credentials <your-cluster-name> --zone <your-zone>
    gcloud container clusters get-credentials go-ethereum-cluster --zone us-central1-f

3. kubectl get nodes
4. kubectl get namespace
6. kubectl get pods -n devops-test-gke

NAME                                   READY   STATUS    RESTARTS   AGE
go-ethereum-hardhat-547946667d-hs9ww   1/1     Running   0          10m
go-ethereum-hardhat-547946667d-j5cn7   1/1     Running   0          10m
go-ethereum-hardhat-547946667d-sk8vk   1/1     Running   0          10m

7. kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

