variable zone {
  description = "Zone for instances"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable apps_env {
  description = "Environment"
  default     = "stage"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}
