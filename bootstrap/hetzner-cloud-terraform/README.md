# Bootstrap faasd on Nixos

This example uses terraform and deploy-rs to deploy a faasd instance on Hetzner Cloud.

1. [Sign up for Hetzner Cloud](https://hetzner.cloud/?ref=EIOIDMcuuXRl)
2. You will need to have [Nix](https://nixos.org/) installed. This project uses an experimental feature called `flakes` that needs to be enabled.

   To enable flake support, add the following line to `~/.config/nix/nix.conf`

   ```
   experimental-features = nix-command flakes
   ```

3. Create a new flake from the `hc-bootstrap` template in the specified directory.
   ```
   nix flake new -t github:welteki/faasd-nix#hc-bootstrap faasd-bootstrap
   ```
4. cd into the directory and activate the development shell. This will make sure all the required tools such as terraform and deploy-rs are available your shell.
   ```
   cd faasd-bootstrap
   nix develop
   ```
5. Run `terraform init`
6. Configure the deployment as needed by updating the `config.json` file:

   | Variable         | Description             | Default | Sensitive |
   | ---------------- | ----------------------- | ------- | --------- |
   | `hc_token`       | Hetzner Cloud API token | None    | true      |
   | `ssh_public_key` | Public SSH key          | None    |           |

7. Run `terraform apply`
   > The terraform module uses [NixOs-Infect](https://github.com/elitak/nixos-infect) to install nixos over the existing os on the Hetzner server instance. This can sometimes take between 2 and 3 minutes. The next steps can only be executed when the infect script has finished succesfully. Currently the terraform module does not wait for this to finish.
8. View the terraform output for the deploy command and run it.
   ```
   terraform output deploy_cmd
   deploy_cmd = deploy .#faasd --hostname=178.128.39.201 --ssh-user=root
   ```
9. View the terraform output for the gateway url and faas-cli login command
   ```
   terraform output
   deploy_cmd = "deploy .#faasd --hostname=178.128.39.201 --ssh-user=root"
   gateway_url = "http://178.128.39.201:8080/"
   login_cmd = "ssh root@178.128.39.201 'cat /var/lib/faasd/secrets/basic-auth-password' | faas-cli login -g http://178.128.39.201:8080/ -s"
   ```
