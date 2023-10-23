{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:82c69e33a2db3d9b3a8bced0e1ee4833bb4277a71097df843741f9540cee343a";
    sha256 = "1wm3jk4lqzfnlmfrgy4cl2wkix6l9lymvygzk60yy022x03gh5cq";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.27.2";
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
    imageDigest = "sha256:030bf2dd73eac06ff3da645f64c39759268568e6436ce85a61b56da93060a96b";
    sha256 = "0ak4nvi86i88rvs4xjc3nwf0gyj6hkhwlz69virh024qlk135l0q";
    finalImageName = "docker.io/library/nats-streaming";
    finalImageTag = "0.25.5";
  };
  prometheus = {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:c5dd3503828713c4949ae1bccd1d8d69f382c33d441954674a6b78ebe69c3331";
    sha256 = "0bhgq9idmlhcg3f8zg9ayxafqw5vibgyw6apbqb31jv4lfx829p4";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.47.0";
  };
}
