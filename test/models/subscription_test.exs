defmodule PodcastsApi.SubscriptionTest do
  use PodcastsApi.ModelCase

  alias PodcastsApi.Subscription

  @valid_attrs %{
    user_id: 1, 
    feed_id: 1
  }
  @invalid_attrs %{}

  def create_test_feed() do
    Enum.each ["test1"], fn name -> 
      Repo.insert! %PodcastsApi.Feed {
        source_url: "http://feeds.metaebene.me/freakshow/m4a",
        title: "freakshow",
        description: name,
        link: "test",
        image_url: "test",
        id: 1
      }
    end
  end

  def create_test_user() do
    Enum.each ["user1"], fn name -> 
      Repo.insert! %PodcastsApi.User {
        username: name,
        password: "abcde1234",
        password_confirmation: "abcde1234",
        email: "testuser@example.com",
        id: 1
      }
    end
  end

  test "changeset with valid attributes" do
    create_test_feed
    create_test_user
    changeset = Subscription.changeset(%Subscription{}, @valid_attrs)
    assert changeset.valid?
  end

  # test "belongs to a feed" do
  #   feed = Repo.insert!(%PodcastsApi.Feed{})
  #   episode = Repo.insert!(%Episode{feed_id: feed.id})
  #   episode = Episode |> Repo.get(episode.id) |> Repo.preload(:feed)
  #   assert feed == episode.feed
  # end

end
