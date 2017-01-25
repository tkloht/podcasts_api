defmodule PodcastsApi.UserView do
  use PodcastsApi.Web, :view

  def render("index.json", %{users: users}) do
    %{data: render_many(users, PodcastsApi.UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, PodcastsApi.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{
      "type": "user",
      "id": user.id,
      "attributes": %{
        "email": user.email,
        "username": user.username,
      }
    }
  end
end
