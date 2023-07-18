images: { writeShellScriptBin, pkgs, ... }:

writeShellScriptBin "prefetch-images" ''
  echo "Fetching gateway image">&2
  gateway=`${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --image-name ${images.gateway.name} --image-tag ${images.gateway.tag} | sed '2~1 s/^/  /'`

  echo "Fetching queue-worker image">&2
  queue_worker=`${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --image-name ${images.queue-worker.name} --image-tag ${images.queue-worker.tag} | sed '2~1 s/^/  /'`

  echo "Fetching nats image">&2
  nats=`${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --image-name ${images.nats.name} --image-tag ${images.nats.tag} | sed '2~1 s/^/  /'`

  echo "Fetching prometheus image">&2
  prometheus=`${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --image-name ${images.prometheus.name} --image-tag ${images.prometheus.tag} | sed '2~1 s/^/  /'`

  echo "{
    gateway = ''${gateway};
    queue-worker = ''${queue_worker};
    nats = ''${nats};
    prometheus = ''${prometheus};
  }"
''
