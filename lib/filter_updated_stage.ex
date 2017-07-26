defmodule PodcastsApi.FilterUpdatedStage do
  use GenStage
  require Logger

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [{PodcastsApi.LoadFeedStage, max_demand: 100, min_demand: 5}]}
  end

  def handle_cast({:push, feeds}, state) do
    {:noreply, feeds, state}
  end
  
  # determine if feed has updated
  # emit only feeds which have updated
  def handle_events(events, _from, state) do

    updated = Enum.filter(events, fn
      %{body_hashed: hash, current_hash: current_hash} ->
        current_hash != nil && current_hash != hash
      _missing_hash -> true
    end)

    Logger.debug "updated feeds: #{inspect(Enum.map(updated, fn x -> x.source_url end))}"
    {:noreply, updated, state}
  end
end
