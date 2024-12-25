defmodule FlameEC2.Utils do
  @moduledoc false

  def with_elapsed_ms(func) when is_function(func, 0) do
    {micro, result} = :timer.tc(func)
    {result, div(micro, 1000)}
  end

  def flatten_json_object(json_object) when is_map(json_object) do
    json_object
    |> do_flatten_json_object()
    |> Map.new()
  end

  defp do_flatten_json_object(map) when is_map(map) do
    Enum.flat_map(map, fn {key, value} ->
      case value do
        value when is_map(value) ->
          value
          |> do_flatten_json_object()
          |> Enum.map(fn {k, v} -> {"#{key}.#{k}", v} end)

        value when is_list(value) ->
          value
          |> Enum.with_index(1)
          |> Enum.map(fn {v, idx} ->
            case v do
              v when is_map(v) or is_list(v) ->
                v
                |> do_flatten_json_object()
                |> Enum.map(fn {k, val} -> {"#{key}.#{idx}.#{k}", val} end)

              v ->
                {"#{key}.#{idx}", v}
            end
          end)
          |> List.flatten()

        value ->
          [{to_string(key), value}]
      end
    end)
  end

  defp do_flatten_json_object(list) when is_list(list) do
    list
    |> Enum.with_index(1)
    |> Map.new(fn {value, idx} -> {to_string(idx), value} end)
    |> do_flatten_json_object()
  end

  defp do_flatten_json_object(value), do: [{to_string(1), value}]
end
