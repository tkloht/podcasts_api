defmodule PodcastsApi.PlaylistItemView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:inserted_at, :updated_at, :episode_id, :playlist_id]
  
  # has_one :playlist,
  #   field: :playlist_id,
  #   type: "playlist"
  # has_one :episode,
  #   field: :episode_id,
  #   type: "episode"

end
