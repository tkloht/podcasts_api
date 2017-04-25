defmodule PodcastsApi.EpisodeController do
  use PodcastsApi.Web, :controller

  def index(conn, _) do
    episodes = Repo.all(PodcastsApi.Episode)
    conn
    |> render("index.json-api", data: episodes)
  end

  def show(conn, %{"id" => id}) do
    episodes = Repo.get_by(PodcastsApi.Episode, %{id: id})

    conn
    |> render(
        "show.json-api",
        data: episodes,
      )
  end

end
