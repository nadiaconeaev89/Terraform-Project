resource "google_compute_network" "vpc-network-team3-project" {
  name                    = var.vpc_name
  auto_create_subnetworks = "true"
  routing_mode            = "GLOBAL"
}