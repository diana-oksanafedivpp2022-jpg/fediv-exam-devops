terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
    bucket = "fediv-terraform-state"
    key    = "terraform.tfstate"

    # Required by S3 backend but ignored by DigitalOcean
    region = "us-east-1"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

variable "do_token" {
  description = "DigitalOcean API Token"
  sensitive   = true
}

variable "spaces_access_id" {
  description = "Spaces Access Key ID"
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "Spaces Secret Key"
  sensitive   = true
}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# 1. Virtual Private Cloud (VPC)
resource "digitalocean_vpc" "vpc" {
  name     = "fediv-vpc"
  region   = "fra1" # Closest to Ukraine
  ip_range = "10.10.10.0/24"
}

# 2. Firewall configuration
resource "digitalocean_firewall" "fw" {
  name        = "fediv-firewall"
  droplet_ids = [digitalocean_droplet.node.id]

  # Inbound connections
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22" # SSH
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80" # HTTP
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443" # HTTPS
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003" # Custom ports 8000; 8001; 8002; 8003
    source_addresses = ["0.0.0.0/0"]
  }

  # Outbound connections (All ports)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 3. Virtual Machine (Droplet)
resource "digitalocean_droplet" "node" {
  name     = "fediv-node"
  size     = "s-2vcpu-4gb" # Meets Minikube/Kubernetes reqs
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  vpc_uuid = digitalocean_vpc.vpc.id
}

# 4. Storage Bucket
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "fediv-bucket"
  region = "fra1"
}

output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}

