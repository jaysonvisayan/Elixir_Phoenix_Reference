defmodule Innerpeace.PayorLink.Web.Api.AcuScheduleController do
  use Innerpeace.PayorLink.Web, :controller

  alias Innerpeace.Db.{
    Base.AcuScheduleContext,
    Schemas.AcuSchedule
  }
  alias Innerpeace.Db.Base.Api.AcuScheduleContext, as: ApiAcuScheduleContext

  def acu_schedule_download(conn, %{"ids" => ids}) do
    result = AcuScheduleContext.generate_xlsx(ids, [])
    conn
    |> json(result)
  end

  def delete_xlsx(conn, %{"files" => files}) do
    path = Path.expand('./export')
    path =
      path
      |> String.split("/export")
      |> List.first()

    for file <- files do
      folder =
        file
        |> String.split("/")
      File.rm_rf("#{path}/#{file}")
    end
    conn
    |> json(%{status: true})
  end

  def acu_schedule_export(conn, params) do
    params = params["acu_data"]
    params = Poison.decode!(params)
    id = params["id"]
    datetime = params["datetime"]
    with {:ok, file} <- AcuScheduleContext.acu_schedule_export(id, datetime) do
      {file_name, binary} = file

      conn
      |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      |> put_resp_header("content-disposition", "inline; filename=#{file_name}")
      |> send_resp(200, binary)
    else
      _ ->
        json(conn, %{status: "failed"})
    end
  end
end
