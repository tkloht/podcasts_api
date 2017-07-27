defmodule PodcastsApi.SubscriptionView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [
    :updated_at,
    :inserted_at,
    :feed_id,
    :id,
  ]

end
