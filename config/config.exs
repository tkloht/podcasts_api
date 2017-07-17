# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :podcasts_api,
  ecto_repos: [PodcastsApi.Repo]

# Configures the endpoint
config :podcasts_api, PodcastsApi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "j6+PXnnkPvTWv6YIi62bIsBDmJgwS/Fql7KGhyhPPMYBBbxtCmCtobxZ+zrVUq4c",
  render_errors: [view: PodcastsApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: PodcastsApi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :format_encoders,
  "json-api": Poison

config :plug, :mimes, %{
  "application/vnd.api+json" => ["json-api"]
}

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "PodcastsApi",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: System.get_env("GUARDIAN_SECRET") || "C9Dk5YJAY31GKL9uW2U6K3CFqxlqVOXUKDhCNxT/y4+W5BKGjCC4UEv7NRAwweMp",
  serializer: PodcastsApi.GuardianSerializer

config :podcasts_api, PodcastsApi.Scheduler,
  jobs: [
    # every minute
    {"* * * * *", {PodcastsApi.Scheduler, :enqueue_feed_update, []}},
  ]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
