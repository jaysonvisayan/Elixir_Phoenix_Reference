defmodule Innerpeace.PayorLink.Application do
  @moduledoc false

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Innerpeace.PayorLink.Web.Endpoint, []),
      worker(Guardian.DB.Token.SweeperServer, []),
      worker(Innerpeace.PayorLink.Scheduler, []),
      # supervisor(Exq.Enqueuer, [])
      # Start your own worker by calling: Innerpeace.PayorLink.Worker.start_link(arg1, arg2, arg3)
      # worker(Innerpeace.PayorLink.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Innerpeace.PayorLink.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
