defmodule Innerpeace.Db.IndustrySeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.IndustryContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case IndustryContext.insert_or_update_industry(params) do
        {:ok, industry} ->
          industry
      end
    end)
  end
end
