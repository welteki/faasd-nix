{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:c87624c061fb5029786f97f0ac5df98eff29d5dc3c4c9143a751f4ab4a16cab0";
    sha256 = "0ivpkzk884dp707mqfk7h9ahnvijwn3y5jjas3jb6z2kwhkh0c1m";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.27.0";
  };
  queue-worker = {
    imageName = "ghcr.io/openfaas/queue-worker";
    imageDigest = "sha256:cd577d1c6f9100da102692cc3a034a5d5b3a6d313212e93508e27e3079b42b65";
    sha256 = "1hdgi5yysj67xx72kfiqdm5pvmx1h2vzq3dgl8201skp8xywii1j";
    finalImageName = "ghcr.io/openfaas/queue-worker";
    finalImageTag = "0.14.0";
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
    imageDigest = "sha256:d6ead9daf2355b9923479e24d7e93f246253ee6a5eb18a61b0f607219f341a80";
    sha256 = "0q85rvdfcdk0yl73dq3l2rdi0nqszs0cn56jqj93bxv1zvh0gcgf";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.46.0";
  };
}
