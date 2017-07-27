defmodule PodcastsApi.SubscriptionController do
  use PodcastsApi.Web, :controller
  alias PodcastsApi.Subscription
  require Logger

  plug Guardian.Plug.EnsureAuthenticated, handler: PodcastsApi.AuthErrorHandler

  def index(conn, _) do
    users = Repo.all(PodcastsApi.Subscription)

    conn
    |> render("index.json-api", data: users)
  end

  def create(conn, %{
    "data" => %{
      "attributes" => %{
        "feed-id" => feed_id,
      }
    }
  } = params) do
    user = conn
    |> Guardian.Plug.current_resource

    Logger.info "create subscription, params: #{inspect params} user: #{inspect user}"

    changeset = Subscription.changeset %Subscription{}, %{
      user_id: user.id,
      feed_id: feed_id
    }

    case Repo.insert changeset do
      {:ok, subscription} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: subscription)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id"=> id}) do

    Logger.info "delete subscription: #{id}"

    user = conn
    |> Guardian.Plug.current_resource

    subscription = Repo.get!(Subscription, id)

    case Repo.delete subscription do
      {:ok, subscription} ->
        conn
        |> put_status(:created)
        |> render("show.json-api", data: subscription)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json", changeset: changeset)
    end

  end

end
