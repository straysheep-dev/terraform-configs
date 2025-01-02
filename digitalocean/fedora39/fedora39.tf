terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}
# Uncomment "pvt_key" if using a passwordless private key file
#variable "pvt_key" {}
variable "key_name" {}
variable "region_choice" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  # Use the name of a public key available in your DigitalOcean account.
  name = var.key_name
}

resource "digitalocean_droplet" "terraform-fedora-39-x64" {
  count  = 1
  image  = "fedora-39-x64"
  name   = "terraform-fedora-39-x64-${count.index}"
  region = var.region_choice
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    # uncomment `private_key` if you're using a passwordless private key file
    #private_key = file(var.pvt_key)
    # uncomment `agent = true` if your ssh key is loaded into the ssh-agent (includes Yubikeys via gpg)
    # Be patient while it's "Still creating...", it can take a minute or two before the Yubikey is called
    agent   = true
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo dnf upgrade -yq",
      "sudo dnf install -yq python3-pip git tmux firewalld zip",
      "sudo systemctl unmask firewalld",
      "sudo systemctl start firewalld",
      "sudo systemctl enable firewalld",
      "python3 -m pip install --user ansible",
      "gpg --keyid-format long --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys '9906 9EB1 2D40 9EA9 3BD1  E52E B09D 00AE C481 71E0'",
      "cd ~/; git clone https://github.com/straysheep-dev/ansible-configs.git",
      "cd ~/; git clone https://github.com/straysheep-dev/linux-configs.git",
      "sudo systemctl reboot"
    ]
  }
}

# If resource names use ${count.index}, you must iterate with for loops when doing output values or use Splat Expressions [*].
# https://developer.hashicorp.com/terraform/language/expressions/for
# https://www.digitalocean.com/community/tutorials/how-to-manage-infrastructure-data-with-terraform-outputs#outputting-complex-structures
output "droplet_ip_address" {
  value = digitalocean_droplet.terraform-fedora-39-x64[*].ipv4_address
}