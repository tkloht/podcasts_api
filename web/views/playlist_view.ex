defmodule PodcastsApi.PlaylistView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:title, :inserted_at, :updated_at]

end
