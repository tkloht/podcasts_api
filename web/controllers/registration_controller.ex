defmodule PodcastsApi.RegistrationController do
  use PodcastsApi.Web, :controller
  alias PodcastsApi.User

  def create(conn, %{"data" => %{"type" => "users",
  	"attributes" => %{"email" => email,
  	  "username" => username,
  	  "password" => password,
  	  "password-confirmation" => password_confirmation}}}) do

    changeset = User.changeset %User{}, %{
      email: email,
      username: username,
      password_confirmation: password_confirmation,
      password: password
    }

    case Repo.insert changeset do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(PodcastsApi.UserView, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json", changeset: changeset)
    end

  end
end
