# main.tf

# Util Module
# - Random Prefix Generation
# - Random Password Generation
module "util" {
  source = "./util"
}

# Vsphere Module
# Import OVA and build machine(s)
module "vsphere" {
  source = "./vsphere"

  xcsovapath           = var.xcsovapath
  user                 = var.user
  password             = var.password
  vsphere_server       = var.vsphere_server
  datacenter           = var.datacenter
  vsphere_host_one     = var.vsphere_host_one
  datastore_one        = var.datastore_one
  resource_pool        = var.resource_pool
  nodename             = var.nodename
  outside_network      = var.outside_network
  inside_network       = var.inside_network
  dns_primary          = var.dns_primary
  dns_secondary        = var.dns_secondary
  guest_type           = var.guest_type
  cpus                 = var.cpus
  memory               = var.memory
  certifiedhardware    = var.certifiedhardware
  node_address         = var.node_address
  publicdefaultroute   = var.publicdefaultroute
  publicdefaultgateway = var.publicdefaultgateway
  sitelatitude         = var.sitelatitude
  sitelongitude        = var.sitelongitude
  clustername          = var.sitename
  sitetoken            = var.sitetoken
  cluster_size         = var.cluster_size
}
