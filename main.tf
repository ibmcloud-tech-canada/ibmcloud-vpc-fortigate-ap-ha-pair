provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region

  ibmcloud_timeout = 300
}

# Get the resource group for this tenant
resource "ibm_resource_group" "group" {
  name = "${var.prefix}-rg"
}

# Create the edge vpc
resource "ibm_is_vpc" "vpc" {
  name                        = "${var.prefix}-fortigate-vpc"
  resource_group              = ibm_resource_group.group.id
  address_prefix_management   = "manual"
  default_security_group_name = "${var.prefix}-sg-default"
  default_network_acl_name    = "${var.prefix}-acl-default"
  default_routing_table_name  = "${var.prefix}-rt-default"
}

variable "vpc_zones_suffix" {
  type        = list(number)
  default     = [1, 2, 3]
  description = "This is an array with the subzones suffix number in the region to create the nodes in them. List all the zones with: 'ibmcloud ks zone ls --provider vpc-gen2'. Example: [1, 3] having the zone 'us-south' and for the sub-zones: 'us-south-1' and 'us-south-3'"
}

locals {
    vpc_zone_names = ["${var.region}-1","${var.region}-2","${var.region}-3"]
}
# Address prefixes for the workload vpc
resource "ibm_is_vpc_address_prefix" "vpc_address_prefixes" {
  count = 3
  name  = "${var.prefix}-wlap-${format("%02s", count.index + 1)}"
  zone  = local.vpc_zone_names[count.index]
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.vpc_cidrs[count.index]
  is_default = true
}


####################################################################################
# Create the subnets for the Fortigate interfaces
####################################################################################
// Four subnets in zone 1
resource "ibm_is_subnet" "subnet-public" {
  depends_on = [ibm_is_vpc_address_prefix.vpc_address_prefixes]

  for_each = var.fortigate_zone_subnet_cidrs

  name                     = "${var.prefix}-subnet-public-${each.key}"
  zone                     = join("-",[var.region,each.key])
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = ibm_resource_group.group.id
  ipv4_cidr_block          = each.value[0]
}

resource "ibm_is_subnet" "subnet-internal" {
  depends_on = [ibm_is_vpc_address_prefix.vpc_address_prefixes]

  for_each = var.fortigate_zone_subnet_cidrs

  name                     = "${var.prefix}-subnet-internal-${each.key}"
  zone                     = join("-",[var.region,each.key])
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = ibm_resource_group.group.id
  ipv4_cidr_block          = each.value[1]
}

resource "ibm_is_subnet" "subnet-ha" {
  depends_on = [ibm_is_vpc_address_prefix.vpc_address_prefixes]

  for_each = var.fortigate_zone_subnet_cidrs

  name                     = "${var.prefix}-subnet-ha-${each.key}"
  zone                     = join("-",[var.region,each.key])
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = ibm_resource_group.group.id
  ipv4_cidr_block          = each.value[2]
}

resource "ibm_is_subnet" "subnet-mgmt" {
  depends_on = [ibm_is_vpc_address_prefix.vpc_address_prefixes]

  for_each = var.fortigate_zone_subnet_cidrs

  name                     = "${var.prefix}-subnet-mgmt-${each.key}"
  zone                     = join("-",[var.region,each.key])
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = ibm_resource_group.group.id
  ipv4_cidr_block          = each.value[3]
}

resource "ibm_is_subnet_network_acl_attachment" "attach-public" {
  for_each = var.fortigate_zone_subnet_cidrs

  subnet      = ibm_is_subnet.subnet-public[each.key].id
  network_acl = ibm_is_network_acl.fortigate-zone[each.key].id
}

resource "ibm_is_subnet_network_acl_attachment" "attach-internal" {
  for_each = var.fortigate_zone_subnet_cidrs

  subnet      = ibm_is_subnet.subnet-internal[each.key].id
  network_acl = ibm_is_network_acl.fortigate-zone[each.key].id
}

resource "ibm_is_subnet_network_acl_attachment" "attach-ha" {
  for_each = var.fortigate_zone_subnet_cidrs

  subnet      = ibm_is_subnet.subnet-ha[each.key].id
  network_acl = ibm_is_network_acl.fortigate-zone[each.key].id
}

resource "ibm_is_subnet_network_acl_attachment" "attach-mgmt" {
  for_each = var.fortigate_zone_subnet_cidrs

  subnet      = ibm_is_subnet.subnet-mgmt[each.key].id
  network_acl = ibm_is_network_acl.fortigate-zone[each.key].id
}

####################################################################################
# Add Transit Gateway Connection
####################################################################################
resource "ibm_tg_connection" "test_ibm_tg_connection" {
  count        = var.connect_to_transitgateway == true ? 1 : 0

  gateway      = var.transit_gateway_id
  network_type = "vpc"
  name         = "${var.prefix}-edge-vpc-connection"
  network_id   = ibm_is_vpc.vpc.resource_crn
}


####################################################################################
# Create Flow Logs for Edge VPC if COS instance is provided.
####################################################################################
# Use a random suffix to avoid collisions with other buckets
resource "random_string" "cos_random_suffix" {
  length           = 4
  special          = true
  override_special = ""
  min_lower        = 4
}

resource "ibm_cos_bucket" "edge-flow-logs-bucket" {
  count = var.cos_crn == null ? 0 : 1

  bucket_name          = "${var.prefix}-flow-logs-${random_string.cos_random_suffix.result}"
  resource_instance_id = var.cos_crn
  region_location      = var.region
  storage_class        = "smart"
  key_protect          = ibm_kms_key.key_flow_logs[0].id
  force_delete         = true

  expire_rule {
    days               = 7
    enable             = true
  }
}

resource "ibm_is_flow_log" "edge-vpc-flow-log" {
  count = var.cos_crn == null ? 0 : 1
  
  depends_on     = [
    ibm_cos_bucket.edge-flow-logs-bucket
  ]
  name           = "${var.prefix}-edge-vpc-flow-log"
  resource_group = ibm_resource_group.group.id
  target         = ibm_is_vpc.vpc.id
  active         = true
  storage_bucket = ibm_cos_bucket.edge-flow-logs-bucket[count.index].bucket_name
}

resource "ibm_iam_authorization_policy" "flow_log_policy" {
  count = var.cos_guid == null ? 0 : 1

  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = var.cos_guid
  roles                       = ["Writer"]
}

resource "ibm_kms_key" "key_flow_logs" {
  count = var.cos_guid == null ? 0 : 1

  instance_id = var.kms_crn
  key_name       = "${var.prefix}-flowlogs-key"
  key_ring_id = ibm_kms_key_rings.key_ring_fortinet.key_ring_id
  standard_key   = false
  force_delete   = true
}

