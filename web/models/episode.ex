defmodule PodcastsApi.Episode do
  use PodcastsApi.Web, :model

  schema "episodes" do
    field :title, :string
    field :subtitle, :string
    field :link, :string
    field :pubDate, Timex.Ecto.DateTimeWithTimezone
    field :guid, :string
    field :description, :string
    field :itunes_summary, :string
    field :content_encoded, :string
    field :duration, :string
    field :shownotes, :string
    field :enclosure, :string
    
    belongs_to :feed, PodcastsApi.Feed

    timestamps
  end

  @required_fields ~w(title link pubDate feed_id)
  @optional_fields ~w(enclosure guid duration description itunes_summary content_encoded)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required([:title, :link, :pubDate])
  end

end