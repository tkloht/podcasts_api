defmodule PodcastsApi.Feed do
  use PodcastsApi.Web, :model

  schema "feeds" do
    field :source_url, :string
    field :title, :string
    field :description, :string
    field :link, :string
    field :image_url, :string

    has_many :episodes, PodcastsApi.Episode

    timestamps()
  end

@required_fields ~w(source_url title description link image_url)
@optional_fields ~w()

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:episodes, params.episodes)
    |> validate_required([:source_url])
  end
end
