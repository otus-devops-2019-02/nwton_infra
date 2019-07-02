terraform {
  backend "gcs" {
    bucket = "nwton-tf-state-infra"
    prefix = "prod"
  }
}
