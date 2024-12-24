defmodule FlameEC2.EC2Api do
  @moduledoc false

  import FlameEC2.Utils

  alias FlameEC2.BackendState
  alias FlameEC2.Config

  def run_instances!(%BackendState{} = state) do
    params =
      state.config
      |> params_from_config()
      |> Map.merge(instance_tags(state))
      |> Map.put("Action", "RunInstances")
      |> flatten_json_object()
      |> Map.filter(fn {_k, v} -> not is_nil(v) end)
      |> URI.encode_query()

    uri =
      state.config.ec2_service_endpoint
      |> URI.new!()
      |> URI.append_query(params)
      |> URI.to_string()

    credentials = :aws_credentials.get_credentials()

    case credentials do
      :undefined ->
        raise "No AWS credentials found in env or in credentials cache"

      %{} ->
        Req.new(
          url: uri,
          method: :get,
          headers: [{:accept, "application/json"}],
          aws_sigv4: [
            service: "ec2",
            access_key_id: credentials.access_key_id,
            secret_access_key: credentials.secret_access_key,
            token: credentials[:token],
            region: credentials[:region]
          ]
        )
    end
  end

  defp instance_tags(%BackendState{}) do
    %{}
  end

  defp params_from_config(%Config{} = config) do
    base_params = %{
      "MaxCount" => 1,
      "MinCount" => 1,
      "KeyName" => config.key_name,
      "SecurityGroupId" => [config.security_group_id],
      "SubnetId" => config.subnet_id,
      "InstanceType" => config.instance_type,
      "IamInstanceProfile" => %{
        "Arn" => config.iam_instance_profile
      },
      "InstanceInitiatedShutdownBehavior" => "terminate"
    }

    Map.merge(base_params, creation_details_params(config))
  end

  defp creation_details_params(%Config{launch_template_id: launch_template_id} = config)
       when is_binary(launch_template_id) and launch_template_id != "" do
    %{
      "LaunchTemplate" => %{
        "LaunchTemplateId" => launch_template_id,
        "Version" => config.launch_template_version
      }
    }
  end

  defp creation_details_params(%Config{image_id: image_id})
       when is_binary(image_id) and image_id != "" do
    %{
      "ImageId" => image_id
    }
  end
end
