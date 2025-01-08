systemd_service = FlameEC2.Templates.systemd_service(app: "flame_ec2")
env = FlameEC2.Templates.env(vars: %{"MY_ENV_1" => "1234", "MY_ENV_2" => "5678", "MY_ENV_3" => "90"})

rendered =
  FlameEC2.Templates.start_script(
    app: "flame_ec2",
    systemd_service: systemd_service,
    env: env,
    aws_region: "us-east-1",
    s3_bundle_url: "s3://code.tar.gz",
    s3_bundle_compressed?: true
  )

File.write!("./example_start_compressed.sh", rendered)

rendered =
  FlameEC2.Templates.start_script(
    app: "flame_ec2",
    systemd_service: systemd_service,
    env: env,
    aws_region: "us-east-1",
    s3_bundle_url: "s3://code/",
    s3_bundle_compressed?: false
  )

File.write!("./example_start_uncompressed.sh", rendered)
