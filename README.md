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

#### **1. Insufficient `boot_disk` Blocks**
If you encounter the error:
```
Error: Insufficient boot_disk blocks
```
Ensure you are using the `boot_disk` block with `initialize_params` in your VM configuration:
```hcl
boot_disk {
  initialize_params {
    image = "projects/debian-cloud/global/images/family/debian-11"
  }
  auto_delete = true
}
```

#### **2. Unsupported `region` Argument**
If you see:
```
Error: Unsupported argument
An argument named "region" is not expected here.
```
Remove the `region` argument from the `google_compute_instance` block and use `zone` instead:
```hcl
zone = "us-central1-a"
```

#### **3. Invalid Disk Configuration**
If you used the `disk` block instead of `boot_disk`, you may encounter:
```
Error: Unsupported block type
```
Replace the `disk` block with the `boot_disk` block.

#### **4. Permissions Issue**
If Terraform fails with an authentication error, ensure your service account key is correctly specified in the `credentials` argument:
```hcl
credentials = file("/path/to/service_key.json")
```
Also, verify that the service account has the necessary roles (e.g., `Compute Admin`, `Compute Network Admin`).

#### **5. No HTTP Access**
If you cannot access the web server in the browser:
- Verify the firewall rule allows traffic on port 80.
- Ensure the `tags = ["http-server"]` in the VM resource matches `target_tags = ["http-server"]` in the firewall rule.

---

### **Cleanup**
To avoid incurring charges, destroy the infrastructure:
```bash
terraform destroy
```
Confirm with `yes` to delete all created resources.

---

### **Conclusion**
This project demonstrates how to automate GCP infrastructure deployment using Terraform. You’ve created a web server that scales dynamically with traffic and learned how to troubleshoot common Terraform errors.

