# I am using localstack in the docker-compose.yml file, so I don't need anything set up in my environment.
# Unfortunately, the `:aws_credentials` app just continuously spams my logs with failure logs when it cannot find credentials,
# and I can't find a configuration to turn those logs off in development.
System.put_env("AWS_ACCESS_KEY_ID", "xxxxxxxxxxxx")
System.put_env("AWS_SECRET_ACCESS_KEY", "xxxxxxxxxxxx")
