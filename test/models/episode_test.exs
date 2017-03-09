defmodule PodcastsApi.EpisodeTest do
  use PodcastsApi.ModelCase

  alias PodcastsApi.Episode

  @valid_attrs %{
    title: "test title",
    link: "http://test.com/feed/item",
    pubDate: Timex.parse!("Thu, 23 Feb 2017 02:11:53 +0000", "{RFC822}"),
    enclosure: "http://test.com/feed/item.mp3",
    feed_id: 1
  }
  @invalid_attrs %{}

  def create_test_feed() do
    Enum.each ["test1"], fn name -> 
      Repo.insert! %PodcastsApi.Feed{
        source_url: "http://feeds.metaebene.me/freakshow/m4a",
        title: "freakshow",
        description: name,
        link: "test",
        image_url: "test",
        id: 1
      }
    end
  end

  test "changeset with valid attributes" do
    create_test_feed
    changeset = Episode.changeset(%Episode{}, @valid_attrs)
    assert changeset.valid?
  end

  test "belongs to a feed" do
    feed = Repo.insert!(%PodcastsApi.Feed{})
    episode = Repo.insert!(%Episode{feed_id: feed.id})
    episode = Episode |> Repo.get(episode.id) |> Repo.preload(:feed)
    assert feed == episode.feed
  end

end
