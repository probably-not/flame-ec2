defmodule FlameEC2.EC2Api do
  @moduledoc false

  import FlameEC2.Utils

  alias FlameEC2.BackendState
  alias FlameEC2.Config

  require Logger

  def run_instances!(%BackendState{} = state) do
    params = build_query_from_state(state)

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
        [
          url: uri,
          method: :get,
          headers: [{:accept, "application/json"}],
          aws_sigv4: Map.put_new(credentials, :service, "ec2")
        ]
        |> Req.new()
        |> Req.request()
        |> raise_or_response!()
    end
  end

  def build_query_from_state(%BackendState{} = state) do
    state.config
    |> params_from_config()
    |> Map.merge(instance_tags(state))
    |> Map.put("Action", "RunInstances")
    |> flatten_json_object()
    |> Map.filter(fn {_k, v} -> not is_nil(v) end)
    |> URI.encode_query()
  end

  defp instance_tags(%BackendState{} = state) do
    %{
      "TagSpecification" => [
        %{
          "ResourceType" => "instance",
          "Tag" => [
            %{
              "Key" => "FLAME_PARENT_IP",
              "Value" => state.config.local_ip
            },
            %{
              "Key" => "FLAME_PARENT_APP",
              "Value" => state.config.app
            }
          ]
        }
      ]
    }
  end

  defp params_from_config(%Config{} = config) do
    base_params = %{
      "MaxCount" => 1,
      "MinCount" => 1,
      "KeyName" => config.key_name,
      "NetworkInterface" => [
        %{
          "AssociatePublicIpAddress" => false,
          "DeleteOnTermination" => true,
          "DeviceIndex" => 0,
          "SubnetId" => config.subnet_id,
          "SecurityGroupId" => [
            config.security_group_id
          ]
        }
      ],
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

  defp creation_details_params(%Config{image_id: image_id}) when is_binary(image_id) and image_id != "" do
    %{
      "ImageId" => image_id
    }
  end

  defp raise_or_response!({:ok, %Req.Response{status: status, body: body}}) when status >= 300 do
    Logger.error("Failed to create instance with status #{status} and errors: #{inspect(body)}")
    raise "Bad status #{status} with errors: #{inspect(body)}"
  end

  defp raise_or_response!({:ok, %Req.Response{} = resp}) do
    resp.body
  end

  defp raise_or_response!({:error, exception}) do
    Logger.error("Failed to create instance with exception: #{inspect(exception)}")
    raise exception
  end
end
