resource "digitalocean_droplet" "terraform-ubuntu-22-04-x64" {
  image = "ubuntu-22-04-x64"
  name = "terraform-ubuntu-22-04-x64"
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
      "sudo apt-get upgrade -yq",
      "sudo ufw allow ssh",
      "echo 'y' | sudo ufw enable",
      "apt install -yq python3-pip",
      "python3 -m pip install --user ansible",
      "gpg --keyid-format long --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys '9906 9EB1 2D40 9EA9 3BD1  E52E B09D 00AE C481 71E0'",
      "cd ~/; git clone https://github.com/straysheep-dev/ansible-configs.git",
      "cd ~/; git clone https://github.com/straysheep-dev/linux-configs.git",
      "sudo systemctl reboot"
    ]
  }
}
