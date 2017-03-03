defmodule PodcastsApi.UserView do
  use PodcastsApi.Web, :view
  use JaSerializer.PhoenixView

  attributes [:email, :username]

end
