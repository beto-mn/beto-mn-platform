terraform {
  backend "s3" {
    bucket                 = "beto-mn-contact-api-terraform-state"
    key                    = "terraform.tfstate"
    region                 = "mx-central-1"
    encrypt                = true
    skip_region_validation = true
  }
}
