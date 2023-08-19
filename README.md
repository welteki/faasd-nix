# faasd-nix - deploy faasd on NixOS

Run serverless functions on NixOS using [faasd](https://github.com/openfaas/faasd) - a lightweight & portable faas engine.

If you are new to [faasd](https://github.com/openfaas/faasd) and [OpenFaaS](https://github.com/openfaas/) checkout the following resources to get started:

- [The faasd README](https://github.com/openfaas/faasd#readme)
- [The OpenFaaS documentation](https://docs.openfaas.com)
- [The official faasd handbook and docs](https://gumroad.com/l/serverless-for-everyone-else)

## Quick start

The easiest way to try out faasd-nix is to run a NixOS vm with nixos-shell.

> This guide assumes you have the experimental flake commands enabled.
> To enable them add the following line to `~/.config/nix/nix.conf`:
>
> ```
> experimental-features = nix-command flakes
> ```

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

## Configuration and options

The faasd NixOS modules include some options to simplify common faasd configuration tasks.

> Full reference: [faasd NixOS module options](./OPTIONS.md)

### Enabeling the service

```nix
{
  services.faasd.enable = true;
}
```

### Gateway configuration

Adjust the gateway timeouts.

```nix
{
  services.faasd.gateway = {
    writeTimeout = 30;
    readTimeout = 30;
    upstreamTimeout = 35;
  };
}
```

### Additional namespaces

Add additional function namespaces using the `services.faasd.namespaces` option.

```nix
{ services.faasd.namespaces = [ "dev" ]; }
```

All namespaces in this list will be created and labeled `openfaas=true` so they can be used with faasd.

### Additional containers and services

Declaratively deploy additional containers.

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

### Parallelism and multiple queues

Increase the parallelism for async function invocations.

```nix
{ services.faasd.defaultQueue.maxInflight = 4; }
```

Easily deploy and configure multiple queues.

```nix
{
  services.faasd.queues.slow-queue = {
    maxInflight = 1;
    natsChannel = "slow-queue";
  };
}
```

> Check the [OpenFaaS documentation](https://docs.openfaas.com/reference/async/) for more info on asynchronous functions.

## Deploy with terraform and deploy-rs

The [bootstrap folder](bootstrap) contains an example of how to provision a NixOS instance on hetzner-cloud using terraform and deploy faasd on it.
