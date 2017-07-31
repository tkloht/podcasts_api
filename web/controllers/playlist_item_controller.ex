defmodule PodcastsApi.PlaylistItemController do
  use PodcastsApi.Web, :controller

  alias PodcastsApi.PlaylistItem
  alias JaSerializer.Params

  require Logger

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    playlist_items = Repo.all(PlaylistItem)
    render(conn, "index.json-api", data: playlist_items)
  end

  def create(conn, %{"data" => data = %{"type" => "playlist_item", "attributes" => _playlist_item_params}}) do
    
    Logger.info "create item with params: #{inspect(Params.to_attributes(data))}"

    changeset = PlaylistItem.changeset(%PlaylistItem{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, playlist_item} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", playlist_item_path(conn, :show, playlist_item))
        |> render("show.json-api", data: playlist_item)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    playlist_item = Repo.get!(PlaylistItem, id)
    render(conn, "show.json-api", data: playlist_item)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => "playlist_item", "attributes" => _playlist_item_params}}) do
    playlist_item = Repo.get!(PlaylistItem, id)
    changeset = PlaylistItem.changeset(playlist_item, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, playlist_item} ->
        render(conn, "show.json-api", data: playlist_item)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    playlist_item = Repo.get!(PlaylistItem, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(playlist_item)

    send_resp(conn, :no_content, "")
  end

end
