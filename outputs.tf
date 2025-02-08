output "public_ips" {
  description = "Public IP addresses of the instances"
  value       = flatten([
    google_compute_instance.k8s_controller[*].network_interface[0].access_config[0].nat_ip,
    google_compute_instance.k8s_workers[*].network_interface[0].access_config[0].nat_ip
  ])
}
output "private_ips" {
  description = "Private (internal) IP addresses of the instances"
  value       = flatten([
    google_compute_instance.k8s_controller[*].network_interface[0].network_ip,
    google_compute_instance.k8s_workers[*].network_interface[0].network_ip
  ])
}