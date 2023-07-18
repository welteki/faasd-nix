{
  gateway = {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:9e9f1e97a9c1243ac3d92387679e55094a6cd6162fd28fff51a125bba8c5cfcc";
    sha256 = "04kvxjdzwmz488cg8w5v9x0pryr3wjr1mkk0gpfyr8yw25lnyzmn";
    finalImageName = "ghcr.io/openfaas/gateway";
    finalImageTag = "0.26.3";
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
    imageDigest = "sha256:0d6971f0a7191bd2fe3d762045e097da478e59c1305223c9fb9323e35c240f40";
    sha256 = "008b7b46q6rwba9hdsyw16mibxmxf701726z9idvkh5akmcq0c6i";
    finalImageName = "docker.io/library/nats-streaming";
    finalImageTag = "0.25.3";
  };
  prometheus = {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:1a3e9a878e50cd339ae7cf5718fda08381dda2d4ccd28e94bbaa3190d1a566c2";
    sha256 = "1gdnkbbfd9iqvy7xkviggzcci7nba2wwkb54sjpnb7vni4464kzw";
    finalImageName = "docker.io/prom/prometheus";
    finalImageTag = "v2.41.0";
  };
}
