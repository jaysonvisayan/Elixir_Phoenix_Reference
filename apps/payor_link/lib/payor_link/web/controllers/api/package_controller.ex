defmodule Innerpeace.PayorLink.Web.Api.PackageController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.{
    Db.Base.PackageContext
  }

  def get_all_package_code_and_name(conn, _params) do
    package =  PackageContext.get_all_package_code_and_name()
    json conn, Poison.encode!(package)
  end

  def get_facility_by_name(conn, %{"name" => name}) do
    code = PackageContext.check_one_facility(name)
    json conn, Poison.encode!(code)
  end
end
