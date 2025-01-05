defmodule FlameEC2.QuickConfigs do
  @moduledoc false

  def simple_valid_config do
    [
      app: :flame_ec2,
      s3_bundle_url: "s3://code-bucket/code.tar.gz",
      subnet_id: "subnet-123",
      security_group_id: "sg-123",
      image_id: "ami-123",
      instance_metadata_url: "http://localhost:1338/latest/meta-data",
      instance_metadata_token_url: "http://localhost:1338/latest/api/token",
      ec2_service_endpoint: "http://localhost:4566/ec2"
    ]
  end

  def sync_localstack_with_ec2_mock do
    client =
      "xxxxxxxxxxxx"
      |> AWS.Client.create("xxxxxxxxxxxx", "xxxxxxxxxxxx", "us-east-1")
      |> AWS.Client.put_endpoint("localhost")
      |> then(fn client ->
        %AWS.Client{client | port: 4566, proto: "http"}
      end)

    {:ok, %{"CreateVpcResponse" => %{"vpc" => %{"vpcId" => vpc_id}}}, _} =
      AWS.EC2.create_vpc(client, %{
        "CidrBlock" => "10.0.0.0/16"
      })

    {:ok, %{"CreateSubnetResponse" => %{"subnet" => %{"subnetId" => subnet_id}}}, _} =
      AWS.EC2.create_subnet(client, %{
        "VpcId" => vpc_id,
        "CidrBlock" => "10.0.1.0/24"
      })

    {:ok, %{"CreateSecurityGroupResponse" => %{"groupId" => security_group_id}}, _} =
      AWS.EC2.create_security_group(client, %{
        "VpcId" => vpc_id,
        "GroupName" => "main-sg",
        "GroupDescription" => "Main Group"
      })

    path = "./compose-env/ec2_mock_config.json"

    metadata =
      path
      |> File.read!()
      |> Jason.decode!()

    ami_id = "ami-flametest123"
    instance_type = "m5.24xlarge"
    local_ipv4 = "10.0.1.1"

    metadata =
      metadata
      |> put_in(["metadata", "values", "ami-id"], ami_id)
      |> put_in(["metadata", "values", "instance-type"], instance_type)
      |> put_in(["metadata", "values", "local-ipv4"], local_ipv4)
      |> put_in(["metadata", "values", "mac-vpc-id"], vpc_id)
      |> put_in(["metadata", "values", "mac-subnet-id"], subnet_id)
      |> put_in(["metadata", "values", "mac-security-group-ids"], security_group_id)

    metadata
    |> Jason.encode!(pretty: true, maps: :strict)
    |> then(&File.write!(path, &1))

    # We sleep, to make sure that the change has been caught by the local dev stack.
    # Some people may say, well, this is stupid, why are we sleeping inside the code.
    # The answer is simple, this is test code, and we want to make sure that we sleep
    # to allow the external container to update itself with the new configurations.
    # This doesn't affect the test itself - i.e. we aren't sleeping to ensure that
    # stuff has happened, this happens as part of the setup for tests, so that the
    # external dependencies are all ready to go when the tests actually run.
    Process.sleep(10_000)

    [
      vpc_id: vpc_id,
      subnet_id: subnet_id,
      security_group_id: security_group_id,
      ami_id: ami_id,
      instance_type: instance_type,
      local_ipv4: local_ipv4
    ]
  end

  def local_auto_configure do
    FlameEC2.BackendState.new([],
      auto_configure: true,
      instance_metadata_url: "http://localhost:1338/latest/meta-data",
      instance_metadata_token_url: "http://localhost:1338/latest/api/token",
      ec2_service_endpoint: "http://localhost:4566/ec2",
      app: :local_testing,
      s3_bundle_url: "s3://code/release.tar.gz"
    )
  end
end
