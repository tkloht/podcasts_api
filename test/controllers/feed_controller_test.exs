defmodule PodcastsApi.FeedControllerTest do
  use PodcastsApi.ConnCase

  alias PodcastsApi.Feed

  defp create_test_feed() do
    Enum.each ["test1", "test2", "test3"], fn name -> 
      Repo.insert! %Feed{
        source_url: "http://feeds.metaebene.me/freakshow/m4a",
        title: "freakshow",
        description: name,
        link: "test",
        image_url: "test"
      }
    end
  end

  setup %{conn: conn} do
    user = Repo.insert! %PodcastsApi.User{}
    { :ok, jwt, _ } = Guardian.encode_and_sign(user, :token)
    conn = conn
    |> put_req_header("content-type", "application/vnd.api+json")
    |> put_req_header("authorization", "Bearer #{jwt}")
 
    {:ok, %{conn: conn, user: user}}
  end

  test "show empty list if no feed available", %{conn: conn} do
    conn = get conn, feed_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "lists all feeds on index",  %{conn: conn} do
    create_test_feed
    conn = get conn, feed_path(conn, :index)
    assert Enum.count(json_response(conn, 200)["data"]) == 3
  end

end
