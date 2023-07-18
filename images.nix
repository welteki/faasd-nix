{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:decf6016283fee486d6f570063ea52fe98ab60b8674828bcf65d578a1b94ade2";
    sha256 = "0dh9r3hbl2m98939ms0nrmqbq3212z4xmi45ys3pi85v7y6vsjf8";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.26.4";
  };
  queue-worker = {
    imageName = "ghcr.io/openfaas/queue-worker";
    imageDigest = "sha256:50ba67a2d12b211975871871a5fb775c41a6123d96b2167941bfb70a8001781c";
    sha256 = "0g2lcrnl376l5fbi3iqfi8nwsf1nq4h5xkzqd6n1g854bmw3lb02";
    finalImageName = "ghcr.io/openfaas/queue-worker";
    finalImageTag = "0.13.3";
  };
  nats = {
    imageName = "docker.io/library/nats-streaming";
    imageDigest = "sha256:1eed8c2ef0f8b6e0c7264013e3f64f7f2a75195827fce558fde4d277bfcb4b7a";
    sha256 = "15fz7dm6gdanf5vcslp8pw5g1hxhggvjsiscwqgh0h1gi5zzldph";
    finalImageName = "docker.io/library/nats-streaming";
    finalImageTag = "0.25.5";
  };
  prometheus = {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:9309deb7c981e8a94584d9ed689fd62f7ac4549d816fd3881550311cf056a237";
    sha256 = "0p1fsfx9fmzv19xpasajmjawayw5bk56m8dqxb4sfjzkc7pvlr9b";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.45.0";
  };
}
