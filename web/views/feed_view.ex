defmodule PodcastsApi.FeedView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:source_url, :title]

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
    }
    |> JaSerializer.ErrorSerializer.format
  end

end
