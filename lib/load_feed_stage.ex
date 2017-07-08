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
    # query = from f in PodcastsApi.Feed,
    #      select: f.source_url
    # feed_urls = Repo.all(query)
    # Logger.info "found feed urls: " <> inspect feed_urls
    # Dispatch the feed_urls as events.
    # These will be buffered if there are no consumers ready.
    {:noreply, feed_urls, state}
  end
  
  def handle_events(events, _from, state) do
    # Do nothing. Events will be dispatched as-is.
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

  # def handle_demand(demand, state) do
  #   Logger.info "in handle_demand (load-feed stage), demand:#{demand}"#, state: " <> inspect state
  #   # events = Enum.to_list(state..state + demand - 1)
  #   {pulled, remaining} = Enum.split(state, demand)
  #   {:noreply, pulled, remaining}
  #   # Do nothing. Events will be dispatched as-is.
  #   # {:noreply, events, state}
  # end

end
