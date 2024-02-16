{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:a0814d6ede0a8a5fadb5b7e71f3fbfafef1d7a5f6e814babedfd24353a71641b";
    sha256 = "1i33f66zxbqhbjcpps5sha6zyhd705gpl0xabjpjayqybv6m96r0";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.27.5";
  };
  queue-worker = {
    imageName = "ghcr.io/openfaas/queue-worker";
    imageDigest = "sha256:978ed61fa5dbfb90b6fd00bdbf15965d03d49d7d5d720a653d1c180ca7740162";
    sha256 = "0chm5rzz1hc4fhhmfbwjqa1c8mhdg0mf7i4pfbqas4hhv1bvyn89";
    finalImageName = "ghcr.io/openfaas/queue-worker";
    finalImageTag = "0.14.1";
  };
  nats = {
    imageName = "docker.io/library/nats-streaming";
    imageDigest = "sha256:d3175589326bc542cdc97ec4900237e1b603492994037e2e0451fb86de40bfb0";
    sha256 = "13d5m5fyyqjqbq96f5q7rlnqbkqsl8fmz9q5fdqps2gz67bkdz5g";
    finalImageName = "docker.io/library/nats-streaming";
    finalImageTag = "0.25.6";
  };
  prometheus = {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:beb5e30ffba08d9ae8a7961b9a2145fc8af6296ff2a4f463df7cd722fcbfc789";
    sha256 = "0gp3y00vq7mr1w8jlda345886nvf6m4xvp06zk83pxzxm9glv5xh";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.49.1";
  };
}
