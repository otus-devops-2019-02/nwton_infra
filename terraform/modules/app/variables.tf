variable zone {
  description = "Zone for instances"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable apps_env {
  description = "Environment"
  default     = "stage"
}

variable apps_count {
  description = "How many instances run"
  default     = "1"
}
