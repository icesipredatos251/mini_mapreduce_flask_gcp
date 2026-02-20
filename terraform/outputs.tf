output "master_ip" {
  value = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
}

output "worker_ips" {
  value = google_compute_instance.worker[*].network_interface[0].access_config[0].nat_ip
}

output "master_internal_ip" {
  value = google_compute_instance.master.network_interface[0].network_ip
}

output "worker_internal_ips" {
  value = google_compute_instance.worker[*].network_interface[0].network_ip
}

output "bucket_name" {
  value = google_storage_bucket.input_bucket.name
}
