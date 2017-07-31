defmodule PodcastsApi.Playlist do
  use PodcastsApi.Web, :model

  schema "playlists" do
    field :title, :string
    belongs_to :user, PodcastsApi.User

    has_many :playlist_items, PodcastsApi.PlaylistItem

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :user_id])
    |> validate_required([:title, :user_id])
  end
end
