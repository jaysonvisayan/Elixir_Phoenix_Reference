defmodule MemberLinkWeb.PageView do
  use MemberLinkWeb, :view

  def status do
    %{
      "Pending" => "pending",
      "For Approval" => "for-approval",
      "Approved" => "eligible"
     }
  end

  def count_status(loa) do
    %{
      "Pending" => Enum.count(loa, &(&1.status == "Pending")),
      "For Approval" => Enum.count(loa, &(&1.status == "For Approval")),
      "Approved" => Enum.count(loa, &(&1.status == "Approved"))
     }
  end
end
