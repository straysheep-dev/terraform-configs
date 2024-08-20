data "digitalocean_ssh_key" "terraform" {
  # Use the name of a public key available in your DigitalOcean account.
  name = var.key_name
}

resource "digitalocean_droplet" "terraform-ubuntu-24-04-x64" {
  count = 1
  image = "ubuntu-24-04-x64"
  name = "terraform-ubuntu-24-04-x64-${count.index}"
  region = var.region_choice
  size = "s-1vcpu-1gb"
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
      # Upgrade packages
      "apt update -yq",
      "NEEDRESTART_MODE=a apt dist-upgrade -yq",
      # Hide last login when connecting over ssh
      "sed -i_bkup 's/^.*PrintLastLog.*$/PrintLastLog no/' /etc/ssh/sshd_config",
      # Enable UFW
      "ufw allow ssh",
      "echo 'y' | ufw enable",
      # Starting with Ubuntu 23.04+ install pipx from apt, then use pipx to install Ansible
      # https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pipx
      "apt install -yq zip",
      # Install RITA
      # This download method was learned and adapted from the Sliver C2 installer script.
      # https://github.com/BishopFox/sliver/blob/127caf54ae22c42fef4cfcabed244daa372073f5/docs/sliver-docs/public/install#L98
      "ARTIFACTS=$(curl -s https://api.github.com/repos/activecm/rita/releases/latest | awk -F '\"' '/browser_download_url/{print $4}' | grep 'tar.gz'); export ARTIFACTS",
      "VERSION=$(curl -s https://api.github.com/repos/activecm/rita/releases/latest | awk -F '\"' '/tag_name/{print $4}'); export VERSION",
      "for URL in $ARTIFACTS; do wget $URL; ARCHIVE=$(basename $URL); tar -xf $ARCHIVE; done",
      # Remove -K from ansible commands
      "sed -i 's/-K //g' rita-$VERSION-installer/install_rita.sh",
      # export BECOME_PASSWORD='' does not work here, -K forces the user to enter a password interactively
      "yes '' | ./rita-$VERSION-installer/install_rita.sh localhost",
      "rita --version",
    ]
  }
}

# If resource names use ${count.index}, you must iterate with for loops when doing output values or use Splat Expressions [*].
# https://developer.hashicorp.com/terraform/language/expressions/for
# https://www.digitalocean.com/community/tutorials/how-to-manage-infrastructure-data-with-terraform-outputs#outputting-complex-structures
output "droplet_ip_address" {
  value = digitalocean_droplet.terraform-ubuntu-24-04-x64[*].ipv4_address
}
