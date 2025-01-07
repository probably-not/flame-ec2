defmodule FlameEC2.EC2Api do
  @moduledoc false

  import FlameEC2.Utils

  alias FlameEC2.BackendState
  alias FlameEC2.Config
  alias FlameEC2.EC2Api.XML
  alias FlameEC2.Templates

  require Logger

  def run_instances!(%BackendState{} = state) do
    params = build_params_from_state(state)

    uri =
      state.config.ec2_service_endpoint
      |> URI.new!()
      |> URI.to_string()

    credentials = :aws_credentials.get_credentials()

    case credentials do
      :undefined ->
        raise "No AWS credentials found in env or in credentials cache"

      %{} ->
        [
          url: uri,
          method: :post,
          form: params,
          aws_sigv4: Map.put_new(credentials, :service, "ec2")
        ]
        |> Req.new()
        |> Req.request()
        |> raise_or_response!()
        |> Map.fetch!(:body)
        |> Map.fetch!("RunInstancesResponse")
        |> Map.fetch!("instancesSet")
        |> Map.fetch!("item")
    end
  end

  def build_params_from_state(%BackendState{} = state) do
    state.config
    |> params_from_config(state.runner_env)
    |> Map.merge(instance_tags(state))
    |> Map.put("Action", "RunInstances")
    |> flatten_json_object()
    |> Map.filter(fn {_k, v} -> not is_nil(v) end)
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

  defp params_from_config(%Config{} = config, env) do
    systemd_service = Templates.systemd_service(app: config.app)
    env = Templates.env(vars: env)

    start_script =
      Templates.start_script(
        app: config.app,
        systemd_service: systemd_service,
        env: env,
        aws_region: config.aws_region,
        s3_bundle_url: config.s3_bundle_url,
        s3_bundle_compressed?: config.s3_bundle_compressed?
      )

    base_params = %{
      "Version" => "2016-11-15",
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
      "InstanceInitiatedShutdownBehavior" => "terminate",
      "UserData" => Base.encode64(start_script)
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
    if xml?(resp) do
      update_in(resp.body, &XML.decode!/1)
    else
      resp
    end
  end

  defp raise_or_response!({:error, exception}) do
    Logger.error("Failed to create instance with exception: #{inspect(exception)}")
    raise exception
  end

  # Adapted from https://github.com/livebook-dev/livebook/blob/v0.14.5/lib/livebook/file_system/s3/client.ex
  defp xml?(response) do
    guess_xml? = String.starts_with?(response.body, "<?xml")

    case FlameEC2.EC2Api.Utils.fetch_content_type(response) do
      {:ok, content_type} when content_type in ["text/xml", "application/xml"] -> true
      # Apparently some requests return XML without content-type
      :error when guess_xml? -> true
      _otherwise -> false
    end
  end
end
