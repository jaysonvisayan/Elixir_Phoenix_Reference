defmodule Innerpeace.PayorLink.Web.PharmacyView do
  use Innerpeace.PayorLink.Web, :view

  def render("load_all_pharmacy.json", %{pharmacy: pharmacy}) do
    drug_codes = Enum.map(pharmacy, &(&1.drug_code))
    %{
      drug_codes: drug_codes
    }
   end

  def render("pharmacy.json", %{pharmacy: pharmacy}) do
    %{
      drug_code: pharmacy.drug_code,
     }
  end
end
