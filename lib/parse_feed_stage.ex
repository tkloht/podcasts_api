defmodule PodcastsApi.ParseFeedStage do
  use GenStage
  import Logger
  import Flow
  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(state) do
    # {:consumer, state}
    {:producer_consumer, state, subscribe_to: [{PodcastsApi.LoadFeedStage, max_demand: 100, min_demand: 5}]}
  end

  def handle_cast({:push, feeds}, state) do
    # query = from f in PodcastsApi.Feed,
    #      select: f.source_url
    # feed_urls = Repo.all(query)
    # Logger.info "found feed urls: " <> inspect feed_urls
    # Dispatch the feed_urls as events.
    # These will be buffered if there are no consumers ready.
    {:noreply, feeds, state}
  end
  
  def handle_events(events, _from, state) do
    Logger.info "begin parsing #{length(events)}"
    # parsed = Enum.map(events, &PodcastsApi.ParseFeed.parseFeed/2)
    # results = Enum.map(events, fn {feed_url, feed_body} -> 
    #   {:ok, parsed} = PodcastsApi.ParseFeed.parseFeed(feed_url, feed_body)
    #   parsed
    # end)

    results = events
      |> Flow.from_enumerable(max_demand: 20)
      |> Flow.map(fn event ->
          case event do
            %{source_url: feed_url, feed_body: feed_body} ->
              {:ok, parsed} = PodcastsApi.ParseFeed.parseFeed(feed_url, feed_body)
              Map.put(event, :body_parsed, parsed)
            nil -> nil              
          end
        end)
      |> Enum.to_list()

    Logger.info "finished parsing #{length(results)} feeds"
    {:noreply, results, state}
  end
end
