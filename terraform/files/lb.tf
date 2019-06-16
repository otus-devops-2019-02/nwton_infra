resource "google_compute_http_health_check" "reddit-health-check" {
  name        = "reddit-puma"
  timeout_sec = 1
  port        = "9292"
}

resource "google_compute_target_pool" "reddit_pool" {
  name = "reddit"

  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]

  health_checks = [
    "${google_compute_http_health_check.reddit-health-check.name}",
  ]
}

resource "google_compute_forwarding_rule" "reddit_forwarding_rule" {
  name = "reddit-forwarding-rule"

  target = "${google_compute_target_pool.reddit_pool.self_link}"

  port_range = "9292"
}
