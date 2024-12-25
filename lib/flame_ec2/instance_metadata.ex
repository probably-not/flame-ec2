defmodule FlameEC2.InstanceMetadata do
  @moduledoc false

  require Logger

  def get(metadata_url, metadata_token_url, root_keys \\ nil) do
    metadata_url =
      if String.ends_with?(metadata_url, "/") do
        metadata_url
      else
        metadata_url <> "/"
      end

    case imds_v2(metadata_url, metadata_token_url, root_keys) do
      {:ok, metadata} ->
        {:ok, metadata}

      {:error, _} ->
        Logger.warning(
          "Failed to fetch EC2 instance metadata via IMDSv2! IMDSv2 is a recommended setting for EC2 instances. For now, falling back to IMDSv1"
        )

        imds_v1(metadata_url, root_keys)
    end
  end

  defp imds_v2(metadata_url, metadata_token_url, root_keys) do
    with {:ok, token} <- fetch_token(metadata_token_url) do
      fetch_metadata(metadata_url, [{"X-aws-ec2-metadata-token", token}], root_keys)
    end
  end

  defp imds_v1(metadata_url, root_keys) do
    fetch_metadata(metadata_url, [], root_keys)
  end

  defp fetch_token(metadata_token_url) do
    case Req.put(metadata_token_url, headers: [{"X-aws-ec2-metadata-token-ttl-seconds", "21600"}]) do
      {:ok, %{status: 200, body: token}} -> {:ok, token}
      _ -> {:error, "Failed to fetch IMDSv2 token"}
    end
  end

  defp fetch_metadata(url, headers, root_keys) do
    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        if String.ends_with?(url, "/") do
          items =
            body
            |> String.split("\n")
            |> Enum.filter(&(byte_size(&1) > 0))
            |> filter_root_keys(root_keys)

          result =
            Enum.reduce(items, %{}, fn item, acc ->
              key = String.trim_trailing(item, "/")

              if String.ends_with?(item, "/") do
                new_url = url <> item

                case fetch_metadata(new_url, headers, nil) do
                  {:ok, value} -> Map.put(acc, key, value)
                  _ -> acc
                end
              else
                case Req.get(url <> item, headers: headers) do
                  {:ok, %{body: value}} when is_binary(value) -> Map.put(acc, key, value)
                  _ -> acc
                end
              end
            end)

          {:ok, result}
        else
          {:ok, body}
        end

      _ ->
        {:error, "Failed to fetch metadata"}
    end
  end

  defp filter_root_keys(items, nil) do
    items
  end

  defp filter_root_keys(items, []) do
    items
  end

  defp filter_root_keys(items, root_keys) do
    Enum.filter(items, fn item ->
      String.trim_trailing(item, "/") in root_keys
    end)
  end
end
