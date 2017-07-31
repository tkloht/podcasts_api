defmodule PodcastsApi.PlaylistItem do
  use PodcastsApi.Web, :model

  schema "playlist_items" do
    belongs_to :playlist, PodcastsApi.Playlist
    belongs_to :episode, PodcastsApi.Episode

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:episode_id, :playlist_id])
    |> validate_required([:episode_id, :playlist_id])
  end
end
