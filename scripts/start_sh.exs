systemd_service = FlameEC2.Templates.systemd_service(app: "flame_ec2")

rendered =
  FlameEC2.Templates.start_script(
    app: "flame_ec2",
    systemd_service: systemd_service,
    aws_region: "us-east-1",
    s3_bundle_url: "s3://code.tar.gz",
    s3_bundle_compressed: true
  )

File.write!("./example_start.sh", rendered)
