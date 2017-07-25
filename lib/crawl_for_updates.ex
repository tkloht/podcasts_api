defmodule PodcastsApi.CrawlForUpdates do
  use GenStage
  require Logger

  alias PodcastsApi.Repo
  import Ecto
  import Ecto.Query

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end


  def init(_args) do
    query = from f in PodcastsApi.Feed,
      select: %{
        id: f.id,
        source_url: f.source_url,
        current_hash: f.hash,
      },
      order_by: f.updated_at
    feed_urls = Repo.all(query)
    
    {:producer, feed_urls}

    # {:producer, []}
  end

  def handle_cast({:push, feed_urls}, state) do
    # query = from f in PodcastsApi.Feed,
    #      select: f.source_url
    # feed_urls = Repo.all(query)
    # Logger.info "found feed urls: " <> inspect feed_urls
    # Dispatch the feed_urls as events.
    # These will be buffered if there are no consumers ready.
    
    # Logger.info "in handle cast... state: #{inspect state} new urls: #{inspect feed_urls}"
    {:noreply, feed_urls, state}
  end
  
  def handle_demand(demand, state) do
    Logger.info "in handle_demand, demand:#{demand} state: #{length(state)}"#, state: " <> inspect state
    # events = Enum.to_list(state..state + demand - 1)

    events = 
      if length(state) >= demand do
        state
      else
        Logger.warn "not enough events, get some new ones"
        query = from f in PodcastsApi.Feed,
          select: %{id: f.id, source_url: f.source_url},
          order_by: f.updated_at
        Repo.all(query)
      end
    
    {pulled, remaining} = Enum.split(events, demand)

    Logger.info "produce #{length pulled} events, remaining: #{length remaining}"
    {:noreply, pulled, remaining}
    # Do nothing. Events will be dispatched as-is.
    # {:noreply, events, state}
  end
end
