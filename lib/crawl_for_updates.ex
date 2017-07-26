defmodule PodcastsApi.CrawlForUpdates do
  use GenStage
  use Timex
  require Logger

  alias PodcastsApi.Repo
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
    feed_urls = if Application.get_env(:podcasts_api, :update_on_startup) do
      Repo.all(query)
    else
      []
    end
    
    {:producer, %{
      feed_urls: feed_urls,
      last_updated: Timex.now
      }
    }

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
  
  def handle_demand(
    demand,
    %{feed_urls: feed_urls, last_updated: last_updated })
  do
    Logger.info "in handle_demand, demand:#{demand} state: #{length(feed_urls)}"

    {last_updated, feed_urls} = 
      if length(feed_urls) >= demand do
        {last_updated, feed_urls}
      else
        Logger.warn "not enough events, get some new ones"
        since_updated = Timex.diff(Timex.now, last_updated, :minutes)

        update_interval = Application.get_env(:podcasts_api, :feed_update_interval)
        if since_updated < update_interval do
          sleep_for = update_interval - since_updated
          Logger.error("last updated was #{since_updated} minutes ago,
            delay next update for #{sleep_for} minutes")
          Process.sleep(60000 * sleep_for)
        end

        query = from f in PodcastsApi.Feed,
          select: %{id: f.id, source_url: f.source_url},
          order_by: f.updated_at
        {Timex.now, Repo.all(query)}
      end
    
    {pulled, remaining} = Enum.split(feed_urls, demand)

    Logger.info "produce #{length pulled} events, remaining: #{length remaining}"
    {:noreply, pulled, %{feed_urls: remaining, last_updated: last_updated}}
  end
end
