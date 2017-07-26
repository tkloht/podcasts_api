defmodule PodcastsApi.FeedController do
  use PodcastsApi.Web, :controller

  import PodcastsApi.ParseFeed

  alias PodcastsApi.Feed
  # plug Guardian.Plug.EnsureAuthenticated, handler: PodcastsApi.AuthErrorHandler

  require Logger

  def index(conn, params) do
    feeds = Repo.paginate(PodcastsApi.Feed, params)
    conn
    |> render("index.json-api", data: feeds)
  end

  def show(conn, %{"id" => id}) do
    feed = Repo.get_by(Feed, %{id: id})
    |> Repo.preload(:episodes)

    conn
    |> render(
      PodcastsApi.FeedView,
      "show.json-api",
      data: feed,
      opts: [include: "episodes"]
    )
  end

  def update_feed(conn, parsed_feed, id) do
    IO.puts "in update feed..."
    # IO.inspect parsed_feed
    insert_feed_id(parsed_feed, id)
    parsed_feed = parsed_feed
      |> insert_feed_id(id)
      |> insert_episode_ids(get_episodes_by_feed_id(id))

    feed = Repo.get!(Feed, id) |> Repo.preload(:episodes)
    changeset = Feed.changeset(feed, parsed_feed)
    case Repo.update changeset do
      {:ok, feed} ->
        conn
        |> put_status(:created)
        |> render(
            PodcastsApi.FeedView,
            "show.json-api",
            data: feed,
            opts: [include: "episodes"]
          )
      {:error, changeset} ->
        # IO.puts(">>>>> unable to insert changeset: ")
        # IO.inspect(changeset )
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", changeset: changeset)
    end 
  end

  def insert_feed(conn, parsed_feed) do
    # IO.puts "in insert feed..."
    # IO.inspect parsed_feed
    changeset = Feed.changeset %Feed{}, parsed_feed
    case Repo.insert changeset do
      {:ok, feed} ->
        # IO.puts "inserted feed..."
        # IO.inspect feed
        conn
        |> put_status(:created)
        |> render(
            PodcastsApi.FeedView,
            "show.json-api",
            data: feed,
            opts: [include: "episodes"]
          )
      {:error, changeset} ->
        IO.puts(">>>>> unable to insert changeset: " )
        # IO.inspect(changeset )
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", changeset: changeset)
    end 
  end

  def handle_feed(conn, feed_body, source_url) do
    case parseFeed(source_url, feed_body) do
      {:ok, parsed} -> conn |> insert_feed(parsed)
      {:error, :no_xml} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.FeedView, "no-xml-error.json-api")
      {:error, :no_feed} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.FeedView, "no-feed-error.json-api")
    end
  end

  def handle_feed_update(conn, feed_body, source_url, id) do
    case parseFeed(source_url, feed_body) do
      {:ok, parsed} -> conn |> update_feed(parsed, id)
      {:error, :no_xml} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.FeedView, "no-xml-error.json-api")
      {:error, :no_feed} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.FeedView, "no-feed-error.json-api")
    end
  end

  def update(conn, %{"data" => %{
    "type" => "feeds",
    "attributes" => %{
      "id" => id
    }
  }}) do

    IO.puts("in update... ")
    handleUdpateFeed(conn, id)
    # case handleUdpateFeed(conn, id) do
    #   {:ok, feed} ->
    #     IO.puts "render ok:"
    #     conn
    #     |> put_status(:updated)
    #     |> render(
    #         PodcastsApi.FeedView,
    #         "show.json-api",
    #         data: feed,
    #         opts: [include: "episodes"]
    #       )
    #   _ -> IO.puts "no clause matching here???"
    # end
  end

  def handleUdpateFeed(conn, feed_id) do
    feed = Repo.get_by(Feed, %{id: feed_id})
    IO.puts("updated feed: ")
    case HTTPoison.get(feed.source_url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts "received a feed..."
        conn |> handle_feed_update(body, feed.source_url, feed_id)
      {:error, %HTTPoison.Error{reason: reason}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", reason: reason)
    end
  end

  def create(conn, %{"data" => %{
    "type" => "feeds",
    "attributes" => %{
      "url" => source_url
    }
  }}) do
    case HTTPoison.get(source_url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        conn |> handle_feed(body, source_url)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        conn
        |> put_status(:not_found)
        |> render(PodcastsApi.FeedView,
          "error.json-api",
          reason: "not found",
          )
      {:error, %HTTPoison.Error{reason: :nxdomain}} ->
        conn
        |> put_status(:not_found)
        |> render(PodcastsApi.FeedView,
          "error.json-api",
          reason: "not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", reason: reason)
    end
  end

  def get_episodes_by_feed_id(feed_id) do
    %{:episodes => episodes} = Repo.get(PodcastsApi.Feed, feed_id)
      |> Repo.preload(:episodes)
    # IO.puts "get episodes by feed id: "
    # IO.inspect(episodes)

    episodes
  end

end
