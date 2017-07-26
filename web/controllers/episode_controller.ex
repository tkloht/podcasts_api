defmodule PodcastsApi.EpisodeController do
  use PodcastsApi.Web, :controller
  require Logger

  def index(conn, %{"filter"=> filter} = params) do
    Logger.debug "filter by: #{inspect filter}"

    episodes = filter
    |> Enum.reduce(PodcastsApi.Episode, fn
      {"feed", v}, query -> 
        from q in query, or_where: q.feed_id in ^String.split(v, ",")
      {_key, _value}, query -> query # unsupported key for filter -> do nothing
    end)
    |> Repo.paginate(params)

    conn
    |> render("index.json-api", data: episodes)
  end

  def index(conn, params) do
    episodes = Repo.paginate(PodcastsApi.Episode, params)
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
