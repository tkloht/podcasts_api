defmodule PodcastsApi.Router do
  use PodcastsApi.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
  end


  scope "/api", PodcastsApi do
    pipe_through :api

    resources "session", SessionController, only: [:index]
  end
end
