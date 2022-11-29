##############################################################################
# Fortigate
##############################################################################

data "ibm_is_security_group" "fortigate-vpc-default-sg" {
  name = ibm_is_vpc.vpc.default_security_group_name
}

module security_groups {
  source = "./modules/fortigate-ha-sg"

  for_each = var.fortigate_zone_subnet_cidrs

  prefix                  = var.prefix
  zone                    = each.key
  vpc_id                  = ibm_is_vpc.vpc.id
  resource_group_id       = ibm_resource_group.group.id
  fortigate_allowed_cidrs = var.fortigate_allowed_cidrs
}


# ## Add an inbound rule to the SG permit https access to specified ips
# resource "ibm_is_security_group_rule" "fortigate-https" {
#   for_each = toset(var.fortigate_allowed_cidrs)
#   group     = ibm_is_vpc.vpc.default_security_group
#   direction = "inbound"
#   remote    = "${each.key}"
#   tcp {
#     port_min = 443
#     port_max = 443
#   }
#   lifecycle {
#     ignore_changes = [
#       group
#     ]
#   }
# }

# ## Add an inbound rule to the SG permit ssh access to specified ips
# resource "ibm_is_security_group_rule" "fortigate-ssh" {
#   for_each = toset(var.fortigate_allowed_cidrs)
#   group     = ibm_is_vpc.vpc.default_security_group
#   direction = "inbound"
#   remote    = "${each.key}"
#   tcp {
#     port_min = 22
#     port_max = 22
#   }
#   lifecycle {
#     ignore_changes = [
#       group
#     ]
#   }
# }

# ## Add an inbound rule to the SG permit ping access to specified ips
# resource "ibm_is_security_group_rule" "fortigate-ping" {
#   for_each = toset(var.fortigate_allowed_cidrs)
#   group     = ibm_is_vpc.vpc.default_security_group
#   direction = "inbound"
#   remote    = "${each.key}"
#   icmp {
#     type = 8
#   }
#   lifecycle {
#     ignore_changes = [
#       group
#     ]
#   }
# }

# Create a Key Ring for Fortinet
resource "ibm_kms_key_rings" "key_ring_fortinet" {
  instance_id = var.kms_crn
  key_ring_id = "${var.prefix}-fortinet-keyring"
}

# Create a Key for Fortinet Volumes
resource "ibm_kms_key" "key_fortinet" {
  for_each = var.fortigate_zone_subnet_cidrs

  instance_id = var.kms_crn
  key_name       = "${var.prefix}-fortinet-key-${each.key}"
  key_ring_id = ibm_kms_key_rings.key_ring_fortinet.key_ring_id
  standard_key   = false
  force_delete   = true
}

# Create a Service Authorization for Cloud Block Storage to access Key Protect
resource "ibm_iam_authorization_policy" "volume-encrypt-policy" {
  source_service_name         = "server-protect"
  target_service_name         = "kms"
  target_resource_instance_id = var.kms_guid
  roles                       = ["Reader"]
}

module "fortigate-ha" {
  depends_on = [
    ibm_is_vpc.vpc,
    module.security_groups
  ]

  source = "./modules/fortigate-ha"

  # count = length(var.fortigate_zone_subnet_cidrs)
  for_each = var.fortigate_zone_subnet_cidrs

  REGION                  = var.region
  ZONE                    = join("-",[var.region,each.key])
  VPC                     = ibm_is_vpc.vpc.name
  RESOURCE_GROUP          = ibm_resource_group.group.id
  SUBNET_1                = ibm_is_subnet.subnet-public[each.key].id
  SUBNET_2                = ibm_is_subnet.subnet-internal[each.key].id
  SUBNET_3                = ibm_is_subnet.subnet-ha[each.key].id
  SUBNET_4                = ibm_is_subnet.subnet-mgmt[each.key].id
  FGT1_STATIC_IP_PORT1    = cidrhost(ibm_is_subnet.subnet-public[each.key].ipv4_cidr_block,10)
  FGT1_STATIC_IP_PORT2    = cidrhost(ibm_is_subnet.subnet-internal[each.key].ipv4_cidr_block,10)
  FGT1_STATIC_IP_PORT3    = cidrhost(ibm_is_subnet.subnet-ha[each.key].ipv4_cidr_block,10)
  FGT1_STATIC_IP_PORT4    = cidrhost(ibm_is_subnet.subnet-mgmt[each.key].ipv4_cidr_block,10)
 
  FGT2_STATIC_IP_PORT1    = cidrhost(ibm_is_subnet.subnet-public[each.key].ipv4_cidr_block,11)
  FGT2_STATIC_IP_PORT2    = cidrhost(ibm_is_subnet.subnet-internal[each.key].ipv4_cidr_block,11)
  FGT2_STATIC_IP_PORT3    = cidrhost(ibm_is_subnet.subnet-ha[each.key].ipv4_cidr_block,11)
  FGT2_STATIC_IP_PORT4    = cidrhost(ibm_is_subnet.subnet-mgmt[each.key].ipv4_cidr_block,11)

  FGT1_PORT4_MGMT_GATEWAY = cidrhost(ibm_is_subnet.subnet-mgmt[each.key].ipv4_cidr_block,1)
  FGT2_PORT4_MGMT_GATEWAY = cidrhost(ibm_is_subnet.subnet-mgmt[each.key].ipv4_cidr_block,1)

  # SECURITY_GROUP         = ibm_is_vpc.vpc.default_security_group_name
  SECURITY_GROUP         = module.security_groups[each.key].security_group_name
  SSH_PUBLIC_KEY         = var.ssh_key_name
  BOOT_ENCRYPTION_KEY    = ibm_kms_key.key_fortinet[each.key].crn
  LOGDISK_ENCRYPTION_KEY = ibm_kms_key.key_fortinet[each.key].crn
}

# Set up routing tables according to instructions here
# https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/ibm-cloud-administration-guide/944419/deploying-fortigate-vm-a-p-ha-on-ibm-vpc-cloud-byol
module "fortigate-rt" {
  depends_on = [
    module.fortigate-ha
  ] 
  for_each = var.fortigate_zone_subnet_cidrs

  source = "./modules/fortigate-ha-routing"
  prefix = var.prefix
  zone              = join("-",[var.region,each.key])
  fortigate_vpc_id  = ibm_is_vpc.vpc.id
  fortigate_vpc_rt  = ibm_is_vpc.vpc.default_routing_table
  subnet_public     = ibm_is_subnet.subnet-public[each.key].id
  subnet_internal   = ibm_is_subnet.subnet-internal[each.key].id
  subnet_heartbeat  = ibm_is_subnet.subnet-ha[each.key].id 
  subnet_management = ibm_is_subnet.subnet-mgmt[each.key].id
  internal_ip       = cidrhost(ibm_is_subnet.subnet-internal[each.key].ipv4_cidr_block,10)

}