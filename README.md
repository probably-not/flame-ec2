# FlameEC2

A FLAME backend for EC2 Machines.

## Why not K8S/ECS/Docker/etc?

I don't like complicating my deployments too much - while I have used K8S and ECS and Docker Compose and have spent years learning their ins and outs, I've recently started preferring simple bare-metal style deployments. Just give me a VPS with SSH access, plus something like Ansible, CodeDeploy (I am using AWS after all), or just simple rsync and a systemd service and I'm happy.

With that in mind - I want my FLAME cluster to shine (see what I did there?) without needing all this fluff as well.

## Setup

See the moduledoc for `FlameEC2` for extensive documentation on different options.

The main thing that you need to set up properly is your `s3_bundle_url` value. This defines the bundle that will be loaded onto the runner machine, in order to run the application. There are various strategies to set up the release bundle url - for example, you may always push the latest release to a specific directory in S3 (the "latest" directory) and simply hardcode pointing to this URL. Alternatively, you may want to maintain versioining and use a Git tag or Git commit hash to point to the correct bundle - the version can be set in the build when compiling your release so that you can know which version to point to on any given release.

## Usage Recommendation

### FLAME.call Timeouts and FLAME.Pool Boot Timeouts

EC2 Machines can take some time coming up (even sometimes several minutes) due to how AWS manages capacity in their availability zones. The time is typically under 2 minutes, although it is highly dependent on the instance types that you are trying to raise. Because of this, the `:boot_timeout` for your `FLAME.Pool` and the `:timeout` option for `FLAME.call` should be set high enough to avoid timeouts happening due to waiting for an instance to move from Pending to Running.

### Warm Pool

If you want to ensure that you don't cause all of your function calls to take a long time due to waiting for capacity, it's highly recommended to have a warm pool (i.e. a pool with a minimum greater than 0). This will ensure that for initial calls, you will not wait for an instance to become ready. **Note:** While having a warm pool does ensure that you have an instance at the beginning, if your scale grows, you will eventually have to wait for new instances to boot up.

### Idle Runner Timeouts

In a similar vein to the above two recommendations - setting the `:idle_shutdown_after` option on your configured `FLAME.Pool` can help in ensuring that you do not scale down too quickly. The default value is set to `30_000` (30 seconds), but setting this to a higher value can help ensure that you aren't constantly raising and terminating instances.

### Example Configuration

Based on the above recommendations, an example configuration that may work well would look something like this:

```elixir
{
  FLAME.Pool,
  name: FlameEC2Demo.Pool,
  # Optionally, set the minimum to 1 so that we can run 100 concurrent tasks without worrying about waiting.
  min: 0,
  max: 10,
  max_concurrency: 100,
  # Set a global FLAME.call timeout that is higher than the boot timeout to ensure that we do not timeout calls before booting
  timeout: 180_000,
  # Set the boot timeout to a high enough number that we can have enough time to raise an instance
  boot_timeout: 150_000,
  # Set the idle shutdown timeout to high enough that we don't constantly raise and terminate instances
  idle_shutdown_after: 60_000,
}
```

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