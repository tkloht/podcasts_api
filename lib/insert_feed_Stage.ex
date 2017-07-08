defmodule PodcastsApi.InsertFeedStage do
  use GenStage
  import Logger
  alias PodcastsApi.Feed
  alias PodcastsApi.Repo

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{PodcastsApi.ParseFeedStage, max_demand: 10, min_demand: 5}]}
  end

  def handle_cast({:push, feeds}, state) do
    {:noreply, feeds, state}
  end
  
  def handle_events(events, _from, state) do
    Logger.info "insert #{length events} feeds"
    # parsed = Enum.map(events, &PodcastsApi.ParseFeed.parseFeed/2)
    Enum.each(events, fn parsed_feed -> 
      changeset = Feed.changeset %Feed{}, parsed_feed
      case Repo.insert changeset do
        {:ok, feed} ->
          Logger.info "inserted feed: #{Map.get(feed, :title, :title_not_found)}"
        {:error, changeset} ->
          Logger.info "unable to insert changeset for feed: #{inspect changeset}"
      end 
    end)

    {:noreply, [], state}
  end
end
