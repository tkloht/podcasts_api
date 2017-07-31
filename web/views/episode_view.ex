defmodule PodcastsApi.EpisodeView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [
    :id,
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
    :content_encoded,
    :itunes_summary,
  ]

end
