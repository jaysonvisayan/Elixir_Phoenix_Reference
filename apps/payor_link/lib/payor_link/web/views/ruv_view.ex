defmodule Innerpeace.PayorLink.Web.RUVView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Base.Api.UtilityContext

  def load_date(date_time) do
    month = append_zeros(Integer.to_string(date_time.month))
    day = append_zeros(Integer.to_string(date_time.day))
    year = Integer.to_string(date_time.year)

    _result = month <> "/" <> day <> "/" <> year
  end

  def append_zeros(string) do
    if String.length(string) == 1 do
      "0" <> string
    else
      string
    end
  end

  def render("ruv.json", %{ruv: ruv}) do
    %{
      id: ruv.id,
      effectivity_date: ruv.effectivity_date
    }
  end

  def render("ruv_logs.json", %{logs: logs}) do
    for log <- logs do
      %{
        "message": UtilityContext.sanitize_value(log.message),
        "inserted_at": log.inserted_at
      }
    end
  end
end
