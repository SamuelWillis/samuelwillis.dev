defmodule SamuelWillis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SamuelWillisWeb.Telemetry,
      # Start the Ecto repository
      SamuelWillis.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: SamuelWillis.PubSub},
      # Start Finch
      {Finch, name: SamuelWillis.Finch},
      # Start the Endpoint (http/https)
      SamuelWillisWeb.Endpoint,
      # Start a worker by calling: SamuelWillis.Worker.start_link(arg)
      SamuelWillis.Metrics.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SamuelWillis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SamuelWillisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
