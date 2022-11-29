resource ibm_is_security_group "fortigate-vpc-sg" {
  name = "${var.prefix}-fortigate-sg-${var.zone}"
  resource_group = var.resource_group_id
  vpc = var.vpc_id
}

## Add an inbound rule to the SG permit https access to specified ips
resource "ibm_is_security_group_rule" "fortigate-https" {
  for_each = toset(var.fortigate_allowed_cidrs)
  group     = ibm_is_security_group.fortigate-vpc-sg.id
  direction = "inbound"
  remote    = "${each.key}"
  tcp {
    port_min = 443
    port_max = 443
  }
}

## Add an inbound rule to the SG permit ssh access to specified ips
resource "ibm_is_security_group_rule" "fortigate-ssh" {
  for_each = toset(var.fortigate_allowed_cidrs)
  group     = ibm_is_security_group.fortigate-vpc-sg.id
  direction = "inbound"
  remote    = "${each.key}"
  tcp {
    port_min = 22
    port_max = 22
  }
}

## Add an inbound rule to the SG permit ping access to specified ips
resource "ibm_is_security_group_rule" "fortigate-ping" {
  for_each = toset(var.fortigate_allowed_cidrs)
  group     = ibm_is_security_group.fortigate-vpc-sg.id
  direction = "inbound"
  remote    = "${each.key}"
  icmp {
    type = 8
  }
}

## Allow traffic within the security group
resource "ibm_is_security_group_rule" "fortigate-sg-rule" {
  group     = ibm_is_security_group.fortigate-vpc-sg.id
  direction = "inbound"
  remote    = ibm_is_security_group.fortigate-vpc-sg.id
}


## Allow all outbound
resource "ibm_is_security_group_rule" "allow-all-outbound" {
  group     = ibm_is_security_group.fortigate-vpc-sg.id
  direction = "outbound"
}