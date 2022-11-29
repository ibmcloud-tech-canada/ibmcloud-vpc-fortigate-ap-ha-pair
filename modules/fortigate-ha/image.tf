

// Create the Custom image in your local cloud.
resource "ibm_is_image" "vnf_custom_image" {
  resource_group   = var.RESOURCE_GROUP
  href             = var.image
  name             = "${var.CLUSTER_NAME}-fortigate-custom-image-${random_string.random_suffix.result}"
  operating_system = "ubuntu-18-04-amd64"


  timeouts {
    create = "60m"
    delete = "20m"
  }
}
