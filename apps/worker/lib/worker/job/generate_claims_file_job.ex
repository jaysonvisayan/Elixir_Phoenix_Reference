defmodule Innerpeace.Worker.Job.GenerateClaimsFileJob do
  @moduledoc "This module activates member on it's effectivity date"

  alias Innerpeace.Db.Base.MemberContext
  import Logger
  import Ecto

  def perform do
    MemberContext.generate_claims_file()
  end
end
