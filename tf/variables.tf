variable "cluster_size" {
  type        = number
  description = "REQUIRED:  Set Cluster Size, options are 1 or 3 today."
  default     = 1
}
variable "user" {
  type        = string
  description = "REQUIRED:  Provide a vpshere username.  [admin@vsphere.local]"
  default     = "admin@vsphere.local"
}
variable "password" {
  type        = string
  description = "REQUIRED:  Provide a vsphere password."
  default     = "pass@word1"
}
variable "vsphere_server" {
  type        = string
  description = "REQUIRED:  Provide a vsphere server or appliance. [vSphere URL (IP, hostname or FQDN)]"
  default     = ""
}
variable "datacenter" {
  type        = string
  description = "REQUIRED:  Provide a Datacenter Name."
  default     = "Default Datacenter"
}
variable "vsphere_host_one" {
  type        = string
  description = "REQUIRED:  Provide a vcenter host. [vCenter URL (IP, hostname or FQDN)]"
  default     = ""
}
variable "datastore_one" {
  type        = string
  description = "REQUIRED:  Provide a Datastore Name."
  default     = ""
}
variable "resource_pool" {
  type        = string
  description = "REQUIRED:  Provide a Resource Pool Name."
  default     = ""

}
# Virtual Machine configuration

# Outside Network
variable "outside_network" {
  type        = string
  description = "REQUIRED:  Provide a Name for the Outside Interface Network. [ SLO ]"
  default     = "SLO"
}
variable "inside_network" {
  type        = string
  description = "REQUIRED:  Provide a Name for the Inside Interface Network. [ SLI ]"
  default     = "SLI"
}
# VM Number of CPU's
variable "cpus" {
  type        = number
  description = "REQUIRED:  Provide a vCPU count.  [ Not Less than 4, and do not limit each instance less than 2.9GHz ]"
  default     = 4
}
# VM Memory in MB
variable "memory" {
  type        = number
  description = "REQUIRED:  Provide RAM in Mb.  [ Not Less than 14336Mb ]"
  default     = 14336
}
#OVA Path
variable "xcsovapath" {
  type        = string
  description = "REQUIRED: Path to XCS OVA. See https://docs.cloud.f5.com/docs/images/node-vmware-images"
  default     = "/home/michael/Downloads/centos-7.2009.10-202107041731.ova"
}
#Guest Type
variable "guest_type" {
  type        = string
  description = "Guest OS Type: centos7_64Guest, other3xLinux64Guest"
  default     = "other3xLinux64Guest"
}

variable "certifiedhardware" {
  type        = string
  description = "REQUIRED: XCS Certified Hardware Type: vmware-voltmesh, vmware-voltstack-combo, vmware-regular-nic-voltmesh, vmware-multi-nic-voltmesh, vmware-multi-nic-voltstack-combo"
  default     = "vmware-regular-nic-voltmesh"
}

variable "node_address" {
  type        = string
  description = "REQUIRED: XCS Node Public Interfaces Addresses"
  default     = ""
}

variable "publicdefaultroute" {
  type        = string
  description = "REQUIRED: XCS Public default route.  Must include CIDR notation."
  default     = "0.0.0.0/0"
}

variable "publicdefaultgateway" {
  type        = string
  description = "REQUIRED: XCS Public default route.  Must include CIDR notation."
  default     = "192.168.125.1"
}

variable "sitelatitude" {
  type        = string
  description = "REQUIRED: Site Physical Location Latitude. See https://www.latlong.net/"
  default     = "30"
}
variable "sitelongitude" {
  type        = string
  description = "REQUIRED: Site Physical Location Longitude. See https://www.latlong.net/"
  default     = "-75"
}

variable "dns_primary" {
  description = "REQUIRED: XCS Site DNS Servers."
  type        = string
  default     = "8.8.8.8"
}

variable "dns_secondary" {
  description = "REQUIRED: XCS Site DNS Servers."
  type        = string
  default     = "8.8.4.4"
}

variable "nodename" {
  type        = string
  description = "REQUIRED: Site Node Name."
  default     = "scaled-worker"
}

variable "clustername" {
  type        = string
  description = "REQUIRED: Site Cluster Name."
  default     = "coleman-vsphere-cluster"
}

variable "sitename" {
  type        = string
  description = "REQUIRED:  This is name for your deployment"
  default     = "adrastea"
}

variable "sitetoken" {
  type        = string
  description = "REQUIRED: Site Registration Token."
  default     = "12345678910"
}
