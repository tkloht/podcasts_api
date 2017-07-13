defmodule PodcastsApi.InsertFeedStage do
  use GenStage
  import Logger
  alias PodcastsApi.Feed
  alias PodcastsApi.Repo
  import PodcastsApi.ParseFeed

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{PodcastsApi.ParseFeedStage, max_demand: 10, min_demand: 5}]}
  end

  def handle_cast({:push, feeds}, state) do
    {:noreply, feeds, state}
  end

  def get_episodes_by_feed_id(feed_id) do
    %{:episodes => episodes} = Repo.get(PodcastsApi.Feed, feed_id)
      |> Repo.preload(:episodes)
    # IO.puts "get episodes by feed id: "
    # IO.inspect(episodes)

    episodes
  end
  
  def handle_events(events, _from, state) do
    Logger.info "insert #{length events} feeds"
    # parsed = Enum.map(events, &PodcastsApi.ParseFeed.parseFeed/2)
    Enum.each(events, fn event ->

      %{id: id, body_parsed: parsed_feed} = event

      parsed_feed = parsed_feed
        |> insert_feed_id(id)
        |> insert_episode_ids(get_episodes_by_feed_id(id))

      feed = Repo.get!(Feed, id) |> Repo.preload(:episodes)
      changeset = Feed.changeset(feed, parsed_feed)

      # changeset = Feed.changeset %Feed{}, parsed_feed
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
