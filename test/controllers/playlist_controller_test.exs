defmodule PodcastsApi.PlaylistControllerTest do
  use PodcastsApi.ConnCase

  alias PodcastsApi.Playlist
  alias PodcastsApi.Repo

  @valid_attrs %{title: "some content"}
  @invalid_attrs %{}

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn}
  end
  
  defp relationships do 
    user = Repo.insert!(%PodcastsApi.User{})

    %{
      "user" => %{
        "data" => %{
          "type" => "user",
          "id" => user.id
        }
      },
    }
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, playlist_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    playlist = Repo.insert! %Playlist{}
    conn = get conn, playlist_path(conn, :show, playlist)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{playlist.id}"
    assert data["type"] == "playlist"
    assert data["attributes"]["title"] == playlist.title
    assert data["attributes"]["user_id"] == playlist.user_id
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, playlist_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, playlist_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Playlist, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, playlist_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    playlist = Repo.insert! %Playlist{}
    conn = put conn, playlist_path(conn, :update, playlist), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist",
        "id" => playlist.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Playlist, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    playlist = Repo.insert! %Playlist{}
    conn = put conn, playlist_path(conn, :update, playlist), %{
      "meta" => %{},
      "data" => %{
        "type" => "playlist",
        "id" => playlist.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    playlist = Repo.insert! %Playlist{}
    conn = delete conn, playlist_path(conn, :delete, playlist)
    assert response(conn, 204)
    refute Repo.get(Playlist, playlist.id)
  end

end
