output "app_external_ip" {
  value = "${module.app.app_external_ip}"
}

output "db_external_ip" {
  value = "${module.db.db_external_ip}"
}

output "app_internal_ip" {
  value = "${module.app.app_internal_ip}"
}

output "db_internal_ip" {
  value = "${module.db.db_internal_ip}"
}

# output "lb_ip_address" {
#   value = "${google_compute_forwarding_rule.reddit_forwarding_rule.ip_address}"
# }

