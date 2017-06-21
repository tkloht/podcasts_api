defmodule PodcastsApi.SearchController do
  use PodcastsApi.Web, :controller
  alias PodcastsApi.Feed

  def get(conn, %{"term" => term} = params) do

    # term = "accidental"

    url = "https://itunes.apple.com/search?term=#{term}&entity=podcast"

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
                  IO.puts "feed is already in library: "
                  IO.inspect head
                  result = Map.put(feed, "feed_id", head)
                  IO.inspect result
                  result
                  # result = %{feed | "feed_id" => head}
                _ ->
                  result = feed
              end
              # IO.puts "is feed already in library?"
              # IO.inspect(result)
              result
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
