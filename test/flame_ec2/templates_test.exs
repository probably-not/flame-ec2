defmodule FlameEC2.TemplatesTest do
  use ExUnit.Case

  doctest FlameEC2.Templates

  test "code loaded" do
    assert Code.loaded?(FlameEC2.Templates)
  end

  test "env template" do
    output = """

    MY_ENV_1=123

    MY_ENV_2=456

    MY_ENV_3=789

    """

    assert output == FlameEC2.Templates.env(vars: %{"MY_ENV_1" => "123", "MY_ENV_2" => "456", "MY_ENV_3" => "789"})
  end

  test "systemd template" do
    output = """
    [Unit]
    Description=flame_ec2 service
    After=local-fs.target network.target

    [Service]
    Type=simple
    WorkingDirectory=/srv/flame_ec2/release


    ExecStart=/srv/flame_ec2/release/bin/flame_ec2 start



    ExecStop=/srv/flame_ec2/release/bin/flame_ec2 stop


    Environment=LANG=en_US.utf8
    EnvironmentFile=/srv/flame_ec2/env
    LimitNOFILE=65535
    UMask=0027
    SyslogIdentifier=flame_ec2
    Restart=no
    ExecStopPost=/usr/bin/systemctl poweroff

    [Install]
    WantedBy=multi-user.target
    """

    assert output == FlameEC2.Templates.systemd_service(app: :flame_ec2)
  end

  test "systemd template (custom commands)" do
    output = """
    [Unit]
    Description=flame_ec2 service
    After=local-fs.target network.target

    [Service]
    Type=simple
    WorkingDirectory=/srv/flame_ec2/release


    ExecStart=ls



    ExecStop=ls


    Environment=LANG=en_US.utf8
    EnvironmentFile=/srv/flame_ec2/env
    LimitNOFILE=65535
    UMask=0027
    SyslogIdentifier=flame_ec2
    Restart=no
    ExecStopPost=/usr/bin/systemctl poweroff

    [Install]
    WantedBy=multi-user.target
    """

    assert output ==
             FlameEC2.Templates.systemd_service(app: :flame_ec2, custom_start_command: "ls", custom_stop_command: "ls")
  end

  test "start script" do
    systemd_service = FlameEC2.Templates.systemd_service(app: :flame_ec2)
    env = FlameEC2.Templates.env(vars: %{"MY_ENV_1" => "123"})

    output =
      FlameEC2.Templates.start_script(
        app: :flame_ec2,
        systemd_service: systemd_service,
        env: env,
        aws_region: "us-east-1",
        s3_bundle_url: "s3://code-bucket/code.tar.gz",
        s3_bundle_compressed?: true
      )

    assert String.contains?(output, systemd_service)
    assert String.contains?(output, env)
  end
end
