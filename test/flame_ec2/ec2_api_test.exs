defmodule FlameEC2.EC2ApiTest do
  use ExUnit.Case

  doctest FlameEC2.EC2Api

  setup_all do
    System.put_env("AWS_ACCESS_KEY_ID", "xxxxxxxxxxxx")
    System.put_env("AWS_SECRET_ACCESS_KEY", "xxxxxxxxxxxx")

    on_exit(fn ->
      System.delete_env("AWS_ACCESS_KEY_ID")
      System.delete_env("AWS_SECRET_ACCESS_KEY")
    end)

    FlameEC2.QuickConfigs.sync_localstack_with_ec2_mock()
  end

  test "code loaded" do
    assert Code.loaded?(FlameEC2.EC2Api)
  end

  test "correct query parameters with valid backend state", context do
    config = FlameEC2.QuickConfigs.simple_valid_config()
    state = FlameEC2.BackendState.new(config, [])

    parsed = FlameEC2.EC2Api.build_params_from_state(state)

    assert parsed["Action"] == "RunInstances"
    assert parsed["ImageId"] == "ami-123"
    assert parsed["InstanceType"] == "t3.nano"
    assert parsed["MaxCount"] == 1
    assert parsed["MinCount"] == 1

    assert parsed["NetworkInterface.1.AssociatePublicIpAddress"] == false
    assert parsed["NetworkInterface.1.DeleteOnTermination"] == true
    assert parsed["NetworkInterface.1.DeviceIndex"] == 0
    assert parsed["NetworkInterface.1.SubnetId"] == "subnet-123"
    assert parsed["NetworkInterface.1.SecurityGroupId.1"] == "sg-123"

    assert parsed["TagSpecification.1.ResourceType"] == "instance"
    assert parsed["TagSpecification.1.Tag.1.Key"] == "FLAME_PARENT_IP"
    assert parsed["TagSpecification.1.Tag.1.Value"] == context[:local_ipv4]
    assert parsed["TagSpecification.1.Tag.2.Key"] == "FLAME_PARENT_APP"
    assert parsed["TagSpecification.1.Tag.2.Value"] == :flame_ec2

    assert parsed["UserData"]
    {:ok, decoded} = Base.decode64(parsed["UserData"])

    systemd_service = FlameEC2.Templates.systemd_service(app: state.config.app)
    env = FlameEC2.Templates.env(vars: state.runner_env)

    start_script =
      FlameEC2.Templates.start_script(
        app: state.config.app,
        systemd_service: systemd_service,
        env: env,
        aws_region: state.config.aws_region,
        s3_bundle_url: state.config.s3_bundle_url,
        s3_bundle_compressed?: state.config.s3_bundle_compressed?
      )

    assert decoded == start_script
  end

  test "correct query parameters with launch template in state" do
    config =
      FlameEC2.QuickConfigs.simple_valid_config()
      |> Keyword.put(:image_id, nil)
      |> Keyword.put(:launch_template_id, "lt-123")
      |> Keyword.put(:launch_template_version, "1")

    state = FlameEC2.BackendState.new(config, [])

    parsed = FlameEC2.EC2Api.build_params_from_state(state)

    assert parsed["LaunchTemplate.LaunchTemplateId"] == "lt-123"
    assert parsed["LaunchTemplate.Version"] == "1"
    assert not Map.has_key?(parsed, "ImageId")
  end

  test "successfully launches an instance", context do
    state =
      FlameEC2.BackendState.new(
        [
          auto_configure: true,
          app: :flame_ec2,
          s3_bundle_url: "s3://code-bucket/code.tar.gz",
          instance_metadata_url: "http://localhost:1338/latest/meta-data",
          instance_metadata_token_url: "http://localhost:1338/latest/api/token",
          ec2_service_endpoint: "http://localhost:4566/ec2"
        ],
        []
      )

    assert %{"instanceId" => _instance_id, "privateIpAddress" => ip} = FlameEC2.EC2Api.run_instances!(state)

    assert List.delete_at(String.split(context[:local_ipv4], "."), 3) == List.delete_at(String.split(ip, "."), 3)
  end
end
