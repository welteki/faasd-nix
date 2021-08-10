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
