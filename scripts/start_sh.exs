systemd_service = FlameEC2.Templates.systemd_service(app: "flame_ec2")

rendered = FlameEC2.Templates.start_script(app: "flame_ec2", systemd_service: systemd_service)

File.write!("./example_start.sh", rendered)
