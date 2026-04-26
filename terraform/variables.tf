variable "public_subnet" {
  description = "Subnet para la zona publica"
  default     = "10.0.1.0/24"
}

variable "dmz_subnet" {
  description = "Subnet para la DMZ"
  default     = "10.0.2.0/24"
}

variable "private_subnet" {
  description = "Subnet para la zona privada"
  default     = "10.0.3.0/24"
}
