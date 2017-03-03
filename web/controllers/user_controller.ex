defmodule PodcastsApi.UserController do
  use PodcastsApi.Web, :controller

  alias PodcastsApi.User
  plug Guardian.Plug.EnsureAuthenticated, handler: PodcastsApi.AuthErrorHandler

  def current(conn, _) do
    user = conn
    |> Guardian.Plug.current_resource

    conn
    |> render(PodcastsApi.UserView, "show.json-api", data: user)
  end
end
