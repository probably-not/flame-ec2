# I am using localstack in the docker-compose.yml file, so I don't need anything set up in my environment.
# Unfortunately, the `:aws_credentials` app just continuously spams my logs with failure logs when it cannot find credentials,
# and I can't find a configuration to turn those logs off in development.
System.put_env("AWS_ACCESS_KEY_ID", "xxxxxxxxxxxx")
System.put_env("AWS_SECRET_ACCESS_KEY", "xxxxxxxxxxxx")

defmodule QuickConfigs do
  def local_auto_configure do
    FlameEC2.BackendState.new([],
      auto_configure: true,
      instance_metadata_url: "http://localhost:1338/latest/meta-data",
      instance_metadata_token_url: "http://localhost:1338/latest/api/token",
      ec2_service_endpoint: "http://localhost:4566/ec2",
      app: :local_testing
    )
  end
end
