defmodule FlameEC2.EC2Api.Utils do
  @moduledoc false
  # Adapted from https://github.com/livebook-dev/livebook/blob/v0.14.5/lib/livebook/utils.ex

  @doc """
  Retrieves content type from response headers.
  """
  @spec fetch_content_type(Req.Response.t()) :: {:ok, String.t()} | :error
  def fetch_content_type(%Req.Response{} = res) do
    case res.headers["content-type"] do
      [value] ->
        {:ok, value |> String.split(";") |> hd()}

      _other ->
        :error
    end
  end
end
