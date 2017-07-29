defmodule PodcastsApi.PlaylistController do
  use PodcastsApi.Web, :controller
  require Logger
  alias PodcastsApi.Playlist
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    playlists = Repo.all(Playlist)
    render(conn, "index.json-api", data: playlists)
  end

  def create(conn, %{"data" => data = %{"type" => "playlist", "attributes" => _playlist_params}}) do
    
    user = conn
    |> Guardian.Plug.current_resource

    params = Params.to_attributes(data)
    |> Map.put("user_id", user.id)

    Logger.info "create changeset with params: #{inspect params}"

    changeset = Playlist.changeset(%Playlist{}, params)

    case Repo.insert(changeset) do
      {:ok, playlist} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", playlist_path(conn, :show, playlist))
        |> render("show.json-api", data: playlist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    playlist = Repo.get!(Playlist, id)
    render(conn, "show.json-api", data: playlist)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "playlist", "attributes" => _playlist_params}}) do
    playlist = Repo.get!(Playlist, id)
    changeset = Playlist.changeset(playlist, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, playlist} ->
        render(conn, "show.json-api", data: playlist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    playlist = Repo.get!(Playlist, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(playlist)

    send_resp(conn, :no_content, "")
  end

end
