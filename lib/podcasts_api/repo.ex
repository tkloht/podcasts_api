defmodule PodcastsApi.Repo do
  use Ecto.Repo, otp_app: :podcasts_api
  use Scrivener, page_size: 10
end
