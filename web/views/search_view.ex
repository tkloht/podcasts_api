defmodule PodcastsApi.SearchView do
  use PodcastsApi.Web, :view
  # use JaSerializer.PhoenixView

  # attributes [
  #   :source_url,
  #   :title,
  #   :description,
  #   :link,
  #   :image_url,
  #   :updated_at,
  #   :feedUrl,
  #   :resultCount,
  # ]

  def render("index.json", %{data: data}) do

    # IO.puts("## in search view:")
    # IO.inspect(data)

    # Poison.encode(data)

    data
  end

end