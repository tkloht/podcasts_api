defmodule PodcastsApi.Feed do
  use PodcastsApi.Web, :model

  schema "feeds" do
    field :source_url, :string
    field :title, :string
    field :description, :string
    field :link, :string
    field :image_url, :string

    has_many :episodes, PodcastsApi.Episode, on_replace: :delete
    has_many :subscriptions, PodcastsApi.Subscription

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

  def search(query, search_term) do
    from(feed in query,
    where: fragment("? % ?", feed.title, ^search_term),
    order_by: fragment("similarity(?, ?) DESC", feed.title, ^search_term))
  end

end
