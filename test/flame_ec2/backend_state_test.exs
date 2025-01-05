defmodule FlameEC2.BackendStateTest do
  use ExUnit.Case

  doctest FlameEC2.BackendState

  setup_all do
    FlameEC2.QuickConfigs.sync_localstack_with_ec2_mock()
  end

  test "code loaded" do
    assert Code.loaded?(FlameEC2.BackendState)
  end

  test "valid configuration" do
    state = FlameEC2.BackendState.new(FlameEC2.QuickConfigs.simple_valid_config(), [])

    assert %FlameEC2.BackendState{} = state
    assert state.config.app == :flame_ec2
    assert state.config.s3_bundle_url == "s3://code-bucket/code.tar.gz"
    assert String.starts_with?(state.runner_node_base, "flame_ec2-flame-")
    assert is_reference(state.parent_ref)
    assert is_map(state.runner_env)
  end

  test "runner_node_base is always unique per state" do
    config = FlameEC2.QuickConfigs.simple_valid_config()
    state1 = FlameEC2.BackendState.new(config, [])
    state2 = FlameEC2.BackendState.new(config, [])

    assert state1.runner_node_base != state2.runner_node_base
    assert String.starts_with?(state1.runner_node_base, "flame_ec2-flame-")
    assert String.length(state1.runner_node_base) == String.length("flame_ec2-flame-") + 20

    assert String.starts_with?(state2.runner_node_base, "flame_ec2-flame-")
    assert String.length(state2.runner_node_base) == String.length("flame_ec2-flame-") + 20
  end

  test "parent encoding" do
    state = FlameEC2.BackendState.new(FlameEC2.QuickConfigs.simple_valid_config(), [])

    assert is_binary(state.runner_env["FLAME_PARENT"])

    System.put_env("FLAME_PARENT", state.runner_env["FLAME_PARENT"])

    parent = FLAME.Parent.get()

    assert not is_nil(parent)
    assert is_struct(parent, FLAME.Parent)
    assert parent.ref == state.parent_ref
    assert parent.node_base == state.runner_node_base
    assert parent.backend == FlameEC2
    assert parent.host_env == "INSTANCE_IP"

    System.delete_env("FLAME_PARENT")
  end
end
