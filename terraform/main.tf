terraform {
  # Версия terraform
  required_version = ">=0.11,<0.12"
}

provider "google" {
  # Версия провайдера
  version = "2.0.0"

  # ID проекта
  project = "${var.project}"

  region = "${var.region}"
}

resource "google_compute_project_metadata_item" "prj-ssh-keys" {
  key = "ssh-keys"

  value = <<EOF
appuser-project:${file("${var.public_key_path}")}
appuser1:${file(var.public_key_path)}
appuser2:${file(var.public_key_path)}
appuser3:${file(var.public_key_path)}
EOF
}
