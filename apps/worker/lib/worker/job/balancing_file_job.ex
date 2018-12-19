defmodule Innerpeace.Worker.Job.BalancingFileJob do
  @moduledoc "This module generates balancing file at the end of the day"

  alias Innerpeace.Db.Base.MemberContext

  def perform(params) do
    MemberContext.generate_balancing_file()
    # Exq
    # |> Exq.enqueue_in(
    #   "balancing_file_job", 86_400,
    #   "Innerpeace.Worker.Job.BalancingFileJob",
    #   [123]
    # )
  end

end
