defmodule PodcastsApi.PlaylistItemControllerTest do
  use PodcastsApi.ConnCase

  alias PodcastsApi.PlaylistItem
  alias PodcastsApi.Repo

  @valid_attrs %{}
  @invalid_attrs %{}

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn}
  end
  
  defp relationships do 
    playlist = Repo.insert!(%PodcastsApi.Playlist{})
    episode = Repo.insert!(%PodcastsApi.Episode{})

    %{
      "playlist" => %{
        "data" => %{
          "type" => "playlist",
          "id" => playlist.id
        }
      },
      "episode" => %{
        "data" => %{
          "type" => "episode",
          "id" => episode.id
        }
      },
    }
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, playlist_item_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    playlist_item = Repo.insert! %PlaylistItem{}
    conn = get conn, playlist_item_path(conn, :show, playlist_item)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{playlist_item.id}"
    assert data["type"] == "playlist_item"
    assert data["attributes"]["playlist_id"] == playlist_item.playlist_id
    assert data["attributes"]["episode_id"] == playlist_item.episode_id
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, playlist_item_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, playlist_item_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist_item",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(PlaylistItem, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, playlist_item_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist_item",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    playlist_item = Repo.insert! %PlaylistItem{}
    conn = put conn, playlist_item_path(conn, :update, playlist_item), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist_item",
        "id" => playlist_item.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(PlaylistItem, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    playlist_item = Repo.insert! %PlaylistItem{}
    conn = put conn, playlist_item_path(conn, :update, playlist_item), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist_item",
        "id" => playlist_item.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    playlist_item = Repo.insert! %PlaylistItem{}
    conn = delete conn, playlist_item_path(conn, :delete, playlist_item)
    assert response(conn, 204)
    refute Repo.get(PlaylistItem, playlist_item.id)
  end

end
