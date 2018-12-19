defmodule Innerpeace.PayorLink.Web.Api.AuthorizationController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.Base.{
    AuthorizationContext,
  }

  def get_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id,
        "unit" => unit
      }) do
    amount = AuthorizationContext.get_op_fppr_amount(id, facility_id, unit)
    json(conn, Poison.encode!(amount))
  end

  def get_emergency_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id,
        "unit" => unit
      }) do
    amount = AuthorizationContext.get_er_fppr_amount(id, facility_id, unit)
    json(conn, Poison.encode!(amount))
  end

  def get_emergency_solo_amount_by_payor_procedure_id(conn, %{
        "id" => id,
        "facility_id" => facility_id
      }) do
    amount = AuthorizationContext.get_er_fppr_solo_amount(id, facility_id)
    json(conn, Poison.encode!(amount))
  end
end
