rendered = FlameEC2.Templates.env(vars: %{"MY_ENV_1" => "1234", "MY_ENV_2" => "5678", "MY_ENV_3" => "90"})

File.write!("./example_env", rendered)
