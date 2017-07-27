defmodule PodcastsApi.Router do
  use PodcastsApi.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
  end

  pipeline :api_auth do
    plug :accepts, ["json", "json-api"]
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  scope "/api", PodcastsApi do
    pipe_through :api

    post "/register", RegistrationController, :create
    post "/token", SessionController, :create, as: :login
    resources "/feeds", FeedController, except: [:new, :edit]
    resources "/episodes", EpisodeController, except: [:new, :edit]
  end

  scope "/api", PodcastsApi do
    pipe_through :api_auth

    get "/users/current", UserController, :current
    get "/users", UserController, :index
    post "/update_feed", FeedController, :update
    get "/search", SearchController, :get
    resources "/subscriptions", SubscriptionController, except: [:new, :edit]

  end

end
