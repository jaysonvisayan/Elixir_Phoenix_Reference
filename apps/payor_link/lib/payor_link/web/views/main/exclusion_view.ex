defmodule Innerpeace.PayorLink.Web.Main.ExclusionView do
  use Innerpeace.PayorLink.Web, :view

  def updated_at(exclusion) do
    date = exclusion.updated_at
    updated_month = date.month
    months_map = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    new_converted_date = months_map[updated_month]
    new_date= "#{(new_converted_date)} #{(date.day)}, #{(date.year)}"
  end

  defp applicability(true, true), do: "Principal & Dependent"
  defp applicability(true, false), do: "Principal"
  defp applicability(false, true), do: "Dependent"
  defp applicability(false, false), do: "N/A"
  defp applicability(_, _), do: "N/A"

end
