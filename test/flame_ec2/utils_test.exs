defmodule FlameEC2.UtilsTest do
  use ExUnit.Case
  doctest FlameEC2.Utils

  test "code loaded" do
    assert Code.loaded?(FlameEC2.Utils)
  end

  describe "flatten json object" do
    test "empty" do
      assert %{} == FlameEC2.Utils.flatten_json_object(%{})
    end

    test "single level" do
      assert %{"a" => "b"} == FlameEC2.Utils.flatten_json_object(%{"a" => "b"})
    end

    test "single level atoms" do
      assert %{"a" => "b"} == FlameEC2.Utils.flatten_json_object(%{a: "b"})
    end

    test "nested map simple" do
      assert %{"user.name" => "John"} ==
               FlameEC2.Utils.flatten_json_object(%{"user" => %{"name" => "John"}})
    end

    test "nested list simple" do
      assert %{"items.1" => "a", "items.2" => "b", "items.3" => "c"} ==
               FlameEC2.Utils.flatten_json_object(%{"items" => ["a", "b", "c"]})
    end

    test "nested list mixed types" do
      assert %{"mixed.1" => 1, "mixed.2" => "two", "mixed.3" => :three} ==
               FlameEC2.Utils.flatten_json_object(%{"mixed" => [1, "two", :three]})
    end
  end

  test "nested list in maps" do
    assert %{"deep.1.1" => "a", "deep.1.2" => "b", "deep.2.1" => "c", "deep.2.2" => "d"} ==
             FlameEC2.Utils.flatten_json_object(%{"deep" => [["a", "b"], ["c", "d"]]})
  end

  test "nested maps in lists" do
    assert %{"users.1.name" => "John", "users.2.name" => "Jane"} ==
             FlameEC2.Utils.flatten_json_object(%{
               "users" => [%{"name" => "John"}, %{"name" => "Jane"}]
             })
  end

  test "nested lists in nested maps in nested lists" do
    assert %{"data.1.tags.1" => "red", "data.1.tags.2" => "blue", "data.2.tags.1" => "green"} ==
             FlameEC2.Utils.flatten_json_object(%{
               "data" => [%{"tags" => ["red", "blue"]}, %{"tags" => ["green"]}]
             })
  end

  test "nested maps deep" do
    assert %{"a.b.c.d" => "e"} ==
             FlameEC2.Utils.flatten_json_object(%{"a" => %{"b" => %{"c" => %{"d" => "e"}}}})
  end

  test "comprehensive nested types" do
    assert %{
             "users.1.name" => "John",
             "users.1.tags.1" => "admin",
             "users.1.tags.2" => "staff",
             "users.1.settings.theme" => "dark",
             "users.2.name" => "Jane",
             "users.2.tags.1" => "user",
             "users.2.settings.theme" => "light",
             "config.options.1.enabled" => true,
             "config.options.2.enabled" => false
           } ==
             FlameEC2.Utils.flatten_json_object(%{
               "users" => [
                 %{
                   "name" => "John",
                   "tags" => ["admin", "staff"],
                   "settings" => %{"theme" => "dark"}
                 },
                 %{"name" => "Jane", "tags" => ["user"], "settings" => %{"theme" => "light"}}
               ],
               "config" => %{
                 "options" => [
                   %{"enabled" => true},
                   %{"enabled" => false}
                 ]
               }
             })
  end

  test "edge cases with empty stuff" do
    assert %{
             "" => "empty_key",
             "keys." => "empty_nested_key",
             "nil_value" => nil,
             "list_with_empty.3" => nil,
             "map_with_empty.nil" => nil
           } ==
             FlameEC2.Utils.flatten_json_object(%{
               "empty_list" => [],
               "empty_map" => %{},
               "nil_value" => nil,
               "list_with_empty" => [[], %{}, nil],
               "map_with_empty" => %{"empty" => [], "nil" => nil},
               "" => "empty_key",
               "keys" => %{"" => "empty_nested_key"}
             })
  end
end
