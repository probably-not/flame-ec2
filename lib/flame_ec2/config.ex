defmodule FlameEC2.Config do
  @moduledoc false

  alias __MODULE__
  alias FLAME.Parser.JSON
  alias FlameEC2.InstanceMetadata

  require Logger

  @valid_opts [
    :auto_configure,
    :log,
    :image_id,
    :launch_template_id,
    :launch_template_version,
    :subnet_id,
    :security_group_id,
    :instance_type,
    :iam_instance_profile,
    :key_name,
    :aws_region,
    :env,
    :boot_timeout,
    :app,
    :s3_bundle_url,
    :instance_metadata_url,
    :instance_metadata_token_url,
    :ec2_service_endpoint
  ]

  defstruct auto_configure: false,
            log: nil,
            image_id: nil,
            launch_template_id: nil,
            launch_template_version: nil,
            subnet_id: nil,
            security_group_id: nil,
            instance_type: nil,
            iam_instance_profile: nil,
            key_name: nil,
            aws_region: nil,
            env: %{},
            boot_timeout: nil,
            app: nil,
            s3_bundle_url: nil,
            s3_bundle_compressed: false,
            local_ip: nil,
            instance_metadata_url: nil,
            instance_metadata_token_url: nil,
            ec2_service_endpoint: nil

  def new(opts, config) do
    default = %Config{
      auto_configure: false,
      log: Keyword.get(config, :log, false),
      launch_template_version: "$Default",
      instance_type: "t3.nano",
      boot_timeout: 120_000,
      app: System.get_env("RELEASE_NAME"),
      instance_metadata_url: "http://169.254.169.254/latest/meta-data/",
      instance_metadata_token_url: "http://169.254.169.254/latest/api/token",
      ec2_service_endpoint: "https://ec2.amazonaws.com/"
    }

    provided_opts =
      config
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    %Config{} = config = Map.merge(default, Map.new(provided_opts))

    config
    |> maybe_auto_configure!()
    |> validate_app_name!()
    |> validate_s3_bundle_url!()
    |> validate_local_ip!()
    |> validate_instance_creation_details!()
    |> validate_instance_subnet!()
    |> validate_instance_security_group!()
  end

  defp maybe_auto_configure!(%Config{auto_configure: false} = config) do
    {:ok, %{} = metadata} =
      InstanceMetadata.get(config.instance_metadata_url, config.instance_metadata_token_url, [
        "local-ipv4",
        "placement"
      ])

    %Config{
      config
      | local_ip: metadata["local-ipv4"],
        aws_region: metadata["placement"]["region"]
    }
  end

  defp maybe_auto_configure!(%Config{} = config) do
    {:ok, %{} = metadata} =
      InstanceMetadata.get(config.instance_metadata_url, config.instance_metadata_token_url)

    {_mac_address, network_interface} = Enum.at(metadata["network"]["interfaces"]["macs"], 0, %{})

    iam_instance_profile =
      if info_json = metadata["iam"]["info"] do
        JSON.decode!(info_json)["InstanceProfileArn"]
      end

    %Config{
      config
      | image_id: metadata["ami-id"],
        subnet_id: network_interface["subnet-id"],
        security_group_id: network_interface["security-group-ids"],
        instance_type: metadata["instance-type"],
        iam_instance_profile: iam_instance_profile,
        local_ip: metadata["local-ipv4"],
        aws_region: metadata["placement"]["region"]
    }
  end

  defp validate_app_name!(%Config{app: nil}) do
    raise ArgumentError, "You must specify the app for the FlameEC2 backend"
  end

  defp validate_app_name!(%Config{} = config) do
    config
  end

  defp validate_s3_bundle_url!(%Config{s3_bundle_url: nil}) do
    raise ArgumentError, "You must specify the S3 Bundle URL for the FlameEC2 backend"
  end

  defp validate_s3_bundle_url!(%Config{} = config) do
    %Config{config | s3_bundle_compressed: String.ends_with?(config.s3_bundle_url, ".tar.gz")}
  end

  defp validate_local_ip!(%Config{local_ip: nil}) do
    raise ArgumentError, "Could not extract the local IPv4 for the instance via instance metadata"
  end

  defp validate_local_ip!(%Config{} = config) do
    config
  end

  defp validate_instance_creation_details!(%Config{image_id: nil, launch_template_id: nil}) do
    raise ArgumentError,
          "You must specify either the image_id or the launch_template_id for the FlameEC2 backend"
  end

  defp validate_instance_creation_details!(%Config{image_id: _image_id, launch_template_id: nil} = config) do
    config
  end

  defp validate_instance_creation_details!(%Config{image_id: nil, launch_template_id: _launch_template_id} = config) do
    config
  end

  defp validate_instance_creation_details!(%Config{} = config) do
    Logger.warning(
      "Found both image_id #{config.image_id} and launch_template_id #{config.launch_template_id} set for the FlameEC2 configuration. launch_template_id will be preferred over the image_id"
    )

    Map.put(config, :image_id, nil)
  end

  defp validate_instance_subnet!(%Config{subnet_id: nil}) do
    raise ArgumentError, "You must specify a subnet ID for the FlameEC2 backend"
  end

  defp validate_instance_subnet!(%Config{} = config) do
    config
  end

  defp validate_instance_security_group!(%Config{security_group_id: nil}) do
    raise ArgumentError, "You must specify a security group ID for the FlameEC2 backend"
  end

  defp validate_instance_security_group!(%Config{} = config) do
    config
  end
end
