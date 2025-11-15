// Variables to use accross the project
// which can be accessed by var.project_id
variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "inner-replica-469607-h9"
}

variable "region" {
  description = "The region the cluster in"
  default     = "europe-west3"
}

variable "zone" {
  description = "The zone cluster in"
  default = "europe-west3-a"
}

variable "bucket" {
  description = "GCS bucket for MLE course"
  default     = "quangtp-mle-course"
}

# Config for the compute engine instance

variable "instance_name" {
  description = "Name of the instance"
  default     = "jenkins-k4"
}

variable "machine_type" {
  description = "Machine type for the instance"
  default     = "e2-standard-4"
}

variable "boot_disk_image" {
  description = "Boot disk image for the instance"
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Boot disk size for the instance"
  default     = 50
}

variable "firewall_name" {
  description = "Name of the firewall rule"
  default     = "jenkins-firewall-k4" 
}

variable "ssh_keys" {
  description = "value of the ssh key"
  default = "quangtp29:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4sU+PKdtK00FPEhtjnk3nAHMFYCPCmCQ+PEa4J/UJ4 quangtp29@gmail.com"
}