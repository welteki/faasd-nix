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

## Roadmap
### Backlog
- [ ] Allow modification of core services
- [ ] Defining additional services

### Completed
- [x] Running faasd with core services
