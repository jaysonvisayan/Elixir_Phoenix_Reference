defmodule Innerpeace.Db.TermsNConditionSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.AuthContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case AuthContext.insert_or_update_terms(params) do
        {:ok, terms} ->
          terms
      end
    end)
  end
end
