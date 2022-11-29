resource "ibm_is_vpc_routing_table" "fortigate-ha-rt" {
  name = join("-",[var.prefix,"fortigate-ha",substr(var.zone,-1,1),"internal"])
  vpc  = var.fortigate_vpc_id
}

resource "ibm_is_subnet_routing_table_attachment" "public" {
  subnet        = var.subnet_public
  routing_table = ibm_is_vpc_routing_table.fortigate-ha-rt.routing_table
}

resource "ibm_is_subnet_routing_table_attachment" "heartbeat" {
  subnet        = var.subnet_heartbeat
  routing_table = ibm_is_vpc_routing_table.fortigate-ha-rt.routing_table
}

resource "ibm_is_subnet_routing_table_attachment" "management" {
  subnet        = var.subnet_management
  routing_table = ibm_is_vpc_routing_table.fortigate-ha-rt.routing_table
}

resource "ibm_is_vpc_routing_table_route" "internal" {

  vpc           = var.fortigate_vpc_id
  routing_table = var.fortigate_vpc_rt
  zone          = var.zone
  name          = join("-",[var.prefix,"fortigate-ha",substr(var.zone,-1,1)])
  destination   = "0.0.0.0/0"
  action        = "deliver"

  # Primary Internal
  next_hop        = var.internal_ip

  lifecycle {
    ignore_changes = [
      # Ignore changes to creator.  This attribute isn't passable and seems
      # to trigger an update on every apply.
      creator
    ]
  }
}