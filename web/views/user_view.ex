defmodule PodcastsApi.UserView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:email, :username, :inserted_at]

end
