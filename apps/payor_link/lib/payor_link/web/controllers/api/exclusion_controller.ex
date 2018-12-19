 defmodule Innerpeace.PayorLink.Web.Api.ExclusionController do
  use Innerpeace.PayorLink.Web, :controller
  alias Innerpeace.Db.Base.{
    ExclusionContext,
  }

  def cpt_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [["Payor Cpt Code", "Remarks"]] ++
      ExclusionContext.cpt_get_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)

  end

  def icd_batch_download(conn, %{"log_id" => log_id, "status" => status}) do

    data = [["Diagnosis Code", "Remarks"]] ++
      ExclusionContext.icd_get_batch_log(log_id, status)
      |> CSV.encode
      |> Enum.to_list
      |> to_string

    conn
    |> json(data)

  end
end
