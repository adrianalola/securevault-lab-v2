variable "resource_group_name" {
  description = "Nombre del resource group"
  default     = "rg-securevault-lab"
}

variable "location" {
  description = "Region de Azure"
  default     = "westeurope"
}

variable "db_password" {
  description = "Password de PostgreSQL"
  sensitive   = true
  default     = "SecureVault123!"
}

variable "tags" {
  description = "Tags para todos los recursos"
  default = {
    project     = "securevault-lab"
    environment = "demo"
    managed_by  = "terraform"
  }
}
