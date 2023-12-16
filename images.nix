{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:f95ee4260457bbaef68113a95b2c2aa75e33c526f618e35fd5104e16db7b195e";
    sha256 = "1i32zg6g0x3dpvxjhhpjwa68viz1lgjaszzgnwjl8byq3a1hybdw";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.27.3";
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
    imageDigest = "sha256:3d397227da27f6733a3072f91500de922cfaadb5755455a05a366504d86fd19a";
    sha256 = "13d5m5fyyqjqbq96f5q7rlnqbkqsl8fmz9q5fdqps2gz67bkdz5g";
    finalImageName = "docker.io/library/nats-streaming";
    finalImageTag = "0.25.6";
  };
  prometheus = {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:a67e5e402ff5410b86ec48b39eab1a3c4df2a7e78a71bf025ec5e32e09090ad4";
    sha256 = "003l9lf0f6d1bd06vp02jya6hph2bf5a43qiyd6p3xmaxialyph5";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.48.1";
  };
}
