# Define Vulnbox attributes.
variable "name" {
  description = "The name assigned to the vulnbox."
  type        = string
}

variable "security_group_id" {
  description = "Security group to apply"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the game will take place."
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where the machines will reside."
}

variable "ami_id" {
  description = "AMI id to use when deploying a new vulnbox."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the vulnbox"
  type        = string
  default     = "t3.micro" # change this: change this if you want a running ad 
}

variable "igw_id" {
  description = "The ID of the default Internet Gateway"
  type        = string
}

variable "volume_size" {
  description = "The disk size of the internal HDD."
  type        = string
  default     = "64"
}

