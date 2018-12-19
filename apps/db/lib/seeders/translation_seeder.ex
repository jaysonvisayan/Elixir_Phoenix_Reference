defmodule Innerpeace.Db.TranslationSeeder do
  @moduledoc false

  alias Innerpeace.Db.Base.TranslationContext

  def seed(data) do
    Enum.map(data, fn(params) ->
      case TranslationContext.insert_or_update_translation(params) do
        {:ok, translation} ->
          translation
      end
    end)
  end
end
