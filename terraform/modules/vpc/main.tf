resource "google_compute_firewall" "firewall_ssh" {
  name = "default-allow-ssh"

  description = "Allow SSH from anywhere"
  priority    = 65534

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = "${var.source_ranges}"
}
