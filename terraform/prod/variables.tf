variable project {
  description = "Project ID"
}

variable region {
  # Описание переменной
  description = "Region"

  # Значение по умолчанию
  default = "europe-west1"
}

variable zone {
  description = "Zone for instances"
  default     = "europe-west1-b"
}

variable apps_count {
  description = "How many instances run"
  default     = "1"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the PRIVATE key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}
