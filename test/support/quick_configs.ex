defmodule FlameEC2.QuickConfigs do
  @moduledoc false

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

    metadata =
      metadata
      |> put_in(["metadata", "values", "mac-vpc-id"], vpc_id)
      |> put_in(["metadata", "values", "mac-subnet-id"], subnet_id)
      |> put_in(["metadata", "values", "mac-security-group-ids"], security_group_id)

    metadata
    |> Jason.encode!(pretty: true, maps: :strict)
    |> then(&File.write!(path, &1))
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
