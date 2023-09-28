output "name_of_vpc" {
  value = google_compute_network.vpc-network-team3-project.name

}


output "database_username" {
  value = google_sql_user.users.name
}

output "target-pool-name" {
  value = google_compute_target_pool.team3-project.name
}