resource "ibm_iam_service_id" "fortigate-ha-serviceid" {
  name        = "${var.CLUSTER_NAME}-Fortigate-HA-Service-ID-${random_string.random_suffix.result}"
  description = "This id and apikey are used by Fortigate HA to failover"
}

# Create a policy with permissions for moving floating point and for updating route table
# Within the resource group of the edge VPC where the Fortigate is.
resource "ibm_iam_service_policy" "policy" {
  iam_service_id = ibm_iam_service_id.fortigate-ha-serviceid.id
  roles          = ["Editor"]
  description    = "Update route table and floating-ip binding for failover"

  resources {
    service           = "is"
    resource_group_id = var.RESOURCE_GROUP
  }
}

# Create the API Key that is used by the Fortigate HA Pair
resource "ibm_iam_service_api_key" "fortigate-api-key" {
  name           = "${var.CLUSTER_NAME}-Fortigate-HA-APIKey-${random_string.random_suffix.result}"
  iam_service_id = ibm_iam_service_id.fortigate-ha-serviceid.iam_id
  store_value    = true
  locked         = false
}