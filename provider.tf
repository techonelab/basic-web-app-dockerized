terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.85.0"
    }
  }
  backend "s3" {
    bucket  = "sanisbucket"
    key     = "demotfstate/terraform.tfstate"
    encrypt = true
    region  = "ap-southeast-1"
    use_lockfile = true #comment this out on first terraform init command then uncomment and rerun terraform init command
  }
}
