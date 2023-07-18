## Update faasd core images

Update the image tags in the images attribute set in flake.nix. Next run:

```bash
nix run .#prefetch-images > images.nix
```
