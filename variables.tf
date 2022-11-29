##################################################################################
# This file contains variables for configuration of Workload VPC 
##################################################################################

##################################################################################
# General configuration, apply to all resources
##################################################################################
variable "ibmcloud_api_key" {
  type          = string
  sensitive     = true
  description   = "The api key for IBM Cloud access"
}

variable "region" {
  type        = string
  default     = "ca-tor"
  description = "Region to all resources. List all available regions with: ibmcloud regions"
}

variable "prefix" {
  type        = string
  description = "Short string that will be used to prefix the names of all resources"
}

variable "fortigate_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "IPs of team members that will be allowlisted"
}

variable "cos_crn" {
  type        = string
  default     = null
  description = "This is the crn of an existing COS instance.  A bucket will be created to store flow logs"
}

variable "cos_guid" {
  type         = string
  default      = null
  description  = "If you need a service-to-service authorization for writing flow logs, pass the cos guid.  If you already have an authorization, leave this null."
}

variable "kms_crn" {
  type        = string
  description = "This is the crn of an existing KMS instance.  A Key Ring and Key swill be created to encrypt flow logs and server storage."
}

variable "kms_guid" {
  type        = string
  description = "This is the guid of an existing KMS instance.  The guid is needed to set up the service-to-service authorizations."
}

variable "ssh_key_name" {
  type        = string
  description = "Name of ssh key to use when creating Fortigate server instances"
}

variable "connect_to_transitgateway" {
  type        = bool
  default     = true
  description = "Set to false if you do not want to connect the vpc to an existing transit gateway."
}

variable "transit_gateway_id" {
  type        = string
  default     = null
  description = "ID of Transit Gateway to add connection"
}

#----------------------------------------------------------------------------------


##################################################################################
# VPC Configuration
##################################################################################


# Address prefixes for the workload vpc
# This range require IP planning and should be unique for each customer
#
# If generated automatically, each zone in a VPC would have
# 16,384 (mask 255.255.192.0 or /18) IP addresses.  Keeping this default range, an 
# example is:
#
# vpc_cidrs = ["10.251.0.0/18","10.251.64.0/18", "10.251.128.0/18"]
variable "vpc_cidrs" {
  type        = list(string)
  description = "CIDR for each VPC zone."
  default     = ["10.70.0.0/18","10.80.0.0/18", "10.90.0.0/18"]
}


variable "fortigate_zone_subnet_cidrs" {
  default = {
    1 = ["10.70.10.0/24","10.70.20.0/24","10.70.30.0/24","10.70.40.0/24"]
    3 = ["10.90.10.0/24","10.90.20.0/24","10.90.30.0/24","10.90.40.0/24"]
  }
}
