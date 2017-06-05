defmodule PodcastsApi.Subscription do
  use PodcastsApi.Web, :model

  schema "subscription" do
    
    belongs_to :user, PodcastsApi.User
    belongs_to :feed, PodcastsApi.Feed

    timestamps
  end

  @required_fields ~w(user_id feed_id)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields )
    |> validate_required([:user_id, :feed_id])
  end

end