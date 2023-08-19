## Update faasd core images

Update the image tags in the images attribute set in flake.nix. Next run:

```bash
nix run .#prefetch-images > images.nix
```

Update NixOS module options doc

```bash
nix run .#gen-options-doc
```
