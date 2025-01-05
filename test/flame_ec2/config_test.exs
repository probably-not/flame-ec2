defmodule FlameEC2.ConfigTest do
  use ExUnit.Case

  doctest FlameEC2.Config

  @valid_config [
    app: :flame_ec2,
    s3_bundle_url: "s3://code-bucket/code.tar.gz",
    subnet_id: "subnet-123",
    security_group_id: "sg-123",
    image_id: "ami-123",
    instance_metadata_url: "http://localhost:1338/latest/meta-data",
    instance_metadata_token_url: "http://localhost:1338/latest/api/token",
    ec2_service_endpoint: "http://localhost:4566/ec2"
  ]

  setup_all do
    FlameEC2.QuickConfigs.sync_localstack_with_ec2_mock()
  end

  test "code loaded" do
    assert Code.loaded?(FlameEC2.Config)
  end

  test "valid configuration" do
    config = FlameEC2.Config.new(@valid_config, [])

    assert config.app == :flame_ec2
    assert config.s3_bundle_url == "s3://code-bucket/code.tar.gz"
    assert config.s3_bundle_compressed? == true
    assert config.subnet_id == "subnet-123"
    assert config.security_group_id == "sg-123"
    assert config.image_id == "ami-123"
    assert config.instance_type == "t3.nano"
    assert config.launch_template_version == "$Default"
    assert config.boot_timeout == 120_000
  end

  test "s3 bundle compressed?" do
    config = FlameEC2.Config.new(Keyword.put(@valid_config, :s3_bundle_url, "s3://code-bucket/code"), [])
    assert not config.s3_bundle_compressed?

    config = FlameEC2.Config.new(Keyword.put(@valid_config, :s3_bundle_url, "s3://code-bucket/code.tar.gz"), [])
    assert config.s3_bundle_compressed?
  end

  test "environment variables" do
    env = %{"MY_ENV_1" => "123", "MY_ENV_2" => "456", "MY_ENV_3" => "789"}
    config = FlameEC2.Config.new(Keyword.put(@valid_config, :env, env), [])

    assert config.env == env
  end

  describe "instance creation details" do
    test "must have image id or launch template" do
      assert_raise ArgumentError,
                   "You must specify either the image_id or the launch_template_id for the FlameEC2 backend",
                   fn ->
                     FlameEC2.Config.new(Keyword.delete(@valid_config, :image_id), [])
                   end

      with_launch_template =
        @valid_config
        |> Keyword.delete(:image_id)
        |> Keyword.put(:launch_template_id, "template-123")
        |> FlameEC2.Config.new([])

      assert with_launch_template.launch_template_id == "template-123"
    end

    test "launch template takes precedence" do
      with_launch_template =
        @valid_config
        |> Keyword.put(:launch_template_id, "template-123")
        |> FlameEC2.Config.new([])

      assert with_launch_template.image_id == nil
      assert with_launch_template.launch_template_id == "template-123"
    end
  end

  describe "raises on missing must specify keys" do
    must_specify_keys = [:app, :s3_bundle_url, :subnet_id, :security_group_id]

    for key <- must_specify_keys do
      test "no #{key} is invalid" do
        assert_raise ArgumentError, ~r/^You must specify/, fn ->
          FlameEC2.Config.new(Keyword.delete(@valid_config, unquote(key)), [])
        end
      end
    end
  end

  describe "auto_configure" do
    test "auto_configure works properly", context do
      config =
        FlameEC2.Config.new(
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

      assert config.image_id == context[:ami_id]
      assert config.subnet_id == context[:subnet_id]
      assert config.security_group_id == context[:security_group_id]
      assert config.instance_type == context[:instance_type]
      assert config.local_ip == context[:local_ipv4]
      assert config.aws_region == "us-east-1"
    end

    test "prefers user provided configs" do
      config =
        FlameEC2.Config.new(
          [
            auto_configure: true,
            app: :flame_ec2,
            instance_type: "t3.small",
            s3_bundle_url: "s3://code-bucket/code.tar.gz",
            instance_metadata_url: "http://localhost:1338/latest/meta-data",
            instance_metadata_token_url: "http://localhost:1338/latest/api/token",
            ec2_service_endpoint: "http://localhost:4566/ec2"
          ],
          []
        )

      assert config.instance_type == "t3.small"
    end
  end
end
