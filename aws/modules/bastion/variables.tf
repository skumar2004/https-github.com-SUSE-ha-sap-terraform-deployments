variable "common_variables" {
  description = "Output of the common_variables module"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the deployment machines will be created"
}

variable "availability_zones" {
  type        = list(string)
  description = "Used availability zones"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids to attach the machines network interface"
}

variable "name" {
  description = "hostname, without the domain part"
  type        = string
}

variable "network_domain" {
  description = "hostname's network domain"
  type        = string
}

variable "bastion_count" {
  type        = number
  description = "Number of bastion machines to deploy"
}

variable "instance_type" {
  type        = string
  description = "The instance type of iscsi server node."
  default     = "t2.large"
}

variable "key_name" {
  type        = string
  description = "AWS key pair name"
}

variable "security_group_id" {
  type        = string
  description = "Security group id"
}

variable "host_ips" {
  description = "List of ip addresses to set to the machines"
  type        = list(string)
}

variable "on_destroy_dependencies" {
  description = "Resources objects needed in the on_destroy script (everything that allows ssh connection)"
  type        = any
  default     = []
}

variable "os_image" {
  description = "sles4sap AMI image identifier or a pattern used to find the image name (e.g. suse-sles-sap-15-sp1-byos)"
  type        = string
}

variable "os_owner" {
  description = "OS image owner"
  type        = string
}
