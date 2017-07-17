defmodule PodcastsApi.Scheduler do
  use Quantum.Scheduler, otp_app: :podcasts_api
  require Logger

  alias PodcastsApi.Repo
  import Ecto
  import Ecto.Query

  def enqueue_feed_update() do
    Logger.info ">>>>> enqueue feed update???"

    query = from f in PodcastsApi.Feed,
      select: %{id: f.id, source_url: f.source_url},
      order_by: f.updated_at
    feed_urls = Repo.all(query)

    GenStage.cast(PodcastsApi.CrawlForUpdates, {:push, feed_urls})
  end

end
