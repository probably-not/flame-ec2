defmodule FlameEC2 do
  @moduledoc """
  A `FLAME.Backend` using [AWS EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html) machines.

  To use, you must tell FLAME to use the `FlameEC2` backend by default.
  This can be set via application configuration in your `config/runtime.exs` withing a `:prod` block:

  ```elixir
  if config_env() == :prod do
    config :flame, :backend, FlameEC2
    ...
  end
  ```

  You must ensure that the IAM Role of whatever is running this backend has access to all of the necessary APIs.
  The following is a minimal IAM Policy recommended to allow the backend to access all required APIs:

  ```json
  {
  }
  ```

  ## Configuration

  Configuration of the backend mirrors a subset of the
  [AWS EC2 LaunchInstance API](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RunInstances.html) options,
  to allow us to raise a machine properly.

  All of the configurations may be automatically set to the current instance's details by setting `auto_configure` to true:

  ```elixir
  config :flame, FlameEC2, auto_configure: true
  ...
  ```

  If you'd like to manually configure the details in your pool, you can read about the available configurations below.

  ### Required Configurations

  * `:image_id` - The ID of the AMI to use. This is a required attribute if you are not using a launch template, and has no default.

  * `:launch_template_id` - The ID of the Launch Template to use. This is a required attribute if you are not using an image id, and has no default.

  * `:launch_template_version` - The version number of the launch template, or "$Default", or "$Latest". Defaults to "$Default".

  * `:subnet_id` - The subnet ID for the attached network interface. This is required in order to properly communicate with the instance.

  * `:security_group_id` - The security group ID for the attached network interface. This is required in order to properly communicate with the instance.

  ### Optional Configurations

  * `:instance_type` - The instance type that should be used. Defaults to "t3.nano", which falls under the AWS free tier,
  however, you likely want to change this to something that's more appropriate for your pool's workload.

  * `:iam_instance_profile` - The ARN of the instance profile to assign to this machine.

  * `:key_name` - The name of the key pair to use for you to be able to connect to the instance.
  This is not required, however, an instance that was created without a key pair will be inaccessible without another way to log in.

  ## Environment Variables

  The FLAME EC2 machines *do not* inherit the environment variables of the parent.
  You must explicit provide the environment that you would like to forward to the
  machine. For example, if your FLAME's are starting your Ecto repos, you can copy
  the env from the parent:

  ```elixir
  config :flame, FlameEC2,
    env: %{
      "DATABASE_URL" => System.fetch_env!("DATABASE_URL"),
      "POOL_SIZE" => "1"
    }
  ```

  Or pass the env to each pool:

  ```elixir
  {FLAME.Pool,
    name: MyRunner,
    backend: {FlameEC2, env: %{"DATABASE_URL" => System.fetch_env!("DATABASE_URL")}}
  }
  ```
  """
  @behaviour FLAME.Backend
end
