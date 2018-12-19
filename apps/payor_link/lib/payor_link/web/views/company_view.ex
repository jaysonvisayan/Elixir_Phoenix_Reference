defmodule Innerpeace.PayorLink.Web.CompanyView do
  use Innerpeace.PayorLink.Web, :view

   def display_date(date) do
    "#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}"
   end

end
