# FlameEC2

A FLAME backend for EC2 Machines.

## Why not K8S/ECS/Docker/etc?

I don't like complicating my deployments too much - while I have used K8S and ECS and Docker Compose and have spent years learning their ins and outs, I've recently started preferring simple bare-metal style deployments. Just give me a VPS with SSH access, plus something like Ansible, CodeDeploy (I am using AWS after all), or just simple rsync and a systemd service and I'm happy.

With that in mind - I want my FLAME cluster to shine (see what I did there?) without needing all this fluff as well.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flame_ec2` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flame_ec2, "~> 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/flame_ec2>.

## Contributing

Feel free to fork and make PRs! I'm definitely happy to have eyes on this and to get feedback so we can take care of edge cases.

For contributions, ensure that you run `git update-index --skip-worktree compose-env/ec2_mock_config.json`. The mock config gets reset
and resynced in every `iex` session to ensure that the local compose environment is up to date for localized tests. This means that
it is constantly changing, and therefore we should not track its changes. However, I do want to ensure that the file is distributed with
the repository, so that developers don't have to know to create it or have to do any setup before getting started.