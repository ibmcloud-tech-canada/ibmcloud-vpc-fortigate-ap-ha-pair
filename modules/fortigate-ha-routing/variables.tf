
variable "prefix" {
    description = "Prefix to use in naming new resources"
    type        = string
}

variable "zone" {
    description = "Zone where this Fortigate HA pair is deployed"
    type        = string
}

variable "fortigate_vpc_id" {
    description = "ID of vpc with fortigate"
    type = string
}

variable "fortigate_vpc_rt" {
    description = "Default route table ID of vpc with fortigate"
    type = string
}

variable "subnet_public" {
  description = "ID of subnet for public interface"
  type        = string
}

variable "subnet_internal" {
  description = "ID of subnet for internal interface"
  type        = string
}

variable "subnet_heartbeat" {
  description = "ID of subnet for heartbeat interface"
  type        = string
}

variable "subnet_management" {
  description = "ID of subnet for management interface"
  type        = string
}

# variable "subnet_edge_zone2" {
#   description = "ID of subnet for edge zone 2"
#   type        = string
# }

# variable "subnet_edge_zone3" {
#   description = "ID of subnet for edge zone 3"
#   type        = string
# }

variable "internal_ip" {
  description = "IP of internal interface for Primary Fortigate"
  type        = string
}