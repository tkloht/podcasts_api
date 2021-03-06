defmodule PodcastsApi.LoadFeedStage do
  use GenStage
  require Logger

  def start_link(initial \\ nil) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [{PodcastsApi.CrawlForUpdates, max_demand: 100, min_demand: 5}]}
  end

  def handle_cast({:push, feed_urls}, state) do
    {:noreply, feed_urls, state}
  end

  # this suppresses "unexpected message :DOWN..." errors
  # TODO: is this ok, or have i screwed up and need to fix?
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # Logger.debug "received unexpected down message"
    {:noreply, [], state}
  end

  # load one feed for given feed_url
  # emit tuple  of feed_url and feed_body
  # feed body is nil if could not be loaded
  def get_feed(event) do
    %{source_url: feed_url} = event
    Logger.info "load feed for url: #{feed_url}"
    body = case HTTPoison.get(feed_url, [], [ ssl: [{:versions, [:'tlsv1.2']}], follow_redirect: true ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info "received a feed for url: #{feed_url}"
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warn "feed not found for url: #{feed_url}"
        nil
      {:error, _error} ->
        Logger.error "unable to load feed at #{feed_url}"
        nil
    end

    hash = if body != nil do
      :crypto.hash(:md5 , body) |> Base.encode16()
    else
      nil
    end
      
    event
     |> Map.put(:feed_body, body)
     |> Map.put(:body_hashed, hash)
  end 

  def handle_events(events, _from, state) do
    Logger.info "load feeds for #{length events} events"
    # tasks = Enum.map(events,  Task.async(&get_feed/1))
    results = events
      |> Enum.map(fn event -> Task.async(fn -> get_feed(event) end) end)
      |> collect_results
      |> Enum.filter(fn x -> x != nil end)
      |> Enum.filter(fn %{feed_body: body} -> body != nil end)

    Logger.info "finished loading #{length(results)} feeds"

    expected = Enum.map(events,fn %{source_url: source_url} -> source_url end)
    actual = Enum.map(results,fn %{source_url: source_url} -> source_url end)
    missing = expected -- actual
    if missing != [] do
      Logger.error "#{length missing} missing feeds: #{inspect missing}"
    end
    {:noreply, results, state}
  end

  defp collect_results(tasks) do
    Logger.info "collect results for tasks: #{length tasks}"
    timeout_ref = make_ref()
    timer = Process.send_after(self(), {:timeout, timeout_ref}, 30000)
    try do
      collect_results(tasks, [], timeout_ref)
    after
      :erlang.cancel_timer(timer)
      receive do
        {:timeout, ^timeout_ref} -> :ok
        after 0 -> :ok
      end
    end
  end

  def collect_results([], aggregator, _) do
    Logger.info "collected all tasks: #{length aggregator}"
    aggregator
  end

  def collect_results(tasks, aggregator, timeout_ref) do
    Logger.info "collect results, pending: #{length tasks} ------- resolved: #{length aggregator}"
    receive do
      {:timeout, ^timeout_ref} ->
        Logger.info ">>> received timeout"
        aggregator

      {ref, msg} ->
        # Logger.info "received message: #{inspect ref} #{inspect tasks}"
        collect_results(
          Enum.filter(tasks, fn %Task{ref: delete_ref} -> ref != delete_ref end),
          [msg | aggregator],
          timeout_ref
        )
          
    end
  end

end
