defmodule PodcastsApi.SearchController do
  use PodcastsApi.Web, :controller
  alias PodcastsApi.Feed

  import PodcastsApi.ParseFeed
  import URI

  require Logger

  # returns id
  def insert_feed(parsed_feed) do
    # IO.puts "in insert feed..."
    # IO.inspect parsed_feed
    changeset = Feed.changeset %Feed{}, parsed_feed
    case Repo.insert changeset do
      {:ok, feed} ->
        # IO.puts "inserted feed..."
        # IO.inspect feed
        %{:id => id} = feed
        id
      {:error, changeset} ->
        Logger.error "unable to insert changeset for feed: #{inspect changeset}"
        # IO.puts(">>>>> unable to insert changeset: " )
        # IO.inspect(changeset )
        nil
    end 
  end

  def get(conn, %{"term" => term} = params) do

    # term = "accidental"
    # 
    encoded = encode(term)
    IO.puts "seaerch term: " <> term
    IO.puts "encoded: " <> encoded
    url = "https://itunes.apple.com/search?term=#{encoded}&entity=podcast"

    case HTTPoison.get(url) do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        # IO.puts("received search results: ")
        # IO.inspect(body)

        case Poison.decode(body) do
          {:error, _} ->
            %{status: 500, message: "Remote Bad Response"}
          {:ok, response} ->
            # IO.puts("decoded search results: ")
            # IO.inspect(response)

            %{"results" => results} = response

            feedWithIds = Enum.map(results, fn(feed) ->
              %{"feedUrl" => x} = feed
              IO.puts "found a feed: " <> x
              query = from f in "feeds",
                      where: f.source_url == ^x,
                      select: f.id

              case Repo.all(query) do
                [head | tail] ->
                  Logger.info "feed #{x} is already in library with id: #{head}"
                  Map.put(feed, "feed_id", head)
                  # result = %{feed | "feed_id" => head}
                _ ->
                  Logger.info "feed #{x} is NOT in the database yet, try to add it"
                  case HTTPoison.get(x, [], [ ssl: [{:versions, [:'tlsv1.2']}], follow_redirect: true ]) do
                    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                      case parseFeed(x, body) do
                        {:ok, parsed} -> Map.put(feed, "feed_id", insert_feed(parsed))
                        _ -> feed
                      end
                    _ -> feed
                   feed
                end
              end
            end)

          responseWithIds = Map.put(response, "results", feedWithIds)

          conn
          |> render("index.json", data: responseWithIds)
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", reason: reason)
    end

    # search_result = Feed
    #   |> Feed.search("accidental")
    #   |> Repo.all

  end

end
