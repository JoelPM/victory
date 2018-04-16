defmodule VictoryWeb.Router do
  use VictoryWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", VictoryWeb do
    pipe_through :api
  end
end
