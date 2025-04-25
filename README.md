## README: Deploying a Scalable Web Server on GCP using Terraform
### **Overview**
This project demonstrates how to use Terraform to deploy a scalable web server on Google Cloud Platform (GCP). The infrastructure includes:
- A Virtual Machine (VM) instance running Apache web server.
- An auto-scaling instance group for handling variable workloads based on CPU utilization.
- A firewall rule to allow HTTP traffic (port 80).

---

### **Prerequisites**
Before starting, ensure you have the following:
1. An active GCP account with billing enabled.
2. Terraform installed on your machine ([Download Terraform](https://www.terraform.io/downloads.html)).
3. Google Cloud SDK installed and authenticated:
   ```bash
   gcloud auth login
   gcloud config set project <your_project_id>
   gcloud config set compute/region us-central1
   ```
4. A GCP service account JSON key for authentication.

---

### **Setup Instructions**

#### **1. Clone the Repository or Create a Working Directory**
Create a directory for your project:
```bash
mkdir scalable-web-server
cd scalable-web-server
```

#### **2. Initialize the Project**
Create a `main.tf` file with the Terraform configuration to:
- Define the GCP provider.
- Create a VM instance with a startup script.
- Configure an auto-scaling instance group.
- Set up HTTP firewall rules.

#### **3. Terraform Configuration**
Paste the following configuration in your `main.tf`:

```hcl
provider "google" {
  project     = "absolute-range-453408-f9"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = file("/mnt/data/Infrastructure_through_terraform/scalable-web-server/service_key.json")
}

resource "google_compute_instance" "web-server" {
  name         = "web-server-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
    auto_delete = true
  }

  network_interface {
    network       = "default"
    access_config {}
  }

  tags = ["http-server"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    EOT
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
```

#### **4. Initialize Terraform**
Run the following commands:
1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Plan the deployment:
   ```bash
   terraform plan
   ```
3. Apply the configuration:
   ```bash
   terraform apply
   ```
   Confirm with `yes` to deploy.

---

### **Validation**
1. After deployment, find the VM instance's external IP address in the Terraform output or GCP console.
2. Open a browser and navigate to `http://<external_ip>`. You should see the default Apache HTTP server page.

---

### **Troubleshooting**

#### **1. GCP Authentication Troubleshooting**
Refer to the **GCP authentication troubleshooting section** for handling issues like missing credentials, insufficient permissions, or incorrect project configurations.

---

#### **2. GitHub Push Troubleshooting**

##### **Problem: Large Files in `.terraform` Directory**
If you encounter an error like:
```
File .terraform/providers/... exceeds GitHub's file size limit of 100.00 MB
```

**Solution**:
1. Add `.terraform` and `.terraform.lock.hcl` to `.gitignore`:
   ```bash
   echo ".terraform/" >> .gitignore
   echo ".terraform.lock.hcl" >> .gitignore
   ```
2. Remove `.terraform` from Git's index:
   ```bash
   git rm -r --cached .terraform
   ```
3. Commit the changes:
   ```bash
   git add .gitignore
   git commit -m "Exclude .terraform files"
   ```

---

##### **Problem: Large Files Persist in Git History**
Large files in previous commits must be removed entirely.

**Option 1: Use BFG Repo-Cleaner**
1. Download the **BFG Repo-Cleaner** JAR file from [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/).
2. Run the following to delete `.terraform` files from the history:
   ```bash
   java -jar bfg-1.13.0.jar --delete-files ".terraform*" .
   ```
3. Clean up and prune:
   ```bash
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```
4. Push the cleaned repository:
   ```bash
   git push origin main --force
   ```

**Option 2: Use a Fresh Clone with `git filter-repo`**
1. Clone a fresh copy:
   ```bash
   git clone https://github.com/<your-repo>.git /tmp/fresh-clone
   cd /tmp/fresh-clone
   ```
2. Use `git filter-repo` to remove the large file:
   ```bash
   git filter-repo --path .terraform/providers/.../terraform-provider-google_v6.31.0_x5 --invert-paths
   ```
3. Prune and force push:
   ```bash
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push origin main --force
   ```

---

### **3. GitHub BFG Method**
If the Snap-based installation of BFG fails:
1. Use `git filter-repo` instead (steps above).
2. As a last resort, reinitialize the repository:
   - Remove the Git folder:
     ```bash
     rm -rf .git
     ```
   - Reinitialize and commit:
     ```bash
     git init
     git add .
     git commit -m "Reinitialize repository"
     git remote add origin <repo-url>
     git push -u origin main --force
     ```

---

### **Cleanup**
To avoid incurring charges, destroy the infrastructure:
```bash
terraform destroy
```
Confirm with `yes` to delete all created resources.


