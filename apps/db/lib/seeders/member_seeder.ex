defmodule Innerpeace.Db.MemberSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.MemberContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case MemberContext.insert_or_update_member(params) do
        {:ok, member} ->
          member
      end
    end)
  end
end
