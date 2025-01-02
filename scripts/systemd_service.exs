rendered = FlameEC2.Templates.systemd_service(app: "flame_ec2")

File.write!("./example_systemd_service.service", rendered)
