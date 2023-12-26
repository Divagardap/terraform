variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0"
}

variable "region" {
  description = "AWS region"
  default     = "ap-south-1"
}

# variable "cidr_output" {
#   description = "CIDR output from the local script"
#   type        = string
#   default     = data.local_file.script_output.content
# }