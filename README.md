> 🛠 **Status: Experimental**
>
> This project is currently in development.

NixOS flake for [faasd](https://github.com/openfaas/faasd)

## Enabeling the service
```nix
{
  services.faasd.enable = true;
}
```

> Learn faasd using [the official handbook and docs](https://gumroad.com/l/serverless-for-everyone-else)

## Defining additional containers and services
This is the grafana example taken from the [serverless-book](https://gumroad.com/l/serverless-for-everyone-else).
```nix
{
  systemd.tmpfiles.rules = [
    "d '/var/lib/faasd/grafana'"
  ];

  services.faasd.containers = {
    grafana = {
      image = "docker.io/grafana/grafana:latest";
      environment = [
        "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin"
        "GF_AUTH_ANONYMOUS_ENABLED=true"
        "GF_AUTH_BASIC_ENABLED=false"
      ];
      volumes = [{ 
        type = "bind";
        source = "./grafana/";
        target = "/etc/grafana/provisioning";
      }];
      cap_add = [ "CAP_NET_RAW" ];
      depends_on = [ "prometheus" ];
      ports = [ "3000:3000" ];
    };
  };
}
```

## Deploying faasd on NixOS
The easiest way to try out faasd is to run a vm with nixos-shell.

1. Start a shell with the tools needed to run the faasd-vm.
    ```sh
    $ nix develop github:welteki/faasd-nix#faasd-vm
    ```
    This will make [nixos-shell](https://github.com/Mic92/nixos-shell) and the [faas-cli](https://github.com/openfaas/faas-cli) available in your shell.
2. Start the faasd-vm.
    ```sh
    $ nixos-shell --flake github:welteki/faasd-nix#faasd-vm
    ```
    This spawns a headless qemu virtual machine with faasd running and provides console access in the same terminal window.
3. Log in as "root" with an empty password.
4. Interact with faasd using the faas-cli.
    ```sh
    # Login
    $ cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login --password-stdin

    # Deploy a function from the function store
    $ faas-cli store deploy figlet

    # Invoke a function
    $ echo "faasd-nix" | faas-cli invoke figlet
    ```
5. Type `Ctrl-a x` to exit the virtual machine or run the `poweroff` command in the virtual machine console.

### Deploy with terraform and deploy-rs
The [bootstrap folder](bootstrap) contains an example of how to provision a NixOS instance on hetzner-cloud using terraform and deploy faasd on it.
