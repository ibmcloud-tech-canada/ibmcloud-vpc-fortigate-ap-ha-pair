locals {
  allow_ips = {for s in var.fortigate_allowed_cidrs: index(var.fortigate_allowed_cidrs, s) => s}
}


resource "ibm_is_network_acl" "fortigate-zone" {

  for_each = var.fortigate_zone_subnet_cidrs

  name = "${var.prefix}-fortigate-zone-acl-${each.key}"
  vpc  = ibm_is_vpc.vpc.id
  rules {
    name        = "allow-all-outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "allow-ibm-inbound"
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    source      = "161.26.0.0/16"
  }
  rules {
    name        = "allow-all-zone1-inbound"
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    source      = var.vpc_cidrs[each.key - 1]
  }
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-dns-response"
    source      = "0.0.0.0/0"
    udp {
        source_port_max = 53
        source_port_min = 53     
    }
  }
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-ha-udp-sync-response"
    source      = "0.0.0.0/0"
    udp {
      source_port_max = 703
      source_port_min = 703     
      }
  }
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-ha-tcp-sync-response"
    source      = "0.0.0.0/0"
    tcp {
      source_port_max = 703
      source_port_min = 703     
    }
  }   
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-ha2-tcp-sync-response"
    source      = "0.0.0.0/0"
    tcp {
      source_port_max = 700
      source_port_min = 700     
    }
  }                                               
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-unicast-heartbeat-response"
    source      = "0.0.0.0/0"
    udp {
      source_port_max = 730
      source_port_min = 730     
    }
  }
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-714-response"
    source      = "0.0.0.0/0"
    udp {
      source_port_max = 714
      source_port_min = 714     
    }
  }
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-ntp-response"
    source      = "0.0.0.0/0"
    udp {
      source_port_max = 123
      source_port_min = 123     
    }
  }
  rules {
    action       = "allow"
    destination  = var.vpc_cidrs[each.key - 1]
    direction    = "inbound"
    name         = "allow-dhcp1-response"
    source       = "0.0.0.0/0"
    udp {
      source_port_max = 68
      source_port_min = 67    
    }
  }                          
  rules {
    action      = "allow"
    destination = var.vpc_cidrs[each.key - 1]
    direction   = "inbound"
    name        = "allow-https-response"
    source      = "0.0.0.0/0"
    tcp {
      source_port_max = 443
      source_port_min = 443     
    }
  }  
  rules {
      action      = "allow"
      destination = var.vpc_cidrs[each.key - 1]
      direction   = "inbound"
      name        = "allow-http-response"
      source      = "0.0.0.0/0"
      tcp {
        source_port_max = 80
        source_port_min = 80     
      }
  }
  dynamic "rules" {
    for_each = local.allow_ips

    content {
      action      = "allow"
      destination = ibm_is_subnet.subnet-public[each.key].ipv4_cidr_block
      direction   = "inbound"
      name        = format("allow-trusted-ips%02d", rules.key)
      source      = rules.value
    }
  }
  dynamic "rules" {
    for_each = local.allow_ips

    content {
      action      = "allow"
      destination = ibm_is_subnet.subnet-mgmt[each.key].ipv4_cidr_block
      direction   = "inbound"
      name        = format("allow-trusted-ips-mgmt%02d", rules.key)
      source      = rules.value
    }
  }
}
