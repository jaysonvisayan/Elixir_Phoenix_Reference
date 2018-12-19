defmodule Innerpeace.PayorLink.Web.UserAccessActivationView do
  use Innerpeace.PayorLink.Web, :view

  def count_data(logs) do
    result = Enum.into(logs, [], &(&1.status))
    %{
      success: Enum.count(result, &(&1 == "success")),
      failed: Enum.count(result, &(&1 == "failed")),
      total: Enum.count(result)
     }
  end
end
