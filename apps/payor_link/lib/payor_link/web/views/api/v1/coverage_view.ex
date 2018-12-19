defmodule Innerpeace.PayorLink.Web.Api.V1.CoverageView do
  use Innerpeace.PayorLink.Web, :view

  def render("coverage.json", %{coverage: coverage}) do
    %{
      code: coverage.code,
      name: coverage.name,
      description: coverage.description,
      status: coverage.status,
      type: coverage.type,
     plan_type: coverage.plan_type
    }
  end


end
