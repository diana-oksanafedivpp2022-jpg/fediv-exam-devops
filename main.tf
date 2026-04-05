terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    endpoint                    = "fra1.digitaloceanspaces.com"
    region                      = "us-east-1" 
    bucket                      = "fediv-exam-state"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_vpc" "vpc" {
  name     = "fediv-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_firewall" "fw" {
  name        = "fediv-firewall"
  droplet_ids = [digitalocean_droplet.node.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_droplet" "node" {
  name     = "fediv-node"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.vpc.id
}

resource "digitalocean_spaces_bucket" "exam_bucket" {
  name   = "fediv-bucket"
  region = "fra1"
}
