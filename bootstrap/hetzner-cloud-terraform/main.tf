terraform {
  required_providers {
    hcloud = {
      source  = "nixpkgs/hcloud"
      version = "~> 1.26.0"
    }
  }
  ## Prevent unwanted updates
  required_version = "1.0.8" # Use nix-shell or nix develop
}

variable "hc_token" {
  description = "Hetzner Cloud API token"
}
variable "ssh_key_file" {
  default = "~/.ssh/id_rsa.pub"
  description = "Path to the SSH public key file"
}

provider "hcloud" {
  token = var.hc_token
}

resource "hcloud_ssh_key" "faasd_ssh_key" {
  name = "faasd-ssh-key"
  public_key = file(var.ssh_key_file)
}

resource "hcloud_server" "faasd" {
  name = "faasd"
  image = "ubuntu-20.04"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.faasd_ssh_key.id]
  # Install NixOS 20.05
  user_data = <<EOF
    #cloud-config

    runcmd:
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-21.05 bash 2>&1 | tee /tmp/infect.log
EOF
}

output "deploy_cmd" {
  value = "deploy .#faasd --hostname=${hcloud_server.faasd.ipv4_address} --ssh-user=root"
}
