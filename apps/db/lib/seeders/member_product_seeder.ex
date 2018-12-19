defmodule Innerpeace.Db.MemberProductSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.MemberContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case MemberContext.insert_or_update_member_product(params) do
        {:ok, member_product} ->
          member_product
      end
    end)
  end
end
