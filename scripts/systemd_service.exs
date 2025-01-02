rendered = FlameEC2.Templates.systemd_service(app: "flame_ec2", custom_start_command: "ls", custom_stop_command: "ls")

File.write!("./example_systemd_service.service", rendered)
