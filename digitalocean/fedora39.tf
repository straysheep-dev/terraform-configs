resource "digitalocean_droplet" "terraform-fedora-39-x64" {
  count = 1
  image = "fedora-39-x64"
  name = "terraform-fedora-39-x64-${count.index}"
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
      "sudo dnf upgrade -yq",
      "sudo dnf install -yq python3-pip git tmux firewalld",
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
