variable "prefix" {
    type        = string
    description = "Prefix for naming resources"
}

variable "zone" {
    type        = string
    description = "Zone this security group will apply to"
}

variable "vpc_id" {
    type        = string
    description = "VPC for this Security Group"
}

variable "resource_group_id" {
    type        = string
    description = "Resource Group for this Security Group"
}

variable "fortigate_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "IPs of team members that will be allowlisted"
}
