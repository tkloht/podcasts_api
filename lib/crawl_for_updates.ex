defmodule PodcastsApi.CrawlForUpdates do
  use GenStage
  import Logger
  alias PodcastsApi.Repo
  import Ecto
  import Ecto.Query

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end


  def init(_args) do
    query = from f in PodcastsApi.Feed,
      select: f.source_url,
      order_by: f.updated_at
    feed_urls = Repo.all(query)
    # feed_urls = Repo.all(PodcastsApi.Feed)
    # Logger.info "found feed urls: " <> inspect feed_urls

    {:producer, feed_urls}
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
  
  def handle_demand(demand, state) do
    Logger.info "in handle_demand, demand:#{demand}"#, state: " <> inspect state
    # events = Enum.to_list(state..state + demand - 1)
    {pulled, remaining} = Enum.split(state, demand)
    {:noreply, pulled, remaining}
    # Do nothing. Events will be dispatched as-is.
    # {:noreply, events, state}
  end
end
