# FlameEC2

A FLAME backend for EC2 Machines.

## Why not K8S/ECS/Docker/etc?

I don't like complicating my deployments too much - while I have used K8S and ECS and Docker Compose and have spent years learning their ins and outs, I've recently started preferring simple bare-metal style deployments. Just give me a VPS with SSH access, plus something like Ansible, CodeDeploy (I am using AWS after all), or just simple rsync and a systemd service and I'm happy.

With that in mind - I want my FLAME cluster to shine (see what I did there?) without needing all this fluff as well.

## Setup

See the moduledoc for `FlameEC2` for extensive documentation on different options.

The main thing that you need to set up properly is your `s3_bundle_url` value. This defines the bundle that will be loaded onto the runner machine, in order to run the application. There are various strategies to set up the release bundle url - for example, you may always push the latest release to a specific directory in S3 (the "latest" directory) and simply hardcode pointing to this URL. Alternatively, you may want to maintain versioining and use a Git tag or Git commit hash to point to the correct bundle - the version can be set in the build when compiling your release so that you can know which version to point to on any given release.

## Debugging Issues

The `FlameEC2` backend works by setting up an EC2 UserData script which will initialize the runner instance with a systemd service that is running the release bundle that you specify. If the runner is not able to start, there may be an issue during the start script which causes the whole process to fail. If there is a problem, you can see the logs of the start script by using the systemd journal as shown here:

```sh
sudo journalctl -t flame_ec2_init
```

This should output any logs related to the start script to show whether or not there is a problem.

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