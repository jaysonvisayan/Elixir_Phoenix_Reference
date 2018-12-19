defmodule Innerpeace.PayorLink.Web.RoomView do
  use Innerpeace.PayorLink.Web, :view

  alias Innerpeace.Db.Base.Api.UtilityContext

   def display_date(date) do
    "#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}"
  end

  def render("room_logs.json", %{room_logs: room_logs}) do
    %{
      room_logs: render_many(
        room_logs,
        Innerpeace.PayorLink.Web.RoomView,
        "logs.json",
        as: :logs
      )
    }
  end

  def render("logs.json", %{logs: logs}) do
    %{
      "message": UtilityContext.sanitize_value(logs.message),
      "inserted_at": UtilityContext.sanitize_value(logs.inserted_at)
    }
  end
end
