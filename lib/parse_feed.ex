defmodule PodcastsApi.ParseFeed do
  import SweetXml

  def insert_feed_id(parsed_feed, feed_id) do
    Map.put(parsed_feed, :id, feed_id)
  end

  def insert_episode_ids(parsed_feed, episodes) do
    episodes_with_ids = Enum.map(
      parsed_feed.episodes,
      fn(episode) ->
        %{:guid => episode_guid} = episode
        case Enum.find(episodes, fn(%{:guid => x}) ->
          x == episode_guid
        end) do
          %{:id => episode_id} -> Map.put(episode, :id, episode_id)
          _ -> episode          
        end
      end
    )
    # IO.puts "episodes with ids: "
    # IO.inspect episodes_with_ids
    Map.put(parsed_feed, :episodes, episodes_with_ids)
  end

  def parseFeed(source_url, feedBody) do
    IO.puts "in parseFeed..."
    case is_feed feedBody do
      {:ok} ->
        parsed = feedBody
        |> xmap(
            title: ~x"//channel/title/text()"S,
            description: ~x"//channel/description/text()"S,
            link: ~x"//channel/link/text()"S,
            image_url: ~x"//channel/image/url/text()"S,
            episodes: [
              ~x"//channel/item"l,
              title: ~x"./title/text()"S,
              subtitle: ~x"./itunes:subtitle/text()"S,
              link: ~x"./link/text()"S,
              pubDate: ~x"./pubDate/text()"S |> transform_by(fn date_string -> parse_pubdate(date_string) end),
              guid: ~x"./guid/text()"S,
              description: ~x"./description/text()"S,
              itunes_summary: ~x"./itunes:summary/text()"S,
              content_encoded: ~x"./content:encoded/text()"S,
              duration: ~x"./itunes:duration/text()"S,
              shownotes: ~x"/content:encoded/text()"S,
              enclosure: ~x"./enclosure/@url"S
              ]
          )
        |> Map.put(:source_url, source_url)
        # IO.puts "feed is parsed..."
        # IO.inspect(parsed)
        {:ok, parsed }
      {:error, :no_xml} -> {:error, :no_xml}
      {:error, :no_feed} -> {:error, :no_feed}
    end
  end

  def parse_pubdate(date_string) do
    {:ok, parsed} = Timex.parse(date_string, "{RFC822}")
    parsed
  end

  def is_feed(feedBody) do
    try do
      case feedBody |> xmap(
        title: ~x"/rss/channel/title",
        description: ~x"/rss/channel/description",
        link: ~x"/rss/channel/link",
      ) do
        %{title: nil} -> {:error, :no_feed}    
        %{description: nil} -> {:error, :no_feed}    
        %{link: nil} -> {:error, :no_feed}    
        _ -> {:ok}
      end
    catch
      :exit, _ -> {:error, :no_xml}
    end
  end

end