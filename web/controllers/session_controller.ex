defmodule PodcastsApi.SessionController do
  use PodcastsApi.Web, :controller

  import Ecto.Query, only: [where: 2]
  import Comeonin.Bcrypt

  alias PodcastsApi.User

  def create(conn, %{
    "grant_type" => "password",
    "username" => username,
    "password" => password}) do
  
    try do

      user = User
      |> where(username: ^username)
      |> Repo.one!
      cond do
        checkpw(password, user.password_hash) ->
          # encode jwt
          { :ok, jwt, _} = Guardian.encode_and_sign(user, :token)

          conn
            |> json(%{ access_token: jwt })

        # login unsuccessful
        true ->
          conn
          |> put_status(401)
          |> render(PodcastsApi.ErrorView, "401.json")
      end
    rescue
      e ->
        IO.inspect e # print error for debugging

        conn
        |> put_status(401)
        |> render(PodcastsApi.ErrorView, "401.json")
    end
  end

  def create(_, %{"grant_type" =>_}) do
    throw "Unsupported grant_type"
  end

end
