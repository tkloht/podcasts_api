defmodule PodcastsApi.LoadFeedStage do
  use GenStage
  import Logger

  @max_demand 100

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial)
  end


  def init(state) do
    {:consumer, state, subscribe_to: [{PodcastsApi.CrawlForUpdates, max_demand: 10, min_demand: 5}]}
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
    Enum.map(events, fn feed_url -> 
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
    {:noreply, [], state}
  end
end
