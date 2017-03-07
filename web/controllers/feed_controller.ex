defmodule PodcastsApi.FeedController do
  use PodcastsApi.Web, :controller

  alias PodcastsApi.Feed
  plug Guardian.Plug.EnsureAuthenticated, handler: PodcastsApi.AuthErrorHandler

  require Logger
  import SweetXml

  def index(conn, _params) do
    feeds = Repo.all(PodcastsApi.Feed)
    Logger.info "feeds: "
    conn
    |> render("index.json-api", data: feeds)
  end

  def is_feed(feedBody) do
    try do
      case feedBody |> xmap(
        title: ~x"/rss/channel/title",
        description: ~x"/rss/channel/description",
        link: ~x"/rss/channel/link",
      ) do
        %{title: nil} -> {:error, :no_feed}    
        %{description: nil} -> {:error, :no_feed}    
        %{link: nil} -> {:error, :no_feed}    
        _ -> {:ok}
      end
    catch
      :exit, _ -> {:error, :no_xml}
    end
  end

  def parseFeed(source_url, feedBody) do

    case is_feed feedBody do
      {:ok} ->
        parsed = feedBody
        |> xmap(
            title: ~x"//channel/title/text()"S,
            description: ~x"//channel/description/text()"S,
            link: ~x"//channel/link/text()"S,
            image_url: ~x"//channel/image/url/text()"S
          )
        |> Map.put(:source_url, source_url)
        
        {:ok, parsed }
      {:error, :no_xml} -> {:error, :no_xml}
      {:error, :no_feed} -> {:error, :no_feed}
    end
  end

  def insert_feed(conn, parsed_feed) do
    changeset = Feed.changeset %Feed{}, parsed_feed
    case Repo.insert changeset do
      {:ok, feed} ->
        conn
        |> put_status(:created)
        |> render(PodcastsApi.FeedView, "show.json-api", data: feed)
      {:error, changeset} ->
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
end
