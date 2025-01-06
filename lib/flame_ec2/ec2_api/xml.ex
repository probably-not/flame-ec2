defmodule FlameEC2.EC2Api.XML do
  # Adapted from https://github.com/livebook-dev/livebook/blob/v0.14.5/lib/livebook/file_system/s3/xml.ex
  @moduledoc false
  import Record

  @text "__text"

  defrecord(:xmlElement, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))
  defrecord(:xmlText, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  @doc """
  Decodes a XML into a map.

  Raises in case of errors.
  """
  def decode!(xml) do
    xml_str = :unicode.characters_to_list(xml)
    opts = [{:hook_fun, &hook_fun/2}]
    {element, []} = :xmerl_scan.string(xml_str, opts)
    element
  end

  # Callback hook_fun for xmerl parser
  defp hook_fun(element, global_state) when Record.is_record(element, :xmlElement) do
    tag = xmlElement(element, :name)
    content = xmlElement(element, :content)

    value =
      case List.foldr(content, :none, &content_to_map/2) do
        %{@text => text} = v ->
          case String.trim(text) do
            "" -> Map.delete(v, @text)
            trimmed -> Map.put(v, @text, trimmed)
          end

        v ->
          v
      end

    {%{Atom.to_string(tag) => value}, global_state}
  end

  defp hook_fun(text, global_state) when Record.is_record(text, :xmlText) do
    text = xmlText(text, :value)
    {:unicode.characters_to_binary(text), global_state}
  end

  # Convert the content of an Xml node into a map.
  # When there is more than one element with the same tag name, their
  # values get merged into a list.
  # If the content is only text then that is what gets returned.
  # If the content is a mix between text and child elements, then the
  # elements are processed as described above and all the text parts
  # are merged under the `__text' key.

  defp content_to_map(x, :none) do
    x
  end

  defp content_to_map(x, acc) when is_map(x) and is_map(acc) do
    [{tag, value}] = Map.to_list(x)

    if Map.has_key?(acc, tag) do
      update_fun = fn
        l when is_list(l) -> [value | l]
        v -> [value, v]
      end

      Map.update!(acc, tag, update_fun)
    else
      Map.put(acc, tag, value)
    end
  end

  defp content_to_map(x, %{@text => text} = acc) when is_binary(x) and is_map(acc) do
    %{acc | @text => <<x::binary, text::binary>>}
  end

  defp content_to_map(x, acc) when is_binary(x) and is_map(acc) do
    Map.put(acc, @text, x)
  end

  defp content_to_map(x, acc) when is_binary(x) and is_binary(acc) do
    <<x::binary, acc::binary>>
  end

  defp content_to_map(x, acc) when is_map(x) and is_binary(acc) do
    Map.put(x, @text, acc)
  end
end
