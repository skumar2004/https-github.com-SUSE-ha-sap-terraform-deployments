variable "common_variables" {
  description = "Output of the common_variables module"
}

variable "name" {
  description = "hostname, without the domain part"
  type        = string
}

variable "timezone" {
  description = "Timezone setting for all VMs"
  default     = "Europe/Berlin"
}

variable "network_domain" {
  description = "hostname's network domain"
  type        = string
}

variable "userdata" {
  description = "userdata to inject into instance"
  type        = string
}

variable "hana_count" {
  description = "number of hosts like this one"
  default     = 2
}

variable "host_ips" {
  description = "ip addresses to set to the nodes"
  type        = list(string)
}

variable "node_count" {
  description = "Number of Majority Maker nodes"
  type        = number
}

variable "majority_maker_ip" {
  description = "ip address to set to the HANA Majority Maker node. If it's not set the addresses will be auto generated from the provided vnet address range"
  type        = string
  validation {
    condition = (
      var.majority_maker_ip == "" || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.majority_maker_ip))
    )
    error_message = "Invalid IP address format."
  }
}

variable "sbd_disk_id" {
  description = "SBD disk volume id. Only used if sbd_storage_type is shared-disk"
  type        = string
}

variable "iscsi_srv_ip" {
  description = "iscsi server address. Only used if sbd_storage_type is iscsi"
  type        = string
  default     = ""
}

// Provider-specific variables

variable "source_image" {
  description = "Source image used to boot the machines (qcow2 format). It's possible to specify the path to a local (relative to the machine running the terraform command) image or a remote one. Remote images have to be specified using HTTP(S) urls for now."
  type        = string
  default     = ""
}

variable "volume_name" {
  description = "Already existing volume name used to boot the machines. It must be in the same storage pool. It's only used if source_image is not provided"
  type        = string
  default     = ""
}

variable "memory" {
  description = "RAM memory in MiB"
  default     = 512
}

variable "vcpu" {
  description = "Number of virtual CPUs"
  default     = 1
}

variable "mac" {
  description = "a MAC address in the form AA:BB:CC:11:22:22"
  default     = ""
}

variable "isolated_network_id" {
  description = "Network id, internally created by terraform"
  type        = string
}

variable "isolated_network_name" {
  description = "Network name to attach the isolated network interface"
  type        = string
}

variable "storage_pool" {
  description = "libvirt storage pool name for VM disks"
  default     = "default"
}

variable "network_name" {
  description = "libvirt NAT network name for VMs, use empty string for bridged networking"
  default     = ""
}

variable "bridge" {
  description = "a bridge device name available on the libvirt host, leave default for NAT"
  default     = ""
}
