defmodule AccountLinkWeb.UserView do
  use AccountLinkWeb, :view

  def address(account_group_address) do
    if Enum.count(account_group_address) > 1 do
      address = for account_address <- account_group_address do
        if account_address.type == "Account Address" do
          account_address
        end
      end

      address =
        address
        |> Enum.uniq()
        |> List.delete(nil)
        |> List.flatten()
        |> List.first()

      "#{address.line_1}, #{address.line_2}, #{address.city}, #{address.province}, #{address.country}, #{address.region}, #{address.postal_code}"
    else
      address = List.first(account_group_address)

      "#{address.line_1}, #{address.line_2}, #{address.city}, #{address.province}, #{address.country}, #{address.region}, #{address.postal_code}"
    end
  end
end
