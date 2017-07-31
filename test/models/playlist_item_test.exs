defmodule PodcastsApi.PlaylistItemTest do
  use PodcastsApi.ModelCase

  alias PodcastsApi.PlaylistItem

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PlaylistItem.changeset(%PlaylistItem{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PlaylistItem.changeset(%PlaylistItem{}, @invalid_attrs)
    refute changeset.valid?
  end
end
