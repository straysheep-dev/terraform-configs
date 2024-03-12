# terraform-configs

Various configuration files for [terraform](https://developer.hashicorp.com/terraform).

Terraform *is* infrastructure as code. It's not meant to interact with cloud providers to query and set account information in the same way that [`doctl`](https://docs.digitalocean.com/reference/doctl/), [`aws`](https://aws.amazon.com/cli/), or [`Az`](https://learn.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-10.4.1) does. It uses your account authorization to build infrastructure.


Install terraform
=============

Validate your install with one of these public keys:

- [hashicorp public keys](https://www.hashicorp.com/trust/security) `C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F`
- [hashicorp public keys on keybase.io](https://keybase.io/hashicorp) `C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F`
- [hashicorp gpg apt key]https://apt.releases.hashicorp.com/gpg) `798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701`

The CLI tool can be installed via apt.

- [terraform CLI tool](https://developer.hashicorp.com/terraform/install)

Ubuntu/Debian install:
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```


## terraform: Azure

- [terraform + Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-powershell?tabs=bash)
	- [Az PowerShell Module](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-11.4.0&tabs=powershell&pivots=windows-psgallery#installation)


## terraform: Digital Ocean

- [terraform + Digital Ocean](https://docs.digitalocean.com/reference/terraform/getting-started/)
- You need a (usually 90 day) personal access token. Save it to your credential manager, as it's only shown during creation
- When using a Yubikey + GPG for SSH, the `var.pvt_key` variable should be commented out, and replaced with `agent = true` instead


## terraform: AWS

- TO DO



Quick Start
=========

Make sure `terrform`'s in your `$PATH`:
```bash
terraform version
```

Write a provider file. The example below is for Digital Ocean.

- `source = "digitalocean/digitalocean"` tells terraform the cloud provider you're using
- `variable "do_token" {}` will prompt you for your personal access token
- `variable "pvt_key" {}` is the path to a private key file (remove this variable if using GPG + Yubikey for SSH)
- `name = "example_key_name"` is what you named the corresponding public key stored in your Digital Ocean account

```tf
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}
#variable "pvt_key" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "example_key_name"
}
```

Write a terraform config file (`.tf`).

```tf
resource "digitalocean_droplet" "terraform-test" {
  image = "ubuntu-22-04-x64"
  name = "terraform-test"
  region = "sfo3"
  size = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    # Use `private_key` if you're using a private key file
    #private_key = file(var.pvt_key)
    # Use `agent = true` if your ssh key is on a Yubikey and the agent can read it
    # Be patient while it's "Still creating...", it can take a minute or two before the Yubikey is called
    agent = true
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "export DEBIAN_FRONTEND=noninteractive",
      # Update the package cache, enable UFW, install ansible, add a public GPG key, clone git repos
      "sudo apt-get update -yq",
      "sudo ufw allow ssh",
      "echo 'y' | sudo ufw enable",
      "apt install -yq python3-pip",
      "python3 -m pip install --user ansible",
      "gpg --keyid-format long --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys '9906 9EB1 2D40 9EA9 3BD1  E52E B09D 00AE C481 71E0'",
      "cd ~/; git clone https://github.com/straysheep-dev/ansible-configs.git",
      "cd ~/; git clone https://github.com/straysheep-dev/linux-configs.git"
    ]
  }
}

```

Finally, the bash lines below do the following three things:

1. Initialize the directory (you only really do this once per directory)
2. Create a plan file (this shows you what you're about to deploy, do this every time)
3. Apply the plan file (deploy the infrastructure)

```bash
terraform init
terraform plan -out=infra.plan
terraform apply "infra.plan"
```

To stop and destroy / delete the resources:

```bash
terraform plan -destroy -out=destroy.plan
terraform apply "destroy.plan"
```


Secrets Management
=================

https://developer.hashicorp.com/vault/docs/what-is-vault

The hashicorp vault should be used to prevent secrets from appearing in scripts, configs, or environment variables.

TO DO