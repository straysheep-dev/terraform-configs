resource "digitalocean_droplet" "terraform-ubuntu-24-04-x64" {
  count = 1
  image = "ubuntu-24-04-x64"
  name = "terraform-ubuntu-24-04-x64-${count.index}"
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
      # `needrestart` is new in 22.04+
      # https://github.com/liske/needrestart/issues/109
      #"export NEEDRESTART_SUSPEND=1",
      # Update the package cache, enable UFW, install ansible, add a public GPG key, clone git repos
      "apt-get update -yq",
      "NEEDRESTART_MODE=a apt-get dist-upgrade -yq",
      "ufw allow ssh",
      # Hide last login when connecting over ssh
      "sed -i_bkup 's/^.*PrintLastLog.*$/PrintLastLog no/' /etc/ssh/sshd_config",
      "echo 'y' | sudo ufw enable",
      # Starting with Ubuntu 23.04+ install pipx from apt, then use pipx to install Ansible
      # https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pipx
      "apt install -yq python3-pip zip pipx",
      "pipx ensurepath",
      "pipx ensurepath --global",
      "pipx install --include-deps ansible",
      "gpg --keyid-format long --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys '9906 9EB1 2D40 9EA9 3BD1  E52E B09D 00AE C481 71E0'",
      "cd ~/; git clone https://github.com/straysheep-dev/ansible-configs.git",
      "cd ~/; git clone https://github.com/straysheep-dev/linux-configs.git",
      "systemctl reboot"
    ]
  }
}
