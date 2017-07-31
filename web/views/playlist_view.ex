defmodule PodcastsApi.PlaylistView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:id, :title, :inserted_at, :updated_at]

  has_many :playlist_items,
    serializer: PodcastsApi.PlaylistItemView,
    include: true,
    identifiers: :when_included

end
