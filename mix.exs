defmodule PodcastsApi.Mixfile do
  use Mix.Project

  def project do
    [app: :podcasts_api,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {PodcastsApi, []},
     applications: [:phoenix, :phoenix_pubsub, :cowboy, :logger, :gettext,
        :phoenix_ecto, :postgrex, :comeonin, :httpoison, :sweet_xml,
        :timex, :timex_ecto
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:postgrex, ">= 0.0.0"},
     {:gettext, "~> 0.11"},
     {:cors_plug, "~> 1.1"},
     {:guardian, "~> 0.14"},
     {:gen_stage, "~> 0.12"},
     {:comeonin, "~> 3.0"},
     {:mix_test_watch, "~> 0.2", only: :dev},
     {:ja_serializer, "~> 0.11.2"},
     {:httpoison, "~> 0.10.0"},
     {:sweet_xml, "~> 0.6.4"},
     {:timex, "~> 3.0"},
     {:timex_ecto, "~> 3.0"},
     {:exvcr, "~> 0.8", only: :test},
     {:flow, "~> 0.11"},
     {:cowboy, "~> 1.0"}]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
