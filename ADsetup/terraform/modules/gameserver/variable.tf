# Define Gameserver attributes.
variable "ami_id" {
  description = "AMI id to use when deploying a new gameserver."
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where the gameserver will reside."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the gameserver."
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "The EC2 key pair name to allow SSH access."
  type        = string
}

variable "user_data" {
  description = "Cloud-init user data for instance bootstrap."
  type        = string
}

variable "vpc_id" {
  description = "The VPC id where the gameserver will be placed."
  type        = string
}

variable "igw_id" {
  description = "The ID of the default Internet Gateway."
  type        = string
}

variable "volume_size" {
  description = "The disk size of the internal HDD."
  type        = string
  default     = "64"
}
