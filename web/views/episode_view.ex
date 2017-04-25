defmodule PodcastsApi.EpisodeView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [
    :title,
    :subtitle,
    :link,
    :pubDate,
    :guid,
    :description,
    :duration,
    :shownotes,
    :enclosure,
    :updated_at,
  ]

end
