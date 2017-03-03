defmodule PodcastsApi.FeedView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:source_url, :title]

end
