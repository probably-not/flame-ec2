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

