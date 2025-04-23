defmodule SigilLockWeb.Router do
  use SigilLockWeb, :router

  # Pipeline for API requests
  pipeline :api do
    plug :accepts, ["json"]
    # You might want to add other plugs here, like CORS (plug Plug.Cors, origins: "*")
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Jason
  end

  # Pipeline for authenticated API requests
  pipeline :authenticated_api do
    # Add the authentication plug
    plug SigilLockWeb.Plugs.Authenticate
  end

  # API scope
  # Use "/" or "/api" as your base path
  scope "/", SigilLockWeb do
    pipe_through :api

    # Public API endpoint (optional)
    get "/public", PageController, :public_api

    # Secure API endpoint
    # Apply the authentication pipeline
    pipe_through :authenticated_api
    get "/secure", PageController, :secure_api
  end

  # Remove /dev scope as it's for browser-based tools
end
