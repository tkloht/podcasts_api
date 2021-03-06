defmodule PodcastsApi.FeedView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [
    :id,
    :source_url,
    :title,
    :description,
    :link,
    :image_url,
    :updated_at,
  ]

  has_many :episodes,
    serializer: PodcastsApi.EpisodeView,
    include: false,
    identifiers: :when_included

  def render("error.json-api", reason) do
    %{
      title: "Not found",
      code: 404,
      reason: reason
    }
    |> JaSerializer.ErrorSerializer.format
  end

  def render("no-xml-error.json-api", reason) do
    %{
      title: "No xml",
      code: 422,
      reason: reason
    }
    |> JaSerializer.ErrorSerializer.format
  end

  def render("no-feed-error.json-api", reason) do
    %{
      title: "No feed",
      code: 422,
      reason: reason
    }
    |> JaSerializer.ErrorSerializer.format
  end

end
