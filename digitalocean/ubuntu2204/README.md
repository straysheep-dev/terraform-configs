# README

Deploy Ubuntu 22.04 in DigitalOcean.

To set the necessary environment variables, both `deploy.sh` and `destroy.sh` will require the following. This block can be copy and pasted into your terminal session so the variables persist between each script execution. Otherwise you need to enter them each time you execute one of the scripts, or run them from a new terminal tab / session.

```bash
# This section could be copy and pasted into your terminal session so variables persist
if [[ "$TF_VAR_do_token" == '' ]]; then
    echo "Enter DigitalOcean Personal Access Token (no echo)"; read -s do_pat; export TF_VAR_do_token=$do_pat
fi
if [[ "$TF_VAR_pvt_key" == '' ]]; then
    echo "Enter path to a private key or leave empty if using ssh-agent"; read key_file; export TF_VAR_pvt_key=$key_file
fi
if [[ "$TF_VAR_region_choice" == '' ]]; then
    echo "Deploy to which region? [sfo|nyc][1|2|3]"; read region_choice; export TF_VAR_region_choice=$region_choice
fi
if [[ "$TF_VAR_key_name" == '' ]]; then
    echo "Enter an SSH public key name from your DigitalOcean account to use"; read key_name; export TF_VAR_key_name=$key_name
fi
```

Commands in `deploy.sh`:

```bash
terraform init
terraform plan -out infra.plan
terraform apply infra.plan
```

Commands in `destroy.sh`:

```bash
terraform plan -destroy -out destroy.plan
terraform apply destroy.plan
```