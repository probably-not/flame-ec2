defmodule FlameEC2.MixProject do
  use Mix.Project

  def project do
    [
      app: :flame_ec2,
      version: "0.0.1-rc-11",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_path(Mix.env()),
      deps: deps(),
      name: "FlameEC2",
      description: "A FLAME backend for EC2 Machines",
      source_url: "https://github.com/probably-not/flame-ec2",
      homepage_url: "https://github.com/probably-not/flame-ec2",
      package: [
        maintainers: ["Coby Benveniste"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/probably-not/flame-ec2"},
        files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"]
      ],
      aliases: aliases(),
      docs: docs(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}, plt_add_deps: :app_tree],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        ci: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_path(:test), do: ["lib/", "test/support", "bench/"]
  defp elixirc_path(:dev), do: ["lib/", "test/support", "bench/"]
  defp elixirc_path(_), do: ["lib/"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: applications(Mix.env())
    ]
  end

  defp applications(:dev), do: applications(:all) ++ [:remixed_remix, :runtime_tools]
  defp applications(_all), do: [:logger, :xmerl, :eex]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flame, "~> 0.5.0"},
      {:aws_credentials, "~> 0.3.2"},
      {:req, "~> 0.5.0"},
      ## Testing and Development Dependencies
      {:styler, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:remixed_remix, "~> 2.0.2", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_markdown, "~> 0.3", only: :dev},
      # We use the AWS client in order to do things in dev and test
      # like syncing between the EC2 Instance Metadata and the LocalStack.
      # It is a dev/test only dependency, and should not be part of the production
      # compilation to avoid adding a massive overhead to the package.
      {:aws, "~> 1.0.0", only: [:dev, :test]},
      {:hackney, "~> 1.18", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      ci: ["coveralls", "format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "README"]
      ],
      groups_for_extras: [],
      skip_undefined_reference_warnings_on: Path.wildcard("**/*.md"),
      main: "FlameEC2"
    ]
  end
end
