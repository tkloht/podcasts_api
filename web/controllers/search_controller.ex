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

            conn
            |> render("index.json", data: response)
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
