terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = local.config.common.aws_region
}

variable "json_path" {
  type    = string
  default = "./config.json"
}
locals {
  config = jsondecode(file(var.json_path))
}