variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "homolog", "prod"], var.environment)
    error_message = "Use dev, homolog ou prod."
  }
}

variable "location" { type = string }

variable "instance_name" {
  type    = string
  default = "kubeshop"
}

variable "app_vm_size" {
  type    = string
  default = "Standard_B2als_v2"
}

variable "db_vm_size" {
  type    = string
  default = "Standard_B2als_v2"
}

variable "db_disk_size_gb" {
  type    = number
  default = 16
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" { type = string }

variable "admin_source_cidrs" {
  description = "IPs fixos da equipe com SSH liberado (opcional)"
  type        = list(string)
  default     = []
}
