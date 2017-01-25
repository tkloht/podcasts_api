defmodule PodcastsApi.AuthErrorHandler do
 use PodcastsApi.Web, :controller

 def unauthenticated(conn, params) do
  conn
   |> put_status(401)
   |> render(PodcastsApi.ErrorView, "401.json")
 end

 def unauthorized(conn, params) do
  conn
   |> put_status(403)
   |> render(PodcastsApi.ErrorView, "403.json")
 end
end
