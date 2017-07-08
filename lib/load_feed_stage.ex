defmodule PodcastsApi.LoadFeedStage do
  use GenStage
  import Logger

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end


  def init(state) do
    {:producer_consumer, state, subscribe_to: [{PodcastsApi.CrawlForUpdates, max_demand: 100, min_demand: 5}]}
  end

  def handle_cast({:push, feed_urls}, state) do
    {:noreply, feed_urls, state}
  end
  
  # events is an array of feed-urls
  # load the feed at the given url for each
  # emit array of tupels with feed-url and feed-body  
  def handle_events(events, _from, state) do
    # Loggger.info "events in consumer:" <> events
    # Logger.info "got new events: #{inspect events}"
    loaded_feeds = Enum.map(events, fn feed_url -> 
      Logger.info "getting feed at #{feed_url}"
      case HTTPoison.get(feed_url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          Logger.info "received a feed for url: #{feed_url}"
          {feed_url, body}
        {_error} ->
          Logger.error "unable to load feed at #{feed_url}"
          {feed_url, nil}
      end
    end)
    {:noreply, loaded_feeds, state}
  end

end
